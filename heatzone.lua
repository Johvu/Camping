if Config.useHeatzone then
    local heatZonecfg = Config.HeatZone
    local radius = heatZonecfg.radius
    local heat = heatZonecfg.heat
    local Zones = {}
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
                        TriggerEvent('esx_status:remove', Config.statusName, heat)
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


    local coldCfg = Config.Cold

    local function isNearHeatSource()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local closestObj = GetClosestObjectOfType(playerCoords, coldCfg.heatSourceRange, GetHashKey(coldCfg.heatSources), false, false, false)
        return closestObj ~= 0
    end

    function getTemperature(weather, currentTime)
        local tempData = Config.Temperature[weather]
        
        if not tempData then
            print("Invalid weather condition.")
            return nil
        end
        
        for _, period in ipairs(tempData) do
            if currentTime >= period.startTime and currentTime < period.endTime then
                return math.random(period.tempMin, period.tempMax)
            end
        end
        
        print("Invalid time for the weather condition.")
        return nil
    end
    exports('getTemperature', getTemperature)

    local function handleColdStatus()
        local hr = 60 * 60 * 1000
        local playerPed = PlayerPedId()
        local gameWeather
        if Config.weatherResource == 'wethersync' then
            gameWeather = exports['weathersync']:getCurrentWeather()
        elseif Config.weatherResource == 'custom' then
            -- place your exports or trigger here
        end
        local timeInHours = GetGameTimer() / hr
        local hours = math.floor(timeInHours) % 24
        local temperature = getTemperature(gameWeather, hours)
        local cold = 0

        TriggerEvent('esx_status:getStatuses', function(statuses)
            if statuses['cold'] then
                cold = statuses['cold'].val
            end
        end)

        if temperature < coldCfg.coldThreshold then
            if cold <= 0 and isNearHeatSource() then
                ResetPedMovementClipset(playerPed, 0.0)
                ClearTimecycleModifier()
                SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
            else
                RequestAnimSet("move_m@drunk@verydrunk")
                while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
                    Wait(0)
                end
                SetPedMovementClipset(playerPed, "move_m@drunk@verydrunk", coldCfg.speedPenalty)

                local stamina = GetPlayerSprintStaminaRemaining(PlayerId())
                SetPlayerStamina(PlayerId(), math.max(stamina - coldCfg.staminaPenalty, 0))

                if temperature < coldCfg.hypothermiaThreshold then
                    local health = GetEntityHealth(playerPed)
                    SetEntityHealth(playerPed, math.max(health - coldCfg.healthPenalty, 1))
                end
            end
        else
            ResetPedMovementClipset(playerPed, 0.0)
            ClearTimecycleModifier()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end
    end

    CreateThread(function()
        while true do
            handleColdStatus()
            Wait(coldCfg.tickInterval)
        end
    end)
end
