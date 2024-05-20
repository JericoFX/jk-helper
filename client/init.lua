local QBCore = lib.load("client.modules.core")
local Config = lib.load("shared.init")
local Zones = lib.load("client.modules.zones")
local Points = {}
local Player = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Player = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Player.job = job
end)

RegisterNetEvent('QBCore:Client:SetPlayerData', function(val)
    Player.job = val
end)
local function onEnter(self)
    lib.showTextUI(("[E] Open %s"):format(self.data.type):upper())
end

local function onExit(self)
    lib.hideTextUI()
end

local function inside(self)
    if not self.data.job == Player.job.name then return end
    local typeZone = self.data.type

    local PlayerCoords = GetEntityCoords(cache.ped)
    local currentDistance = #(self.coords - PlayerCoords)
    DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0,
        0.0,
        0.5, 0.5, 0.5,
        200,
        255, 255, 255, false, true, 2, false, nil, nil, false)
    if currentDistance <= 2 and IsControlJustReleased(0, 38) then
        if typeZone == "boss" and not (Player.job.isboss) then
            lib.notify({
                title = "Boss",
                description = "You are not a boss",
                type = "error"
            })
            return
        end
        Points[self.data.job][typeZone]:Open()
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
                cloth = {}
            }
        end
        if el.stash then
            local els = lib.table.deepclone(el.stash)
            Points[k].stash = Zones:new(
                k, "stash", els.coords, { type = "stash", label = els.label, job = k }, onEnter, onExit, inside)
            Points[k].stash:Create()
            els = nil
        end
        if el.privateStash then
            local els = lib.table.deepclone(el.privateStash)
            Points[k].privateStash = Zones:new(
                k, "privateStash", els.coords, { type = "privateStash", label = els.label, job = k }, onEnter, onExit,
                inside)
            Points[k].privateStash:Create()
            els = nil
        end
        if el.duty then
            local els = lib.table.deepclone(el.duty)
            Points[k].duty = Zones:new(
                k, "duty", els.coords, { type = "duty", label = els.label, job = k }, onEnter, onExit, inside)
            Points[k].duty:Create()
            els = nil
        end
        if el.boss then
            local els = lib.table.deepclone(el.boss)
            Points[k].boss = Zones:new(
                k, "boss", els.coords, { type = "boss", label = els.label, job = k }, onEnter, onExit, inside)
            Points[k].boss:Create()
            els = nil
        end
        if el.shop then
            local els = lib.table.deepclone(el.shop)
            if table.type(v.shop.locations) == "array" and #v.shop.locations >= 2 then
                for i = 1, #v.shop.locations do
                    Points[k].shop = Zones:new(k, "shop", els.locations[i],
                        { type = "shop", label = els.label, job = k, id = i }, onEnter, onExit, inside)
                    Points[k].shop:Create()
                end
            end
            Points[k].shop = Zones:new(k, "shop", els.locations[1], { type = "shop", label = els.label, job = k, id = 1 },
                onEnter, onExit, inside)
            Points[k].shop:Create()
            els = nil
        end
        if el.garage then
            local els = lib.table.deepclone(el.garage)
            els.data.type = "garage"
            els.data.label = els.data.title,
            els.data.job = k
            Points[k].garage = Zones:new(k,"garage",els.coords,els.data, onEnter, onExit, inside)
            Points[k].garage:Create()
            els = nil
        end
    end
end

CreateThread(createZones)
