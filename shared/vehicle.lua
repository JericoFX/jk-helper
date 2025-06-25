local Vehicle = {}

--- Get vehicle type for CreateVehicleServerSetter
--- @param model string|number Vehicle model hash or name
--- @return string Vehicle type
function Vehicle.getType(model)
    local modelHash = type(model) == "string" and GetHashKey(model) or model


    return "automobile"
end

--- Framework-agnostic vehicle extras handler
--- @param vehicle number Vehicle entity
--- @param extras table|number Extras configuration - can be table with extra ids as keys and boolean values, or livery number
function Vehicle.setExtras(vehicle, extras)
    if not vehicle or not DoesEntityExist(vehicle) then
        return false
    end

    if type(extras) == "number" then
        SetVehicleLivery(vehicle, extras)
        return true
    end

    if type(extras) == "table" then
        for extraId, enabled in pairs(extras) do
            extraId = tonumber(extraId)
            if extraId and extraId >= 1 and extraId <= 14 then
                SetVehicleExtra(vehicle, extraId, not enabled)
            end
        end
        return true
    end

    return false
end

--- Framework-agnostic vehicle spawning (client-side helper)
--- @param model string Vehicle model hash
--- @param coords vector4 Spawn coordinates with heading
--- @param jobName string Job name for validation
--- @param gradeRequired number Minimum grade required
--- @param callback function Callback function with netId parameter
function Vehicle.spawn(model, coords, jobName, gradeRequired, callback)
    lib.callback('jk-helper:server:spawnVehicle', false, callback, model, coords, jobName, gradeRequired)
end

--- Server-side vehicle extras handler via callback
--- @param netId number Network ID of the vehicle
--- @param extras table|number Extras configuration
lib.callback.register('jk-helper:server:setVehicleExtras', function(src, netId, extras)
    if not netId then return false end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 then return false end

    return Vehicle.setExtras(vehicle, extras)
end)

--- Client-side helper to set extras with server validation
--- @param vehicle number Vehicle entity
--- @param extras table|number Extras configuration
function Vehicle.setExtrasSecure(vehicle, extras)
    if not vehicle or not DoesEntityExist(vehicle) then
        return false
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then
        return Vehicle.setExtras(vehicle, extras)
    end

    lib.callback('jk-helper:server:setVehicleExtras', false, function(success)
        if not success then
            Vehicle.setExtras(vehicle, extras)
        end
    end, netId, extras)

    return true
end

return Vehicle
