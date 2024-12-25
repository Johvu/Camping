Config = {}

Config.targetDistance = 2.0

Config.TentModel = 'prop_skid_tent_01'
Config.CampfireModel = 'prop_beach_fire'

Config.tentItem = 'tent'
Config.campfireItem = 'campfire'

Config.weather = 'wethersync' -- 'wethersync' or 'custom'
Config.statusName = 'cold' -- ESX status name
Config.HeatZone = { 
    radius = 10.0,
    heat = 500,
    tick = 1000
}

Config.Cold = {
    coldThreshold = -2,
    hypothermiaThreshold = -5, -- Temperature where hypothermia risk starts
    tickInterval = 10000, -- Time in milliseconds between cold status checks
    staminaPenalty = 10, -- Stamina penalty per tick
    healthPenalty = 5, -- Health penalty per tick at hypothermia level
    speedPenalty = 0.9, -- Movement speed reduction when cold
    heatSources = Config.CampfireModel, -- Entities acting as heat sources
    heatSourceRange = 10.0 -- Range to detect heat sources
}

Config.maxFuel = 300 -- seconds
Config.FuelMenu = {
    [1] = {
        icon = 'fas fa-newspaper',
        title = "Garbage (5 seconds)",
        description = "Adds 5 seconds of fuel per unit.",
        event = 'add_fuel_option', -- don't edit if you don't know what is it
        args = { type = "garbage", duration = 5 }, -- type = item , duration = seconds
    },
    [2] = {
        icon = 'fas fa-tree',
        title = "Fire Wood (30 seconds)",
        description = "Adds 30 seconds of fuel per unit.",
        event = 'add_fuel_option', -- don't edit if you don't know what is it
        args = { type = "tr_firewood", duration = 30 }, -- type = item , duration = seconds
    },
    [3] = {
        icon = 'fas fa-fire',
        title = "Coal (60 seconds)",
        description = "Adds 60 seconds of fuel per unit.",
        event = 'add_fuel_option', -- don't edit if you don't know what is it
        args = { type = "coal", duration = 60 }, -- type = item , duration = seconds
    },
}

Config.CookingMenu = {
    [1] = {
            title = "Grill Fish",
            description = "Cook time: 60 seconds. Recipe: Rainbow Trout x1",
            event = 'campfire_cooking', -- don't edit if you don't know what is it
            icon = 'nui://ox_inventory/web/images/grilled_fish.png',
            args = 'grilled_rainbow_trout'}, -- Recipe
    [2] = {
            title = "Venison Stew",
            description = "Cook time: 120 seconds. Recipe: Venison x1, Water x1, Potato x1",
            event = 'campfire_cooking', -- don't edit if you don't know what is it
            icon = 'nui://ox_inventory/web/images/meat_stew.png',
            args = 'meat_stew'}, -- Recipe
    [3] = {
            title = "Grill Potato",
            description = "Cook time: 30 seconds. Recipe: Potato x1",
            event = 'campfire_cooking', -- don't edit if you don't know what is it
            icon = 'nui://ox_inventory/web/images/potato.png',
            args = 'grilled_potato'}, -- Recipe
    --Add more menu here
}

Config.Recipes = {
    grilled_rainbow_trout = {
        label = "Grill Rainbow Trout",
        cookTime = 60000, -- seconds
        ingredients = { 
            { name = "rainbow-trout", count = 1 }
        }
    },
    meat_soup = {
        label = "Meat Soup",
        cookTime = 120000, -- seconds
        ingredients = {
            { name = "venison", count = 1 },
            { name = "water", count = 1 },
            { name = "potato_1", count = 1 }
        } 
    },
    grilled_potato = {
        label = "Grill Potato",
        cookTime = 30000, -- seconds
        ingredients = { 
            { name = "potato_1", count = 1 } 
        } 
    },
    -- Add more Data here
}

Config.Temperature = {
    extrasunny = {          -- DO NOT CHANGES THE startTime & endTime.
            {startTime = 0, endTime = 1, tempMin = 22, tempMax = 23}, -- celsius.
            {startTime = 1, endTime = 2, tempMin = 21, tempMax = 24},
            {startTime = 2, endTime = 3, tempMin = 22, tempMax = 22},
            {startTime = 3, endTime = 4, tempMin = 20, tempMax = 21},
            {startTime = 4, endTime = 5, tempMin = 20, tempMax = 21},
            {startTime = 5, endTime = 6, tempMin = 20, tempMax = 21},
            {startTime = 6, endTime = 7, tempMin = 20, tempMax = 24},
            {startTime = 7, endTime = 8, tempMin = 20, tempMax = 23},
            {startTime = 8, endTime = 9, tempMin = 20, tempMax = 24},
            {startTime = 9, endTime = 10, tempMin = 21, tempMax = 24},
            {startTime = 10, endTime = 11, tempMin = 21, tempMax = 24},
            {startTime = 11, endTime = 12, tempMin = 22, tempMax = 24},
            {startTime = 12, endTime = 13, tempMin = 22, tempMax = 26},
            {startTime = 13, endTime = 14, tempMin = 24, tempMax = 29},
            {startTime = 14, endTime = 15, tempMin = 24, tempMax = 21},
            {startTime = 15, endTime = 16, tempMin = 26, tempMax = 32},
            {startTime = 16, endTime = 17, tempMin = 21, tempMax = 32},
            {startTime = 17, endTime = 18, tempMin = 1, tempMax = 4},
            {startTime = 18, endTime = 19, tempMin = 5, tempMax = 6},
            {startTime = 19, endTime = 20, tempMin = 2, tempMax = 3},
            {startTime = 20, endTime = 21, tempMin = 21, tempMax = 28},
            {startTime = 21, endTime = 22, tempMin = 21, tempMax = 26},
            {startTime = 22, endTime = 23, tempMin = 21, tempMax = 24},
            {startTime = 23, endTime = 24, tempMin = 21, tempMax = 23} 
        },
    clouds = {
        {startTime = 0, endTime = 1, tempMin = 19, tempMax = 22},
        {startTime = 1, endTime = 2, tempMin = 18, tempMax = 22},
        {startTime = 2, endTime = 3, tempMin = 17, tempMax = 21},
        {startTime = 3, endTime = 4, tempMin = 16, tempMax = 20},
        {startTime = 4, endTime = 5, tempMin = 16, tempMax = 20},
        {startTime = 5, endTime = 6, tempMin = 15, tempMax = 19},
        {startTime = 6, endTime = 7, tempMin = 14, tempMax = 18},
        {startTime = 7, endTime = 8, tempMin = 14, tempMax = 18},
        {startTime = 8, endTime = 9, tempMin = 14, tempMax = 19},
        {startTime = 9, endTime = 10, tempMin = 15, tempMax = 20},
        {startTime = 10, endTime = 11, tempMin = 16, tempMax = 21},
        {startTime = 11, endTime = 12, tempMin = 17, tempMax = 22},
        {startTime = 12, endTime = 13, tempMin = 18, tempMax = 23},
        {startTime = 13, endTime = 14, tempMin = 19, tempMax = 24},
        {startTime = 14, endTime = 15, tempMin = 19, tempMax = 24},
        {startTime = 15, endTime = 16, tempMin = 18, tempMax = 23},
        {startTime = 16, endTime = 17, tempMin = 17, tempMax = 22},
        {startTime = 17, endTime = 18, tempMin = 16, tempMax = 21},
        {startTime = 18, endTime = 19, tempMin = 15, tempMax = 20},
        {startTime = 19, endTime = 20, tempMin = 14, tempMax = 19},
        {startTime = 20, endTime = 21, tempMin = 14, tempMax = 18},
        {startTime = 21, endTime = 22, tempMin = 15, tempMax = 19},
        {startTime = 22, endTime = 23, tempMin = 16, tempMax = 20},
        {startTime = 23, endTime = 24, tempMin = 17, tempMax = 21} 
    },
    clear = {
        {startTime = 0, endTime = 1, tempMin = 15, tempMax = 18},
        {startTime = 1, endTime = 2, tempMin = 14, tempMax = 17},
        {startTime = 2, endTime = 3, tempMin = 13, tempMax = 16},
        {startTime = 3, endTime = 4, tempMin = 12, tempMax = 15},
        {startTime = 4, endTime = 5, tempMin = 12, tempMax = 14},
        {startTime = 5, endTime = 6, tempMin = 11, tempMax = 13},
        {startTime = 6, endTime = 7, tempMin = 11, tempMax = 13},
        {startTime = 7, endTime = 8, tempMin = 12, tempMax = 14},
        {startTime = 8, endTime = 9, tempMin = 13, tempMax = 15},
        {startTime = 9, endTime = 10, tempMin = 15, tempMax = 17},
        {startTime = 10, endTime = 11, tempMin = 16, tempMax = 18},
        {startTime = 11, endTime = 12, tempMin = 17, tempMax = 19},
        {startTime = 12, endTime = 13, tempMin = 18, tempMax = 20},
        {startTime = 13, endTime = 14, tempMin = 19, tempMax = 21},
        {startTime = 14, endTime = 15, tempMin = 20, tempMax = 22},
        {startTime = 15, endTime = 16, tempMin = 21, tempMax = 23},
        {startTime = 16, endTime = 17, tempMin = 21, tempMax = 23},
        {startTime = 17, endTime = 18, tempMin = 20, tempMax = 22},
        {startTime = 18, endTime = 19, tempMin = 19, tempMax = 21},
        {startTime = 19, endTime = 20, tempMin = 18, tempMax = 20},
        {startTime = 20, endTime = 21, tempMin = 17, tempMax = 19},
        {startTime = 21, endTime = 22, tempMin = 16, tempMax = 18},
        {startTime = 22, endTime = 23, tempMin = 15, tempMax = 17},
        {startTime = 23, endTime = 24, tempMin = 15, tempMax = 18} 
    },
    smog = {
        {startTime = 0, endTime = 1, tempMin = 4, tempMax = 6},
        {startTime = 1, endTime = 2, tempMin = 4, tempMax = 6},
        {startTime = 2, endTime = 3, tempMin = 3, tempMax = 5},
        {startTime = 3, endTime = 4, tempMin = 3, tempMax = 5},
        {startTime = 4, endTime = 5, tempMin = 2, tempMax = 4},
        {startTime = 5, endTime = 6, tempMin = 2, tempMax = 4},
        {startTime = 6, endTime = 7, tempMin = 2, tempMax = 4},
        {startTime = 7, endTime = 8, tempMin = 3, tempMax = 5},
        {startTime = 8, endTime = 9, tempMin = 4, tempMax = 6},
        {startTime = 9, endTime = 10, tempMin = 5, tempMax = 7},
        {startTime = 10, endTime = 11, tempMin = 6, tempMax = 8},
        {startTime = 11, endTime = 12, tempMin = 7, tempMax = 9},
        {startTime = 12, endTime = 13, tempMin = 8, tempMax = 10},
        {startTime = 13, endTime = 14, tempMin = 9, tempMax = 11},
        {startTime = 14, endTime = 15, tempMin = 9, tempMax = 11},
        {startTime = 15, endTime = 16, tempMin = 8, tempMax = 10},
        {startTime = 16, endTime = 17, tempMin = 7, tempMax = 9},
        {startTime = 17, endTime = 18, tempMin = 6, tempMax = 8},
        {startTime = 18, endTime = 19, tempMin = 5, tempMax = 7},
        {startTime = 19, endTime = 20, tempMin = 4, tempMax = 6},
        {startTime = 20, endTime = 21, tempMin = 4, tempMax = 6},
        {startTime = 21, endTime = 22, tempMin = 4, tempMax = 5},
        {startTime = 22, endTime = 23, tempMin = 4, tempMax = 6},
        {startTime = 23, endTime = 24, tempMin = 4, tempMax = 6} 
    },
    overcast = {
        {startTime = 0, endTime = 1, tempMin = 12, tempMax = 14},
        {startTime = 1, endTime = 2, tempMin = 12, tempMax = 14},
        {startTime = 2, endTime = 3, tempMin = 11, tempMax = 13},
        {startTime = 3, endTime = 4, tempMin = 11, tempMax = 13},
        {startTime = 4, endTime = 5, tempMin = 10, tempMax = 12},
        {startTime = 5, endTime = 6, tempMin = 10, tempMax = 12},
        {startTime = 6, endTime = 7, tempMin = 10, tempMax = 12},
        {startTime = 7, endTime = 8, tempMin = 11, tempMax = 13},
        {startTime = 8, endTime = 9, tempMin = 12, tempMax = 14},
        {startTime = 9, endTime = 10, tempMin = 13, tempMax = 15},
        {startTime = 10, endTime = 11, tempMin = 14, tempMax = 16},
        {startTime = 11, endTime = 12, tempMin = 14, tempMax = 16},
        {startTime = 12, endTime = 13, tempMin = 15, tempMax = 17},
        {startTime = 13, endTime = 14, tempMin = 15, tempMax = 17},
        {startTime = 14, endTime = 15, tempMin = 14, tempMax = 16},
        {startTime = 15, endTime = 16, tempMin = 13, tempMax = 15},
        {startTime = 16, endTime = 17, tempMin = 12, tempMax = 14},
        {startTime = 17, endTime = 18, tempMin = 11, tempMax = 13},
        {startTime = 18, endTime = 19, tempMin = 11, tempMax = 13},
        {startTime = 19, endTime = 20, tempMin = 12, tempMax = 14},
        {startTime = 20, endTime = 21, tempMin = 12, tempMax = 14},
        {startTime = 21, endTime = 22, tempMin = 11, tempMax = 13},
        {startTime = 22, endTime = 23, tempMin = 12, tempMax = 14},
        {startTime = 23, endTime = 24, tempMin = 12, tempMax = 14} 
    },
    foggy = {
        {startTime = 0, endTime = 1, tempMin = 10, tempMax = 12},
        {startTime = 1, endTime = 2, tempMin = 9, tempMax = 11},
        {startTime = 2, endTime = 3, tempMin = 8, tempMax = 10},
        {startTime = 3, endTime = 4, tempMin = 7, tempMax = 9},
        {startTime = 4, endTime = 5, tempMin = 6, tempMax = 8},
        {startTime = 5, endTime = 6, tempMin = 6, tempMax = 7},
        {startTime = 6, endTime = 7, tempMin = 7, tempMax = 8},
        {startTime = 7, endTime = 8, tempMin = 8, tempMax = 9},
        {startTime = 8, endTime = 9, tempMin = 9, tempMax = 10},
        {startTime = 9, endTime = 10, tempMin = 10, tempMax = 11},
        {startTime = 10, endTime = 11, tempMin = 11, tempMax = 12},
        {startTime = 11, endTime = 12, tempMin = 12, tempMax = 13},
        {startTime = 12, endTime = 13, tempMin = 13, tempMax = 14},
        {startTime = 13, endTime = 14, tempMin = 14, tempMax = 15},
        {startTime = 14, endTime = 15, tempMin = 15, tempMax = 16},
        {startTime = 15, endTime = 16, tempMin = 16, tempMax = 17},
        {startTime = 16, endTime = 17, tempMin = 17, tempMax = 18},
        {startTime = 17, endTime = 18, tempMin = 18, tempMax = 19},
        {startTime = 18, endTime = 19, tempMin = 17, tempMax = 18},
        {startTime = 19, endTime = 20, tempMin = 16, tempMax = 17},
        {startTime = 20, endTime = 21, tempMin = 15, tempMax = 16},
        {startTime = 21, endTime = 22, tempMin = 14, tempMax = 15},
        {startTime = 22, endTime = 23, tempMin = 13, tempMax = 14},
        {startTime = 23, endTime = 24, tempMin = 12, tempMax = 13} 
    },
    rain = {
        {startTime = 0, endTime = 1, tempMin = 10, tempMax = 12},
        {startTime = 1, endTime = 2, tempMin = 10, tempMax = 12},
        {startTime = 2, endTime = 3, tempMin = 9, tempMax = 11},
        {startTime = 3, endTime = 4, tempMin = 9, tempMax = 11},
        {startTime = 4, endTime = 5, tempMin = 8, tempMax = 10},
        {startTime = 5, endTime = 6, tempMin = 8, tempMax = 10},
        {startTime = 6, endTime = 7, tempMin = 8, tempMax = 10},
        {startTime = 7, endTime = 8, tempMin = 9, tempMax = 11},
        {startTime = 8, endTime = 9, tempMin = 10, tempMax = 12},
        {startTime = 9, endTime = 10, tempMin = 11, tempMax = 13},
        {startTime = 10, endTime = 11, tempMin = 12, tempMax = 14},
        {startTime = 11, endTime = 12, tempMin = 12, tempMax = 14},
        {startTime = 12, endTime = 13, tempMin = 13, tempMax = 15},
        {startTime = 13, endTime = 14, tempMin = 13, tempMax = 15},
        {startTime = 14, endTime = 15, tempMin = 12, tempMax = 14},
        {startTime = 15, endTime = 16, tempMin = 11, tempMax = 13},
        {startTime = 16, endTime = 17, tempMin = 10, tempMax = 12},
        {startTime = 17, endTime = 18, tempMin = 10, tempMax = 12},
        {startTime = 18, endTime = 19, tempMin = 11, tempMax = 13},
        {startTime = 19, endTime = 20, tempMin = 12, tempMax = 14},
        {startTime = 20, endTime = 21, tempMin = 12, tempMax = 14},
        {startTime = 21, endTime = 22, tempMin = 11, tempMax = 13},
        {startTime = 22, endTime = 23, tempMin = 10, tempMax = 12},
        {startTime = 23, endTime = 24, tempMin = 10, tempMax = 12} 
    },
    thunder = {
        {startTime = 0, endTime = 1, tempMin = 18, tempMax = 20},
        {startTime = 1, endTime = 2, tempMin = 18, tempMax = 20},
        {startTime = 2, endTime = 3, tempMin = 17, tempMax = 19},
        {startTime = 3, endTime = 4, tempMin = 17, tempMax = 19},
        {startTime = 4, endTime = 5, tempMin = 16, tempMax = 18},
        {startTime = 5, endTime = 6, tempMin = 16, tempMax = 18},
        {startTime = 6, endTime = 7, tempMin = 16, tempMax = 18},
        {startTime = 7, endTime = 8, tempMin = 17, tempMax = 19},
        {startTime = 8, endTime = 9, tempMin = 18, tempMax = 20},
        {startTime = 9, endTime = 10, tempMin = 19, tempMax = 21},
        {startTime = 10, endTime = 11, tempMin = 19, tempMax = 21},
        {startTime = 11, endTime = 12, tempMin = 20, tempMax = 22},
        {startTime = 12, endTime = 13, tempMin = 21, tempMax = 23},
        {startTime = 13, endTime = 14, tempMin = 22, tempMax = 24},
        {startTime = 14, endTime = 15, tempMin = 22, tempMax = 24},
        {startTime = 15, endTime = 16, tempMin = 21, tempMax = 23},
        {startTime = 16, endTime = 17, tempMin = 21, tempMax = 23},
        {startTime = 17, endTime = 18, tempMin = 20, tempMax = 22},
        {startTime = 18, endTime = 19, tempMin = 19, tempMax = 21},
        {startTime = 19, endTime = 20, tempMin = 18, tempMax = 20},
        {startTime = 20, endTime = 21, tempMin = 18, tempMax = 20},
        {startTime = 21, endTime = 22, tempMin = 17, tempMax = 19},
        {startTime = 22, endTime = 23, tempMin = 17, tempMax = 19},
        {startTime = 23, endTime = 24, tempMin = 18, tempMax = 20} 
    },
    snow = {
        {startTime = 0, endTime = 1, tempMin = -8, tempMax = -6},
        {startTime = 1, endTime = 2, tempMin = -8, tempMax = -5},
        {startTime = 2, endTime = 3, tempMin = -7, tempMax = -4},
        {startTime = 3, endTime = 4, tempMin = -6, tempMax = -3},
        {startTime = 4, endTime = 5, tempMin = -6, tempMax = -3},
        {startTime = 5, endTime = 6, tempMin = -5, tempMax = -2},
        {startTime = 6, endTime = 7, tempMin = -5, tempMax = -1},
        {startTime = 7, endTime = 8, tempMin = -4, tempMax = 0},
        {startTime = 8, endTime = 9, tempMin = -4, tempMax = 1},
        {startTime = 9, endTime = 10, tempMin = -3, tempMax = 2},
        {startTime = 10, endTime = 11, tempMin = -2, tempMax = 3},
        {startTime = 11, endTime = 12, tempMin = -2, tempMax = 4},
        {startTime = 12, endTime = 13, tempMin = -1, tempMax = 5},
        {startTime = 13, endTime = 14, tempMin = -1, tempMax = 6},
        {startTime = 14, endTime = 15, tempMin = 0, tempMax = 7},
        {startTime = 15, endTime = 16, tempMin = 0, tempMax = 6},
        {startTime = 16, endTime = 17, tempMin = -1, tempMax = 5},
        {startTime = 17, endTime = 18, tempMin = -2, tempMax = 4},
        {startTime = 18, endTime = 19, tempMin = -3, tempMax = 3},
        {startTime = 19, endTime = 20, tempMin = -5, tempMax = 2},
        {startTime = 20, endTime = 21, tempMin = -6, tempMax = 1},
        {startTime = 21, endTime = 22, tempMin = -7, tempMax = 0},
        {startTime = 22, endTime = 23, tempMin = -8, tempMax = -1},
        {startTime = 23, endTime = 24, tempMin = -8, tempMax = -6} 
    },
    blizzard = {
        {startTime = 0, endTime = 1, tempMin = -15, tempMax = -10},
        {startTime = 1, endTime = 2, tempMin = -15, tempMax = -9},
        {startTime = 2, endTime = 3, tempMin = -14, tempMax = -8},
        {startTime = 3, endTime = 4, tempMin = -13, tempMax = -7},
        {startTime = 4, endTime = 5, tempMin = -13, tempMax = -6},
        {startTime = 5, endTime = 6, tempMin = -12, tempMax = -5},
        {startTime = 6, endTime = 7, tempMin = -12, tempMax = -4},
        {startTime = 7, endTime = 8, tempMin = -11, tempMax = -3},
        {startTime = 8, endTime = 9, tempMin = -11, tempMax = -2},
        {startTime = 9, endTime = 10, tempMin = -10, tempMax = -1},
        {startTime = 10, endTime = 11, tempMin = -9, tempMax = 0},
        {startTime = 11, endTime = 12, tempMin = -8, tempMax = 1},
        {startTime = 12, endTime = 13, tempMin = -7, tempMax = 2},
        {startTime = 13, endTime = 14, tempMin = -6, tempMax = 3},
        {startTime = 14, endTime = 15, tempMin = -5, tempMax = 4},
        {startTime = 15, endTime = 16, tempMin = -5, tempMax = 3},
        {startTime = 16, endTime = 17, tempMin = -6, tempMax = 2},
        {startTime = 17, endTime = 18, tempMin = -7, tempMax = 1},
        {startTime = 18, endTime = 19, tempMin = -8, tempMax = 0},
        {startTime = 19, endTime = 20, tempMin = -10, tempMax = -1},
        {startTime = 20, endTime = 21, tempMin = -12, tempMax = -3},
        {startTime = 21, endTime = 22, tempMin = -13, tempMax = -5},
        {startTime = 22, endTime = 23, tempMin = -14, tempMax = -7},
        {startTime = 23, endTime = 24, tempMin = -15, tempMax = -10} 
    },
    snowlight = {
        {startTime = 0, endTime = 1, tempMin = -5, tempMax = -2},
        {startTime = 1, endTime = 2, tempMin = -5, tempMax = -1},
        {startTime = 2, endTime = 3, tempMin = -4, tempMax = 0},
        {startTime = 3, endTime = 4, tempMin = -4, tempMax = 1},
        {startTime = 4, endTime = 5, tempMin = -3, tempMax = 2},
        {startTime = 5, endTime = 6, tempMin = -3, tempMax = 3},
        {startTime = 6, endTime = 7, tempMin = -2, tempMax = 4},
        {startTime = 7, endTime = 8, tempMin = -2, tempMax = 5},
        {startTime = 8, endTime = 9, tempMin = -1, tempMax = 6},
        {startTime = 9, endTime = 10, tempMin = -1, tempMax = 7},
        {startTime = 10, endTime = 11, tempMin = 0, tempMax = 8},
        {startTime = 11, endTime = 12, tempMin = 0, tempMax = 9},
        {startTime = 12, endTime = 13, tempMin = 1, tempMax = 10},
        {startTime = 13, endTime = 14, tempMin = 1, tempMax = 11},
        {startTime = 14, endTime = 15, tempMin = 2, tempMax = 12},
        {startTime = 15, endTime = 16, tempMin = 2, tempMax = 11},
        {startTime = 16, endTime = 17, tempMin = 1, tempMax = 10},
        {startTime = 17, endTime = 18, tempMin = 0, tempMax = 9},
        {startTime = 18, endTime = 19, tempMin = -1, tempMax = 8},
        {startTime = 19, endTime = 20, tempMin = -2, tempMax = 7},
        {startTime = 20, endTime = 21, tempMin = -3, tempMax = 6},
        {startTime = 21, endTime = 22, tempMin = -4, tempMax = 5},
        {startTime = 22, endTime = 23, tempMin = -5, tempMax = 4},
        {startTime = 23, endTime = 24, tempMin = -5, tempMax = -2} 
    },
    xmas = {
        {startTime = 0, endTime = 1, tempMin = -8, tempMax = -6},
        {startTime = 1, endTime = 2, tempMin = -7, tempMax = -5},
        {startTime = 2, endTime = 3, tempMin = -6, tempMax = -4},
        {startTime = 3, endTime = 4, tempMin = -6, tempMax = -3},
        {startTime = 4, endTime = 5, tempMin = -5, tempMax = -2},
        {startTime = 5, endTime = 6, tempMin = -5, tempMax = -1},
        {startTime = 6, endTime = 7, tempMin = -4, tempMax = 0},
        {startTime = 7, endTime = 8, tempMin = -4, tempMax = 1},
        {startTime = 8, endTime = 9, tempMin = -3, tempMax = 2},
        {startTime = 9, endTime = 10, tempMin = -3, tempMax = 3},
        {startTime = 10, endTime = 11, tempMin = -2, tempMax = 4},
        {startTime = 11, endTime = 12, tempMin = -2, tempMax = 5},
        {startTime = 12, endTime = 13, tempMin = -1, tempMax = 6},
        {startTime = 13, endTime = 14, tempMin = -1, tempMax = 7},
        {startTime = 14, endTime = 15, tempMin = 0, tempMax = 8},
        {startTime = 15, endTime = 16, tempMin = 0, tempMax = 7},
        {startTime = 16, endTime = 17, tempMin = -1, tempMax = 6},
        {startTime = 17, endTime = 18, tempMin = -2, tempMax = 5},
        {startTime = 18, endTime = 19, tempMin = -3, tempMax = 4},
        {startTime = 19, endTime = 20, tempMin = -4, tempMax = 3},
        {startTime = 20, endTime = 21, tempMin = -5, tempMax = 2},
        {startTime = 21, endTime = 22, tempMin = -6, tempMax = 1},
        {startTime = 22, endTime = 23, tempMin = -7, tempMax = 0},
        {startTime = 23, endTime = 24, tempMin = -8, tempMax = -6} 
    },
}



