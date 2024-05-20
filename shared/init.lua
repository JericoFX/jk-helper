return {
    jobs = {
        police = {
            stash = {
                coords = vector3(-657.6261, -351.6659, 34.4325),
                debug = true,
                label = "Police Stash",
                slots = 1000,
                weight = 900000,
                job = { police = 0 },
                data = {}
            },
            privateStash = {
                coords = vector3(-660.4341, -359.0129, 34.7840),
                debug = true,
                label = "Private Stash",
                slots = 1000,
                job = { police = 0 },
                weight = 900000,
                data = {}
            },
            duty = {
                coords = vector3(-635.6767, -349.9048, 34.8154),
                data = {}
            },
            shop = {
                data = {},
                blip = {
                    coords = vector3(-648.2387, -357.6097, 34.7127),
                    sprite = 135,
                    color = 1,
                    size = 0.6,
                    range = true,
                    label = "Police Station Shop"
                },
                name = "Police Station Shop",                     -- Name of the shop
                inventory = {
                    { name = "bluelabel", price = 1, grade = 1 }, -- Item | price
                    { name = "beer",      price = 1, grade = 1 },
                },
                locations = { vector3(-652.8856, -367.9322, 34.9211) }, -- Where the shop is, can be an array like { vector3(0, 0, 0), vector3(0, 0, 0) }
                grades = { police = 0 },
            },
            garage = {
                coords = vector3(-643.5857, -344.9204, 34.8216),
                data= {
                    options = { -- Options for the garage
                        {
                            label = "Long Vehicle",
                            args = { hash = "police" },
    
                        },
                        {
                            label = "Stafford",
                            args = { hash = "police2" },
    
                        },
                        {
                            label = "Hammer",
                            args = { hash = "police3" },
    
                        },
                    },
                    title = "Police Garage",
                    blip = false,
                    markerCoods = vector3(0, 0, 0),     -- This means take the vehicle from this coords
                    returnCoords = vector3(0, 0, 0),    -- This means return the vehicle to this coords
                    spawnVehicle = vector4(0, 0, 0, 0), -- Spawn coords
                    livery = false,


                },
                onDutyOnly = false,
            },
            boss = {
                coords = vector3(-635.6767, -349.9048, 34.8154),
            },
            cloth = {
                coords = vector3(-627.8377, -359.2138, 34.8079),
                data = {}
            }
        }
    }
}
