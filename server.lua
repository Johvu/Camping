local serverTentStates = {} -- Table to track tent occupancy

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
    local query = "INSERT INTO camping (type, model, x, y, z, stashID, heading) VALUES (@type, @model, @x, @y, @z, @stashID, @heading)"
    exports.oxmysql:insert(query, {
        ['@type'] = type,
        ['@model'] = model,
        ['@x'] = x,
        ['@y'] = y,
        ['@z'] = z,
        ['@stashID'] = stashID or '',
        ['@heading'] = heading
    })
    exports.ox_inventory:RegisterStash(stashID, "Tent", 10, 10000)
end)

RegisterNetEvent('camping:LoadData')
AddEventHandler('camping:LoadData', function()
    local src = source
    local result = exports.oxmysql:executeSync("SELECT * FROM camping")
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
end)

-- Add Item
RegisterNetEvent('camping:AI', function(itemName, amount, meta)
    if source == '' then return end
    local src = source
    exports.ox_inventory:AddItem(src, itemName, amount, meta or nil)
end)

-- Remove Item
RegisterNetEvent('camping:RI', function(itemName, amount, meta, slot)
    if source == '' then return end
    local src = source
    exports.ox_inventory:RemoveItem(src, itemName, amount, meta or nil, slot or nil)
end)

-- Create a tent stash
RegisterNetEvent('camping:server:spawnTent', function(x,y,z,h,randomModel, stashId, slot)
    local src = source
    exports.ox_inventory:RemoveItem(src, Config.tentItem, 1, nil, slot or nil)
    TriggerClientEvent('camping:client:spawnTent', -1, x,y,z,h,randomModel, stashId)
end)

RegisterNetEvent('camping:server:spawnCampfire', function(x,y,z,h,fireModel,campfireId, slot)
    local src = source
    exports.ox_inventory:RemoveItem(src, Config.campfireItem, 1, nil, slot or nil)
    TriggerClientEvent('camping:client:spawnCampfire', -1, x,y,z,h,fireModel,campfireId)
end)

RegisterNetEvent('camping:createTentStash', function(stashId)
    exports.ox_inventory:RegisterStash(stashId, "Tent", 10, 10000)
end)

RegisterNetEvent('camping:server:removeTentItem', function(tentId)
    TriggerClientEvent('camping:client:removeTentItem', -1, tentId)
end)

RegisterNetEvent('camping:server:removeFireItem', function(fireId)
    TriggerClientEvent('camping:client:removeFireItem', -1, fireId)
end)