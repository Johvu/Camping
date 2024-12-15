local function debugLog(message)
    if Config.DEBUG then
        print("^3[DEBUG]^7 " .. tostring(message))
    end
end
local sec = 1000
local minute = 60 * sec

local prevtent = {
    prop = nil,
    stashID = nil,
    busy = false
}
local prevfire = {
    prop = nil,
    ID = nil,
}
local TentModels = Config.TentModels
local CampfireModels = Config.CampfireModels



Citizen.CreateThread(function()
    debugLog("Initializing camping script.")
    AddTentModel(TentModels, "camping:UseTent", "camping:TentStorage", "camping:PickupTent", "camping:IsPlayerInsideTent")
    AddCampfireModel(CampfireModels, "camping:UseCampfire", "camping:PickupCampfire")
    TriggerServerEvent('camping:LoadData')
end)

RegisterNetEvent('camping:loadCampingData')
AddEventHandler('camping:loadCampingData', function(data)
    debugLog("Received camping data: " .. json.encode(data))
    local modelHash = GetHashKey(data.model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end

    local prop = CreateObject(modelHash, data.x, data.y, data.z, true, false, true)
    SetEntityHeading(prop, data.heading)

    if data.type == 'tent' then
        prevtent = { prop = prop, stashID = data.stashID, coords = vector3(data.x, data.y, data.z) }
    else
        prevfire = { prop = prop, ID = data.stashID }
    end
end)

function generateRandomTentStashId()
    local randomId = math.random(100000, 999999)
    local stashId = "tent_" .. randomId
    debugLog("Generated random stash ID: " .. stashId)
    return stashId
end

function generateRandomCampfireId()
    local randomId = math.random(100000, 999999)
    local campfireId = "campfire_" .. randomId
    debugLog("Generated random ID: " .. campfireId)
    return campfireId
end

-- Tent spawning logic
function spawnTent(x,y,z)
    debugLog("Attempting to spawn a tent.")
    if prevtent.prop then
        debugLog("Previous tent exists. Deleting it.")
        SetEntityAsMissionEntity(prevtent.prop)
        DeleteObject(prevtent.prop)
        prevtent = { prop = nil, stashID = nil, coords = nil }
    end

    debugLog(("Tent coordinates: X: %.2f, Y: %.2f, Z: %.2f"):format(x, y, (z -0.945)))

    local randomModel = TentModels[math.random(1, #TentModels)]
    debugLog("Selected tent model: " .. randomModel)

    local tentHash = GetHashKey(randomModel)
    RequestModel(tentHash)
    while not HasModelLoaded(tentHash) do Wait(0) end
    local prop = CreateObject(tentHash, x, y, z, true, false, true)
    local heading = GetEntityHeading(PlayerPedId())
    SetEntityHeading(prop, heading)
    PlaceObjectOnGroundProperly(prop)
    SetEntityCoordsNoOffset(prop, x, y, z + 0.58)
    

    local stashId = generateRandomTentStashId()
    prevtent = { prop = prop, stashID = stashId , coords = vector3(x, y, z) }

    TriggerServerEvent('camping:RI', Config.tentItem, 1)
    TriggerServerEvent('camping:createTentStash', stashId)
    debugLog("Tent spawned and stash created with ID: " .. stashId)

    lib.notify({ title = 'Tent', description = 'Tent spawned successfully.', type = 'success' })

    TriggerServerEvent('camping:saveCampingData', 'tent', randomModel, x, y, (z -0.945), stashId, heading)
end

-- Campfire spawning logic
function spawnCampfire(x,y,z)
    debugLog("Attempting to spawn a campfire.")
    if prevfire then
        debugLog("Previous campfire exists. Deleting it.")
        SetEntityAsMissionEntity(prevfire.prop)
        DeleteObject(prevfire.prop)
        prevfire = { prop = nil, ID = nil }
    end

    debugLog(("Campfire coordinates: X: %.2f, Y: %.2f, Z: %.2f"):format(x, y, (z -0.55)))
    local fireModel = CampfireModels[math.random(1, #CampfireModels)]
    local fireHash = GetHashKey(fireModel)
    local campfireID = generateRandomCampfireId()
    RequestModel(fireHash)
    while not HasModelLoaded(fireHash) do Wait(0) end
    local prop = CreateObject(fireHash, x, y, (z -0.55), true, false, true)
    local heading = GetEntityHeading(PlayerPedId())
    SetEntityHeading(prop, heading)
    PlaceObjectOnGroundProperly(prop)
    SetEntityCoordsNoOffset(prop, x, y, z + 0.1)


    prevfire = { prop = prop, ID = campfireID }

    TriggerServerEvent('camping:RI', Config.campfireItem, 1)
    lib.notify({ title = 'Campfire', description = 'Campfire spawned successfully.', type = 'success' })

    TriggerServerEvent('camping:saveCampingData', 'campfire', fireModel, x, y, (z -0.55), campfireID, heading)
end

-- Event Handlers
AddEventHandler('ox_inventory:usedItem', function(name, slotId, metadata)
    debugLog(("Item used: %s (Slot: %d)"):format(name, slotId))
    if name == Config.tentItem then
        toggleRaycastTent()
        debugLog("Spawning tent.")
    elseif name == Config.campfireItem then
        toggleRaycastCampfire()
        debugLog("Spawning campfire.")
    end
end)

RegisterNetEvent('camping:IsPlayerInsideTent', function()
    if prevtent.busy then
        lib.notify({title = 'Tent Status', description = 'Someone is inside the tent.', type = 'success'})
    else
        lib.notify({title = 'Tent Status', description = 'No one is inside the tent.', type = 'error'})
    end
end)


RegisterNetEvent('camping:UseTent', function()
    debugLog("Sleeping in the tent.")
    local playerPed = PlayerPedId()
    local PedCoord = GetEntityCoords(playerPed)

    if not prevtent or not DoesEntityExist(prevtent.prop) then
        lib.notify({title = 'Tent', description = 'No tent found or tent is invalid!', type = 'error'})
        return
    end

    local tentCoords = GetEntityCoords(prevtent.prop)
    SetEntityCoordsNoOffset(playerPed, tentCoords.x, tentCoords.y, tentCoords.z, true, true, true)

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
    prevtent.busy = true

    -- Debug log to confirm TextUI display

    local showingText = false
    CreateThread(function()
        while prevtent.busy do
            if not showingText then
                lib.showTextUI('[E] to leave the tent')
                showingText = true
            end
            Wait(0)
            if IsControlJustReleased(0, 38) then
                ClearPedTasksImmediately(playerPed)
                SetEntityCoords(playerPed, PedCoord.x, PedCoord.y, PedCoord.z -1, true, false, false, false)
                prevtent.busy = false
                lib.hideTextUI()
                showingText = false
                lib.notify({title = 'Tent', description = 'You left the tent.', type = 'success'})
            end
        end
    end)
end)


-- Tent Storage Interaction
RegisterNetEvent('camping:TentStorage', function()
    debugLog("Accessing tent storage.")
    if prevtent.prop then
        debugLog("Opening inventory for stash ID: " .. prevtent.stashID)
        exports.ox_inventory:openInventory('stash', prevtent.stashID)
    else
        debugLog("No tent deployed.")
        lib.notify({ title = 'Tent Storage', description = 'No tent is deployed.', type = 'error' })
    end
end)

RegisterNetEvent('camping:PickupTent', function()
    debugLog("Attempting to pick up the tent.")
    deleteTent()
end)

function deleteTent()
    debugLog("Deleting tent.")
    if not prevtent.prop then
        debugLog("No tent to delete.")
        lib.notify({
            title = 'Error',
            description = 'No previous tent spawned, or your previous tent has already been deleted.',
            type = 'error'
        })
    else
        SetEntityAsMissionEntity(prevtent.prop)
        DeleteObject(prevtent.prop)
        TriggerServerEvent('camping:deleteCampingData', 'tent', prevtent.stashID)
        prevtent = { prop = nil, stashID = nil }
        debugLog("Tent deleted successfully.")
        lib.notify({
            title = 'Tent',
            description = 'Tent deleted successfully.',
            type = 'success'
        })
        TriggerServerEvent('camping:AI', 'tent', 1)
    end
end

local maxFuelLevel = Config.maxFuel
local fuelLevel = 0 -- Initialize fuel level
-- Update fuel progress bar dynamically
function updateFuelProgressBar(consume)
    if fuelLevel <= 0 then
        lib.notify({ title = 'Campfire', description = 'The campfire is out of fuel.', type = 'error' })
        return
    end

    fuelLevel = fuelLevel - consume
    debugLog("Fuel level updated to: " .. fuelLevel)
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

-- Event for using campfire
RegisterNetEvent('camping:UseCampfire', function()
    showCampfireMenu()
end)

-- Add fuel handler
RegisterNetEvent('add_fuel_option', function(data)
    local src = source
    local itemtype = data.type
    local minAmt, maxAmt
    
    -- Define the item type ranges
    if itemtype == "paper" then minAmt, maxAmt = 1, 20
    elseif itemtype == "wood" then minAmt, maxAmt = 1, 10
    elseif itemtype == "coal" then minAmt, maxAmt = 1, 5 end

    -- Check if the player has the required items before proceeding
    local itemCount = exports.ox_inventory:Search('count', itemtype)
    if itemCount <= 0 then
        lib.notify({ title = 'Fuel', description = 'You do not have any ' .. itemtype .. '.', type = 'error' })
        return
    end

    -- Prompt for input dialog
    local amount = lib.inputDialog("Add Fuel", { { type = "number", label = "Amount (" .. minAmt .. "-" .. maxAmt .. ")", min = minAmt, max = maxAmt } })

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
    debugLog("Fuel level updated to: " .. fuelLevel .. " Total duration: " .. totalDuration .. " Fuel percentage: " .. fuelPercentage)
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
    local requiredFuel = selectedRecipe.cookTime / 1000 -- Convert milliseconds to seconds
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

RegisterNetEvent('camping:PickupCampfire', function()
    debugLog("Attempting to pick up the campfire.")
    deleteCampfire()
end)

function deleteCampfire()
    debugLog("Deleting campfire.")
    if not prevfire then
        debugLog("No camping to delete.")
        lib.notify({
            title = 'Error',
            description = 'No previous camping spawned, or your previous campfire has already been deleted.',
            type = 'error'
        })
    else
        SetEntityAsMissionEntity(prevfire.prop)
        DeleteObject(prevfire.prop)
        TriggerServerEvent('camping:deleteCampingData', 'campfire', prevfire.ID)
        prevfire = { prop = nil, ID = nil }
        debugLog("Campfire deleted successfully.")
        lib.notify({
            title = 'Campfire',
            description = 'Campfire deleted successfully.',
            type = 'success'
        })
        TriggerServerEvent('camping:AI', 'campfire', 1)
    end
end

local distance = Config.targetDistance

-- Add Tent Model and interactions
function AddTentModel(model, eventtotrigger, eventtotrigger2, eventtotrigger3, eventtotrigger4)
    debugLog("Adding tent models to ox_target.")
    exports.ox_target:addModel(model, {
        { label = "Is some one inside?", icon = 'magnifying-glass', iconColor = 'white', distance = distance, event = eventtotrigger4 },
        { label = "Go inside", icon = 'bed',iconColor = 'white', distance = distance, event = eventtotrigger },
        { label = "Open tent storage", icon = 'box-archive',iconColor = 'white', distance = distance, event = eventtotrigger2 },
        { label = "Pickup tent", icon = 'hand',iconColor = 'white', distance = distance, event = eventtotrigger3 },
    })
end

function AddCampfireModel(model, eventtotrigger, eventtotrigger2)
    debugLog("Adding campfire models to ox_target.")
    exports.ox_target:addModel(model, {
        { label = "Use campfire", icon = 'fire',iconColor = 'white', distance = distance, event = eventtotrigger },
        { label = "Pickup campfire", icon = 'hand',iconColor = 'white', distance = distance, event = eventtotrigger2 },
    })
end

local enableTent = false
local enableCampfire = false

function toggleRaycastTent()
    enableTent = not enableTent  -- Toggle between true and false
end
function toggleRaycastCampfire()
    enableCampfire = not enableCampfire  -- Toggle between true and false
end
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

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end

function math.round(input, decimalPlaces)
    return tonumber(string.format("%." .. (decimalPlaces or 0) .. "f", input))
end

Citizen.CreateThread(function()
    local showingText = false
    while true do
        local Wait = 500
        if enableTent or enableCampfire then
            local color = {r = 255, g = 255, b = 255, a = 200}
            local position = GetEntityCoords(PlayerPedId())
            local hit, coords, entity = RayCastGamePlayCamera(1000.0)

            if not showingText then
                lib.showTextUI('[E] - Place Object')
                showingText = true
            end

            DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
            DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false)
            
            if IsControlJustReleased(0, 38) then
                if enableTent then
                    spawnTent(coords.x, coords.y, coords.z)
                    toggleRaycastTent()
                elseif enableCampfire then
                    spawnCampfire(coords.x, coords.y, coords.z)
                    toggleRaycastCampfire()
                end
            end
            Wait = 5
        else
            if showingText then
                lib.hideTextUI()
                showingText = false
            end
        end
        Citizen.Wait(Wait)
    end
end)
