local Zones = lib.class("Zones")
local ox = exports.ox_inventory

function Zones:constructor(name, zoneType, coords, data, onEnter, onExit, inside)
    self.name = name
    self.type = zoneType
    self.coords = coords
    self.data = data
    self.onEnter = onEnter
    self.onExit = onExit
    self.inside = inside
    self.zone = nil
    self.garage = nil
    return self
end

function Zones:Create()
    self.zone = lib.zones.box({
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
end

function Zones:Open()
    if self.type == "stash" then
        ox:openInventory("stash", { id = self.name })
    elseif self.type == "privateStash" then
        ox:openInventory("stash", { id = self.name .. "_private" })
    elseif self.type == "duty" then
        TriggerServerEvent("QBCore:ToggleDuty")
    elseif self.type == "boss" then
        TriggerEvent("qb-bossmenu:client:OpenMenu")
    elseif self.type == "shop" then
        ox:openInventory("shop", { type = self.name, id = self.data.id })
    elseif self.type == "cloth" then
        local action = self.data and self.data.data
        local actionType = type(action)
        if actionType == "function" then
            action()
        elseif actionType == "string" then
            local eventName = action ~= "" and action or nil
            if not eventName and self.data and type(self.data.eventName) == "string" and self.data.eventName ~= "" then
                eventName = self.data.eventName
            end
            if eventName and eventName ~= "" then
                TriggerEvent(eventName)
            else
                lib.notify({
                    title = 'Clothing',
                    description = 'No clothing event configured for this point',
                    type = 'error'
                })
            end
        else
            lib.notify({
                title = 'Clothing',
                description = 'Invalid clothing configuration',
                type = 'error'
            })
        end
    elseif self.type == "dj" then
        if GetResourceState('fx-djsound') == 'started' then
            exports['fx-djsound']:openDjPanel()
        else
            lib.notify({
                title = 'DJ Panel',
                description = 'The resource fx-djsound is not available',
                type = 'error'
            })
        end
    end
end

function Zones:delete()
    if self.zone and self.zone.remove then
        self.zone:remove()
    end
    self.zone = nil
end

function Zones:update(coords, data)
    if coords then
        self.coords = coords
    end
    if data then
        self.data = data
    end
    self:delete()
    self:Create()
end

return Zones
