local Framework = {}

local function normalizeJob(job)
    return {
        name = job.name,
        grade = { level = job.grade or (job.grade.level or 0) },
        isboss = job.isboss or job.isBoss or job.grade_name == 'boss'
    }
end

-- Detect QBCore
if GetResourceState('qb-core'):find('start') or GetResourceState('qbx-core'):find('started') then
    local QBCore = exports['qb-core']:GetCoreObject()

    function Framework.getPlayerData()
        return QBCore.Functions.GetPlayerData()
    end

    -- forward events to neutral ones
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        TriggerEvent('jk-helper:playerLoaded', Framework.getPlayerData())
    end)
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        TriggerEvent('jk-helper:jobUpdate', job)
    end)
    RegisterNetEvent('QBCore:Client:SetPlayerData', function(val)
        TriggerEvent('jk-helper:setPlayerData', val)
    end)

    Framework.spawnVehicle = QBCore.Functions.SpawnVehicle
    Framework.identifier = 'qb-core'

    -- Detect ESX
elseif GetResourceState('es_extended'):find('start') then
    local ESX = exports['es_extended']:getSharedObject()

    function Framework.getPlayerData()
        local p = ESX.GetPlayerData()
        return { job = normalizeJob(p.job) }
    end

    -- wait for load and send event
    CreateThread(function()
        while not ESX.IsPlayerLoaded() do Wait(100) end
        TriggerEvent('jk-helper:playerLoaded', Framework.getPlayerData())
    end)

    RegisterNetEvent('esx:setJob', function(job)
        TriggerEvent('jk-helper:jobUpdate', normalizeJob(job))
    end)

    Framework.spawnVehicle = function(src, model, coords, isNetworked)
        -- placeholder simple spawn client; real server-side spawn handled elsewhere
        local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w or 0.0, true, isNetworked or true)
        return veh
    end
    Framework.identifier = 'es_extended'
else
    print('[jk-helper] WARNING: No supported framework detected (qb-core / es_extended)')
    Framework.getPlayerData = function() return { job = { name = 'unemployed', grade = { level = 0 } } } end
    Framework.spawnVehicle = function() return nil end
    Framework.identifier = 'none'
end

return Framework
