local Zones = lib.load("client.modules.zones")
local Garages = lib.load("client.modules.garage")
local Framework = lib.load("shared.framework")

local PointManager = {}
PointManager.__index = PointManager

-- Helper: create blip and cache id
local function createBlip(blips, blipConfig)
    local blip = AddBlipForCoord(blipConfig.coords.x, blipConfig.coords.y, blipConfig.coords.z)
    SetBlipSprite(blip, blipConfig.sprite)
    SetBlipColour(blip, blipConfig.color)
    SetBlipScale(blip, blipConfig.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipConfig.label)
    EndTextCommandSetBlipName(blip)
    blips[#blips + 1] = blip
end

-- Access check shared by onEnter/inside
local function hasAccess(pm, data)
    if data.requireJob == false then return true end
    if not pm.Player or not pm.Player.job or not data.job then return false end
    if data.job ~= pm.Player.job.name then return false end
    if data.grade and pm.Player.job.grade.level < data.grade then return false end
    return true
end

-- Dynamic callbacks ----------------------------------------------------------
local function makeOnEnter(pm)
    return function(self)
        if not hasAccess(pm, self.data) then return end
        lib.showTextUI(("[E] Open %s"):format(self.data.type):upper())
    end
end

local function makeOnExit(_pm)
    return function(_self) lib.hideTextUI() end
end

local function makeInside(pm)
    return function(self)
        if not hasAccess(pm, self.data) then return end
        local plyCoords = GetEntityCoords(cache.ped)
        local dist = #(self.coords - plyCoords)
        DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0,
            0.0, 0.5, 0.5, 0.5, 200, 255, 255, 255, false, true, 2, false, nil, nil, false)
        if dist <= 2 and IsControlJustReleased(0, 38) then
            if self.data.type == "boss" and not (pm.Player.job.isboss) then
                lib.notify({ title = "Boss", description = "You are not a boss", type = "error" })
                return
            end
            pm.Points[self.data.job][self.data.type]:Open()
        end
    end
end

-------------------------------------------------------------------------------
-- Constructor
function PointManager:new()
    local obj = setmetatable({}, self)
    obj.Config = {}
    obj.Points = {}
    obj.Blips = {}
    obj.Player = {}

    -- Player data events
    RegisterNetEvent('jk-helper:playerLoaded', function(pdata) obj.Player = pdata end)
    RegisterNetEvent('jk-helper:jobUpdate', function(job) obj.Player.job = job end)
    RegisterNetEvent('jk-helper:setPlayerData', function(job) obj.Player.job = job end)

    return obj
end

-- Helpers --------------------------------------------------------------------
local function clearBlips(pm)
    for i = 1, #pm.Blips do RemoveBlip(pm.Blips[i]) end
    pm.Blips = {}
end

local function safeDelete(zone)
    if zone and zone.delete and type(zone.delete) == "function" then zone:delete() end
end

local function buildZones(pm)
    pm.Player = Framework.getPlayerData()

    local onEnter = makeOnEnter(pm)
    local onExit = makeOnExit(pm)
    local inside = makeInside(pm)
    local clone = lib.table.deepclone

    for jobName, data in pairs(pm.Config.jobs) do
        pm.Points[jobName] = pm.Points[jobName] or {}
        local buckets = pm.Points[jobName]

        -- Stash ----------------------------------------------------------------
        if data.stash then
            if not buckets.stash or not buckets.stash.zone then
                local els = clone(data.stash)
                buckets.stash = Zones:new(jobName, 'stash', els.coords,
                    { type = 'stash', label = els.label, job = jobName, grade = els.grade, requireJob = els.requireJob },
                    onEnter, onExit, inside)
                buckets.stash:Create()
            end
            if data.stash.blip then createBlip(pm.Blips, data.stash.blip) end
        end

        -- Private Stash --------------------------------------------------------
        if data.privateStash then
            if not buckets.privateStash or not buckets.privateStash.zone then
                local els = clone(data.privateStash)
                buckets.privateStash = Zones:new(jobName, 'privateStash', els.coords,
                    {
                        type = 'privateStash',
                        label = els.label,
                        job = jobName,
                        grade = els.grade,
                        requireJob = els
                            .requireJob
                    },
                    onEnter, onExit, inside)
                buckets.privateStash:Create()
            end
            if data.privateStash.blip then createBlip(pm.Blips, data.privateStash.blip) end
        end

        -- Duty -----------------------------------------------------------------
        if data.duty then
            if not buckets.duty or not buckets.duty.zone then
                local els = clone(data.duty)
                buckets.duty = Zones:new(jobName, 'duty', els.coords,
                    { type = 'duty', label = els.label, job = jobName, grade = els.grade, requireJob = els.requireJob },
                    onEnter, onExit, inside)
                buckets.duty:Create()
            end
            if data.duty.blip then createBlip(pm.Blips, data.duty.blip) end
        end

        -- Boss -----------------------------------------------------------------
        if data.boss then
            if not buckets.boss or not buckets.boss.zone then
                local els = clone(data.boss)
                buckets.boss = Zones:new(jobName, 'boss', els.coords,
                    { type = 'boss', label = els.label, job = jobName, grade = els.grade, requireJob = els.requireJob },
                    onEnter, onExit, inside)
                buckets.boss:Create()
            end
            if data.boss.blip then createBlip(pm.Blips, data.boss.blip) end
        end

        -- Shop -----------------------------------------------------------------
        if data.shop then
            if not buckets.shop or not buckets.shop.zone then
                local els = clone(data.shop)
                if table.type(els.locations) == 'array' and #els.locations >= 2 then
                    for i = 1, #els.locations do
                        buckets.shop = Zones:new(jobName, 'shop', els.locations[i],
                            {
                                type = 'shop',
                                label = els.label,
                                job = jobName,
                                id = i,
                                requireJob = els.requireJob,
                                grade =
                                    els.grade
                            },
                            onEnter, onExit, inside)
                        buckets.shop:Create()
                    end
                end
                buckets.shop = Zones:new(jobName, 'shop', els.locations[1],
                    {
                        type = 'shop',
                        label = els.label,
                        job = jobName,
                        id = 1,
                        requireJob = els.requireJob,
                        grade = els
                            .grade
                    },
                    onEnter, onExit, inside)
                buckets.shop:Create()
            end
            if data.shop.blip then createBlip(pm.Blips, data.shop.blip) end
        end

        -- Garage ---------------------------------------------------------------
        if data.garage then
            if not buckets.garage or not buckets.garage.garage then
                local els = clone(data.garage)
                els.data = els.data or {}
                els.data.type = 'garage'
                els.data.label = els.title
                els.data.job = jobName
                els.data.grade = els.grade or 0
                buckets.garage = Garages:new(jobName, 'garage', els.coords, els.data,
                    onEnter, onExit, inside, els.title, els.options, els.returnCoords, els.spawnCoords, els.livery,
                    els.deleteCoords)
            end
            if data.garage.blip then createBlip(pm.Blips, data.garage.blip) end
        end

        -- Cloth ----------------------------------------------------------------
        if data.cloth then
            if not buckets.cloth or not buckets.cloth.zone then
                local els = clone(data.cloth)
                buckets.cloth = Zones:new(jobName, 'cloth', els.coords,
                    { type = 'cloth', label = 'Cloth', data = els.event, job = jobName, requireJob = els.requireJob },
                    onEnter, onExit, inside)
                buckets.cloth:Create()
            end
            if data.cloth.blip then createBlip(pm.Blips, data.cloth.blip) end
        end
    end
end

-- Public API -----------------------------------------------------------------
function PointManager:sync(cfg)
    -- remove obsolete zones
    for job, jobPoints in pairs(self.Points) do
        if not cfg.jobs[job] then
            for _, z in pairs(jobPoints) do safeDelete(z) end
            self.Points[job] = nil
        else
            for pType, z in pairs(jobPoints) do
                if not cfg.jobs[job][pType] then
                    safeDelete(z)
                    self.Points[job][pType] = nil
                end
            end
        end
    end

    clearBlips(self)
    self.Config = cfg
    buildZones(self)
end

function PointManager:addPoint(p) self:sync({ jobs = { [p.job or p.jobName] = { [p.type or p.typeName] = p } } }) end

function PointManager:updatePoint(p) self:addPoint(p) end

function PointManager:deletePoint(uuid)
    if not uuid then return end
    for job, data in pairs(self.Config.jobs) do
        for t, cfg in pairs(data) do
            if cfg.uuid == uuid then
                safeDelete(self.Points[job] and self.Points[job][t])
                self.Points[job][t] = nil
                self.Config.jobs[job][t] = nil
                if next(self.Config.jobs[job]) == nil then self.Config.jobs[job] = nil end
                clearBlips(self)
                buildZones(self)
                return
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Singleton factory
local instance
return function()
    if not instance then instance = PointManager:new() end
    return instance
end
