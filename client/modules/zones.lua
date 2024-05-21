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
        debug = true,
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
        self.data.data()
    end
end

return Zones
