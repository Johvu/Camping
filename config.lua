Config = {}

Config.DEBUG = true

Config.targetDistance = 1.5

Config.TentModels = {
    [1] = {
        model ='prop_skid_tent_01',
        slot = 10,
        weight = 10000,
    },
    [2] = {
        model ='prop_skid_tent_01b',
        slot = 20,
        weight = 10000,
    },
    [3] = {
        model = 'prop_skid_tent_03',
        slot = 30,
        weight = 10000,
    }
}
Config.CampfireModels = {
    'prop_beach_fire',
}

Config.tentItem = 'tent'
Config.campfireItem = 'campfire'

Config.maxFuel = 300 -- seconds
Config.FuelMenu = {
    [1] = {
        icon = 'fa-newspaper',
        title = "Paper (15 seconds)",
        description = "Adds 15 seconds of fuel per unit.",
        event = 'add_fuel_option', -- don't edit if you don't know what is it
        args = { type = "paper", duration = 15 }, -- type = item , duration = seconds
    },
    [2] = {
        icon = 'fa-tree',
        title = "Wood (30 seconds)",
        description = "Adds 30 seconds of fuel per unit.",
        event = 'add_fuel_option', -- don't edit if you don't know what is it
        args = { type = "wood", duration = 30 }, -- type = item , duration = seconds
    },
    [3] = {
        icon = 'fa-fire',
        title = "Coal (60 seconds)",
        description = "Adds 60 seconds of fuel per unit.",
        event = 'add_fuel_option', -- don't edit if you don't know what is it
        args = { type = "coal", duration = 60 }, -- type = item , duration = seconds
    },
}

Config.CookingMenu = {
    [1] = {
            title = "Grill Meat",
            description = "Cook time: 60 seconds. Recipe: Meat x1",
            event = 'campfire_cooking', -- don't edit if you don't know what is it
            args = 'grill_meat'}, -- Recipe
    [2] = {
            title = "Meat Soup",
            description = "Cook time: 120 seconds. Recipe: Meat x1, Water x1, Bowl x1",
            event = 'campfire_cooking', -- don't edit if you don't know what is it
            args = 'meat_soup'}, -- Recipe
    [3] = {
            title = "Grill Potato",
            description = "Cook time: 30 seconds. Recipe: Potato x1",
            event = 'campfire_cooking', -- don't edit if you don't know what is it
            args = 'grill_potato'}, -- Recipe
    --Add more menu here
}

Config.Recipes = {
    grill_meat = {
        label = "Grill Meat",
        cookTime = 5000, -- seconds
        ingredients = { 
            { name = "meat", count = 1 }
        }
    },
    meat_soup = {
        label = "Meat Soup",
        cookTime = 120000, -- seconds
        ingredients = {
            { name = "meat", count = 1 },
            { name = "water", count = 1 },
            { name = "bowl", count = 1 } 
        } 
    },
    grill_potato = {
        label = "Grill Potato",
        cookTime = 30000, -- seconds
        ingredients = { 
            { name = "potato", count = 1 } 
        } 
    },
    -- Add more Data here
}

