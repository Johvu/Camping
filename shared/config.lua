Config = Config or {}

Config.targetDistance = 2.0

Config.TentModel = 'prop_skid_tent_01'
Config.CampfireModel = 'prop_beach_fire'

Config.tentItem = 'tent'
Config.campfireItem = 'campfire'

-- Add missing config values
Config.DefaultFuelLevel = 0 -- Starting fuel level for campfires
Config.maxFuel = 100 -- Maximum fuel
Config.useGESTemperature = true
Config.Framework = 'qbox' -- Options: 'esx', 'qbox', 'standalone'
Config.Inventory = 'ox' -- Options: 'ox', 'qb'
Config.Debug = false -- Set to true to enable debug mode for heat zones

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
        args = { type = "firewood", duration = 30 }, -- type = item , duration = seconds
    },
    [3] = {
        icon = 'fas fa-fire',
        title = "Coal (60 seconds)",
        description = "Adds 60 seconds of fuel per unit.",
        event = 'add_fuel_option', -- don't edit if you don't know what is it
        args = { type = "coal", duration = 60 }, -- type = item , duration = seconds
    },
}

-- Keep the original recipes structure but rename to Recipes (capital R)
Config.Recipes = {
    ["grilled_meat"] = {
        ingredients = "beef",
        amount = 1,
        category = "meat",
        time = 12, -- seconds
        positive = {["heal"] = 45},
        negative = {["slow"] = 18, ["stress"] = 5},
        -- Add these fields for better UI display
        label = "Grilled Meat",
        description = "Succulent meat grilled over an open fire."
    },
    ["grilled_fish"] = {
        ingredients = "raw_fish",
        amount = 1,
        category = "fish",
        time = 18, -- seconds
        positive = {["heal"] = 35},
        negative = {["slow"] = 5, ["stress"] = 10},
        label = "Grilled Fish",
        description = "Fresh fish cooked to perfection."
    },
    ["mushroom_soup"] = {
        ingredients = {"mushroom", "water"},
        amount = {2, 1},
        category = "soup",
        time = 28, -- seconds
        positive = {["heal"] = 30, ["energy"] = 20},
        negative = {["stress"] = 15},
        label = "Mushroom Soup",
        description = "A hearty soup made with wild mushrooms."
    }
}

-- Cooking skill system configuration
Config.SkillSystem = {
    Enabled = true,
    MaxLevel = 10,
    XPPerCook = 5, -- Base XP gained per cooking action
    
    -- Benefits per level (applied cumulatively)
    LevelBenefits = {
        [1] = { description = "Novice Cook", ingredientReduction = 0, qualityBonus = 0, cookTimeReduction = 0 },
        [2] = { description = "Amateur Cook", ingredientReduction = 0, qualityBonus = 5, cookTimeReduction = 5 },
        [3] = { description = "Home Cook", ingredientReduction = 0, qualityBonus = 10, cookTimeReduction = 10 },
        [4] = { description = "Skilled Cook", ingredientReduction = 10, qualityBonus = 15, cookTimeReduction = 15 },
        [5] = { description = "Professional Cook", ingredientReduction = 15, qualityBonus = 20, cookTimeReduction = 20 },
        [6] = { description = "Expert Cook", ingredientReduction = 20, qualityBonus = 25, cookTimeReduction = 25 },
        [7] = { description = "Master Cook", ingredientReduction = 25, qualityBonus = 30, cookTimeReduction = 30 },
        [8] = { description = "Chef", ingredientReduction = 30, qualityBonus = 35, cookTimeReduction = 35 },
        [9] = { description = "Master Chef", ingredientReduction = 35, qualityBonus = 40, cookTimeReduction = 40 },
        [10] = { description = "Legendary Chef", ingredientReduction = 40, qualityBonus = 50, cookTimeReduction = 50 }
    },
    
    -- XP required for each level
    XPRequirements = {
        [1] = 0,
        [2] = 100,
        [3] = 250,
        [4] = 500,
        [5] = 1000,
        [6] = 2000,
        [7] = 4000,
        [8] = 8000,
        [9] = 16000,
        [10] = 32000
    }
}

-- Recipe discovery system
Config.RecipeDiscovery = {
    Enabled = true,
    -- Chance to discover a new recipe when combining ingredients (percentage)
    DiscoveryChance = 15,
    -- Bonus discovery chance per cooking skill level
    DiscoveryChancePerLevel = 2
}

-- Add seasonal recipes
Config.SeasonalRecipes = {
    -- Spring recipes (March-May)
    spring = {
        ["spring_vegetable_soup"] = {
            ingredients = {"carrot", "potato", "onion", "water"},
            amount = {1, 1, 1, 1},
            category = "soup",
            time = 20,
            positive = {["heal"] = 25, ["energy"] = 15},
            negative = {},
            label = "Spring Vegetable Soup",
            description = "A light soup made with fresh spring vegetables."
        },
        ["wild_herb_fish"] = {
            ingredients = {"raw_fish", "herb"},
            amount = {1, 2},
            category = "fish",
            time = 15,
            positive = {["heal"] = 30, ["stamina"] = 20},
            negative = {},
            label = "Wild Herb Fish",
            description = "Fish seasoned with wild spring herbs."
        }
    },
    
    -- Summer recipes (June-August)
    summer = {
        ["grilled_summer_vegetables"] = {
            ingredients = {"corn", "tomato", "pepper"},
            amount = {1, 1, 1},
            category = "other",
            time = 10,
            positive = {["heal"] = 20, ["energy"] = 25},
            negative = {},
            label = "Grilled Summer Vegetables",
            description = "A colorful mix of grilled summer vegetables."
        },
        ["spicy_bbq_meat"] = {
            ingredients = {"beef", "pepper", "salt"},
            amount = {1, 2, 1},
            category = "meat",
            time = 18,
            positive = {["heal"] = 40, ["strength"] = 15},
            negative = {["thirst"] = 10},
            label = "Spicy BBQ Meat",
            description = "Meat with a spicy summer BBQ flavor."
        }
    },
    
    -- Fall recipes (September-November)
    fall = {
        ["mushroom_risotto"] = {
            ingredients = {"rice", "mushroom", "butter"},
            amount = {2, 2, 1},
            category = "other",
            time = 25,
            positive = {["heal"] = 35, ["energy"] = 30},
            negative = {},
            label = "Mushroom Risotto",
            description = "A creamy risotto with fall mushrooms."
        },
        ["pumpkin_soup"] = {
            ingredients = {"pumpkin", "cream", "water"},
            amount = {2, 1, 1},
            category = "soup",
            time = 22,
            positive = {["heal"] = 30, ["cold_resistance"] = 20},
            negative = {},
            label = "Pumpkin Soup",
            description = "A warming soup perfect for cold fall days."
        }
    },
    
    -- Winter recipes (December-February)
    winter = {
        ["hearty_stew"] = {
            ingredients = {"beef", "potato", "carrot", "onion"},
            amount = {1, 2, 1, 1},
            category = "soup",
            time = 30,
            positive = {["heal"] = 45, ["cold_resistance"] = 30},
            negative = {},
            label = "Hearty Winter Stew",
            description = "A thick, warming stew to fight the winter cold."
        },
        ["hot_chocolate"] = {
            ingredients = {"chocolate", "milk"},
            amount = {2, 1},
            category = "other",
            time = 8,
            positive = {["cold_resistance"] = 25, ["stress"] = -20},
            negative = {},
            label = "Hot Chocolate",
            description = "A comforting hot chocolate to warm you up."
        }
    },
    
    -- Special holiday recipes
    holiday = {
        ["christmas_pudding"] = {
            ingredients = {"flour", "sugar", "dried_fruit"},
            amount = {2, 1, 2},
            category = "other",
            time = 35,
            positive = {["heal"] = 25, ["happiness"] = 30},
            negative = {},
            label = "Christmas Pudding",
            description = "A traditional festive dessert.",
            availableFrom = {month = 12, day = 15},
            availableTo = {month = 12, day = 31}
        },
        ["halloween_pumpkin_pie"] = {
            ingredients = {"pumpkin", "sugar", "flour"},
            amount = {2, 1, 1},
            category = "other",
            time = 28,
            positive = {["heal"] = 30, ["night_vision"] = 15},
            negative = {},
            label = "Spooky Pumpkin Pie",
            description = "A sweet pie with a spooky twist.",
            availableFrom = {month = 10, day = 25},
            availableTo = {month = 11, day = 1}
        }
    }
}

-- Hidden recipes that can be discovered
Config.HiddenRecipes = {
    ["secret_fish_stew"] = {
        ingredients = {"raw_fish", "potato", "onion", "water"},
        amount = {1, 1, 1, 1},
        category = "soup",
        time = 25,
        positive = {["heal"] = 50, ["energy"] = 25, ["water_breathing"] = 60},
        negative = {},
        label = "Secret Fish Stew",
        description = "A special stew with mysterious properties.",
        discoveryDifficulty = 3 -- Higher number = harder to discover
    },
    ["wilderness_survival_meal"] = {
        ingredients = {"mushroom", "herb", "raw_fish", "water"},
        amount = {2, 2, 1, 1},
        category = "other",
        time = 30,
        positive = {["heal"] = 60, ["stamina"] = 40, ["strength"] = 20},
        negative = {},
        label = "Wilderness Survival Meal",
        description = "A complete meal that significantly boosts survival abilities.",
        discoveryDifficulty = 5
    },
    ["campfire_dessert"] = {
        ingredients = {"sugar", "flour", "berry"},
        amount = {1, 1, 2},
        category = "other",
        time = 15,
        positive = {["heal"] = 20, ["happiness"] = 40, ["stress"] = -30},
        negative = {},
        label = "Campfire Dessert",
        description = "A sweet treat that lifts the spirits.",
        discoveryDifficulty = 2
    }
}
