Config = {}

Config.targetDistance = 2.0

-- โมเดลเต็นท์ (ตามเดิม)
Config.TentModel = 'prop_skid_tent_01'

-- เปลี่ยนเป็นพร็อพกองไฟของคุณ
Config.CampfireModel = 'log_campfire'   -- เดิมเป็น 'prop_beach_fire'

Config.tentItem = 'tent'
Config.campfireItem = 'campfire'

-- ฐานเวลาเต็มถังเชื้อเพลิง (วินาที) ใช้แปลง % ตอนเติม/หัก
Config.maxFuel = 300

-- อัตราลดเชื้อเพลิงเมื่อไฟติด (% ต่อวินาที)
Config.fuelDrainPerSecond = 0.1

-- เอฟเฟกต์ไฟ (พาร์ติเคิล) เมื่อจุดไฟ
Config.CampfireFx = {
    asset = 'core',
    name  = 'ent_amb_beach_campfire',
    offset = { x = 0.0, y = -0.15, z = 0.0 },
    scale  = 1.0
}

-- เมนูเชื้อเพลิง (คงไว้ตามเดิม)
Config.FuelMenu = {
    { icon='fas fa-newspaper', title="Garbage (5 seconds)",  description="Adds 5 seconds of fuel per unit.",  event='add_fuel_option', args={ type="garbage",     duration=5  } },
    { icon='fas fa-tree',      title="Fire Wood (30 seconds)", description="Adds 30 seconds of fuel per unit.", event='add_fuel_option', args={ type="wood", duration=30 } },
    { icon='fas fa-fire',      title="Coal (60 seconds)",     description="Adds 60 seconds of fuel per unit.", event='add_fuel_option', args={ type="coal",        duration=60 } },
}

-- สูตรทำอาหาร (ตามเดิม)
Config.Recipes = {
    grilled_rainbow_trout = {
        key='grilled_rainbow_trout', label="Grill Rainbow Trout",
        icon='nui://ox_inventory/web/images/grilled_fish.png', cookTime=60000,
        ingredients = { { name="rainbow-trout", count=1 } }
    },
    meat_soup = {
        key='meat_soup', label="Meat Soup",
        icon='nui://ox_inventory/web/images/meat_stew.png', cookTime=120000,
        ingredients = { { name="venison",count=1 }, { name="water",count=1 }, { name="potato_1",count=1 } }
    },
    grilled_potato = {
        key='grilled_potato', label="Grill Potato",
        icon='nui://ox_inventory/web/images/potato.png', cookTime=30000,
        ingredients = { { name="potato_1", count=1 } }
    },
}
