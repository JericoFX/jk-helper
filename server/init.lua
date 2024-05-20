local QBCore = exports["qb-core"]:GetCoreObject()
local Config = lib.load("shared.init")
local ox_inventory = exports.ox_inventory
local function createZones()
    for k, v in pairs(Config.jobs) do
        local el = Config.jobs[k]
        if v.stash then
            ox_inventory:RegisterStash(k, v.stash.label, v.stash.slots, v.stash.weight, false, v.stash.job)
        end
        if v.privateStash then
            ox_inventory:RegisterStash(k .. "_private", v.privateStash.label, v.privateStash.slots, v.privateStash
                .weight, true,
                v.privateStash.job)
        end
        if v.shop then
            if table.type(v.shop.locations) == "array" and #v.shop.locations >= 2 then
                for i = 1, #v.shop.locations do
                    ox_inventory:RegisterShop(k .. i, {
                        name = v.shop.name,
                        inventory = v.shop.inventory,
                        locations = v.shop.locations[i],
                        groups = v.shop.grades,
                    })
                end
            end
            ox_inventory:RegisterShop(k, {
                name = v.shop.name,
                inventory = v.shop.inventory,
                locations = v.shop.locations,
                groups = v.shop.grades,
            })
        end
    end
end

CreateThread(createZones)
