--[[ Globals ]]--
SessionState = {
    isSessionInProgress = false,
    currentPoint = 0,
    headshotHitCount = 0,
    bodyshotHitCount = 0,
    missCount = 0,
    elapsedTime = 0,
    remainingTime = 0,
    remainingTarget = 0,
    gameMode = nil,
    lastSessionState = nil
}


--[[Local Variables]]--
local spawnedEntities = {}
local currentZone = nil
local currentTarget = nil
local currentIntId = 0

local targetConfigs = Config.TargetRotations
local rangeRows = Config.UpperRows
local lowerRangeRows = Config.LowerRows


-- Populating new tables for easier usage
local headOffsets = {}
local bodyOffsets = {}
for key, value in pairs(Config.TargetOffsets) do
    headOffsets[key] = value.headOffset
    bodyOffsets[key] = value.bodyOffset
end

--[[ Local Functions ]]--
local function string_split(inputstr, sep)
    sep = sep or "%s"
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[#t+1] = str
    end
    return t
end

-- Utility functions
local function FormatTime(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local msec = math.floor((milliseconds % 1000) / 100)
    return string.format("%02d:%02d.%d", minutes, seconds, msec)
end

local function FormatUIText()
    local str = ''
    if SessionState.lastSessionState then
        str = string.format('Total Points: %d  \nTarget Hit: %d  \nHeadshots: %d  \n Bodyshots: %d  \n Missed: %d  \n Elapsed Time: %s', SessionState.lastSessionState.currentPoint, SessionState.lastSessionState.headshotHitCount+SessionState.lastSessionState.bodyshotHitCount+SessionState.lastSessionState.missCount, SessionState.lastSessionState.headshotHitCount, SessionState.lastSessionState.bodyshotHitCount, SessionState.lastSessionState.missCount, FormatTime(SessionState.lastSessionState.elapsedTime))
    else
        if SessionState.gameMode == 'timetrial' then
            str = string.format('Remaining Time: %s  \nCurrent Points: %d', FormatTime(SessionState.remainingTime), SessionState.currentPoint)
        elseif SessionState.gameMode == 'pointrush' then
            str = string.format('Current Points: %d  \nElapsed Time: %s', SessionState.currentPoint, FormatTime(SessionState.elapsedTime))
        elseif SessionState.gameMode == 'targethunt' then
            str = string.format('Target Hit: %d  \nHeadshots: %d  \nBodyshots: %d  \nElapsed Time: %s', SessionState.headshotHitCount+SessionState.bodyshotHitCount+SessionState.missCount, SessionState.headshotHitCount, SessionState.bodyshotHitCount, FormatTime(SessionState.elapsedTime))
        end
    end
    return str
end

local function updateSessionPanel()
    if not SessionState.isSessionInProgress and not SessionState.lastSessionState then
        Wait(1000)
        return lib.hideTextUI()
    end

    lib.showTextUI(FormatUIText())
end

-- Session management
local function manageSessionTime(sessionType, sessionOptions)
    local startTime = GetNetworkTime()
    if sessionType == 'timetrial' then
        local endTime = startTime + sessionOptions.timetrialTime * 1000
        CreateThread(function()
            while GetNetworkTime() < endTime do
                local remainingTime = endTime - GetNetworkTime()
                TriggerServerEvent('pc-shootingranges:server:setStoreState:setRemainingTime', currentIntId, remainingTime)
                Wait(100)
            end
        end)
    else
        CreateThread(function()
            while (sessionType == 'pointrush' and SessionState.currentPoint < sessionOptions.pointGoal) or
                  (sessionType == 'targethunt' and SessionState.remainingTarget > 0) do
                local elapsedTime = GetNetworkTime() - startTime
                TriggerServerEvent('pc-shootingranges:server:setStoreState:setElapsedTime', currentIntId, elapsedTime)
                Wait(100)
            end
        end)
    end
end

local function isPointInBounds(point, bounds)
    if bounds.x then
        return point.x >= bounds.x.min and point.x <= bounds.x.max and point.z >= bounds.z.min and point.z <= bounds.z.max
    else
        return point.z >= bounds.z.min and point.z <= bounds.z.max
    end
end

local function RotationToDirection(rotation)
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

local function RayCastPlayerWeapon(weapon)
    local cameraRotation = GetGameplayCamRot(2)
    local weaponCoords = GetGameplayCamCoord()
    if GetFollowPedCamViewMode() ~= 4 then
        cameraRotation = vector3(cameraRotation.x+1.5, cameraRotation.y, cameraRotation.z-1.5)
        weaponCoords = GetEntityCoords(weapon)
    end
	local direction = RotationToDirection(cameraRotation)
	local destination =  vector3(weaponCoords.x + direction.x * 2000,
        weaponCoords.y + direction.y * 2000,
        weaponCoords.z + direction.z * 2000
    )
    local flag = 4294967295 -- Intersect Objects
	local shapeTestHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(weaponCoords.x, weaponCoords.y, weaponCoords.z, destination.x, destination.y, destination.z, flag, 0, 1))
	return hit, endCoords
end

local function randomPointBetween(point1, point2)
    math.randomseed(GetNetworkTime())
    local t = math.random()
    if t < 0.05 then t = 0.05 end
    if t > 0.95 then t = 0.95 end
    local x = point1.x + t * (point2.x - point1.x)
    local y = point1.y + t * (point2.y - point1.y)
    return vector2(x, y)
end

local function calculateUnitVector(startPoint, endPoint)
    local direction = endPoint - startPoint
    return direction / #direction
end

local function movePointAlongVector(startPoint, unitVector, speed, deltaTime)
    return vector3(startPoint.x+(unitVector * speed * deltaTime).x, startPoint.y+(unitVector * speed * deltaTime).y, startPoint.z)
end

local function CreateTarget(propHash, rows)
    local interiorId = GetInteriorFromEntity(PlayerPedId())
    print(interiorId, rows[interiorId])
    if not rows[interiorId] then return end
    local randRow = math.random(1, #rows[interiorId])
    local targetPos
    if rows[interiorId][randRow].startPoint then
        targetPos = randomPointBetween(rows[interiorId][randRow].startPoint, rows[interiorId][randRow].endPoint)
    else
        local tmpIndex = math.random(1, #rows[interiorId][randRow])
        targetPos = rows[interiorId][randRow][tmpIndex]
    end
    local targetRotation = targetConfigs[interiorId][propHash].spawnRotation
    local targetHandle = CreateObject(propHash, targetPos.x, targetPos.y, rows[interiorId][randRow].startPoint and rows[interiorId][randRow].startPoint.z or targetPos.z, true, true, false)
    Entity(targetHandle).state:set('currRow', randRow, true)
    SetEntityRotation(targetHandle, targetRotation.x, targetRotation.y, targetRotation.z, 2, false)
    table.insert(spawnedEntities, targetHandle)
    return targetHandle
end

local function MoveTargetToCoord(targetHandle, targetPos, lastTime, unitVector, speed)
    local currentPosition = GetEntityCoords(targetHandle)
    while Entity(targetHandle).state.moving and not Entity(targetHandle).state.closing and #(targetPos - vector2(currentPosition.x, currentPosition.y)) > 0.1 do
        local currentTime = GetNetworkTime()
        local deltaTime = (currentTime - lastTime) / 1000.0
        currentPosition = movePointAlongVector(currentPosition, unitVector, speed, deltaTime)
        SetEntityCoords(targetHandle, currentPosition.x ,currentPosition.y, currentPosition.z, false, false, false, false)
        Wait(1)
    end
    Entity(targetHandle).state:set('targetSet', nil, true)
    Wait(10)
end

local function MoveTarget(targetHandle, rows)
    while Entity(targetHandle).state.opening do
        Wait(10)
    end
    local interiorId = GetInteriorFromEntity(PlayerPedId())
    if not rows[interiorId] then return end
    local targetState = Entity(targetHandle).state
    local currRow = targetState.currRow
    if not rows[interiorId][currRow].startPoint then return end
    if not Entity(targetHandle).state.moving then
        Entity(targetHandle).state:set('moving', true, true)
    end
    while Entity(targetHandle).state.moving and not targetState.closing do
        math.randomseed(GetNetworkTime())
        local speed = math.random(2, 3) / 50 -- Units per second
        local startPoint = rows[interiorId][currRow].startPoint
        local endPoint = rows[interiorId][currRow].endPoint
        local targetPos = randomPointBetween(startPoint, endPoint)
        local currentPosition = GetEntityCoords(targetHandle)
        local unitVector = calculateUnitVector(vector2(currentPosition.x, currentPosition.y), targetPos)
        local lastTime = GetNetworkTime()
        Entity(targetHandle).state:set('moving', true, true)
        Entity(targetHandle).state:set('targetPos', targetPos, true)
        Entity(targetHandle).state:set('lastTime', lastTime, true)
        Entity(targetHandle).state:set('unitVector', unitVector, true)
        Entity(targetHandle).state:set('speed', speed, true)
        Entity(targetHandle).state:set('targetSet', true, true)
        Wait(10)
        while Entity(targetHandle).state.targetSet do
            Wait(1)
        end
        Wait(50)
    end
end



local function DropTargetFast(targetHandle, nextState)
    local interiorId = GetInteriorFromEntity(PlayerPedId())
    local targetModel = GetEntityModel(targetHandle)
    if not nextState then
        return
    end
    CreateThread(function()

        -- Pitch is basically up and down angle, it is either -90.0 or 90.0 degrees here.
        local startPitch = GetEntityRotation(targetHandle, 2).x

        -- Target Pitch is 0.0 which makes the targets "stand" but I'm retrieving from the config anyway
        local targetRotation = targetConfigs[interiorId][targetModel].openRotation

        -- This is a hack to basically calculate if I should add or remove the deltaAngle which is 2.0 degrees.
        local isTargetRotationNegative = startPitch < 0.0 and -1 or 1

        -- This one just rotates it until it is opened or closed.
        -- You can even change its speed, reducing while closing increasing while opening
        while GetEntityRotation(targetHandle, 2).x * isTargetRotationNegative > targetRotation.x do
            if GetEntityRotation(targetHandle, 2).x * isTargetRotationNegative < targetRotation.x or not Entity(targetHandle).state.opening then
                SetEntityRotation(targetHandle, targetRotation.x, targetRotation.y, targetRotation.z, 2, false)
                break
            end
            startPitch -= 2.0 * isTargetRotationNegative

            SetEntityRotation(targetHandle, startPitch, 0, targetRotation.z, 2, false)
            Wait(10)
        end
        if nextState then
            Wait(1)
            Entity(targetHandle).state:set('opening', nil, true)
        end
    end)
end

local function PushTargetFast(targetHandle, nextState)
    local interiorId = GetInteriorFromEntity(PlayerPedId())
    local targetModel = GetEntityModel(targetHandle)
    if not nextState then
        return
    end
    CreateThread(function()
        local startPitch = GetEntityRotation(targetHandle, 2).x
        local targetRotation = targetConfigs[interiorId][targetModel].closeRotation
        local isTargetRotationNegative = targetRotation.x < 0.0 and -1 or 1
        while GetEntityRotation(targetHandle, 2).x < targetRotation.x * isTargetRotationNegative do
            print(GetEntityRotation(targetHandle, 2).x * isTargetRotationNegative > targetRotation.x * isTargetRotationNegative, GetEntityRotation(targetHandle, 2).x * isTargetRotationNegative, targetRotation.x * isTargetRotationNegative)
            if targetRotation.x * isTargetRotationNegative - GetEntityRotation(targetHandle, 2).x * isTargetRotationNegative < 1.0  or not Entity(targetHandle).state.closing then
                SetEntityRotation(targetHandle, targetRotation.x, targetRotation.y, targetRotation.z, 2, false)
                break
            end
            startPitch += 5.0 * isTargetRotationNegative
            SetEntityRotation(targetHandle, startPitch, 0, targetRotation.z, 2, false)
            Wait(10)
        end
        if nextState then
            Wait(1)
            Entity(targetHandle).state:set('closing', false, true)
        end
        local toBeRemoved = table.remove(spawnedEntities)
        DeleteEntity(toBeRemoved)
    end)
end

local function GetRandomModel(sessionOptions)
    if math.random() <= 0.5 then
        return sessionOptions.upperRowModel, rangeRows
    else
        return sessionOptions.lowerRowModel, lowerRangeRows
    end
end

local function createAndManageTarget(sessionOptions)
    math.randomseed(GetNetworkTime())
    local modelHash, currRowData = GetRandomModel(sessionOptions)
    local target = CreateTarget(modelHash, currRowData)
    if not target then return end
    Entity(target).state:set('opening', true, true)
    if math.random() * 100 < sessionOptions.movingChance then
        MoveTarget(target, currRowData)
    end
    Wait(10)
    while #spawnedEntities ~= 0 do
        if not SessionState.isSessionInProgress then
            DropTargetFast(spawnedEntities[0])
        end
        Wait(100)
    end
    Wait(100 * math.random(1, 5))
end

--[[ Global Functions ]]--
function StartSession(sessionType, sessionOptions)
    TriggerServerEvent('pc-shootingranges:server:startSession', currentIntId, sessionType, sessionOptions)
    Wait(1000)
    updateSessionPanel()
    manageSessionTime(sessionType, sessionOptions)

    local startTime = GetNetworkTime()

    local continueSession = function()
        if sessionType == 'timetrial' then
            return GetNetworkTime() < startTime + sessionOptions.timetrialTime * 1000
        elseif sessionType == 'pointrush' then
            return SessionState.currentPoint < sessionOptions.pointGoal
        elseif sessionType == 'targethunt' then
            return SessionState.remainingTarget > 0
        end
    end

    while continueSession() do
        createAndManageTarget(sessionOptions)
        Wait(0)
    end
    TriggerServerEvent('pc-shootingranges:server:resetStoreState', currentIntId)
    Wait(100)
    
end

--[[Event Handlers]]--
AddEventHandler('onResourceStop', function()
    for _, entHandle in ipairs(spawnedEntities) do
        DeleteEntity(entHandle)
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if not name == 'CEventNetworkEntityDamage' then return end
    if args[2] ~= PlayerPedId() then return end
    local currWeaponHandle = GetCurrentPedWeaponEntityIndex(PlayerPedId())
    if currWeaponHandle == 0 then return end

    local currEntityModel = GetEntityModel(args[1])
    local isTargetValid = false
    for _, value in pairs(targetConfigs) do
        for key2 in pairs(value) do
            if currEntityModel == key2 then
                isTargetValid = true
                break
            end
        end
        if isTargetValid then break end
    end

    if not isTargetValid or not HasEntityBeenDamagedByWeapon(args[1], 0, 2) then return end

    local hit, endCoords = RayCastPlayerWeapon(currWeaponHandle)
    local offset = GetOffsetFromEntityGivenWorldCoords(args[1], endCoords.x, endCoords.y, endCoords.z)
    print("offset:", offset)

    if isPointInBounds(offset, headOffsets[currEntityModel]) then
        TriggerServerEvent('pc-shootingranges:server:setStoreState:addPoint', currentIntId, Config.HeadShotPoint)
        TriggerServerEvent('pc-shootingranges:server:setStoreState:addHeadshotHitCount', currentIntId)
    elseif isPointInBounds(offset, bodyOffsets[currEntityModel]) then
        TriggerServerEvent('pc-shootingranges:server:setStoreState:addPoint', currentIntId, Config.BodyShotPoint)
        TriggerServerEvent('pc-shootingranges:server:setStoreState:addBodyshotHitCount', currentIntId)
    else
        TriggerServerEvent('pc-shootingranges:server:setStoreState:addMissCount', currentIntId)
    end
    if SessionState.gameMode == 'targethunt' then
        TriggerServerEvent('pc-shootingranges:server:setStoreState:removeRemainingTarget', currentIntId)
    end
    --Entity(args[1]).state:set('moving', nil, true)
    Entity(args[1]).state:set('opening', nil, true)
    Entity(args[1]).state:set('targetPos', nil, true)
    Entity(args[1]).state:set('lastTime', nil, true)
    Entity(args[1]).state:set('unitVector', nil, true)
    Entity(args[1]).state:set('speed', nil, true)
    Entity(args[1]).state:set('moving', nil, true)
    
    Entity(args[1]).state:set('closing', true, true)
    
    --PushTargetFast(args[1])
end)

RegisterNetEvent('pc-shootingranges:client:setStoreState')
AddEventHandler('pc-shootingranges:client:setStoreState', function(newState)
    -- Update the SessionState with the new values
    for key, value in pairs(newState) do
        if SessionState[key] ~= nil then
            SessionState[key] = value
        end
    end
    SessionState.gameMode = newState.gameMode
    SessionState.lastSessionState = newState.lastSessionState or nil

    -- Update UI or trigger other necessary client-side actions
    updateSessionPanel()
end)

-- Network events
RegisterNetEvent('pc-shootingranges:client:setStoreState:addPoint')
AddEventHandler('pc-shootingranges:client:setStoreState:addPoint', function(point)
    SessionState.currentPoint = SessionState.currentPoint + point
    updateSessionPanel()
end)

RegisterNetEvent('pc-shootingranges:client:setStoreState:elapsedTime')
AddEventHandler('pc-shootingranges:client:setStoreState:elapsedTime', function(elapsedTime)
    SessionState.elapsedTime = elapsedTime
    updateSessionPanel()
end)

RegisterNetEvent('pc-shootingranges:client:setStoreState:remainingTime')
AddEventHandler('pc-shootingranges:client:setStoreState:remainingTime', function(remainingTime)
    SessionState.remainingTime = remainingTime
    updateSessionPanel()
end)

RegisterNetEvent('pc-shootingranges:client:setStoreState:remainingTarget')
AddEventHandler('pc-shootingranges:client:setStoreState:remainingTarget', function(remainingTarget)
    SessionState.remainingTarget = remainingTarget
    updateSessionPanel()
end)

RegisterNetEvent('pc-shootingranges:client:setStoreState:headshotHitCount')
AddEventHandler('pc-shootingranges:client:setStoreState:headshotHitCount', function()
    SessionState.headshotHitCount = SessionState.headshotHitCount + 1
    updateSessionPanel()
end)

RegisterNetEvent('pc-shootingranges:client:setStoreState:bodyshotHitCount')
AddEventHandler('pc-shootingranges:client:setStoreState:bodyshotHitCount', function()
    SessionState.bodyshotHitCount = SessionState.bodyshotHitCount + 1
    updateSessionPanel()
end)

RegisterNetEvent('pc-shootingranges:client:setStoreState:missCount')
AddEventHandler('pc-shootingranges:client:setStoreState:missCount', function()
    SessionState.missCount = SessionState.missCount + 1
    updateSessionPanel()
end)

RegisterNetEvent('pc-shootingranges:client:setStoreState:removeRemainingTarget')
AddEventHandler('pc-shootingranges:client:setStoreState:removeRemainingTarget', function()
    SessionState.remainingTarget = SessionState.remainingTarget - 1
    updateSessionPanel()
end)

RegisterNetEvent('CEventOpenDoor', function(entities, eventEntity, args)
    Wait(1000)
    if not Config.ShootingrangeIntId[GetInteriorFromEntity(PlayerPedId())] then
        if currentZone then
            currentZone:remove()
            currentZone = nil
            exports.ox_target:removeZone(currentTarget)
            -- rangeRows = {}
            -- lowerRangeRows = {}
        end
        currentIntId = 0
        SessionState = {
            isSessionInProgress = false,
            currentPoint = 0,
            headshotHitCount = 0,
            bodyshotHitCount = 0,
            missCount = 0,
            elapsedTime = 0,
            remainingTime = 0,
            remainingTarget = 0,
            gameMode = nil,
            lastSessionState = nil
        }
        TriggerServerEvent('pc-shootingranges:server:removePlayerFromStore')
        return
    end

    if currentZone then return end

    currentIntId = GetInteriorFromEntity(PlayerPedId())
    TriggerServerEvent('pc-shootingranges:server:getStoreState', currentIntId)

    local interiorCoords = vector3(GetInteriorPosition(currentIntId))
    local targetConfig = Config.TargetConfig[currentIntId]
    local zoneConfig = Config.ZoneConfig[currentIntId]

    local targetOptions = {}
    for _, targetData in ipairs(Config.TrainingModes[currentIntId]) do
        local options = targetData.targetOptions
        options.interiorId = currentIntId
        options.sessionMode = targetData.mode
        options.canInteract = function()
            return not SessionState.isSessionInProgress
        end
        options.sessionOptions = {
            timetrialTime = targetData.timetrialTime,
            pointGoal = targetData.pointGoal,
            targetGoal = targetData.targetGoal,
            upperRowModel = targetData.upperRowModel,
            upperRows = targetData.upperRows,
            lowerRowModel = targetData.lowerRowModel,
            lowerRows = targetData.lowerRows,
            movingChance = targetData.movingChance
        }
        table.insert(targetOptions, options)
    end

    currentTarget = exports.ox_target:addBoxZone({
        name = "pc-shootingranges:shooting_range_zone_" .. tostring(currentIntId),
        coords = targetConfig.coords,
        size = targetConfig.size,
        rotation = targetConfig.heading,
        options = targetOptions,
        debug = targetConfig.debug
    })

    currentZone = lib.zones.box({
        name = "pc-shootingranges:mainzone_" .. tostring(currentIntId),
        coords = zoneConfig.coords,
        size = zoneConfig.size,
        rotation = zoneConfig.Heading,
        debug = zoneConfig.debug,
        onEnter = updateSessionPanel,
        onExit = function()
            lib.hideTextUI()
        end
    })

    TriggerServerEvent('pc-shootingranges:server:addPlayerToStore', currentIntId)
end)
RegisterCommand("createEntity", function()
    local target = CreateTarget(`gr_prop_gr_target_05b`)
    DropTargetFast(target)
end, false)

AddStateBagChangeHandler('opening', nil, function(bagName, key, value, reserved, replicated)
    if not value then return end
    local bagType, handle = string.strsplit(':', bagName, 2)
    
    handle = NetToObj(tonumber(handle))
    Wait(1)
    DropTargetFast(handle, value)
end)

AddStateBagChangeHandler('closing', nil, function(bagName, key, value, reserved, replicated)
    if not value then return end
    local bagType, handle = string.strsplit(':', bagName, 2)
    
    handle = NetToObj(tonumber(handle))
    Wait(1)
    PushTargetFast(handle, value)
end)

AddStateBagChangeHandler('targetSet', nil, function(bagName, key, value, reserved, replicated)
    if not value then return end

    local bagType, handle = string.strsplit(':', bagName, 2)
    
    handle = NetToObj(tonumber(handle))
    Wait(1)
    MoveTargetToCoord(handle, Entity(handle).state.targetPos, Entity(handle).state.lastTime, Entity(handle).state.unitVector, Entity(handle).state.speed)
end)