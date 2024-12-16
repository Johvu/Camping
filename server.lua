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
RegisterNetEvent('camping:AI', function(itemName, amount)
    if source == '' then return end
    local src = source
    local added = exports.ox_inventory:AddItem(src, itemName, amount)
    debugLog(("Added %d of %s to player %d"):format(amount, itemName, src))
end)

-- Remove Item
RegisterNetEvent('camping:RI', function(itemName, amount)
    if source == '' then return end
    local src = source
    local removed = exports.ox_inventory:RemoveItem(src, itemName, amount)
    debugLog(("Removed %d of %s from player %d"):format(amount, itemName, src))
end)

local tentStashes = {}
local TentModels = Config.TentModels
-- Create a tent stash
RegisterNetEvent('camping:createTentStash', function(model, stashId)
    local slot, weight
    local tent
    if tentStashes[stashId] then
        debugLog("Tent stash already exists: " .. stashId)
        return
    end

    for i = 1 , #TentModels do
        if TentModels[i].model == model then 
            slot = TentModels[i].slot
            weight = TentModels[i].weight
            break
        end
    end

    exports.ox_inventory:RegisterStash(stashId, "Tent", slot, weight)
    tentStashes[stashId] = stashId
    debugLog("Tent stash created with ID: " .. stashId)

end)


function debugLog(message)
    if Config.DEBUG then
        print("^3[DEBUG]^7 " .. tostring(message))
    end
end