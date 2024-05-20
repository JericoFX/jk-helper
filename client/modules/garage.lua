local Garages = lib.class("Garage")
local QBCore = lib.load("client.modules.core")
function Garages:constructor(id, title, position, options, returnCoords, spawnCoords, livery)
    self.id = id
    self.title = title
    self.position = position
    self.options = type(options) == "table" and options or { options }
    self.returnCoords = returnCoords
    self.spawnCoords = spawnCoords
    self.livery = livery
    self.vehicle = {}
    self.garage = nil
    self:create()
    return self
end

function Garages:create()
    self.garage = lib.registerMenu({
        id = self.id .. "_Menu",
        title = self.title,
        position = self.position,
        options = self.options,
        data = { id = self.id },
        function(selected, scroll, args)
            self:SpawnVehicle(args.hash)
        end
    })
    return self.garage
end

function Garages:SpawnVehicle(hash)
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        SetVehicleNumberPlateText(veh, string.random(".", 8))
        SetEntityHeading(veh, self.spawn.w or 180)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        if self.livery and self.livery[tostring(hash)] then
            QBCore.Shared.SetDefaultVehicleExtras(veh, self.livery[hash])
        end
        self.vehicle[veh] = true
        SetVehicleEngineOn(veh, true, true, false)
    end, hash, self.spawnCoords, true)
end

function Garages:open()
    return lib.showMenu(self.id .. "_Menu")
end

function Garages:returnVehicle()
    local veh = cache.vehicle
    if not self.vehicle[veh] then
        print("You didnt take the vehicle from here")
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
    end
end

function Garages:delete()
    self.garage = nil
    self = nil
end
