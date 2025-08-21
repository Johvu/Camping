local activeTents = {}
local enteredTent = false
local points  = {}       -- points[stashID] = lib.points.new(...)
local spawned = {}       -- spawned[stashID] = true/false
local pointMeta = {}     -- เก็บข้อมูลตำแหน่งของจุด (สำหรับหา coords ตอนเล่นเอฟเฟกต์)

local TentModel    = Config.TentModel
local CampfireModel= Config.CampfireModel

-- เชื้อเพลิง/ไฟต่อกองไฟ (0..100 และ true/false)
local fuelById = {}
local litById  = {}

-- แฮนเดิลพาร์ติเคิลของแต่ละกองไฟ
local fireFxById = {}

Citizen.CreateThread(function()
    TriggerServerEvent('camping:LoadData')
end)

RegisterNetEvent('camping:updateTentState', function(tentID, isOccupied)
    if isOccupied then activeTents[tentID] = true else activeTents[tentID] = nil end
end)

-- sync fuel จาก server
RegisterNetEvent('camping:updateFuel', function(campfireId, value)
    fuelById[campfireId] = value or 0
end)

-- sync สถานะไฟ + เปิด/ปิดเอฟเฟกต์
RegisterNetEvent('camping:updateLit', function(campfireId, lit)
    litById[campfireId] = (lit and true) or false
    local meta = pointMeta[campfireId]
    if not meta then return end

    local base = vec3(meta.x, meta.y, meta.z)
    local off  = Config.CampfireFx and Config.CampfireFx.offset or {x=0.0,y=0.0,z=0.0}
    local p = vec3(base.x + (off.x or 0.0), base.y + (off.y or 0.0), base.z + (off.z or 0.0))

    if litById[campfireId] then
        if not fireFxById[campfireId] then
            lib.requestNamedPtfxAsset(Config.CampfireFx.asset)
            UseParticleFxAsset(Config.CampfireFx.asset)
            local scale = (Config.CampfireFx.scale or 1.0)
            fireFxById[campfireId] = StartParticleFxLoopedAtCoord(
                Config.CampfireFx.name, p.x, p.y, p.z, 0.0, 0.0, 0.0, scale, false, false, false, false
            )
        end
    else
        if fireFxById[campfireId] and DoesParticleFxLoopedExist(fireFxById[campfireId]) then
            StopParticleFxLooped(fireFxById[campfireId], 0)
            fireFxById[campfireId] = nil
        end
    end
end)

-- helper: ลงทะเบียน point (เข้าใกล้ค่อยสปอว์น, ออกค่อยลบ)
local function registerCampingPoint(data)
    if points[data.stashID] then return end
    pointMeta[data.stashID] = { type=data.type, x=data.x, y=data.y, z=data.z, heading=data.heading }

    local offsetZ = (data.type == 'tent') and -1.55 or -0.2
    local heading = data.heading
    local id      = data.stashID
    local pos     = vec3(data.x, data.y, data.z + offsetZ)

    points[id] = lib.points.new({ coords = vec3(data.x, data.y, data.z), distance = 80.0 })
    local p = points[id]  -- <<<< ชี้ตาราง point ด้วยตัวแปรก่อน

    function p:onEnter()
        if spawned[id] then return end
        spawned[id] = true

        if data.type == 'tent' then
            Renewed.addObject({
                id=id, coords=pos, object=TentModel, dist=75, heading=heading,
                canClimb=false, freeze=true, snapGround=false,
                target = {
                    { label="Go inside", icon='fa-solid fa-tent-arrows-down', iconColor='grey',
                      distance=Config.targetDistance, canInteract=function() return not enteredTent end,
                      onSelect=function(info) UseTent(info.entity, id) end },
                    { label="Open tent storage", icon='fa-solid fa-box-open', iconColor='grey',
                      distance=Config.targetDistance, onSelect=function() exports.ox_inventory:openInventory('stash', id) end },
                    { label="Pickup tent", icon='fa-solid fa-hand', iconColor='grey',
                      distance=Config.targetDistance, canInteract=function() return not enteredTent end,
                      onSelect=function() deleteTent(id) end },
                }
            })
        else
            Renewed.addObject({
                id=id, coords=pos, object=CampfireModel, dist=75, heading=heading,
                canClimb=false, freeze=true, snapGround=true,
                target = {
                    { label="Campfire Menu", icon='fas fa-fire', iconColor='orange',
                      distance=Config.targetDistance, onSelect=function() showCampfireMenu(id) end },

                    { label="Ignite Fire", icon='fa-solid fa-fire-flame-curved', iconColor='orange',
                      distance=Config.targetDistance,
                      canInteract=function() return (litById[id] ~= true) and ((fuelById[id] or 0) > 0) end,
                      onSelect=function() TriggerServerEvent('camping:ignite', id) end },

                    { label="Extinguish Fire", icon='fa-solid fa-hand', iconColor='grey',
                      distance=Config.targetDistance,
                      canInteract=function() return litById[id] == true end,
                      onSelect=function() TriggerServerEvent('camping:extinguish', id) end },

                    { label="Pickup Campfire", icon='fas fa-hand', iconColor='grey',
                      distance=Config.targetDistance, onSelect=function() deleteCampfire(id) end },
                }
            })

            -- ถ้าไฟติดอยู่แล้วตอนเราเข้าระยะ ให้เปิดเอฟเฟกต์ทันที
            if litById[id] then
                TriggerEvent('camping:updateLit', id, true)
            end
        end
    end

    function p:onExit()
        if not spawned[id] then return end
        spawned[id] = false
        -- ปิดเอฟเฟกต์ถ้ามี
        if fireFxById[id] and DoesParticleFxLoopedExist(fireFxById[id]) then
            StopParticleFxLooped(fireFxById[id], 0)
            fireFxById[id] = nil
        end
        Renewed.removeObject(id)
    end

    if data.type == 'tent' then
        TriggerServerEvent('camping:createTentStash', id)
    end
end

RegisterNetEvent('camping:loadCampingData', function(data)
    registerCampingPoint(data)
end)

-- ===== Utility IDs =====
local function generateRandomTentStashId() return "tent_"     .. math.random(100000, 999999) end
local function generateRandomCampfireId() return "campfire_" .. math.random(100000, 999999) end

-- ===== Spawn =====
RegisterNetEvent('camping:client:spawnTent', function(x,y,z,h,randomModel,stashId)
    registerCampingPoint({ type='tent', model=randomModel, x=x, y=y, z=z, heading=h, stashID=stashId })
end)

RegisterNetEvent('camping:client:spawnCampfire', function(x,y,z,h,fireModel,campfireID)
    -- เริ่มต้นไฟดับ
    litById[campfireID] = false
    registerCampingPoint({ type='campfire', model=fireModel, x=x, y=y, z=z, heading=h, stashID=campfireID })
end)

-- ===== Item use =====
AddEventHandler('ox_inventory:usedItem', function(name, slotId, metadata)
    if name == Config.tentItem then
        TriggerEvent('ox_inventory:closeInventory')
        local tentCoords, tentHeading = Renewed.placeObject(TentModel, 25, false, {
            '-- Place Object --  \n','[E] Place  \n','[X] Cancel  \n','[SCROLL UP] Change Heading  \n','[SCROLL DOWN] Change Heading'
        }, nil, vec3(0.0, 0.0, 0.65))
        if tentCoords and tentHeading then
            local stashId = (metadata and metadata.stashID) and metadata.stashID or generateRandomTentStashId()
            TriggerServerEvent('camping:server:spawnTent', tentCoords.x, tentCoords.y, tentCoords.z, tentHeading, TentModel, stashId, slotId)
            TriggerServerEvent('camping:saveCampingData', 'tent', TentModel, tentCoords.x, tentCoords.y, tentCoords.z, stashId, tentHeading)
            lib.notify({ title='Tent', description='Tent placed successfully.', type='success' })
        end
    elseif name == Config.campfireItem then
        TriggerEvent('ox_inventory:closeInventory')
        local fireCoords, fireHeading = Renewed.placeObject(CampfireModel, 25, false, {
            '-- Place Object --  \n','[E] Place  \n','[X] Cancel  \n','[SCROLL UP] Change Heading  \n','[SCROLL DOWN] Change Heading'
        }, nil, vec3(0.0, 0.0, 0.1))
        if fireCoords and fireHeading then
            local campfireID = generateRandomCampfireId()
            TriggerServerEvent('camping:server:spawnCampfire', fireCoords.x, fireCoords.y, fireCoords.z, fireHeading, CampfireModel, campfireID, slotId)
            TriggerServerEvent('camping:saveCampingData', 'campfire', CampfireModel, fireCoords.x, fireCoords.y, fireCoords.z, campfireID, fireHeading)
            lib.notify({ title='Campfire', description='Campfire placed successfully.', type='success' })
        end
    end
end)

-- ===== Tent use flow (คงเดิม) =====
function UseTent(entity, tentID)
    local playerPed = cache.ped
    local PedCoord = GetEntityCoords(playerPed)
    if not DoesEntityExist(entity) then
        lib.notify({title='Tent', description='No tent found or tent is invalid!', type='error'}); return
    end
    if activeTents[tentID] then
        lib.notify({ title='Tent', description='Someone is already inside this tent.', type='error' }); return
    end
    local dict, anim = "amb@medic@standing@kneel@base", "base"
    RequestAnimDict(dict); local timeout, startTime = 5000, GetGameTimer()
    while not HasAnimDictLoaded(dict) do Wait(10); if GetGameTimer()-startTime>timeout then lib.notify({title='Tent',description='Failed to load animation.',type='error'}); return end end
    TaskTurnPedToFaceEntity(cache.ped, entity, 1000); Wait(1000)
    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0,-8.0,-1,1,0,false,false,false); Wait(1000)
    local tentCoords = GetEntityCoords(entity)
    SetEntityCoordsNoOffset(playerPed, tentCoords.x, tentCoords.y, tentCoords.z, true, true, true)
    SetEntityHeading(cache.ped, (GetEntityHeading(entity)+45.0))
    dict = Config.TentAnimDict or "amb@world_human_sunbathe@male@back@base"
    anim = Config.TentAnimName or "base"
    RequestAnimDict(dict); timeout, startTime = 5000, GetGameTimer()
    while not HasAnimDictLoaded(dict) do Wait(10); if GetGameTimer()-startTime>timeout then lib.notify({title='Tent',description='Failed to load animation.',type='error'}); return end end
    if IsEntityPlayingAnim(playerPed, dict, anim, 3) then lib.notify({title='Tent', description='You are already resting.', type='info'}); return end
    TaskPlayAnim(playerPed, dict, anim, 8.0,-8.0,-1,1,0,false,false,false)

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
                SetEntityCoords(playerPed, PedCoord.x, PedCoord.y, PedCoord.z, true, false, false, false)
                if activeTents[tentID] then
                    activeTents[tentID] = nil
                    TriggerServerEvent('camping:tentExited', tentID)
                    lib.notify({ title='Tent', description='You have exited the tent.', type='info' })
                else
                    lib.notify({ title='Tent', description='You are not inside this tent.', type='error' })
                end
                lib.hideTextUI()
            end
        end
    end)
end

-- ===== Delete =====
function deleteTent(tentId)
    if not tentId then
        lib.notify({ title='Error', description='No previous tent spawned, or your previous tent has already been deleted.', type='error' })
    else
        TriggerServerEvent('camping:deleteCampingData', 'tent', tentId)
        lib.notify({ title='Tent', description='Tent deleted successfully.', type='success' })
        TriggerServerEvent('camping:AI', 'tent', 1, {stashID = tentId})
        TriggerServerEvent('camping:server:removeTentItem', tentId)
        if points[tentId] then points[tentId]:remove(); points[tentId] = nil end
        if spawned[tentId] then Renewed.removeObject(tentId); spawned[tentId] = false end
    end
end

function deleteCampfire(fireId)
    if not fireId then
        lib.notify({ title='Error', description='No previous camping spawned, or your previous campfire has already been deleted.', type='error' })
    else
        TriggerServerEvent('camping:deleteCampingData', 'campfire', fireId)
        lib.notify({ title='Campfire', description='Campfire deleted successfully.', type='success' })
        TriggerServerEvent('camping:AI', 'campfire', 1)
        TriggerServerEvent('camping:server:removeFireItem', fireId)
        if points[fireId] then points[fireId]:remove(); points[fireId] = nil end
        if spawned[fireId] then Renewed.removeObject(fireId); spawned[fireId] = false end
        -- ปิดเอฟเฟกต์ของกองไฟนี้ด้วย
        if fireFxById[fireId] and DoesParticleFxLoopedExist(fireFxById[fireId]) then
            StopParticleFxLooped(fireFxById[fireId], 0)
            fireFxById[fireId] = nil
        end
        litById[fireId] = nil
        fuelById[fireId] = nil
        pointMeta[fireId] = nil
    end
end

RegisterNetEvent('camping:client:removeTentItem', function(tentID) Renewed.removeObject(tentID) end)
RegisterNetEvent('camping:client:removeFireItem', function(fireId)  Renewed.removeObject(fireId)  end)

-- ===== Fuel / Cooking (เหมือนเดิม) =====
local function ingredientsText(ings)
    local t = {}
    for _, ing in ipairs(ings or {}) do t[#t+1] = (ing.name or "item") .. " x" .. tostring(ing.count or 1) end
    return table.concat(t, ", ")
end

function showCampfireMenu(campfireId)
    local fuel = lib.callback.await('camping:getFuel', false, campfireId) or 0
    fuelById[campfireId] = fuel

    local cookOptions = {}
    for key, data in pairs(Config.Recipes or {}) do
        local cookSec = math.floor((data.cookTime or 0) / 1000)
        cookOptions[#cookOptions+1] = {
            icon = data.icon or 'fa-utensils', title = data.label or key,
            description = ("Cook time: %d seconds. Recipe: %s"):format(cookSec, ingredientsText(data.ingredients)),
            event='campfire_cooking', args={ recipe=data, campfireId=campfireId },
        }
    end
    table.sort(cookOptions, function(a,b) return (a.title or "") < (b.title or "") end)

    local fuelOptions = {}
    for _, opt in ipairs(Config.FuelMenu or {}) do
        fuelOptions[#fuelOptions+1] = {
            icon=opt.icon, title=opt.title, description=opt.description, event='add_fuel_option',
            args={ type=opt.args.type, duration=opt.args.duration, campfireId=campfireId },
        }
    end

    lib.registerContext({
        id='campfire_menu', title='Campfire',
        options = {
            { icon='fa-fire', title=('Fuel Level: %d%%'):format(math.floor(fuelById[campfireId] or 0)),
              description='Current fuel level of this campfire.', progress=fuelById[campfireId] or 0, colorScheme='orange', readOnly=true },
            { icon='fa-plus', title='Add Fuel', description='Add fuel to keep the fire burning.', menu='add_fuel_menu', arrow=true },
            { icon='fa-kitchen-set', title='Cooking', description='Prepare meals using the campfire.', menu='campfire_cooking_menu', arrow=true },
            { icon= (litById[campfireId] and 'fa-toggle-on' or 'fa-toggle-off'),
              title= (litById[campfireId] and 'Fire: ON' or 'Fire: OFF'),
              description= (litById[campfireId] and 'The fire is burning.' or 'The fire is out.'),
              disabled = (not litById[campfireId] and (fuelById[campfireId] or 0) <= 0),
              event = (litById[campfireId] and 'extinguish_fire_now' or 'ignite_fire_now'),
              args = { campfireId = campfireId },
            },
        }
    })
    lib.registerContext({ id='add_fuel_menu', title='Add Fuel', menu='campfire_menu', options=fuelOptions })
    lib.registerContext({ id='campfire_cooking_menu', title='Cooking Menu', menu='campfire_menu', options=cookOptions })
    lib.showContext('campfire_menu')
end

RegisterNetEvent('ignite_fire_now',    function(p) local id = p and p.campfireId; if id then TriggerServerEvent('camping:ignite', id) end end)
RegisterNetEvent('extinguish_fire_now',function(p) local id = p and p.campfireId; if id then TriggerServerEvent('camping:extinguish', id) end end)

RegisterNetEvent('add_fuel_option', function(data)
    local campfireId = data.campfireId
    local itemtype   = data.type
    local duration   = data.duration or 0

    local minAmt, maxAmt, itemlabel
    if itemtype == "garbage" then       minAmt, maxAmt, itemlabel = 1, 20, "Garbage"
    elseif itemtype == "wood" then minAmt, maxAmt, itemlabel = 1, 10, "Firewood"
    elseif itemtype == "coal" then        minAmt, maxAmt, itemlabel = 1, 5,  "Coal" end

    local itemCount = exports.ox_inventory:Search('count', itemtype)
    if itemCount <= 0 then return lib.notify({ title='Fuel', description='You do not have enough ' .. itemlabel .. '.', type='error' }) end

    local amount = lib.inputDialog("Add Fuel", { { type="number", label=("Amount (%d-%d)"):format(minAmt, maxAmt), min=minAmt, max=maxAmt, default=itemCount } })
    if not amount or tonumber(amount[1]) < 1 then return lib.notify({ title='Fuel', description='Invalid amount.', type='error' }) end

    local inputAmount = tonumber(amount[1])
    if inputAmount > itemCount then return lib.notify({ title='Fuel', description='You do not have enough ' .. itemtype .. '.', type='error' }) end

    local totalDuration = duration * inputAmount
    local fuelPercent   = (totalDuration / Config.maxFuel) * 100

    local newv = lib.callback.await('camping:addFuel', false, campfireId, fuelPercent)
    fuelById[campfireId] = newv or fuelById[campfireId]

    TriggerServerEvent('camping:RI', itemtype, inputAmount)
    lib.notify({ title='Campfire', description='Fuel added successfully.', type='success' })

    showCampfireMenu(campfireId)
end)

RegisterNetEvent('campfire_cooking', function(payload)
    local data = payload or {}
    local campfireId = data.campfireId
    local selectedRecipe = data.recipe
    if type(selectedRecipe) ~= "table" then return lib.notify({ title='Campfire', description='Invalid recipe selected.', type='error' }) end

    local cookSec = (selectedRecipe.cookTime or 0) / 1000
    local requiredFuelPercent = (cookSec / Config.maxFuel) * 100

    local curFuel = lib.callback.await('camping:getFuel', false, campfireId) or 0
    if curFuel < requiredFuelPercent then return lib.notify({ title='Campfire', description='Not enough fuel to start cooking.', type='error' }) end

    for _, ingredient in pairs(selectedRecipe.ingredients or {}) do
        if exports.ox_inventory:Search('count', ingredient.name) < (ingredient.count or 1) then
            return lib.notify({ title='Campfire', description='Not enough ' .. tostring(ingredient.name), type='error' })
        end
    end
    for _, ingredient in pairs(selectedRecipe.ingredients or {}) do
        TriggerServerEvent('camping:RI', ingredient.name, ingredient.count or 1)
    end

    local ok = lib.progressBar({
        duration = selectedRecipe.cookTime or 0, label = 'Cooking ' .. (selectedRecipe.label or 'Food'),
        useWhileDead=false, canCancel=false, disable={ move=true, car=true, combat=true, mouse=false },
        anim={ dict='amb@prop_human_bbq@male@base', clip='base', flag=49 }
    })
    if ok then
        local result = lib.callback.await('camping:tryConsumeFuel', false, campfireId, requiredFuelPercent) or {}
        if not result.ok then return lib.notify({ title='Campfire', description='Not enough fuel (changed during cooking).', type='error' }) end
        fuelById[campfireId] = result.fuel or fuelById[campfireId]
        if selectedRecipe.key then TriggerServerEvent('camping:AI', selectedRecipe.key, 1) end
        lib.notify({ title='Campfire', description=(selectedRecipe.label or 'Food') .. ' cooked successfully!', type='success' })
        showCampfireMenu(campfireId)
    end
end)

RegisterNetEvent('camping:notify', function(data) if data then lib.notify(data) end end)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  for id, p in pairs(points) do p:remove() end
  for id, fx in pairs(fireFxById) do
    if DoesParticleFxLoopedExist(fx) then StopParticleFxLooped(fx, 0) end
  end
  if enteredTent then lib.hideTextUI() end
end)