local QBCore = lib.load("client.modules.core")

local pointTypes = {
    { label = 'Stash',         value = 'stash' },
    { label = 'Private Stash', value = 'privateStash' },
    { label = 'Duty',          value = 'duty' },
    { label = 'Shop',          value = 'shop' },
    { label = 'Garage',        value = 'garage' },
    { label = 'Boss',          value = 'boss' },
    { label = 'Cloth',         value = 'cloth' },
    { label = 'DJ',            value = 'dj' },
}

-- Helper that lets the admin aim at the ground and press E to select the point location using a live raycast preview
local function pickCoords()
    lib.showTextUI('[E] Select location')
    local coords = nil
    while true do
        local hit, _, endCoords = lib.raycast.fromCamera(511, 4, 10.0)
        if hit and endCoords then
            DrawMarker(20, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.35, 0.35, 0.35, 0,
                255, 255, 150, false, true, 2, false, nil, nil, false)
        end
        if IsControlJustReleased(0, 38) then -- E key
            coords = hit and endCoords or GetEntityCoords(cache.ped)
            break
        end
        Wait(0)
    end
    lib.hideTextUI()
    return coords
end

local function formatDuration(seconds)
    seconds = math.max(seconds or 0, 0)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    minutes = minutes % 60
    local secs = seconds % 60
    if hours > 0 then
        return ('%dh %02dm'):format(hours, minutes)
    elseif minutes > 0 then
        return ('%dm %02ds'):format(minutes, secs)
    else
        return ('%ds'):format(secs)
    end
end

local function openCreatePointDialog()
    lib.callback('jk-helper:server:isAdmin', false, function(isAdmin)
        if not isAdmin then
            lib.notify({ title = 'Permission', description = 'You are not admin', type = 'error' })
            return
        end

        -- First let the admin choose the location with raycast
        local coordsVec = pickCoords()
        if not coordsVec then return end

        local input = lib.inputDialog('Create Job Point', {
            { type = 'input',  label = 'Job Name',               placeholder = 'police' },
            { type = 'select', label = 'Type',                   options = pointTypes },
            { type = 'number', label = 'Min Grade',              default = 0 },
            { type = 'input',  label = 'Label',                  placeholder = 'Label for point' },
            { type = 'number', label = 'Blip Sprite (0 = none)', default = 0 },
            { type = 'number', label = 'Blip Color',             default = 0 },
        })
        if not input then return end
        local jobName, pType, grade, label, blipSprite, blipColor = table.unpack(input)
        if not jobName or jobName == '' then return end
        if not QBCore.Shared.Jobs or not QBCore.Shared.Jobs[jobName] then
            lib.notify({
                title = 'Create Point',
                description = ('Job "%s" does not exist'):format(jobName),
                type =
                'error'
            })
            return
        end
        
        if pType == 'dj' then
            if GetResourceState('fx-djsound') ~= 'started' then
                lib.notify({
                    title = 'Create Point',
                    description = 'The resource fx-djsound is not started. DJ points require this resource.',
                    type = 'error'
                })
                return
            end
        end

        local options = {}
        if pType == 'stash' or pType == 'privateStash' then
            local extra = lib.inputDialog('Stash Options', {
                { type = 'number', label = 'Slots',      default = 100 },
                { type = 'number', label = 'Max Weight', default = 100000 }
            })
            if not extra then return end
            local slots, weight = table.unpack(extra)
            options.slots = tonumber(slots) or 100
            options.weight = tonumber(weight) or 100000
        elseif pType == 'shop' then
            local shopOpts = lib.inputDialog('Shop Options', {
                { type = 'checkbox', label = 'Require job to open?', checked = true },
            })
            if not shopOpts then return end
            local requireJob = shopOpts[1] and true or false
            
            local inventory = {}
            while true do
                local itm = lib.inputDialog('Add Item to Shop', {
                    { type = 'input',  label = 'Item Name',              placeholder = 'bread' },
                    { type = 'number', label = 'Amount (0 = unlimited)', default = 0 },
                    { type = 'number', label = 'Price (0 = free)',       default = 0 },
                })
                if not itm then break end
                local name, amount, price = table.unpack(itm)
                if not name or name == '' then break end

                amount = tonumber(amount) or 0
                price = tonumber(price) or 0

                local items = exports.ox_inventory:Items()
                if not items[name] then
                    lib.notify({ title = 'Shop', description = ('Item "%s" does not exist'):format(name), type = 'error' })
                else
                    local itemData = { name = name }
                    if amount > 0 then itemData.amount = amount end
                    itemData.price = price
                    inventory[#inventory + 1] = itemData
                end
                local again = lib.alertDialog({ header = 'Shop', content = 'Add another item?', centered = true, cancel = true })
                if again ~= 'confirm' then break end
            end
            if #inventory == 0 then return end
            options.inventory = inventory
            options.requireJob = requireJob
        elseif pType == 'garage' then
            local vehicleOptions = {}
            local liveryMap = {}
            while true do
                local vehInput = lib.inputDialog('Add Vehicle', {
                    { type = 'input',  label = 'Label',              placeholder = 'Patrol Cruiser' },
                    { type = 'input',  label = 'Model/Hash',         placeholder = 'police' },
                    { type = 'number', label = 'Livery (-1 = none)', default = -1 },
                })
                if not vehInput then break end
                local vLabel, vModel, vLivery = table.unpack(vehInput)
                if not vModel or vModel == '' then break end
                if not IsModelInCdimage(vModel) then
                    lib.notify({ title = 'Garage', description = ('Model "%s" not found'):format(vModel), type = 'error' })
                elseif not QBCore.Shared.Vehicles[vModel] then
                    lib.notify({
                        title = 'Garage',
                        description = ('Vehicle "%s" is not registered in shared'):format(
                            vModel),
                        type = 'error'
                    })
                else
                    vehicleOptions[#vehicleOptions + 1] = { label = vLabel ~= '' and vLabel or vModel, args = { hash = vModel } }
                    if tonumber(vLivery) and tonumber(vLivery) >= 0 then liveryMap[vModel] = tonumber(vLivery) end
                end
                local again = lib.alertDialog({ header = 'Garage', content = 'Add another vehicle?', centered = true, cancel = true })
                if again ~= 'confirm' then break end
            end
            if #vehicleOptions == 0 then return end

            lib.notify({ title = 'Garage Setup', description = 'Now select spawn point for vehicles', type = 'info' })
            local spawnCoords = pickCoords()
            if not spawnCoords then return end

            lib.notify({ title = 'Garage Setup', description = 'Now select return point for vehicles', type = 'info' })
            local returnCoords = pickCoords()
            if not returnCoords then return end

            lib.notify({ title = 'Garage Setup', description = 'Now select police menu location', type = 'info' })
            local deleteCoords = pickCoords()
            if not deleteCoords then return end

            options.options = vehicleOptions
            options.spawnCoords = { x = spawnCoords.x, y = spawnCoords.y, z = spawnCoords.z, w = 0.0 }
            options.returnCoords = { x = returnCoords.x, y = returnCoords.y, z = returnCoords.z }
            options.deleteCoords = { x = deleteCoords.x, y = deleteCoords.y, z = deleteCoords.z }
            if next(liveryMap) then options.livery = liveryMap end
        end

        -- We already grabbed the coords earlier
        local coords = { x = coordsVec.x, y = coordsVec.y, z = coordsVec.z }

        local blip = nil
        local spriteNum = tonumber(blipSprite) or 0
        if spriteNum > 0 then
            blip = {
                coords = coords,
                sprite = spriteNum,
                color = tonumber(blipColor) or 0,
                scale = 0.8,
                label = label ~= '' and label or (jobName .. ' ' .. pType)
            }
        end

        local data = {
            job = jobName,
            type = pType,
            coords = coords,
            label = label,
            grade = tonumber(grade) or 0,
            options = options,
            blip = blip,
        }

        TriggerServerEvent('jk-helper:server:addPoint', data)
        lib.notify({ title = 'JK Helper', description = 'Point created successfully', type = 'success' })
    end)
end

local function openManagePointsMenu()
    lib.callback('jk-helper:server:isAdmin', false, function(isAdmin)
        if not isAdmin then
            lib.notify({ title = 'Permission', description = 'You are not admin', type = 'error' })
            return
        end
        lib.callback('jk-helper:server:getAllPoints', false, function(points)
            if not points or #points == 0 then
                lib.notify({ title = 'Manage Points', description = 'No points found', type = 'error' })
                return
            end
            local opts = {}
            for i, p in ipairs(points) do
                opts[#opts + 1] = {
                    label = ("[%s] %s - %s"):format(p.uuid:sub(1, 8), p.job, p.type),
                    args = p,
                }
            end
            lib.registerMenu({ id = 'jk_manage_points', title = 'JK Helper - Points', options = opts },
                function(selected, scroll, args)
                    local point = args
                    local subOpts = {
                        {
                            label = 'Edit',
                            args = { action = 'edit', point = point }
                        },
                        {
                            label = 'Move',
                            args = { action = 'move', point = point }
                        },
                        {
                            label = 'Clone',
                            args = { action = 'clone', point = point }
                        },
                        {
                            label = 'Delete',
                            args = { action = 'delete', point = point }
                        },
                    }
                    lib.registerMenu(
                        { id = 'jk_manage_point_actions', title = 'Point ' .. point.uuid:sub(1, 8), options = subOpts },
                        function(_, _, actionArgs)
                            if actionArgs.action == 'edit' then
                                local editInput = lib.inputDialog('Edit Point ' .. point.uuid:sub(1, 8), {
                                    { type = 'input',    label = 'Label',                             default = point.label or '' },
                                    { type = 'number',   label = 'Grade',                             default = point.grade or 0 },
                                    { type = 'checkbox', label = 'Update Coords to current position', checked = false },
                                })
                                if editInput then
                                    local newLabel, newGrade, updateCoords = table.unpack(editInput)
                                    local fields = { label = newLabel, grade = tonumber(newGrade) or 0 }
                                    if updateCoords then
                                        local v = GetEntityCoords(cache.ped)
                                        fields.coords = { x = v.x, y = v.y, z = v.z }
                                    end
                                    TriggerServerEvent('jk-helper:server:updatePoint', point.uuid, fields)
                                    lib.notify({ title = 'JK Helper', description = 'Point updated', type = 'success' })
                                end
                            elseif actionArgs.action == 'move' then
                                lib.hideMenu()
                                local coordsVec = pickCoords()
                                if coordsVec then
                                    local fields = { coords = { x = coordsVec.x, y = coordsVec.y, z = coordsVec.z } }
                                    TriggerServerEvent('jk-helper:server:updatePoint', point.uuid, fields)
                                    lib.notify({ title = 'JK Helper', description = 'Point moved', type = 'success' })
                                end
                                openManagePointsMenu()
                            elseif actionArgs.action == 'clone' then
                                lib.hideMenu()
                                local coordsVec = pickCoords()
                                if coordsVec then
                                    local inputs = lib.inputDialog('Clone Point ' .. point.uuid:sub(1, 8), {
                                        { type = 'input',  label = 'Label', default = point.label or '' },
                                        { type = 'number', label = 'Grade', default = point.grade or 0 },
                                    })
                                    if inputs then
                                        local labelInput, gradeInput = table.unpack(inputs)
                                        local overrides = {
                                            coords = { x = coordsVec.x, y = coordsVec.y, z = coordsVec.z },
                                            label = labelInput,
                                        }
                                        if gradeInput ~= nil then
                                            overrides.grade = tonumber(gradeInput) or point.grade or 0
                                        end
                                        lib.callback('jk-helper:server:clonePoint', false, function(result)
                                            if result and result.message then
                                                lib.notify({
                                                    title = 'JK Helper',
                                                    description = result.message,
                                                    type = result.success and 'success' or 'error'
                                                })
                                            end
                                            openManagePointsMenu()
                                        end, point.uuid, overrides)
                                    else
                                        openManagePointsMenu()
                                    end
                                else
                                    openManagePointsMenu()
                                end
                            elseif actionArgs.action == 'delete' then
                                local confirm = lib.alertDialog({
                                    header = 'Delete',
                                    content = 'Delete point ' ..
                                        point.uuid:sub(1, 8) .. '?',
                                    centered = true,
                                    cancel = true
                                })
                                if confirm == 'confirm' then
                                    TriggerServerEvent('jk-helper:server:deletePoint', point.uuid)
                                    lib.notify({ title = 'JK Helper', description = 'Point deleted', type = 'success' })
                                end
                            end
                        end)
                    lib.showMenu('jk_manage_point_actions')
                end)
            lib.showMenu('jk_manage_points')
        end)
    end)
end

local function openVehicleRegistryPanel()
    lib.callback('jk-helper:server:isAdmin', false, function(isAdmin)
        if not isAdmin then
            lib.notify({ title = 'Permission', description = 'You are not admin', type = 'error' })
            return
        end

        lib.callback('jk-helper:server:getVehicleRegistry', false, function(entries)
            if not entries or #entries == 0 then
                lib.notify({ title = 'Vehicle Registry', description = 'No active plates', type = 'info' })
                return
            end

            local opts = {}
            for i, entry in ipairs(entries) do
                local status = entry.ownerOnline and 'Online' or 'Offline'
                local description = ('Owner: %s\nCitizen ID: %s\nJob: %s\nStatus: %s\nTime Active: %s'):format(
                    entry.ownerName or 'Unknown',
                    entry.citizenid or 'N/A',
                    entry.job or 'N/A',
                    status,
                    formatDuration(entry.secondsActive)
                )
                opts[#opts + 1] = {
                    label = ('[%s] %s'):format(entry.plate, status),
                    description = description,
                    args = { action = 'release', plate = entry.plate }
                }
            end
            opts[#opts + 1] = {
                label = 'Release All Plates',
                description = 'Force release of every tracked plate',
                args = { action = 'release_all' }
            }

            lib.registerMenu({ id = 'jk_vehicle_registry', title = 'JK Helper - Vehicle Registry', options = opts },
                function(_, _, args)
                    if args.action == 'release' then
                        lib.hideMenu()
                        lib.callback('jk-helper:server:releasePlate', false, function(result)
                            if result and result.message then
                                lib.notify({
                                    title = 'Vehicle Registry',
                                    description = result.message,
                                    type = result.success and 'success' or 'error'
                                })
                            end
                            openVehicleRegistryPanel()
                        end, args.plate)
                    elseif args.action == 'release_all' then
                        local confirm = lib.alertDialog({
                            header = 'Vehicle Registry',
                            content = 'Release all tracked plates?',
                            centered = true,
                            cancel = true
                        })
                        if confirm == 'confirm' then
                            lib.hideMenu()
                            lib.callback('jk-helper:server:releaseAllPlates', false, function(result)
                                if result and result.message then
                                    lib.notify({
                                        title = 'Vehicle Registry',
                                        description = result.message,
                                        type = result.success and 'success' or 'error'
                                    })
                                end
                                openVehicleRegistryPanel()
                            end)
                        else
                            lib.showMenu('jk_vehicle_registry')
                        end
                    end
                end)
            lib.showMenu('jk_vehicle_registry')
        end)
    end)
end

RegisterCommand('jkcreatepoint', openCreatePointDialog, false)
RegisterKeyMapping('jkcreatepoint', 'JK Helper: Create Point (Admin)', 'keyboard', 'F7')
RegisterCommand('jkmanagepoints', openManagePointsMenu, false)
RegisterKeyMapping('jkmanagepoints', 'JK Helper: Manage Points (Admin)', 'keyboard', 'F9')
RegisterCommand('jkvehregistry', openVehicleRegistryPanel, false)
RegisterKeyMapping('jkvehregistry', 'JK Helper: Vehicle Registry (Admin)', 'keyboard', 'F10')
