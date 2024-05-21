local Garages = lib.class("Garage")
local QBCore = lib.load("client.modules.core")
function Garages:constructor(name, zoneType, coords, data, onEnter, onExit, inside, title, options,
                             returnCoords, spawnCoords, livery)
    self.name = name
    self.type = zoneType
    self.coords = coords
    self.data = data
    self.onEnter = onEnter
    self.onExit = onExit
    self.inside = inside
    self.id = name
    self.title = title
    self.position = "top-right"
    self.options = type(options) == "table" and options or { options }
    self.returnCoords = returnCoords
    self.spawnCoords = spawnCoords
    self.livery = livery
    self.vehicle = nil
    self.garage = nil
    self.points = nil
    self:Create()
    self:CreatePoints()
    return self
end

function Garages:Create()
    self.garage = lib.zones.box({
        name = self.name,
        coords = self.coords,
        size = vec3(5, 5, 5),
        rotation = 0,
        onEnter = self.onEnter,
        debug = true,
        onExit = self.onExit,
        inside = self.inside,
        data = self.data or {}
    })

    lib.registerMenu({
        id = self.id .. "_Menu",
        title = self.title,
        position = self.position,
        options = self.options,
    }, function(selected, scroll, args)
        self:CreateVehicle(args.hash)
    end)
end

local function onEnter(self)
    local veh = cache.vehicle
    if (veh == nil or veh == 0 or veh == false) then
        lib.showTextUI("No Vehicle Detected")
        return
    end
    lib.showTextUI("[E] Save Vehicle")
end

local function onExit(self)
    lib.hideTextUI()
end

local function inside(self)
    local PlayerCoords = GetEntityCoords(cache.ped)
    local currentDistance = #(self.coords - PlayerCoords)
    DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0,
        0.0,
        0.5, 0.5, 0.5,
        200,
        255, 255, 255, false, true, 2, false, nil, nil, false)
    if currentDistance <= 2 and IsControlJustReleased(0, 38) then
        local veh = cache.vehicle
        if (veh == nil or veh == 0 or veh == false) then
            lib.notify({
                title = "Save Vehicle",
                description = "You don't have a vehicle",
                type = "error"
            })
            return
        end
        local alert = lib.alertDialog({
            header = 'Save Vehicle',
            content = '¿Save Vehicle?',
            centered = true,
            cancel = true
        })

        if veh and alert == "confirm" then
            TaskEveryoneLeaveVehicle(veh)
            Wait(1000)
            DeleteVehicle(veh)
            self.plate = nil
            self.vehicle = nil
        end
    end
end

function Garages:CreatePoints()
    self.points = lib.zones.box({
        name = "Devolver" .. self.name,
        coords = self.returnCoords,
        size = vec3(5, 5, 5),
        rotation = 0,
        onEnter = onEnter,
        debug = true,
        onExit = onExit,
        inside = inside,
        typeZone = "devolver",
    })
end

function Garages:CreateVehicle(hash)
    local plate = ("%s%s"):format("JK", math.random(100000, 999999))
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        SetVehicleNumberPlateText(veh, plate)
        SetEntityHeading(veh, self.spawnCoords.w or 180)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        if self.livery and self.livery[tostring(hash)] then
            QBCore.Shared.SetDefaultVehicleExtras(veh, self.livery[hash])
        end
        SetVehicleEngineOn(veh, true, true, false)
        self.vehicle = veh
    end, hash, self.spawnCoords, true)
end

function Garages:Open()
    return lib.showMenu(self.id .. "_Menu")
end

function Garages:delete()
    self.garage = nil
end

return Garages
