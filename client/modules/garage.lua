local Garages = lib.class("Garage")
local QBCore = lib.load("client.modules.core")
local Vehicle = lib.load("shared.vehicle")

--- Check if the plate has the correct patter JK+ 6 random numbers
local function isValid(str)
    local pattern = "^JK%d%d%d%d%d%d$"
    return string.match(str, pattern) ~= nil
end

local function hasJobAccess(garageData)
    local Player = QBCore.Functions.GetPlayerData()
    if not Player or not Player.job then return false end
    if garageData.job ~= Player.job.name then return false end
    if garageData.grade and Player.job.grade.level < garageData.grade then return false end
    return true
end



function Garages:constructor(name, zoneType, coords, data, onEnter, onExit, inside, title, options,
                             returnCoords, spawnCoords, livery, deleteCoords)
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
    self.deleteCoords = deleteCoords or (returnCoords and (returnCoords + vec3(3.0, 0.0, 0.0)))
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
        debug = false,
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
        if not hasJobAccess(self.data) then
            lib.notify({
                title = "Access Denied",
                description = "You don't have permission to use this garage",
                type = "error"
            })
            return
        end
        self:CreateVehicle(args.hash)
    end)
end

function Garages:CreatePoints()
    local function onEnterReturn(zone)
        if not hasJobAccess(self.data) then return end
        local veh = cache.vehicle
        if (veh == nil or veh == 0 or veh == false) then
            lib.showTextUI("No Vehicle Detected")
            return
        end
        lib.showTextUI("[E] Save Vehicle")
    end

    local function onExitReturn()
        lib.hideTextUI()
    end

    local function insideReturn(zone)
        if not hasJobAccess(self.data) then return end
        local PlayerCoords = GetEntityCoords(cache.ped)
        local currentDistance = #(zone.coords - PlayerCoords)
        DrawMarker(2, zone.coords.x, zone.coords.y, zone.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0,
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
            local plate = GetVehicleNumberPlateText(veh)
            if not isValid(plate) then
                lib.notify({
                    title = "Error",
                    description = "You didn't take the vehicle from this place",
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

    self.points = lib.zones.box({
        name = "Devolver" .. self.name,
        coords = self.returnCoords,
        size = vec3(5, 5, 5),
        rotation = 0,
        onEnter = onEnterReturn,
        debug = false,
        onExit = onExitReturn,
        inside = insideReturn,
        typeZone = "devolver",
    })

    if self.deleteCoords then
        local function onEnterDelete(zone)
            if not hasJobAccess(self.data) then return end
            local veh = cache.vehicle
            if (veh == nil or veh == 0 or veh == false) then
                lib.showTextUI("No Vehicle Detected")
                return
            end
            lib.showTextUI("[E] Delete Vehicle")
        end

        local function onExitDelete()
            lib.hideTextUI()
        end

        local function insideDelete(zone)
            if not hasJobAccess(self.data) then return end
            local PlayerCoords = GetEntityCoords(cache.ped)
            local currentDistance = #(zone.coords - PlayerCoords)
            DrawMarker(2, zone.coords.x, zone.coords.y, zone.coords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 180.0,
                0.0,
                0.5, 0.5, 0.5,
                255,
                0, 0, 0, false, true, 2, false, nil, nil, false)
            if currentDistance <= 2 and IsControlJustReleased(0, 38) then
                local veh = cache.vehicle
                if not veh or veh == 0 then
                    lib.notify({ title = "Delete", description = "You don't have a vehicle", type = "error" })
                    return
                end
                local alert = lib.alertDialog({
                    header = 'Delete Vehicle',
                    content = 'Delete current vehicle?',
                    centered = true,
                    cancel = true
                })
                if veh and alert == 'confirm' then
                    if not hasJobAccess(self.data) then
                        lib.notify({
                            title = "Access Denied",
                            description = "You don't have permission to delete vehicles from this garage",
                            type = "error"
                        })
                        return
                    end
                    local plate = GetVehicleNumberPlateText(veh)
                    if not isValid(plate:upper()) then
                        lib.notify({
                            title = "Error",
                            description = "You didn't take the vehicle from this place",
                            type = "error"
                        })
                        return
                    end
                    TaskEveryoneLeaveVehicle(veh)
                    Wait(1000)
                    DeleteVehicle(veh)
                end
            end
        end

        self.deletePoint = lib.zones.box({
            name = "Delete" .. self.name,
            coords = self.deleteCoords,
            size = vec3(5, 5, 5),
            rotation = 0,
            onEnter = onEnterDelete,
            debug = false,
            onExit = onExitDelete,
            inside = insideDelete,
            typeZone = "delete",
        })
    end
end

function Garages:delete()
    if self.garage and self.garage.remove then
        self.garage:remove()
    end
    if self.points and self.points.remove then
        self.points:remove()
    end
    if self.deletePoint and self.deletePoint.remove then
        self.deletePoint:remove()
    end
    if lib.removeMenu then
        lib.removeMenu(self.id .. "_Menu")
    end
    self.garage = nil
    self.points = nil
    self.deletePoint = nil
end

function Garages:update(coords, data, options, returnCoords, spawnCoords, livery, deleteCoords, title)
    if coords then
        self.coords = coords
    end
    if data then
        self.data = data
    end
    if options then
        self.options = type(options) == "table" and options or { options }
    end
    if returnCoords then
        self.returnCoords = returnCoords
    end
    if spawnCoords then
        self.spawnCoords = spawnCoords
    end
    if deleteCoords ~= nil then
        self.deleteCoords = deleteCoords
    end
    if livery ~= nil then
        self.livery = livery
    end
    if title then
        self.title = title
    end
    self:delete()
    self:Create()
    self:CreatePoints()
end

function Garages:CreateVehicle(hash)
    if not hasJobAccess(self.data) then
        lib.notify({
            title = "Access Denied",
            description = "You don't have permission to spawn vehicles from this garage",
            type = "error"
        })
        return
    end

    local plate = ("%s%s"):format("JK", math.random(100000, 999999))
    Vehicle.spawn(hash, self.spawnCoords, self.data.job, self.data.grade, function(netId)
        if not netId then
            lib.notify({
                title = "Spawn Error",
                description = "Failed to spawn vehicle. Contact an administrator.",
                type = "error"
            })
            return
        end

        local veh = NetToVeh(netId)
        if not veh or veh == 0 then
            lib.notify({
                title = "Spawn Error",
                description = "Vehicle network synchronization failed",
                type = "error"
            })
            return
        end

        SetVehicleNumberPlateText(veh, plate)
        exports["lc_fuel"]:SetFuel(veh, 100)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))

        if self.livery and self.livery[tostring(hash)] then
            Vehicle.setExtrasSecure(veh, self.livery[hash])
        end

        SetVehicleEngineOn(veh, true, true, false)
        self.vehicle = veh

        lib.callback('jk-helper:server:registerVehicle', false, plate, self.data.job, self.data.grade)
    end)
end

function Garages:Open()
    if not hasJobAccess(self.data) then
        lib.notify({
            title = "Access Denied",
            description = "You don't have permission to access this garage",
            type = "error"
        })
        return false
    end
    return lib.showMenu(self.id .. "_Menu")
end

function Garages:delete()
    if self.garage and self.garage.remove then
        self.garage:remove()
    end
    if self.points and self.points.remove then
        self.points:remove()
    end
    if self.deletePoint and self.deletePoint.remove then
        self.deletePoint:remove()
    end
    
    lib.hideTextUI()
    
    self.garage = nil
    self.points = nil
    self.deletePoint = nil
    self.vehicle = nil
end

return Garages
