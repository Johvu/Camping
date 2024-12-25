local heatZonecfg = Config.HeatZone
local propHash = Config.CampfireModel -- Change this to the desired prop model
local radius = heatZonecfg.radius -- Heat zone radius
local heat = heatZonecfg.heat -- Damage per tick
local tickInterval = heatZonecfg.tick -- Time between damage ticks (in milliseconds)
local Zones = {} -- Store zones to track them
local heatzone

-- Function to create a heat zone around a prop
function createHeatZoneAroundProp(coords, id)
    local zoneName = id
    local InZone = false
    if Zones[zoneName] then return end -- Avoid duplicate zones

    -- Create a target zone
    heatzone = lib.zones.sphere({
        coords = coords,
        radius = radius,
        debug = true,
        onEnter = function()
            lib.notify({
                title = 'Warning',
                description = 'You have entered a heat zone!',
                type = 'error'
            })
            InZone = true
            Citizen.CreateThread(function()
                while InZone do
                    TriggerEvent('esx_status:remove', 'cold', heat)
                    Wait(1000)  -- Trigger every 10 seconds (10000 ms)
                end
            end)
        end,
        onExit = function()
            lib.notify({
                title = 'Safe Zone',
                description = 'You have left the heat zone!',
                type = 'inform'
            })
            InZone = false
        end
    })

    Zones[zoneName] = id
end

function deleteHeatZone(zoneName)
    if Zones[zoneName] then
        heatzone:remove()
        Zones[zoneName] = nil
        lib.notify({
            title = 'Zone Removed',
            description = 'The heat zone has been deleted.',
            type = 'inform'
        })
    end
end


-- Cold status management
local coldCfg = Config.Cold

-- Utility function to check player proximity to heat sources
local function isNearHeatSource()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local closestObj = GetClosestObjectOfType(playerCoords, coldCfg.heatSourceRange, GetHashKey(coldCfg.heatSources), false, false, false)
    return closestObj ~= 0
end

-- Calculate temperature based on weather and time
function getTemperature(weather, currentTime)
    local tempData = Config.Temperature[weather]
    
    if not tempData then
        print("Invalid weather condition.")
        return nil
    end
    
    for _, period in ipairs(tempData) do
        if currentTime >= period.startTime and currentTime < period.endTime then
            -- Get a random temperature within the range for this period
            return math.random(period.tempMin, period.tempMax)
        end
    end
    
    print("Invalid time for the weather condition.")
    return nil
end
exports('getTemperature', getTemperature)

-- Main cold status handler with ESX integration
local function handleColdStatus()
    local hr = 60 * 60 * 1000  -- Convert to milliseconds
    local playerPed = PlayerPedId()
    local gameWeather = exports['weathersync']:getCurrentWeather()
    local timeInHours = GetGameTimer() / hr

    -- Extract hours and calculate temperature
    local hours = math.floor(timeInHours) % 24  -- Ensure 24-hour format (0-23)
    local temperature = getTemperature(gameWeather, hours)
    local cold = 0 -- Default cold value if not available

    -- Fetch the player's current cold status using ESX
    TriggerEvent('esx_status:getStatuses', function(statuses)
        if statuses['cold'] then
            cold = statuses['cold'].val
        end
    end)

    -- Apply cold effects based on temperature and cold level
    if temperature < coldCfg.coldThreshold then
        if cold <= 0 and isNearHeatSource() then
            -- Reset effects if warming up
            ResetPedMovementClipset(playerPed, 0.0)
            ClearTimecycleModifier()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        else
            -- Apply cold effects based on current cold value
            RequestAnimSet("move_m@drunk@verydrunk")
            while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
                Wait(0)
            end
            SetPedMovementClipset(playerPed, "move_m@drunk@verydrunk", coldCfg.speedPenalty)

            -- Apply stamina penalty based on cold level
            local stamina = GetPlayerSprintStaminaRemaining(PlayerId())
            SetPlayerStamina(PlayerId(), math.max(stamina - coldCfg.staminaPenalty, 0))

            -- Apply health penalty if hypothermic
            if temperature < coldCfg.hypothermiaThreshold then
                local health = GetEntityHealth(playerPed)
                SetEntityHealth(playerPed, math.max(health - coldCfg.healthPenalty, 1))
            end
        end
    else
        -- Reset effects if not cold
        ResetPedMovementClipset(playerPed, 0.0)
        ClearTimecycleModifier()
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    end
end

-- Main loop for handling cold status
CreateThread(function()
    while true do
        handleColdStatus()
        Wait(coldCfg.tickInterval)
    end
end)
