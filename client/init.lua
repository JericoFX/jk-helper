-- jk-helper client bootstrap

local PointManagerFactory = lib.load("client.modules.point_manager")
local PM = PointManagerFactory()

-- Receive full configuration
RegisterNetEvent("jk-helper:client:setConfig", function(cfg)
    PM:sync(cfg)
end)

-- Delta updates -------------------------------------------------------------
RegisterNetEvent("jk-helper:client:addPoint", function(p)
    PM:addPoint(p)
end)

RegisterNetEvent("jk-helper:client:updatePoint", function(p)
    PM:updatePoint(p)
end)

RegisterNetEvent("jk-helper:client:deletePoint", function(uuid)
    PM:deletePoint(uuid)
end)

-- Cleanup on resource stop --------------------------------------------------
AddEventHandler("onResourceStop", function(resource)
    if cache.resource == resource then
        PM:sync({ jobs = {} })
    end
end)

-- Request initial config ----------------------------------------------------
lib.callback("jk-helper:server:getConfig", false, function(cfg)
    TriggerEvent("jk-helper:client:setConfig", cfg)
end)
