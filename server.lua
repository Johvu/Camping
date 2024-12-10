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
end)

RegisterNetEvent('camping:LoadData')
AddEventHandler('camping:LoadData', function()
    local result = exports.oxmysql:executeSync("SELECT * FROM camping")
    for _, data in ipairs(result) do
        TriggerClientEvent('camping:loadCampingData', -1, data)
        debugLog("Loaded camping data : " .. json.encode(data))
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
RegisterNetEvent('camping:addItem', function(itemName, amount)
    local src = source
    local added = exports.ox_inventory:AddItem(src, itemName, amount)
    debugLog(("Added %d of %s to player %d"):format(amount, itemName, src))
end)

-- Remove Item
RegisterNetEvent('camping:removeItem', function(itemName, amount)
    local src = source
    local removed = exports.ox_inventory:RemoveItem(src, itemName, amount)
    debugLog(("Removed %d of %s from player %d"):format(amount, itemName, src))
end)

local tentStashes = {}

-- Create a tent stash
RegisterNetEvent('camping:createTentStash', function(stashId)
    if tentStashes[stashId] then
        debugLog("Tent stash already exists: " .. stashId)
        return
    end

    exports.ox_inventory:RegisterStash(stashId, "Tent", 10, 10000)
    tentStashes[stashId] = stashId
    debugLog("Tent stash created with ID: " .. stashId)

end)


function debugLog(message)
    if Config.DEBUG then
        print("^3[DEBUG]^7 " .. tostring(message))
    end
end