local sec = 1000
local minute = 60 * sec
local activeTents = {} -- Table to track tents by stashID
local enteredTent = false
local TentModel = Config.TentModel
local CampfireModel = Config.CampfireModel

Citizen.CreateThread(function()
    TriggerServerEvent('camping:LoadData')
end)

RegisterNetEvent('camping:updateTentState', function(tentID, isOccupied)
    if isOccupied then
        activeTents[tentID] = true
    else
        activeTents[tentID] = nil
    end
end)

RegisterNetEvent('camping:loadCampingData', function(data)
    if data.type == 'tent' then
        Renewed.addObject({
            id = data.stashID,
            coords = vec3(data.x, data.y, data.z-1.55),
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
                        if not enteredTent then return true end
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
                    onSelect = function(info)
                        exports.ox_inventory:openInventory('stash', data.stashID)
                    end
                },
                {
                    label = "Pickup tent",
                    icon = 'fa-solid fa-hand',
                    iconColor = 'grey',
                    distance = Config.targetDistance,
                    canInteract = function()
                        if not enteredTent then return true end
                    end,
                    onSelect = function(info)
                        deleteTent(data.stashID)
                    end
                },
            }
        })
        TriggerServerEvent('camping:createTentStash', data.stashID)
    else
        Renewed.addObject({
            id = data.stashID,
            coords = vec3(data.x, data.y, data.z-0.7),
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
                        showCampfireMenu()
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

function generateRandomTentStashId()
    local randomId = math.random(100000, 999999)
    local stashId = "tent_" .. randomId
    return stashId
end

function generateRandomCampfireId()
    local randomId = math.random(100000, 999999)
    local campfireId = "campfire_" .. randomId
    return campfireId
end

-- Tent spawning logic
RegisterNetEvent('camping:client:spawnTent', function(x,y,z,h,randomModel,stashId)
    Renewed.addObject({
        id = stashId,
        coords = vec3(x,y,z-1.55),
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
                    if not enteredTent then return true end
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
                onSelect = function(info)
                    exports.ox_inventory:openInventory('stash', stashId)
                end
            },
            {
                label = "Pickup tent",
                icon = 'fa-solid fa-hand',
                iconColor = 'grey',
                distance = Config.targetDistance,
                canInteract = function()
                    if not enteredTent then return true end
                end,
                onSelect = function(info)
                    deleteTent(stashId)
                end
            },
        }
    })
end)

-- Campfire spawning logic
RegisterNetEvent('camping:client:spawnCampfire', function(x,y,z,h,fireModel,campfireID)
    Renewed.addObject({
        id = campfireID,
        coords = vec3(x,y,z-0.7),
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
                    showCampfireMenu()
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

-- Event Handlers
AddEventHandler('ox_inventory:usedItem', function(name, slotId, metadata)
    if name == Config.tentItem then
        TriggerEvent('ox_inventory:closeInventory')
        local tentCoords, tentHeading = Renewed.placeObject(TentModel, 25, false, {
            '-- Place Object --  \n',
            '[E] Place  \n',
            '[X] Cancel  \n',
            '[SCROLL UP] Change Heading  \n',
            '[SCROLL DOWN] Change Heading'
        }, nil, vec3(0.0, 0.0, 0.65))
        if tentCoords and tentHeading then
            local stashId = nil
            if metadata and metadata.stashID then
                stashId = metadata.stashID
            else
                stashId = generateRandomTentStashId()
            end
            TriggerServerEvent('camping:server:spawnTent', tentCoords.x, tentCoords.y, tentCoords.z, tentHeading, TentModel, stashId, slotId)
            TriggerServerEvent('camping:saveCampingData', 'tent', TentModel, tentCoords.x, tentCoords.y, tentCoords.z, stashId, tentHeading)
            lib.notify({ title = 'Tent', description = 'Tent placed successfully.', type = 'success' })
        end
    elseif name == Config.campfireItem then
        TriggerEvent('ox_inventory:closeInventory')
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

    local dict = "amb@medic@standing@kneel@base"
    local anim = "base"
    RequestAnimDict(dict)
    local timeout = 5000
    local startTime = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        if GetGameTimer() - startTime > timeout then
            lib.notify({title = 'Tent', description = 'Failed to load animation.', type = 'error'})
            return
        end
    end
    TaskTurnPedToFaceEntity(cache.ped, entity, 1000)
    Wait(1000)
    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(1000)
    local tentCoords = GetEntityCoords(entity)
    SetEntityCoordsNoOffset(playerPed, tentCoords.x, tentCoords.y, tentCoords.z, true, true, true)
    SetEntityHeading(cache.ped, (GetEntityHeading(entity)+45.0))

    local dict = Config.TentAnimDict or "amb@world_human_sunbathe@male@back@base"
    local anim = Config.TentAnimName or "base"
    RequestAnimDict(dict)
    local timeout = 5000
    local startTime = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        if GetGameTimer() - startTime > timeout then
            lib.notify({title = 'Tent', description = 'Failed to load animation.', type = 'error'})
            return
        end
    end
    if IsEntityPlayingAnim(playerPed, dict, anim, 3) then
        lib.notify({title = 'Tent', description = 'You are already resting.', type = 'info'})
        return
    end

    TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    activeTents[tentID] = true -- Mark the tent as occupied locally
    TriggerServerEvent('camping:tentEntered', tentID) -- Notify server
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
                    activeTents[tentID] = nil -- Remove tent from local table
                    TriggerServerEvent('camping:tentExited', tentID) -- Notify server
                    lib.notify({ title = 'Tent', description = 'You have exited the tent.', type = 'info' })
                else
                    lib.notify({ title = 'Tent', description = 'You are not inside this tent.', type = 'error' })
                end
                lib.hideTextUI()
            end
        end
    end)
end

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

RegisterNetEvent('camping:client:removeTentItem', function(tentID)
    Renewed.removeObject(tentID)
end)

RegisterNetEvent('camping:client:removeFireItem', function(fireId)
    Renewed.removeObject(fireId)
end)

local maxFuelLevel = Config.maxFuel
local fuelLevel = 0 -- Initialize fuel level
-- Update fuel progress bar dynamically
function updateFuelProgressBar(consume)
    if fuelLevel <= 0 then
        lib.notify({ title = 'Campfire', description = 'The campfire is out of fuel.', type = 'error' })
        return
    end
    fuelLevel = fuelLevel - consume
end

-- Show the campfire menu with the current fuel level
function showCampfireMenu()
    lib.registerContext({
        id = 'campfire_menu',
        title = 'Campfire',
        options = {
            {
                icon = 'fa-fire',
                title = 'Fuel Level',
                description = 'Current fuel level of the campfire.',
                progress = fuelLevel, -- Show fuel level as a progress bar
                colorScheme = 'orange',
                readOnly = true, -- Display-only
            },
            {
                icon = 'fa-plus',
                title = 'Add Fuel',
                description = 'Add fuel to keep the fire burning.',
                menu = 'add_fuel_menu',
                arrow = true,
            },
            {
                icon = 'fa-kitchen-set',
                title = 'Cooking',
                description = 'Prepare meals using the campfire.',
                menu = 'campfire_cooking_menu',
                arrow = true,
            },
        },
    })

    lib.registerContext({
        id = 'add_fuel_menu',
        title = 'Add Fuel',
        menu = 'campfire_menu',
        options = {
            Config.FuelMenu[1],
            Config.FuelMenu[2],
            Config.FuelMenu[3],
        },
    })

    lib.registerContext({
        id = 'campfire_cooking_menu',
        title = 'Cooking Menu',
        menu = 'campfire_menu',
        options = {
            Config.CookingMenu[1],
            Config.CookingMenu[2],
            Config.CookingMenu[3],
        },
    })

    lib.showContext('campfire_menu')
end

-- Add fuel handler
RegisterNetEvent('add_fuel_option', function(data)
    local itemtype = data.type
    local minAmt, maxAmt, itemlabel
    
    -- Define the item type ranges
    if itemtype == "garbage" then minAmt, maxAmt, itemlabel = 1, 20, "Garbage"
    elseif itemtype == "tr_firewood" then minAmt, maxAmt, itemlabel = 1, 10, 'Firewood'
    elseif itemtype == "coal" then minAmt, maxAmt, itemlabel = 1, 5, 'Coal' end

    -- Check if the player has the required items before proceeding
    local itemCount = exports.ox_inventory:Search('count', itemtype)
    if itemCount <= 0 then
        lib.notify({ title = 'Fuel', description = 'You do not have enough ' .. itemlabel .. '.', type = 'error' })
        return
    end

    -- Prompt for input dialog
    local amount = lib.inputDialog("Add Fuel", { { type = "number", label = "Amount (" .. minAmt .. "-" .. maxAmt .. ")", min = minAmt, max = maxAmt, default = itemCount } })

    if not amount or tonumber(amount[1]) < 1 then
        lib.notify({ title = 'Fuel', description = 'Invalid amount.', type = 'error' })
        return
    end

    local inputAmount = tonumber(amount[1])

    -- Check if the player has enough of the required item
    if inputAmount > itemCount then
        lib.notify({ title = 'Fuel', description = 'You do not have enough ' .. itemtype .. '.', type = 'error' })
        return
    end
    
    -- Calculate total duration based on input amount
    local totalDuration = data.duration * inputAmount
    -- Calculate fuel percentage
    local fuelPercentage = (totalDuration / maxFuelLevel) * 100
    fuelLevel = fuelLevel + fuelPercentage
    lib.notify({ title = 'Campfire', description = 'Fuel added successfully.', type = 'success' })
    updateFuelProgressBar(0)  -- Update fuel progress bar with the current level
    TriggerServerEvent('camping:RI', itemtype, inputAmount)
end)


-- Cooking handler
RegisterNetEvent('campfire_cooking', function(recipe)
    local cookingData = Config.Recipes

    local selectedRecipe = cookingData[recipe]
    if not selectedRecipe then
        lib.notify({ title = 'Campfire', description = 'Invalid recipe selected.', type = 'error' })
        return
    end

    -- Check if there's enough fuel before starting cooking
    local requiredFuel = ((selectedRecipe.cookTime / 1000) / 100) -- Convert milliseconds to seconds
    if fuelLevel < requiredFuel then
        lib.notify({ title = 'Campfire', description = 'Not enough fuel to start cooking.', type = 'error' })
        return
    end

    -- Check player inventory for ingredients
    for _, ingredient in pairs(selectedRecipe.ingredients) do
        if exports.ox_inventory:Search('count', ingredient.name) < ingredient.count then
            lib.notify({ title = 'Campfire', description = 'Not enough ' .. ingredient.name, type = 'error' })
            return
        end
    end

    -- Remove ingredients
    for _, ingredient in pairs(selectedRecipe.ingredients) do
        TriggerServerEvent('camping:RI', ingredient.name, ingredient.count)
    end

    -- Start cooking process
    local progress = lib.progressBar({
        duration = selectedRecipe.cookTime,
        label = 'Cooking ' .. selectedRecipe.label,
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true, -- Prevents the player from moving
            car = true,  -- Prevents using vehicles
            combat = true, -- Disables combat actions
            mouse = false -- Disables mouse movement
        },
        anim = {
            dict = 'amb@prop_human_bbq@male@base', -- Animation dictionary
            clip = 'base', -- Animation clip
            flag = 49 -- Prevents movement while keeping controls disabled
        }
    })

    if progress then
        -- Deduct fuel using updateFuelProgressBar
        updateFuelProgressBar(requiredFuel)
        TriggerServerEvent('camping:AI', recipe, 1)
        lib.notify({ title = 'Campfire', description = selectedRecipe.label .. ' cooked successfully!', type = 'success' })
    end
end)

function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

function math.round(input, decimalPlaces)
    return tonumber(string.format("%." .. (decimalPlaces or 0) .. "f", input))
end