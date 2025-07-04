local QBCore = exports["qb-core"]:GetCoreObject()
local ox_inventory = exports.ox_inventory
local DB = lib.load("server.db")
local Medias = {
    management = false
}
local Config = {}

--- helper to register points in ox_inventory once Config is loaded
local DEFAULT_STASH = { slots = 100, weight = 100000 }

local function registerJobStash(job, opts, isPrivate)
    ox_inventory:RegisterStash(
        isPrivate and (job .. "_private") or job,
        opts.label or (job .. (isPrivate and " Private" or " Stash")),
        opts.slots or DEFAULT_STASH.slots,
        opts.weight or DEFAULT_STASH.weight,
        isPrivate or false,
        opts.job or { [job] = opts.grade or 0 }
    )
end
    
local function registerJobShop(job, shop)
    local requireJob = not (shop.requireJob == false or shop.requireJob == 0)
    local baseName = shop.name or (job .. " Shop")
    local inventory = {}
    if shop.inventory then
        for i, item in ipairs(shop.inventory) do
            inventory[i] = {
                name = item.name,
                amount = item.amount,
                price = tonumber(item.price) or 0,
                grade = item.grade
            }
        end
    end

    if table.type(shop.locations) == "array" and #shop.locations >= 2 then
        for i = 1, #shop.locations do
            local cfg = {
                name = baseName,
                inventory = inventory,
                locations = shop.locations[i],
            }
            if requireJob then
                cfg.groups = shop.grades or { [job] = shop.grade or 0 }
            end
            ox_inventory:RegisterShop(job .. i, cfg)
        end
    end

    local cfg = {
        name = baseName,
        inventory = inventory,
        locations = shop.locations,
    }
    if requireJob then
        cfg.groups = shop.grades or { [job] = shop.grade or 0 }
    end
    ox_inventory:RegisterShop(job, cfg)
end

local function registerInventoryPoints()
    for job, data in pairs(Config.jobs) do
        if data.stash then
            registerJobStash(job, data.stash, false)
        end
        if data.privateStash then
            registerJobStash(job, data.privateStash, true)
        end
        if data.shop then
            registerJobShop(job, data.shop)
        end
    end
end

--- Broadcast full config to all clients
local function syncConfig(src)
    if src then
        TriggerClientEvent("jk-helper:client:setConfig", src, Config)
    else
        TriggerClientEvent("jk-helper:client:setConfig", -1, Config)
    end
end

--- Load config from DB and sync
local function loadAndSync()
    Config = DB.loadConfig()
    registerInventoryPoints()
    syncConfig()
end

-- Ensure DB ready and load config
CreateThread(function()
    DB.ensureSchema()
    loadAndSync()
end)

--- Callbacks
lib.callback.register("jk-helper:server:getConfig", function(_src)
    return Config
end)

lib.callback.register("jk-helper:server:isAdmin", function(src)
    return DB.isAdmin(src)
end)

lib.callback.register("jk-helper:server:getAllPoints", function(src)
    if not DB.isAdmin(src) then return {} end
    return DB.getAllPoints()
end)

--- Event: add point
RegisterNetEvent("jk-helper:server:addPoint", function(data)
    local src = source
    if not DB.isAdmin(src) then return end
    DB.addPoint(data)
    loadAndSync()
end)

-- Future TODO: update & delete events
RegisterNetEvent("jk-helper:server:deletePoint", function(id)
    local src = source
    if not DB.isAdmin(src) then return end
    DB.deletePoint(id)
    loadAndSync()
end)

RegisterNetEvent("jk-helper:server:updatePoint", function(id, fields)
    local src = source
    if not DB.isAdmin(src) then return end
    DB.updatePoint(id, fields)
    loadAndSync()
end)

-- When a player joins request sync
AddEventHandler("QBCore:Server:PlayerLoaded", function(source)
    syncConfig(source)
end)

--- Vehicle registry to track spawned garage vehicles
local vehicleRegistry = {}

local function hasGarageAccess(src, jobName, gradeRequired)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    if Player.PlayerData.job.name ~= jobName then return false end
    if gradeRequired and Player.PlayerData.job.grade.level < gradeRequired then return false end
    return true
end

lib.callback.register('jk-helper:server:validateGarageAccess', function(src, jobName, gradeRequired)
    return hasGarageAccess(src, jobName, gradeRequired)
end)

lib.callback.register('jk-helper:server:spawnVehicle', function(src, model, coords, jobName, gradeRequired)
    if not hasGarageAccess(src, jobName, gradeRequired) then
        print(('[jk-helper] WARNING: Player %s tried to spawn vehicle without proper garage access'):format(src))
        return false
    end

    if not model or not coords then
        print(('[jk-helper] ERROR: Player %s provided invalid spawn parameters'):format(src))
        return false
    end

    local spawnCoords = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = coords.w or 0.0
    }

    local vehicle = QBCore.Functions.SpawnVehicle(src, model, spawnCoords, true)
    if not vehicle then
        print(('[jk-helper] ERROR: Failed to create vehicle %s for player %s'):format(model, src))
        return false
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then
        DeleteEntity(vehicle)
        print(('[jk-helper] ERROR: Failed to get network ID for vehicle of player %s'):format(src))
        return false
    end

    return netId
end)

lib.callback.register('jk-helper:server:registerVehicle', function(src, plate, jobName, gradeRequired)
    if not plate then return false end
    if not hasGarageAccess(src, jobName, gradeRequired) then
        print(('[jk-helper] WARNING: Player %s tried to register vehicle without proper garage access'):format(src))
        return false
    end
    vehicleRegistry[plate] = { owner = src, time = os.time(), job = jobName }
    return true
end)

lib.callback.register('jk-helper:server:returnVehicle', function(src, plate)
    local data = vehicleRegistry[plate]
    if data and data.owner == src then
        vehicleRegistry[plate] = nil
        return true
    end
    return false
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    for plate, data in pairs(vehicleRegistry) do
        if data.owner == src then
            vehicleRegistry[plate] = nil
        end
    end
end)

-- Admin command to manually release a plate
lib.addCommand('releaseplate', {
    help = 'Free a garage vehicle plate in case of issues',
    params = {
        { name = 'plate', type = 'string', help = 'Vehicle plate to release (e.g. JK123456)' }
    },
    restricted = 'group.admin'
}, function(source, args, _raw)
    local plate = args.plate and tostring(args.plate):upper()
    if not plate or plate == '' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Release Plate',
            description = 'Invalid plate',
            type = 'error'
        })
        return
    end

    vehicleRegistry[plate] = nil
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Release Plate',
        description = ('Plate %s released'):format(plate),
        type = 'success'
    })
end)

-- Hook to add money to the job account when a player buys an item from a shop
ox_inventory:registerHook('buyItem', function(payload)
    if not Medias.management then return end
    if payload.currency ~= 'money' then return false end
    local job = payload.shopType:gsub('%d+$', '')
    if not QBCore.Shared.Jobs[job] then return false end
    exports['qb-management']:AddMoney(job, payload.totalPrice)
    print(('[JK-Helper] %s compró %dx %s en %s por $%s')
        :format(GetPlayerName(payload.source), payload.amount, payload.itemName, payload.shopType, payload.totalPrice))
end)
