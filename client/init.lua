local QBCore = lib.load("client.modules.core")
local Config = lib.load("shared.init")
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
                cloth = {},
               
            }

        end
        if el.stash then
            local els = lib.table.deepclone(el.stash)
            Points[k].stash = Zones:new(
                k, "stash", els.coords, { type = "stash", label = els.label, job = k }, onEnter, onExit, inside)
            Points[k].stash:Create()
            if els.blip then
                Blips[#Blips+1] = CreateBlip(els.blip)
            end
            els = nil

        end
        if el.privateStash then
            local els = lib.table.deepclone(el.privateStash)
            Points[k].privateStash = Zones:new(
                k, "privateStash", els.coords, { type = "privateStash", label = els.label, job = k }, onEnter, onExit,
                inside)
            Points[k].privateStash:Create()
             if els.blip then
                Blips[#Blips+1] = CreateBlip(els.blip)
            end
            els = nil
        end
        if el.duty then
            local els = lib.table.deepclone(el.duty)
            Points[k].duty = Zones:new(
                k, "duty", els.coords, { type = "duty", label = els.label, job = k }, onEnter, onExit, inside)
            Points[k].duty:Create()
              if els.blip then
                Blips[#Blips+1] = CreateBlip(els.blip)
            end
            els = nil
        end
        if el.boss then
            local els = lib.table.deepclone(el.boss)
            Points[k].boss = Zones:new(
                k, "boss", els.coords, { type = "boss", label = els.label, job = k }, onEnter, onExit, inside)
            Points[k].boss:Create()
              if els.blip then
                Blips[#Blips+1] = CreateBlip(els.blip)
            end
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
              if els.blip then
                Blips[#Blips+1] = CreateBlip(els.blip)
            end
            Points[k].shop = Zones:new(k, "shop", els.locations[1], { type = "shop", label = els.label, job = k, id = 1 },
                onEnter, onExit, inside)
            Points[k].shop:Create()
            els = nil
        end
        if el.garage then
            local els = lib.table.deepclone(el.garage)
            els.data.type = "garage"
            els.data.label = els.title
            els.data.job = k
            Points[k].garage = Garages:new(k, "garage", els.coords, els.data, onEnter, onExit, inside, els.title,
                els.options,
                els.returnCoords, els.spawnCoords, els.livery)
                  if els.blip then
                Blips[#Blips+1] = CreateBlip(els.blip)
            end
            els = nil
        end
        if el.cloth then
            local els = lib.table.deepclone(el.cloth)
             Points[k].cloth = Zones:new(k, "cloth", els.coords, { type = "cloth", label = "Cloth",data = els.event,job = k},
                onEnter, onExit, inside)
            Points[k].cloth:Create()
              if els.blip then
                Blips[#Blips+1] = CreateBlip(els.blip)
            end
            els = nil
        end
    end
end

CreateThread(createZones)


AddEventHandler("onResourceStop",function(res) 
    if cache.resource == res then
        for i = 1, #Blips do
            RemoveBlip(Blips[i])
        end
    end
end)