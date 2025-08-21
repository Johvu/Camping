local serverTentStates = {}             -- ผู้ครองเต็นท์
local campfireFuel = {}                 -- % เชื้อเพลิง ต่อกองไฟ
local campfireLit  = {}                 -- true/false ไฟติด-ดับ ต่อกองไฟ

-- ========== Tent (เดิม) ==========
RegisterNetEvent('camping:tentEntered')
AddEventHandler('camping:tentEntered', function(tentID)
    local src = source
    if serverTentStates[tentID] then
        TriggerClientEvent('camping:notify', src, { title='Tent', description='This tent is already occupied.', type='error' })
    else
        serverTentStates[tentID] = src
        TriggerClientEvent('camping:updateTentState', -1, tentID, true)
    end
end)

RegisterNetEvent('camping:tentExited')
AddEventHandler('camping:tentExited', function(tentID)
    local src = source
    if serverTentStates[tentID] == src then
        serverTentStates[tentID] = nil
        TriggerClientEvent('camping:updateTentState', -1, tentID, false)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for tentID, occupant in pairs(serverTentStates) do
        if occupant == src then
            serverTentStates[tentID] = nil
            TriggerClientEvent('camping:updateTentState', -1, tentID, false)
        end
    end
end)

-- ========== Persistence ==========
RegisterNetEvent('camping:saveCampingData')
AddEventHandler('camping:saveCampingData', function(type, model, x, y, z, stashID, heading)
    local query = "INSERT INTO camping (type, model, x, y, z, stashID, heading) VALUES (@type, @model, @x, @y, @z, @stashID, @heading)"
    exports.oxmysql:insert(query, {
        ['@type']=type, ['@model']=model, ['@x']=x, ['@y']=y, ['@z']=z,
        ['@stashID']=stashID or '', ['@heading']=heading
    })
end)

RegisterNetEvent('camping:LoadData')
AddEventHandler('camping:LoadData', function()
    local src = source
    local result = exports.oxmysql:executeSync("SELECT * FROM camping")
    for _, data in ipairs(result) do
        if data.type == 'campfire' then
            if campfireFuel[data.stashID] == nil then campfireFuel[data.stashID] = 0 end
            if campfireLit[data.stashID]  == nil then campfireLit[data.stashID]  = false end
        end
        TriggerClientEvent('camping:loadCampingData', src, data)
        if data.type == 'campfire' then
            TriggerClientEvent('camping:updateFuel', src, data.stashID, campfireFuel[data.stashID] or 0)
            TriggerClientEvent('camping:updateLit',  src, data.stashID, campfireLit[data.stashID]  or false)
        end
    end
end)

RegisterNetEvent('camping:deleteCampingData')
AddEventHandler('camping:deleteCampingData', function(type, stashID)
    local query = "DELETE FROM camping WHERE type = @type AND stashID = @stashID"
    exports.oxmysql:execute(query, { ['@type']=type, ['@stashID']=stashID })
    if type == 'campfire' then
        campfireFuel[stashID] = nil
        campfireLit[stashID]  = nil
        TriggerClientEvent('camping:updateFuel', -1, stashID, 0)
        TriggerClientEvent('camping:updateLit',  -1, stashID, false)
    end
end)

-- ========== Items I/O ==========
RegisterNetEvent('camping:AI', function(itemName, amount, meta)
    if not source then return end
    exports.ox_inventory:AddItem(source, itemName, amount, meta or nil)
end)
RegisterNetEvent('camping:RI', function(itemName, amount, meta, slot)
    if not source then return end
    exports.ox_inventory:RemoveItem(source, itemName, amount, meta or nil, slot or nil)
end)

-- ========== Spawn ==========
RegisterNetEvent('camping:server:spawnTent', function(x,y,z,h,randomModel, stashId, slot)
    exports.ox_inventory:RemoveItem(source, Config.tentItem, 1, nil, slot or nil)
    TriggerClientEvent('camping:client:spawnTent', -1, x,y,z,h,randomModel, stashId)
end)

RegisterNetEvent('camping:server:spawnCampfire', function(x,y,z,h,fireModel,campfireId, slot)
    exports.ox_inventory:RemoveItem(source, Config.campfireItem, 1, nil, slot or nil)
    campfireFuel[campfireId] = campfireFuel[campfireId] or 0
    campfireLit[campfireId]  = false
    TriggerClientEvent('camping:client:spawnCampfire', -1, x,y,z,h,fireModel,campfireId)
    TriggerClientEvent('camping:updateFuel', -1, campfireId, campfireFuel[campfireId])
    TriggerClientEvent('camping:updateLit',  -1, campfireId, false)
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

-- ========== Fuel API (server-authoritative) ==========
lib.callback.register('camping:getFuel', function(_, campfireId)
    return campfireFuel[campfireId] or 0
end)

lib.callback.register('camping:addFuel', function(_, campfireId, addPercent)
    local cur = campfireFuel[campfireId] or 0
    local newv = math.max(0, math.min(100, cur + (addPercent or 0)))
    campfireFuel[campfireId] = newv
    TriggerClientEvent('camping:updateFuel', -1, campfireId, newv)
    return newv
end)

lib.callback.register('camping:tryConsumeFuel', function(_, campfireId, consumePercent)
    local cur = campfireFuel[campfireId] or 0
    consumePercent = consumePercent or 0
    if cur >= consumePercent then
        local newv = math.max(0, math.min(100, cur - consumePercent))
        campfireFuel[campfireId] = newv
        TriggerClientEvent('camping:updateFuel', -1, campfireId, newv)
        if newv <= 0 and campfireLit[campfireId] then
            campfireLit[campfireId] = false
            TriggerClientEvent('camping:updateLit', -1, campfireId, false)
        end
        return { ok = true, fuel = newv }
    else
        return { ok = false, fuel = cur }
    end
end)

-- ========== จุดไฟ / ดับไฟ ==========
RegisterNetEvent('camping:ignite', function(campfireId)
    local src = source
    local cur = campfireFuel[campfireId] or 0
    if cur <= 0 then
        return TriggerClientEvent('camping:notify', src, { title='Campfire', description='No fuel to ignite.', type='error' })
    end
    if not campfireLit[campfireId] then
        campfireLit[campfireId] = true
        TriggerClientEvent('camping:updateLit', -1, campfireId, true)
    end
end)

RegisterNetEvent('camping:extinguish', function(campfireId)
    if campfireLit[campfireId] then
        campfireLit[campfireId] = false
        TriggerClientEvent('camping:updateLit', -1, campfireId, false)
    end
end)

-- ========== Auto-drain: ลดเชื้อเพลิง 0.1%/วิ เมื่อไฟติด ==========
CreateThread(function()
    while true do
        Wait(1000)
        local drain = (Config and Config.fuelDrainPerSecond) or 0.1
        if drain <= 0 then goto continue end
        for id, lit in pairs(campfireLit) do
            if lit then
                local cur = campfireFuel[id] or 0
                if cur > 0 then
                    local newv = cur - drain
                    if newv <= 0 then
                        newv = 0
                        campfireLit[id] = false
                        TriggerClientEvent('camping:updateLit', -1, id, false)
                    end
                    campfireFuel[id] = newv
                    TriggerClientEvent('camping:updateFuel', -1, id, newv)
                end
            end
        end
        ::continue::
    end
end)
