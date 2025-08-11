local serverTentStates = {} -- Table to track tent occupancy
local cachedCampingData = {} -- Cache for camping data
local playerCooldowns = {} -- For rate limiting

local Framework = Config.Framework or 'standalone'
local Inventory = Config.Inventory or 'ox'

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

RegisterNetEvent('camping:updateFuel')
AddEventHandler('camping:updateFuel', function(fuelUsed)
    local src = source
    if fuelUsed and fuelUsed > 0 then
        -- Send updated fuel level back to the client
        TriggerClientEvent('camping:syncFuel', src, fuelUsed)
    end
end)


-- Function to check and set cooldowns
function CheckCooldown(playerId, action, cooldownTime)
    cooldownTime = cooldownTime or 2000 -- Default 2 seconds
    
    if not playerCooldowns[playerId] then
        playerCooldowns[playerId] = {}
    end
    
    local lastTime = playerCooldowns[playerId][action]
    local currentTime = GetGameTimer()
    
    if lastTime and (currentTime - lastTime) < cooldownTime then
        return false -- Still on cooldown
    end
    
    playerCooldowns[playerId][action] = currentTime
    return true -- Not on cooldown
end

-- Add input validation function
function ValidateCoordinates(x, y, z)
    -- Check if coordinates are within reasonable bounds
    if not x or not y or not z then return false end
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then return false end
    
    -- GTA V map boundaries (approximate)
    if x < -4000 or x > 4000 then return false end
    if y < -4000 or y > 8000 then return false end
    if z < -200 or z > 1500 then return false end
    
    return true
end

RegisterNetEvent('camping:tentEntered')
AddEventHandler('camping:tentEntered', function(tentID)
    local src = source

    if serverTentStates[tentID] then
        -- Notify the player that the tent is already occupied
        TriggerClientEvent('camping:notify', src, {
            title = 'Tent',
            description = 'This tent is already occupied.',
            type = 'error'
        })
    else
        -- Mark the tent as occupied on the server
        serverTentStates[tentID] = src
        TriggerClientEvent('camping:updateTentState', -1, tentID, true) -- Broadcast state
    end
end)

RegisterNetEvent('camping:tentExited')
AddEventHandler('camping:tentExited', function(tentID)
    local src = source

    -- Check if the player exiting matches the one who entered
    if serverTentStates[tentID] == src then
        serverTentStates[tentID] = nil -- Free the tent
        TriggerClientEvent('camping:updateTentState', -1, tentID, false) -- Broadcast state
    end
end)

-- When a player disconnects, clear their occupied tents
AddEventHandler('playerDropped', function()
    local src = source
    for tentID, occupant in pairs(serverTentStates) do
        if occupant == src then
            serverTentStates[tentID] = nil
            TriggerClientEvent('camping:updateTentState', -1, tentID, false) -- Broadcast state
        end
    end
end)

RegisterNetEvent('camping:saveCampingData')
AddEventHandler('camping:saveCampingData', function(type, model, x, y, z, stashID, heading)
    local src = source
    
    -- Basic validation
    if not ValidateCoordinates(x, y, z) then
        return
    end
    
    -- Sanitize stashID to prevent SQL injection
    local safeStashID = stashID or ''
    if string.len(safeStashID) > 50 then
        safeStashID = string.sub(safeStashID, 1, 50)
    end
    
    local query = "INSERT INTO camping (type, model, x, y, z, stashID, heading) VALUES (@type, @model, @x, @y, @z, @stashID, @heading)"
    local insertId = exports.oxmysql:insert(query, {
        ['@type'] = type,
        ['@model'] = model,
        ['@x'] = x,
        ['@y'] = y,
        ['@z'] = z,
        ['@stashID'] = safeStashID,
        ['@heading'] = heading
    })
    
    if insertId then
        -- Add to cache
        table.insert(cachedCampingData, {
            id = insertId,
            type = type,
            model = model,
            x = x,
            y = y,
            z = z,
            stashID = safeStashID,
            heading = heading
        })
    end
    
    if type == 'tent' and safeStashID ~= '' then
        if Inventory == 'ox' then
            exports.ox_inventory:RegisterStash(safeStashID, "Tent", 10, 10000)
        elseif Inventory == 'qb' then
            -- add your qb stash function
        end
    end
end)

RegisterNetEvent('camping:LoadData')
AddEventHandler('camping:LoadData', function()
    local src = source
    
    -- Check if we already have cached data
    if next(cachedCampingData) then
        for _, data in ipairs(cachedCampingData) do
            TriggerClientEvent('camping:loadCampingData', src, data)
        end
        return
    end
    
    -- If not cached, load from database
    local result = exports.oxmysql:executeSync("SELECT * FROM camping")
    cachedCampingData = result -- Cache the result
    
    for _, data in ipairs(result) do
        TriggerClientEvent('camping:loadCampingData', src, data)
    end
end)

RegisterNetEvent('camping:deleteCampingData')
AddEventHandler('camping:deleteCampingData', function(type, stashID)
    local query = "DELETE FROM camping WHERE type = @type AND stashID = @stashID"
    exports.oxmysql:execute(query, {
        ['@type'] = type,
        ['@stashID'] = stashID
    })
    
    -- Remove from cache
    for i, data in ipairs(cachedCampingData) do
        if data.type == type and data.stashID == stashID then
            table.remove(cachedCampingData, i)
            break
        end
    end
end)

-- Add a function to refresh the cache periodically
function RefreshCampingDataCache()
    local result = exports.oxmysql:executeSync("SELECT * FROM camping")
    cachedCampingData = result
end

-- Refresh cache every 15 minutes
Citizen.CreateThread(function()
    while true do
        Wait(900000) -- 15 minutes
        RefreshCampingDataCache()
    end
end)

-- Add Item
RegisterNetEvent('camping:AI', function(itemName, amount, meta)
    if not source or source == 0 then return end
    local src = source
    if Inventory == 'ox' then
        exports.ox_inventory:AddItem(src, itemName, amount, meta or nil)
    elseif Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem(itemName, amount, meta)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "add")
        end
    end
end)

-- Remove Item
RegisterNetEvent('camping:RI', function(itemName, amount, meta, slot)
    if not source or source == 0 then return end
    local src = source
    if Inventory == 'ox' then
        exports.ox_inventory:RemoveItem(src, itemName, amount, meta or nil, slot or nil)
    elseif Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(itemName, amount, meta)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "remove")
        end
    end
    
end)

-- Create a tent stash
RegisterNetEvent('camping:server:spawnTent', function(x, y, z, h, randomModel, stashId, slot)
    local src = source
    
    -- Validate input
    if not ValidateCoordinates(x, y, z) then
        return
    end
    
    -- Check cooldown (5 second cooldown for spawning tents)
    if not CheckCooldown(src, 'spawnTent', 5000) then
        TriggerClientEvent('lib.notify', src, {
            title = 'Cooldown',
            description = 'Please wait before placing another tent.',
            type = 'error'
        })
        return
    end   
    if Inventory == 'ox' then
        exports.ox_inventory:RemoveItem(src, Config.tentItem, 1, nil, slot or nil)
    elseif Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(Config.tentItem, 1, nil)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.tentItem], "remove")
        end
    end
    TriggerClientEvent('camping:client:spawnTent', -1, x, y, z, h, randomModel, stashId)
end)

RegisterNetEvent('camping:server:spawnCampfire', function(x, y, z, h, fireModel, campfireId, slot)
    local src = source
    
    -- Validate input
    if not ValidateCoordinates(x, y, z) then
        return
    end
    
    -- Check cooldown (5 second cooldown for spawning campfires)
    if not CheckCooldown(src, 'spawnCampfire', 5000) then
        TriggerClientEvent('lib.notify', src, {
            title = 'Cooldown',
            description = 'Please wait before placing another campfire.',
            type = 'error'
        })
        return
    end
    
    if Inventory == 'ox' then
        exports.ox_inventory:RemoveItem(src, Config.campfireItem, 1, nil, slot or nil)
    elseif Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(Config.campfireItem, 1, nil)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.campfireItem], "remove")
        end
    end
    TriggerClientEvent('camping:client:spawnCampfire', -1, x, y, z, h, fireModel, campfireId)
end)

RegisterNetEvent('camping:createTentStash', function(stashId)
    local src = source
    
    -- Validate stash ID format
    if not stashId or type(stashId) ~= "string" or not stashId:match("^tent_%d+$") then
        return
    end
    
    -- Check if this stash already exists
    local exists = exports.ox_inventory:GetInventory(stashId)
    if exists then
        -- Stash already exists, no need to register again
        return
    end
    
    if Inventory == 'ox' then
        exports.ox_inventory:RegisterStash(stashId, "Tent", 10, 10000)
    elseif Inventory == 'qb' then
        -- add your qb stash function
    end
end)

RegisterNetEvent('camping:server:removeTentItem', function(tentId)
    TriggerClientEvent('camping:client:removeTentItem', -1, tentId)
end)

RegisterNetEvent('camping:server:removeFireItem', function(fireId)
    TriggerClientEvent('camping:client:removeFireItem', -1, fireId)
end)

-- Player cooking skills
local playerCookingSkills = {}

-- Player discovered recipes
local playerDiscoveredRecipes = {}

-- Load player cooking skill
function LoadPlayerCookingSkill(source)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if not identifier then return end
    
    -- Initialize default skill if not exists
    if not playerCookingSkills[identifier] then
        playerCookingSkills[identifier] = {
            level = 1,
            xp = 0,
            nextLevelXP = Config.SkillSystem.XPRequirements[2] or 100
        }
    end
    
    return playerCookingSkills[identifier]
end

-- Save player cooking skill
function SavePlayerCookingSkill(source)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if not identifier or not playerCookingSkills[identifier] then return end
    
    -- Here you would typically save to database
    -- For example with oxmysql:
    -- exports.oxmysql:execute('UPDATE players SET cooking_skill = ? WHERE identifier = ?', {
    --     json.encode(playerCookingSkills[identifier]),
    --     identifier
    -- })
end

-- Load player discovered recipes
function LoadPlayerDiscoveredRecipes(source)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if not identifier then return end
    
    -- Initialize empty recipes if not exists
    if not playerDiscoveredRecipes[identifier] then
        playerDiscoveredRecipes[identifier] = {}
    end
    
    return playerDiscoveredRecipes[identifier]
end

-- Save player discovered recipes
function SavePlayerDiscoveredRecipes(source)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if not identifier or not playerDiscoveredRecipes[identifier] then return end
    
    -- Here you would typically save to database
    -- For example with oxmysql:
    -- exports.oxmysql:execute('UPDATE players SET discovered_recipes = ? WHERE identifier = ?', {
    --     json.encode(playerDiscoveredRecipes[identifier]),
    --     identifier
    -- })
end

-- Add cooking XP to player
RegisterNetEvent('camping:addCookingXP')
AddEventHandler('camping:addCookingXP', function(xpAmount)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if not identifier then return end
    
    -- Initialize skill if not exists
    if not playerCookingSkills[identifier] then
        playerCookingSkills[identifier] = {
            level = 1,
            xp = 0,
            nextLevelXP = Config.SkillSystem.XPRequirements[2] or 100
        }
    end
    
    -- Add XP
    playerCookingSkills[identifier].xp = playerCookingSkills[identifier].xp + xpAmount
    
    -- Check for level up
    local currentLevel = playerCookingSkills[identifier].level
    local nextLevel = currentLevel + 1
    
    if nextLevel <= Config.SkillSystem.MaxLevel and 
       playerCookingSkills[identifier].xp >= Config.SkillSystem.XPRequirements[nextLevel] then
        -- Level up
        playerCookingSkills[identifier].level = nextLevel
        playerCookingSkills[identifier].nextLevelXP = Config.SkillSystem.XPRequirements[nextLevel + 1] or 999999
        
        -- Notify player
        TriggerClientEvent('lib.notify', src, {
            title = 'Cooking Skill',
            description = 'Level up! You are now a ' .. Config.SkillSystem.LevelBenefits[nextLevel].description,
            type = 'success'
        })
    end
    
    -- Update client
    TriggerClientEvent('camping:loadCookingSkill', src, playerCookingSkills[identifier])
    
    -- Save to database
    SavePlayerCookingSkill(src)
end)

-- Check for recipe discovery
RegisterNetEvent('camping:checkRecipeDiscovery')
AddEventHandler('camping:checkRecipeDiscovery', function(ingredients)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if not identifier or not Config.RecipeDiscovery.Enabled then return end
    
    -- Initialize discovered recipes if not exists
    if not playerDiscoveredRecipes[identifier] then
        playerDiscoveredRecipes[identifier] = {}
    end
    
    -- Get player cooking skill level
    local skillLevel = 1
    if playerCookingSkills[identifier] then
        skillLevel = playerCookingSkills[identifier].level
    end
    
    -- Calculate discovery chance based on skill level
    local discoveryChance = Config.RecipeDiscovery.DiscoveryChance + 
                           (skillLevel - 1) * Config.RecipeDiscovery.DiscoveryChancePerLevel
    
    -- Check if player discovers a recipe
    if math.random(1, 100) <= discoveryChance then
        -- Find a hidden recipe that matches the ingredients
        local potentialRecipes = {}
        
        for recipeName, recipeData in pairs(Config.HiddenRecipes) do
            -- Skip already discovered recipes
            if not playerDiscoveredRecipes[identifier][recipeName] then
                local matchScore = 0
                local requiredIngredients = {}
                
                -- Convert recipe ingredients to a table for easier comparison
                if type(recipeData.ingredients) == "string" then
                    requiredIngredients = {recipeData.ingredients}
                else
                    requiredIngredients = recipeData.ingredients
                end
                
                -- Check how many ingredients match
                for _, requiredIngredient in ipairs(requiredIngredients) do
                    for _, usedIngredient in ipairs(ingredients) do
                        if requiredIngredient == usedIngredient.name then
                            matchScore = matchScore + 1
                            break
                        end
                    end
                end
                
                -- Calculate match percentage
                local matchPercentage = (matchScore / #requiredIngredients) * 100
                
                -- If match percentage is high enough, add to potential recipes
                if matchPercentage >= 50 then
                    table.insert(potentialRecipes, {
                        name = recipeName,
                        data = recipeData,
                        matchScore = matchScore,
                        difficulty = recipeData.discoveryDifficulty or 1
                    })
                end
            end
        end
        
        -- If there are potential recipes, select one based on match score and difficulty
        if #potentialRecipes > 0 then
            -- Sort by match score (higher is better)
            table.sort(potentialRecipes, function(a, b)
                return a.matchScore > b.matchScore
            end)
            
            -- Select a recipe, with preference for higher match scores
            local selectedRecipe = potentialRecipes[1]
            
            -- Check if player's skill level is high enough for the recipe difficulty
            if skillLevel >= selectedRecipe.difficulty then
                -- Discover the recipe
                playerDiscoveredRecipes[identifier][selectedRecipe.name] = true
                
                -- Notify player
                TriggerClientEvent('lib.notify', src, {
                    title = 'Recipe Discovery',
                    description = 'You discovered a new recipe: ' .. selectedRecipe.data.label,
                    type = 'success'
                })
                
                -- Update client
                TriggerClientEvent('camping:loadDiscoveredRecipes', src, playerDiscoveredRecipes[identifier])
                
                -- Save to database
                SavePlayerDiscoveredRecipes(src)
            end
        end
    end
end)

-- Request cooking skill data
RegisterNetEvent('camping:requestCookingSkill')
AddEventHandler('camping:requestCookingSkill', function()
    local src = source
    local skillData = LoadPlayerCookingSkill(src)
    
    if skillData then
        TriggerClientEvent('camping:loadCookingSkill', src, skillData)
    end
end)

-- Request discovered recipes
RegisterNetEvent('camping:requestDiscoveredRecipes')
AddEventHandler('camping:requestDiscoveredRecipes', function()
    local src = source
    local recipes = LoadPlayerDiscoveredRecipes(src)
    
    if recipes then
        TriggerClientEvent('camping:loadDiscoveredRecipes', src, recipes)
    end
end)

-- Clean up player data on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    if identifier then
        -- Save data before removing from memory
        if playerCookingSkills[identifier] then
            SavePlayerCookingSkill(src)
        end
        
        if playerDiscoveredRecipes[identifier] then
            SavePlayerDiscoveredRecipes(src)
        end
    end
end)


