local function debugLog(message)
    if Config.DEBUG then
        print("^3[DEBUG]^7 " .. tostring(message))
    end
end

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

