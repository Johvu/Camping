local sec = 1000
local minute = 60 * sec
local activeTents = {} -- Table to track tents by stashID
local activeFires = {}
local enteredTent = false
local Inventory = Config.Inventory
local TentModel = Config.TentModel
local CampfireModel = Config.CampfireModel
local FuelSystem = {
    fuelLevel = Config.DefaultFuelLevel or 0,
    maxFuelLevel = Config.maxFuel or 300,
    isUIOpen = false,
}
local currentWeather = "clear"
local cachedInventory = {}

-- Determine if the optional GES-Temperature resource is available. This
-- prevents calling exports from a resource that isn't running.
local function isGESTemperatureAvailable()
    if not Config.useGESTemperature then
        return false
    end

    if not GetResourceState or GetResourceState('GES-Temperature') ~= 'started' then
        return false
    end

    return true
end

-- Skill system variables
local cookingSkill = {
    level = 1,
    xp = 0,
    nextLevelXP = 100
}

-- Recipe discovery variables
local discoveredRecipes = {}

-- Framework initialization
local Framework = Config.Framework or 'standalone'

if Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
    if not ESX then
        Framework = 'standalone'
    end
elseif Framework == 'qbox' or Framework == 'qb-core' then
    QBCore = exports['qb-core']:GetCoreObject()
    if not QBCore then
        Framework = 'standalone'
    end
end

-- Animation loading helper function
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local timeout = 500
        while not HasAnimDictLoaded(dict) and timeout > 0 do
            timeout = timeout - 1
            Wait(10)
        end
    end
    return HasAnimDictLoaded(dict)
end

-- Get current season based on in-game date
function GetCurrentSeason()
    local month = GetClockMonth() + 1 -- GetClockMonth is 0-based
    
    if (month >= 3 and month <= 5) then
        return "spring"
    elseif (month >= 6 and month <= 8) then
        return "summer"
    elseif (month >= 9 and month <= 11) then
        return "fall"
    else
        return "winter"
    end
end

-- Optimized object caching
local cachedModels = {}

function GetCachedModel(model)
    if not cachedModels[model] then
        if not IsModelInCdimage(model) then return nil end
        
        RequestModel(model)
        local timeout = 500
        while not HasModelLoaded(model) and timeout > 0 do
            timeout = timeout - 1
            Wait(10)
        end
        
        if HasModelLoaded(model) then
            cachedModels[model] = true
        else
            return nil
        end
    end
    return model
end

-- Cleanup function to remove unused models from cache
function CleanupModelCache()
    for model in pairs(cachedModels) do
        if not IsModelInCdimage(model) then
            SetModelAsNoLongerNeeded(model)
            cachedModels[model] = nil
        end
    end
end

local function updateInventoryCache()
    if Inventory ~= 'ox' then return end
    cachedInventory = {}
    local items = exports.ox_inventory:GetPlayerItems()
    for _, item in ipairs(items) do
        cachedInventory[item.name] = item.count
    end
end

if Inventory == 'ox' then
    AddEventHandler('ox_inventory:updateInventory', function()
        updateInventoryCache()
        if FuelSystem.isUIOpen then
            FuelSystem:refreshUI()
        end
    end)

    CreateThread(function()
        updateInventoryCache()
    end)
end

-- Refresh UI with current fuel level and inventory (if UI is open)
function FuelSystem:refreshUI()
    if self.isUIOpen then
        SendNUIMessage({
            action = 'updateFuel',
            fuelLevel = self.fuelLevel,
            inventory = cachedInventory
        })
    end
end

-- Consume a given amount of fuel. Returns true if successful.
function FuelSystem:consume(amount)
    if self.fuelLevel <= 0 then
        lib.notify({ title = 'Campfire', description = 'The campfire is out of fuel.', type = 'error' })
        return false
    end
    self.fuelLevel = math.max(self.fuelLevel - amount, 0)
    self:refreshUI()
    return true
end

-- Add fuel using an item. Validates input, plays an animation, updates UI and notifies the server.
function FuelSystem:addFuel(itemtype, inputAmount, duration)
    local itemRanges = {
        garbage  = { min = 1, max = 20, label = "Garbage" },
        firewood = { min = 1, max = 10, label = "Firewood" },
        coal     = { min = 1, max = 5,  label = "Coal" }
    }
    local range = itemRanges[itemtype]
    if not range then
        lib.notify({ title = 'Fuel', description = 'Invalid fuel type: ' .. tostring(itemtype), type = 'error' })
        return false
    end
    local availableCount = exports.ox_inventory:Search('count', itemtype)
    if availableCount < inputAmount then
        lib.notify({ title = 'Fuel', description = 'Not enough ' .. range.label .. '.', type = 'error' })
        return false
    end
    if not inputAmount or tonumber(inputAmount) < range.min then
        lib.notify({ title = 'Fuel', description = 'Invalid amount provided for ' .. range.label .. '.', type = 'error' })
        return false
    end
    local totalDuration = duration * inputAmount
    local fuelAddition = (totalDuration / self.maxFuelLevel) * 100
    self.fuelLevel = math.min(self.fuelLevel + fuelAddition, self.maxFuelLevel)
    
    -- (Optional) Enhance immersion with a fueling animation.
    self:refreshUI()
    
    lib.notify({ title = 'Campfire', description = 'Fuel added successfully.', type = 'success' })
    TriggerServerEvent('camping:RI', itemtype, inputAmount)
    return true
end

-- Expose FuelSystem for debugging if needed
_G.FuelSystem = FuelSystem

-- Heat zone system
local activeHeatZones = {}

-- Create heat zone around a prop (campfire)
function createHeatZoneAroundProp(coords, zoneId)
    if isGESTemperatureAvailable() then
        exports['GES-Temperature']:createHeatZone(coords, zoneId)
        
        -- Store the heat zone in our tracking table for reference
        if not activeFires[zoneId] then
            activeFires[zoneId] = {
                coords = coords,
                active = true
            }
        end
        
        if Config.Debug then
            print("^2[DEBUG] Created heat zone: " .. zoneId .. " at coords: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z .. "^7")
        end
    end
end

-- Delete heat zone
function deleteHeatZone(zoneId)
    if isGESTemperatureAvailable() then
        exports['GES-Temperature']:deleteHeatZone(zoneId)
        
        -- Remove from our tracking table
        if activeFires[zoneId] then
            activeFires[zoneId] = nil
        end
        
        if Config.Debug then
            print("^2[DEBUG] Deleted heat zone: " .. zoneId .. "^7")
        end
    end
end

-- Initialize data and cleanup thread
Citizen.CreateThread(function()
    TriggerServerEvent('camping:LoadData')
    
    -- Periodically clean up model cache
    while true do
        Wait(60000) -- Clean up every minute
        CleanupModelCache()
    end
end)

-- Event handlers for tent state
RegisterNetEvent('camping:updateTentState', function(tentID, isOccupied)
    activeTents[tentID] = isOccupied or nil
end)

-- Load camping data from server
RegisterNetEvent('camping:loadCampingData', function(data)
    if data.type == 'tent' then
        Renewed.addObject({
            id = data.stashID,
            coords = vec3(data.x, data.y, data.z - 1.5),
            object = data.model,
            dist = 75,
            heading = data.heading,
            canClimb = false,
            freeze = true,
            snapGround = false,
            target = {
                {
                    label = "Go inside",
                    icon = 'fa-solid fa-tent-arrows-down',
                    iconColor = 'grey',
                    distance = Config.targetDistance,
                    canInteract = function()
                        return not enteredTent
                    end,
                    onSelect = function(info)
                        UseTent(info.entity, data.stashID)
                    end
                },
                {
                    label = "Open tent storage",
                    icon = 'fa-solid fa-box-open',
                    iconColor = 'grey',
                    distance = Config.targetDistance,
                    onSelect = function()
                        exports.ox_inventory:openInventory('stash', data.stashID)
                    end
                },
                {
                    label = "Pickup tent",
                    icon = 'fa-solid fa-hand',
                    iconColor = 'grey',
                    distance = Config.targetDistance,
                    canInteract = function()
                        return not enteredTent
                    end,
                    onSelect = function()
                        deleteTent(data.stashID)
                    end
                },
            }
        })
        TriggerServerEvent('camping:createTentStash', data.stashID)
    else
        Renewed.addObject({
            id = data.stashID,
            coords = vec3(data.x, data.y, data.z - 0.7),
            object = data.model,
            dist = 75,
            heading = data.heading,
            canClimb = false,
            freeze = true,
            snapGround = false,
            target = {
                {
                    label = "Use Campfire",
                    icon = 'fas fa-fire',
                    iconColor = 'orange',
                    distance = Config.targetDistance,
                    onSelect = function()
                        OpenCampfireMenu(data.stashID)
                    end
                },
                {
                    label = "Put Out Campfire",
                    icon = 'fas fa-hand',
                    iconColor = 'grey',
                    distance = Config.targetDistance,
                    onSelect = function()
                        deleteCampfire(data.stashID)
                    end
                },
            }
        })
    end
end)


function getCurrentWeather()
    if Config.weatherResource == 'renewed-weathersync' then
        return GlobalState.weather and GlobalState.weather.weather or "clear"
    else
        if isGESTemperatureAvailable() then
            local weatherData = exports['GES-Temperature']:getTemperatureData()
            if weatherData and weatherData.weather then
                return weatherData.weather
            end
        else
            return "clear"
        end
    end
end

-- Add a thread to update the current weather periodically
Citizen.CreateThread(function()
    while true do
        -- Update current weather
        currentWeather = getCurrentWeather()
        Wait(60000) -- Update every minute
    end
end)

-- Generate unique IDs
function generateRandomTentStashId()
    return "tent_" .. math.random(100000, 999999)
end

function generateRandomCampfireId()
    return "campfire_" .. math.random(100000, 999999)
end

-- Tent spawning event handler
RegisterNetEvent('camping:client:spawnTent', function(x, y, z, h, randomModel, stashId)
    Renewed.addObject({
        id = stashId,
        coords = vec3(x, y, z-1.5),
        object = randomModel,
        dist = 75,
        heading = h,
        canClimb = false,
        freeze = true,
        snapGround = false,
        target = {
            {
                label = "Go inside",
                icon = 'fa-solid fa-tent-arrows-down',
                iconColor = 'grey',
                distance = Config.targetDistance,
                canInteract = function()
                    return not enteredTent
                end,
                onSelect = function(info)
                    UseTent(info.entity, stashId)
                end
            },
            {
                label = "Open tent storage",
                icon = 'fa-solid fa-box-open',
                iconColor = 'grey',
                distance = Config.targetDistance,
                onSelect = function()
                    exports.ox_inventory:openInventory('stash', stashId)
                end
            },
            {
                label = "Pickup tent",
                icon = 'fa-solid fa-hand',
                iconColor = 'grey',
                distance = Config.targetDistance,
                canInteract = function()
                    return not enteredTent
                end,
                onSelect = function()
                    deleteTent(stashId)
                end
            },
        }
    })
end)

-- Campfire spawning event handler
RegisterNetEvent('camping:client:spawnCampfire', function(x, y, z, h, fireModel, campfireID)
    Renewed.addObject({
        id = campfireID,
        coords = vec3(x, y, z-0.7),
        object = fireModel,
        dist = 75,
        heading = h,
        canClimb = false,
        freeze = true,
        snapGround = false,
        target = {
            {
                label = "Use Campfire",
                icon = 'fas fa-fire',
                iconColor = 'orange',
                distance = Config.targetDistance,
                onSelect = function()
                    OpenCampfireMenu(campfireID)
                end
            },
            {
                label = "Put Out Campfire",
                icon = 'fas fa-hand',
                iconColor = 'grey',
                distance = Config.targetDistance,
                onSelect = function()
                    deleteCampfire(campfireID)
                end
            },
        }
    })
end)

-- Item usage handler
AddEventHandler('ox_inventory:usedItem', function(name, slotId, metadata)
    if name == Config.tentItem then
        if Inventory == 'ox' then
            TriggerEvent('ox_inventory:closeInventory')
        elseif Inventory == 'qb' then
            TriggerEvent('inventory:client:closeInventory')
        end
        local tentCoords, tentHeading = Renewed.placeObject(TentModel, 25, false, {
            '-- Place Object --  \n',
            '[E] Place  \n',
            '[X] Cancel  \n',
            '[SCROLL UP] Change Heading  \n',
            '[SCROLL DOWN] Change Heading'
        }, nil, vec3(0.0, 0.0, 0.65))
        
        if tentCoords and tentHeading then
            local stashId = metadata and metadata.stashID or generateRandomTentStashId()
            TriggerServerEvent('camping:server:spawnTent', tentCoords.x, tentCoords.y, tentCoords.z, tentHeading, TentModel, stashId, slotId)
            TriggerServerEvent('camping:saveCampingData', 'tent', TentModel, tentCoords.x, tentCoords.y, tentCoords.z, stashId, tentHeading)
            lib.notify({ title = 'Tent', description = 'Tent placed successfully.', type = 'success' })
        end
    elseif name == Config.campfireItem then
        if Inventory == 'ox' then
            TriggerEvent('ox_inventory:closeInventory')
        elseif Inventory == 'qb' then
            TriggerEvent('inventory:client:closeInventory')
        end
        local fireCoords, fireHeading = Renewed.placeObject(CampfireModel, 25, false, {
            '-- Place Object --  \n',
            '[E] Place  \n',
            '[X] Cancel  \n',
            '[SCROLL UP] Change Heading  \n',
            '[SCROLL DOWN] Change Heading'
        }, nil, vec3(0.0, 0.0, 0.1))
        
        if fireCoords and fireHeading then
            local campfireID = generateRandomCampfireId()
            TriggerServerEvent('camping:server:spawnCampfire', fireCoords.x, fireCoords.y, fireCoords.z, fireHeading, CampfireModel, campfireID, slotId)
            TriggerServerEvent('camping:saveCampingData', 'campfire', CampfireModel, fireCoords.x, fireCoords.y, fireCoords.z, campfireID, fireHeading)
            createHeatZoneAroundProp(fireCoords, campfireID)
            lib.notify({ title = 'Campfire', description = 'Campfire placed successfully.', type = 'success' })
        end
    end
end)

-- Tent usage function
function UseTent(entity, tentID)
    local playerPed = cache.ped
    local PedCoord = GetEntityCoords(playerPed)
    if not DoesEntityExist(entity) then
        lib.notify({title = 'Tent', description = 'No tent found or tent is invalid!', type = 'error'})
        return
    end
    if activeTents[tentID] then
        lib.notify({ title = 'Tent', description = 'Someone is already inside this tent.', type = 'error' })
        return
    end
    if not LoadAnimDict("amb@medic@standing@kneel@base") then
        lib.notify({title = 'Tent', description = 'Failed to load animation.', type = 'error'})
        return
    end
    TaskTurnPedToFaceEntity(cache.ped, entity, 1000)
    Wait(1000)
    TaskPlayAnim(PlayerPedId(), "amb@medic@standing@kneel@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(1000)
    local tentCoords = GetEntityCoords(entity)
    SetEntityCoordsNoOffset(playerPed, tentCoords.x, tentCoords.y, tentCoords.z, true, true, true)
    SetEntityHeading(cache.ped, (GetEntityHeading(entity)+45.0))
    local dict = Config.TentAnimDict or "amb@world_human_sunbathe@male@back@base"
    local anim = Config.TentAnimName or "base"
    if not LoadAnimDict(dict) then
        lib.notify({title = 'Tent', description = 'Failed to load animation.', type = 'error'})
        return
    end
    if IsEntityPlayingAnim(playerPed, dict, anim, 3) then
        lib.notify({title = 'Tent', description = 'You are already resting.', type = 'info'})
        return
    end
    TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    activeTents[tentID] = true
    TriggerServerEvent('camping:tentEntered', tentID)
    enteredTent = true
    lib.showTextUI('[E] to leave the tent')
    CreateThread(function()
        while enteredTent do
            Wait(0)
            if IsControlJustReleased(0, 38) then
                enteredTent = false
                ClearPedTasksImmediately(playerPed)
                SetEntityCoords(playerPed, PedCoord.x, PedCoord.y, PedCoord.z -1, true, false, false, false)
                if activeTents[tentID] then
                    activeTents[tentID] = nil
                    TriggerServerEvent('camping:tentExited', tentID)
                    lib.notify({ title = 'Tent', description = 'You have exited the tent.', type = 'info' })
                else
                    lib.notify({ title = 'Tent', description = 'You are not inside this tent.', type = 'error' })
                end
                lib.hideTextUI()
            end
        end
    end)
end

-- Delete tent function
function deleteTent(tentId)
    if not tentId then
        lib.notify({
            title = 'Error',
            description = 'No previous tent spawned, or your previous tent has already been deleted.',
            type = 'error'
        })
    else
        TriggerServerEvent('camping:deleteCampingData', 'tent', tentId)
        lib.notify({
            title = 'Tent',
            description = 'Tent deleted successfully.',
            type = 'success'
        })
        TriggerServerEvent('camping:AI', 'tent', 1, {stashID = tentId})
        TriggerServerEvent('camping:server:removeTentItem', tentId)
    end
end

-- Delete campfire function
function deleteCampfire(fireId)
    if not fireId then
        lib.notify({
            title = 'Error',
            description = 'No previous camping spawned, or your previous campfire has already been deleted.',
            type = 'error'
        })
    else
        TriggerServerEvent('camping:deleteCampingData', 'campfire', fireId)
        lib.notify({
            title = 'Campfire',
            description = 'Campfire deleted successfully.',
            type = 'success'
        })
        TriggerServerEvent('camping:AI', 'campfire', 1)
        TriggerServerEvent('camping:server:removeFireItem', fireId)
        deleteHeatZone(fireId)
    end
end

-- Remove tent/fire item events
RegisterNetEvent('camping:client:removeTentItem', function(tentID)
    Renewed.removeObject(tentID)
end)

RegisterNetEvent('camping:client:removeFireItem', function(fireId)
    Renewed.removeObject(fireId)
end)

-- Fuel system
RegisterNetEvent('camping:syncFuel')
AddEventHandler('camping:syncFuel', function(fuelUsed)
    FuelSystem:consume(fuelUsed)
end)
RegisterNUICallback('addFuel', function(data, cb)
    local success = FuelSystem:addFuel(data.type, tonumber(data.amount), tonumber(data.duration))
    cb({ success = success })
end)

function OpenCookingMenu(campfireID)
    if FuelSystem.isUIOpen then 
        return 
    end
    
    local inventory = {}

    if Inventory == 'ox' then
        for name, count in pairs(cachedInventory) do
            inventory[name] = count
        end
    elseif Inventory == 'qb' then
        local PlayerData = QBCore.Functions.GetPlayerData()
        for _, item in pairs(PlayerData.items) do
            if item and item.name then
                inventory[item.name] = item.amount
            end
        end
    end
    
    local availableRecipes = GetAvailableRecipes()
    local recipes = {}
    for recipeName, recipeData in pairs(availableRecipes) do
        local label = recipeData.label or recipeName:gsub("_", " "):gsub("^%l", string.upper)
        local description = recipeData.description or "A delicious recipe"
        table.insert(recipes, {
            id = recipeName,
            label = label,
            description = description,
            cookTime = recipeData.time * 1000, -- seconds to milliseconds
            category = recipeData.category or "other",
            ingredients = {},
            seasonal = recipeData.seasonal or false,
            hidden = recipeData.hidden or false
        })
        if Config.SkillSystem.Enabled and cookingSkill.level > 1 then
            local benefit = Config.SkillSystem.LevelBenefits[cookingSkill.level]
            if benefit and benefit.cookTimeReduction > 0 then
                local reduction = (benefit.cookTimeReduction / 100)
                recipes[#recipes].cookTime = recipes[#recipes].cookTime * (1 - reduction)
            end
        end
        if type(recipeData.ingredients) == "string" then
            local amount = recipeData.amount or 1
            if Config.SkillSystem.Enabled and cookingSkill.level > 1 then
                local benefit = Config.SkillSystem.LevelBenefits[cookingSkill.level]
                if benefit and benefit.ingredientReduction > 0 then
                    local saveChance = benefit.ingredientReduction / 100
                    if saveChance > 0 and amount > 1 then
                        if math.random() < saveChance then
                            amount = amount - 1
                        end
                    end
                end
            end
            table.insert(recipes[#recipes].ingredients, { name = recipeData.ingredients, count = amount })
        elseif type(recipeData.ingredients) == "table" then
            for i, ingredient in ipairs(recipeData.ingredients) do
                local amount = 1
                if type(recipeData.amount) == "table" then
                    amount = recipeData.amount[i] or 1
                end
                if Config.SkillSystem.Enabled and cookingSkill.level > 1 then
                    local benefit = Config.SkillSystem.LevelBenefits[cookingSkill.level]
                    if benefit and benefit.ingredientReduction > 0 then
                        local saveChance = benefit.ingredientReduction / 100
                        if saveChance > 0 and amount > 1 then
                            if math.random() < saveChance then
                                amount = amount - 1
                            end
                        end
                    end
                end
                table.insert(recipes[#recipes].ingredients, { name = ingredient, count = amount })
            end
        end
    end
    
    FuelSystem.isUIOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'openCookingMenu',
        recipes = recipes,
        inventory = inventory,
        fuelLevel = FuelSystem.fuelLevel,
        skill = cookingSkill
    })
end

-- Register NUI callbacks
RegisterNUICallback('closeCookingMenu', function(data, cb)
    SetNuiFocus(false, false)
    FuelSystem.isUIOpen = false
    cb({})
end)

RegisterNUICallback('cookRecipe', function(data, cb)
    local recipe = data.recipe
    
    -- Close UI
    SetNuiFocus(false, false)
    FuelSystem.isUIOpen = false
    
    -- Trigger the cooking process
    TriggerEvent('campfire_cooking', recipe)
    
    cb({})
end)

-- Update the existing OpenCampfireMenu function to use the new React UI
function OpenCampfireMenu(campfireID)
    OpenCookingMenu(campfireID)
end

-- Fuel menu callback
RegisterNUICallback('openFuelMenu', function(data, cb)
    SetNuiFocus(false, false)
    lib.registerContext({
        id = 'add_fuel_menu',
        title = 'Add Fuel',
        options = {
            Config.FuelMenu[1],
            Config.FuelMenu[2],
            Config.FuelMenu[3],
            {
                title = "Cancel",
                icon = "fas fa-times",
                onSelect = function()
                    if FuelSystem.isUIOpen then
                        SetNuiFocus(true, true)
                    end
                end
            }
        },
        onExit = function()
            TriggerEvent('camping:restoreNUIFocus')
        end
    })
    lib.showContext('add_fuel_menu')
    cb({})
end)

-- Restore NUI focus event

RegisterNetEvent('camping:restoreNUIFocus')
AddEventHandler('camping:restoreNUIFocus', function()
    if FuelSystem.isUIOpen then
        SetNuiFocus(true, true)
    end
end)

-- Cooking handler
RegisterNetEvent('campfire_cooking', function(recipe)
    local availableRecipes = GetAvailableRecipes()
    local selectedRecipe = availableRecipes[recipe]
    if not selectedRecipe then
        lib.notify({ title = 'Campfire', description = 'Invalid recipe selected.', type = 'error' })
        return
    end

    local requiredFuel = ((selectedRecipe.time / 100)) -- Convert seconds to fuel units
    local weatherMultiplier = 1.0
    if isGESTemperatureAvailable() then
        local weatherConfig = exports["GES-Temperature"]:GetWeatherConfig()
        weatherMultiplier = weatherConfig.WeatherEffects.FuelConsumption[currentWeather] or 1.0
    end
    requiredFuel = requiredFuel * weatherMultiplier

    if FuelSystem.fuelLevel < requiredFuel then
        lib.notify({ title = 'Campfire', description = 'Not enough fuel to start cooking.', type = 'error' })
        return
    end

    -- Check player inventory for ingredients
    local hasAllIngredients = true
    local missingIngredients = {}
    local ingredientsToRemove = {}

    -- Handle both string and table ingredients
    if type(selectedRecipe.ingredients) == "string" then
        -- Single ingredient
        local ingredient = selectedRecipe.ingredients
        local amount = selectedRecipe.amount or 1
        
        -- Apply ingredient reduction from cooking skill
        if Config.SkillSystem.Enabled and cookingSkill.level > 1 then
            local benefit = Config.SkillSystem.LevelBenefits[cookingSkill.level]
            if benefit and benefit.ingredientReduction > 0 then
                -- Calculate chance to save an ingredient
                local saveChance = benefit.ingredientReduction / 100
                if saveChance > 0 and amount > 1 then
                    -- Potentially reduce amount by 1 based on skill level
                    if math.random() < saveChance then
                        amount = amount - 1
                    end
                end
            end
        end
        
        local playerAmount = exports.ox_inventory:Search('count', ingredient)
        
        if playerAmount < amount then
            hasAllIngredients = false
            table.insert(missingIngredients, ingredient)
        else
            table.insert(ingredientsToRemove, {name = ingredient, count = amount})
        end
    elseif type(selectedRecipe.ingredients) == "table" then
        -- Multiple ingredients
        for i, ingredient in ipairs(selectedRecipe.ingredients) do
            local amount = 1
            if type(selectedRecipe.amount) == "table" then
                amount = selectedRecipe.amount[i] or 1
            end
            
            -- Apply ingredient reduction from cooking skill
            if Config.SkillSystem.Enabled and cookingSkill.level > 1 then
                local benefit = Config.SkillSystem.LevelBenefits[cookingSkill.level]
                if benefit and benefit.ingredientReduction > 0 then
                    -- Calculate chance to save an ingredient
                    local saveChance = benefit.ingredientReduction / 100
                    if saveChance > 0 and amount > 1 then
                        -- Potentially reduce amount by 1 based on skill level
                        if math.random() < saveChance then
                            amount = amount - 1
                        end
                    end
                end
            end
            
            local playerAmount = exports.ox_inventory:Search('count', ingredient)
            if playerAmount < amount then
                hasAllIngredients = false
                table.insert(missingIngredients, ingredient)
            else
                table.insert(ingredientsToRemove, {name = ingredient, count = amount})
            end
        end
    end

    if not hasAllIngredients then
        local missingText = table.concat(missingIngredients, ", ")
        lib.notify({ title = 'Campfire', description = 'Not enough ingredients. Missing: ' .. missingText, type = 'error' })
        return
    end

    -- Remove ingredients
    for _, item in ipairs(ingredientsToRemove) do
        TriggerServerEvent('camping:RI', item.name, item.count)
    end
    local cookTime = selectedRecipe.time
    if Config.SkillSystem.Enabled and cookingSkill.level > 1 then
        local benefit = Config.SkillSystem.LevelBenefits[cookingSkill.level]
        if benefit and benefit.cookTimeReduction > 0 then
            local reduction = (benefit.cookTimeReduction / 100)
            cookTime = cookTime * (1 - reduction)
        end
    end

    local progress = lib.progressBar({
        duration = cookTime * 1000,
        label = 'Cooking ' .. (selectedRecipe.label or recipe),
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'amb@prop_human_bbq@male@base',
            clip = 'base',
            flag = 49
        }
    })

    if progress then
        FuelSystem:consume(requiredFuel)
        TriggerServerEvent('camping:updateFuel', requiredFuel)
        local qualityBonus = 0
        if Config.SkillSystem.Enabled and cookingSkill.level > 1 then
            local benefit = Config.SkillSystem.LevelBenefits[cookingSkill.level]
            if benefit and benefit.qualityBonus > 0 then
                qualityBonus = benefit.qualityBonus
            end
        end
        
        if Config.SkillSystem.Enabled then
            TriggerServerEvent('camping:addCookingXP', Config.SkillSystem.XPPerCook)
        end
        
        TriggerServerEvent('camping:AI', recipe, 1, {quality = 100 + qualityBonus})
        if Config.RecipeDiscovery.Enabled then
            TriggerServerEvent('camping:checkRecipeDiscovery', ingredientsToRemove)
        end
        
        lib.notify({ title = 'Campfire', description = (selectedRecipe.label or recipe) .. ' cooked successfully!', type = 'success' })
    end
end)

-- Get available recipes based on season and discovered recipes
function GetAvailableRecipes()
    local allRecipes = {}
    local season = GetCurrentSeason()
    
    -- Add standard recipes
    for k, v in pairs(Config.Recipes) do
        allRecipes[k] = v
    end
    
    -- Add seasonal recipes if available
    if Config.SeasonalRecipes[season] then
        for k, v in pairs(Config.SeasonalRecipes[season]) do
            allRecipes[k] = v
        end
    end
    
    -- Add holiday recipes if they're in season
    if Config.SeasonalRecipes.holiday then
        for k, v in pairs(Config.SeasonalRecipes.holiday) do
            if IsHolidayRecipeAvailable(v) then
                allRecipes[k] = v
            end
        end
    end
    
    -- Add discovered hidden recipes
    for k, v in pairs(discoveredRecipes) do
        if Config.HiddenRecipes[k] then
            allRecipes[k] = Config.HiddenRecipes[k]
        end
    end
    
    return allRecipes
end

-- Check if a holiday recipe is available
function IsHolidayRecipeAvailable(recipe)
    if not recipe.availableFrom or not recipe.availableTo then
        return true -- No date restrictions
    end
    
    local day = GetClockDayOfMonth()
    local month = GetClockMonth() + 1 -- GetClockMonth is 0-based
    
    local fromMonth = recipe.availableFrom.month
    local fromDay = recipe.availableFrom.day
    local toMonth = recipe.availableTo.month
    local toDay = recipe.availableTo.day
    
    -- Simple check for same month
    if month == fromMonth and month == toMonth then
        return day >= fromDay and day <= toDay
    -- Check for period spanning multiple months
    elseif month == fromMonth then
        return day >= fromDay
    elseif month == toMonth then
        return day <= toDay
    elseif month > fromMonth and month < toMonth then
        return true
    end
    
    return false
end

-- Load cooking skill data from server
RegisterNetEvent('camping:loadCookingSkill')
AddEventHandler('camping:loadCookingSkill', function(skillData)
    cookingSkill = skillData
    
    -- Update UI if it's open
    if FuelSystem.isUIOpen then
        SendNUIMessage({
            action = 'updateSkill',
            skill = cookingSkill
        })
    end
end)

-- Load discovered recipes from server
RegisterNetEvent('camping:loadDiscoveredRecipes')
AddEventHandler('camping:loadDiscoveredRecipes', function(recipes)
    discoveredRecipes = recipes
end)

-- Request skill and recipe data when player spawns
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('camping:requestCookingSkill')
    TriggerServerEvent('camping:requestDiscoveredRecipes')
end)

-- Add emergency UI close command
RegisterCommand('closecampingui', function()
    if FuelSystem.isUIOpen then
        FuelSystem.isUIOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = 'hide'
        })
        lib.notify({
            title = 'UI',
            description = 'Forced UI to close',
            type = 'inform'
        })
    end
end)

-- Register a keybind for it (F10 key)
RegisterKeyMapping('closecampingui', 'Force close camping UI', 'keyboard', 'F10')





