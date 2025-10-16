local QBCore = lib.load("client.modules.core")
local Config = {}
local Zones = lib.load("client.modules.zones")
local Garages = lib.load("client.modules.garage")
local Points = {}
local Player = {}
local Blips = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Player = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Player.job = job
end)

RegisterNetEvent('QBCore:Client:SetPlayerData', function(val)
    Player.job = val
end)

local function CreateBlip(blipConfig)
    local blip = AddBlipForCoord(blipConfig.coords.x, blipConfig.coords.y, blipConfig.coords.z)
    SetBlipSprite(blip, blipConfig.sprite)
    SetBlipColour(blip, blipConfig.color)
    SetBlipScale(blip, blipConfig.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipConfig.label)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function hasAccess(zone)
    if not zone or not zone.data then return false end

    if zone.data.requireJob == false then return true end

    if not Player.job or not Player.job.name then return false end
    if zone.data.job and zone.data.job ~= Player.job.name then return false end

    if zone.data.grade then
        local gradeLevel = Player.job.grade and Player.job.grade.level or 0
        if gradeLevel < zone.data.grade then return false end
    end

    return true
end

local function onEnter(zone)
    if not hasAccess(zone) then return end
    lib.showTextUI(("[E] Open %s"):format(zone.data.type):upper())
end

local function onExit()
    lib.hideTextUI()
end

local function inside(zone)
    if not hasAccess(zone) then return end

    local typeZone = zone.data.type
    local PlayerCoords = GetEntityCoords(cache.ped)
    local currentDistance = #(zone.coords - PlayerCoords)
    DrawMarker(2, zone.coords.x, zone.coords.y, zone.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0,
        0.0,
        0.5, 0.5, 0.5,
        200,
        255, 255, 255, false, true, 2, false, nil, nil, false)
    if currentDistance <= 2 and IsControlJustReleased(0, 38) then
        if typeZone == "boss" and not (Player.job and Player.job.isboss) then
            lib.notify({
                title = "Boss",
                description = "You are not a boss",
                type = "error"
            })
            return
        end
        zone:Open()
    end
end

local function createZones()
    if GetResourceState("qb-core"):find("started") then
        Player = QBCore.Functions.GetPlayerData()
    end
    for k, v in pairs(Config.jobs) do
        local el = Config.jobs[k]
        if not Points[k] then
            Points[k] = {
                stash = {},
                privateStash = {},
                duty = {},
                shop = {},
                garage = {},
                boss = {},
                cloth = {},
                dj = {},

            }
        end
        if el.stash then
            if not Points[k].stash or not Points[k].stash.zone then
                local els = lib.table.deepclone(el.stash)
                Points[k].stash = Zones:new(
                    k, "stash", els.coords, { type = "stash", label = els.label, job = k }, onEnter, onExit, inside)
                Points[k].stash:Create()
                els = nil
            end
            if el.stash.blip then
                Blips[#Blips + 1] = CreateBlip(el.stash.blip)
            end
        end
        if el.privateStash then
            if not Points[k].privateStash or not Points[k].privateStash.zone then
                local els = lib.table.deepclone(el.privateStash)
                Points[k].privateStash = Zones:new(
                    k, "privateStash", els.coords, { type = "privateStash", label = els.label, job = k }, onEnter, onExit,
                    inside)
                Points[k].privateStash:Create()
                els = nil
            end
            if el.privateStash.blip then
                Blips[#Blips + 1] = CreateBlip(el.privateStash.blip)
            end
        end
        if el.duty then
            if not Points[k].duty or not Points[k].duty.zone then
                local els = lib.table.deepclone(el.duty)
                Points[k].duty = Zones:new(
                    k, "duty", els.coords, { type = "duty", label = els.label, job = k }, onEnter, onExit, inside)
                Points[k].duty:Create()
                els = nil
            end
            if el.duty.blip then
                Blips[#Blips + 1] = CreateBlip(el.duty.blip)
            end
        end
        if el.boss then
            if not Points[k].boss or not Points[k].boss.zone then
                local els = lib.table.deepclone(el.boss)
                Points[k].boss = Zones:new(
                    k, "boss", els.coords, { type = "boss", label = els.label, job = k }, onEnter, onExit, inside)
                Points[k].boss:Create()
                els = nil
            end
            if el.boss.blip then
                Blips[#Blips + 1] = CreateBlip(el.boss.blip)
            end
        end
        if el.shop then
            if Points[k].shop and Points[k].shop.delete and type(Points[k].shop.delete) == "function" then
                Points[k].shop:delete()
                Points[k].shop = {}
            end

            Points[k].shop = Points[k].shop or {}

            local els = lib.table.deepclone(el.shop)
            local locations = {}

            if table.type(els.locations) == "array" then
                locations = els.locations
            elseif els.locations then
                locations = { els.locations }
            elseif els.coords then
                locations = { els.coords }
            end

            if #locations > 0 then
                local validIndices = {}

                for i = 1, #locations do
                    validIndices[i] = true
                    if Points[k].shop[i] then
                        Points[k].shop[i]:delete()
                    end

                    Points[k].shop[i] = Zones:new(k, "shop", locations[i],
                        { type = "shop", label = els.label, job = k, id = i, requireJob = els.requireJob },
                        onEnter, onExit, inside)
                    Points[k].shop[i]:Create()
                end

                for idx, zone in pairs(Points[k].shop) do
                    if not validIndices[idx] then
                        if zone and zone.delete and type(zone.delete) == "function" then
                            zone:delete()
                        end
                        Points[k].shop[idx] = nil
                    end
                end
            elseif next(Points[k].shop) ~= nil then
                for idx, zone in pairs(Points[k].shop) do
                    if zone and zone.delete and type(zone.delete) == "function" then
                        zone:delete()
                    end
                    Points[k].shop[idx] = nil
                end
            end

            if el.shop.blip then
                Blips[#Blips + 1] = CreateBlip(el.shop.blip)
            end
        end
        if el.garage then
            if not Points[k].garage or not Points[k].garage.garage then
                local els = lib.table.deepclone(el.garage)
                els.data = els.data or {}
                els.data.type = "garage"
                els.data.label = els.title
                els.data.job = k
                els.data.grade = els.grade or 0
                Points[k].garage = Garages:new(k, "garage", els.coords, els.data, onEnter, onExit, inside, els.title,
                    els.options,
                    els.returnCoords, els.spawnCoords, els.livery, els.deleteCoords)
                els = nil
            end
            if el.garage.blip then
                Blips[#Blips + 1] = CreateBlip(el.garage.blip)
            end
        end
        if el.cloth then
            if not Points[k].cloth or not Points[k].cloth.zone then
                local els = lib.table.deepclone(el.cloth)
                Points[k].cloth = Zones:new(k, "cloth", els.coords,
                    { type = "cloth", label = "Cloth", data = els.event, job = k },
                    onEnter, onExit, inside)
                Points[k].cloth:Create()
                els = nil
            end
            if el.cloth.blip then
                Blips[#Blips + 1] = CreateBlip(el.cloth.blip)
            end
        end
        if el.dj then
            if not Points[k].dj or not Points[k].dj.zone then
                local els = lib.table.deepclone(el.dj)
                Points[k].dj = Zones:new(k, "dj", els.coords,
                    { type = "dj", label = "DJ Panel", job = k },
                    onEnter, onExit, inside)
                Points[k].dj:Create()
                els = nil
            end
            if el.dj.blip then
                Blips[#Blips + 1] = CreateBlip(el.dj.blip)
            end
        end
    end
end

local function updatePoints(newConfig)
    local function deletePointEntry(entry)
        if type(entry) ~= "table" then return end

        if entry.delete and type(entry.delete) == "function" then
            entry:delete()
            return
        end

        for key, value in pairs(entry) do
            deletePointEntry(value)
            entry[key] = nil
        end
    end

    -- Clear all blips first and recreate them
    if #Blips > 0 then
        for i = 1, #Blips do
            RemoveBlip(Blips[i])
        end
        Blips = {}
    end

    -- Check existing points and remove those that no longer exist in new config
    for job, jobPoints in pairs(Points) do
        if not newConfig.jobs[job] then
            -- Job completely removed, delete all its points
            for pointType, point in pairs(jobPoints) do
                deletePointEntry(point)
                jobPoints[pointType] = nil
            end
            Points[job] = nil
        else
            -- Job still exists, check individual point types
            local removedTypes = {}
            for pointType, point in pairs(jobPoints) do
                if not newConfig.jobs[job][pointType] then
                    -- This point type was removed for this job
                    deletePointEntry(point)
                    removedTypes[#removedTypes + 1] = pointType
                end
            end

            for i = 1, #removedTypes do
                jobPoints[removedTypes[i]] = nil
            end
        end
    end

    -- Update config and create new/updated zones
    Config = newConfig
    createZones()
end

RegisterNetEvent("jk-helper:client:setConfig", function(cfg)
    updatePoints(cfg)
end)

AddEventHandler("onResourceStop", function(res)
    if cache.resource == res then
        for i = 1, #Blips do
            RemoveBlip(Blips[i])
        end
    end
end)

-- Request config on start
lib.callback('jk-helper:server:getConfig', false, function(cfg)
    TriggerEvent('jk-helper:client:setConfig', cfg)
end)
