local GunStoreStates = {
    [137729] = {
        isSessionInProgress = false,
        currentPoint = 0,
        headshotHitCount = 0,
        bodyshotHitCount = 0,
        elapsedTime = 0.0,
        remainingTime = 0.0,
        remainingTarget = 0,
        missCount = 0,
        players = {},
        gameMode = nil
    },
    [248065] = {
        isSessionInProgress = false,
        currentPoint = 0,
        headshotHitCount = 0,
        bodyshotHitCount = 0,
        elapsedTime = 0.0,
        remainingTime = 0.0,
        remainingTarget = 0,
        missCount = 0,
        players = {},
        gameMode = nil
    }
}

local function createDefaultState(interiorId)
    local lastSessionState = {}
    for key, value in pairs(GunStoreStates[interiorId]) do
        if type(value) ~= 'table' then
            lastSessionState[key] = value
        end
    end
    local players = {}
    for _, source in ipairs(GunStoreStates[interiorId].players) do
        table.insert(players, source)
    end
    return {
        isSessionInProgress = false,
        currentPoint = 0,
        headshotHitCount = 0,
        bodyshotHitCount = 0,
        elapsedTime = 0.0,
        remainingTime = 0.0,
        remainingTarget = 0,
        missCount = 0,
        players = players,
        gameMode = nil,
        lastSessionState = lastSessionState
    }
end

local function broadcastToPlayers(interiorId, eventName, ...)
    if not GunStoreStates[interiorId].players then return end
    for _, src in ipairs(GunStoreStates[interiorId].players) do
        TriggerClientEvent(eventName, src, ...)
    end
end

local function resetSessionState(interiorId)
    GunStoreStates[interiorId] = createDefaultState(interiorId)
    broadcastToPlayers(interiorId, 'pc-shootingranges:client:setStoreState', GunStoreStates[interiorId])
end

local function updateState(interiorId, key, value)
    GunStoreStates[interiorId][key] = value
    broadcastToPlayers(interiorId, 'pc-shootingranges:client:setStoreState:' .. key, value)
end

RegisterNetEvent('pc-shootingranges:server:resetStoreState')
AddEventHandler('pc-shootingranges:server:resetStoreState', resetSessionState)

RegisterNetEvent('pc-shootingranges:server:addPlayerToStore')
AddEventHandler('pc-shootingranges:server:addPlayerToStore', function(interiorId)
    table.insert(GunStoreStates[interiorId].players, source)
end)

RegisterNetEvent('pc-shootingranges:server:removePlayerFromStore')
AddEventHandler('pc-shootingranges:server:removePlayerFromStore', function()
    local src = source
    for _, state in pairs(GunStoreStates) do
        for i, player in ipairs(state.players) do
            if src == player then
                table.remove(state.players, i)
                break
            end
        end
    end
end)

RegisterNetEvent('pc-shootingranges:server:startSession')
AddEventHandler('pc-shootingranges:server:startSession', function(interiorId, gameMode, sessionOptions)
    local state = GunStoreStates[interiorId]
    state.isSessionInProgress = true
    state.gameMode = gameMode

    if gameMode == 'timetrial' then
        state.remainingTime = sessionOptions.timetrialTime * 1000
    elseif gameMode == 'targethunt' then
        state.remainingTarget = sessionOptions.targetGoal
    end

    broadcastToPlayers(interiorId, 'pc-shootingranges:client:setStoreState', state)
end)

RegisterNetEvent('pc-shootingranges:server:setStoreState:isSessionInProgress')
AddEventHandler('pc-shootingranges:server:setStoreState:isSessionInProgress', function(interiorId, isSessionInProgress)
    updateState(interiorId, 'isSessionInProgress', isSessionInProgress)
    if not isSessionInProgress then
        resetSessionState(interiorId)
    else
        GunStoreStates[interiorId].lastSessionState = nil
    end
end)

RegisterNetEvent('pc-shootingranges:server:setStoreState:addPoint')
AddEventHandler('pc-shootingranges:server:setStoreState:addPoint', function(interiorId, point)
    local state = GunStoreStates[interiorId]
    state.currentPoint = state.currentPoint + point
    broadcastToPlayers(interiorId, 'pc-shootingranges:client:setStoreState:addPoint', point)
end)

RegisterNetEvent('pc-shootingranges:server:setStoreState:addHeadshotHitCount')
AddEventHandler('pc-shootingranges:server:setStoreState:addHeadshotHitCount', function(interiorId)
    updateState(interiorId, 'headshotHitCount', GunStoreStates[interiorId].headshotHitCount + 1)
end)

RegisterNetEvent('pc-shootingranges:server:setStoreState:addBodyshotHitCount')
AddEventHandler('pc-shootingranges:server:setStoreState:addBodyshotHitCount', function(interiorId)
    updateState(interiorId, 'bodyshotHitCount', GunStoreStates[interiorId].bodyshotHitCount + 1)
end)

RegisterNetEvent('pc-shootingranges:server:setStoreState:addMissCount')
AddEventHandler('pc-shootingranges:server:setStoreState:addMissCount', function(interiorId)
    updateState(interiorId, 'missCount', GunStoreStates[interiorId].missCount + 1)
end)

RegisterNetEvent('pc-shootingranges:server:setStoreState:setElapsedTime')
AddEventHandler('pc-shootingranges:server:setStoreState:setElapsedTime', function(interiorId, elapsedTime)
    updateState(interiorId, 'elapsedTime', elapsedTime)
end)

RegisterNetEvent('pc-shootingranges:server:setStoreState:setRemainingTime')
AddEventHandler('pc-shootingranges:server:setStoreState:setRemainingTime', function(interiorId, remainingTime)
    updateState(interiorId, 'remainingTime', remainingTime)
end)

RegisterNetEvent('pc-shootingranges:server:setStoreState:setRemainingTarget')
AddEventHandler('pc-shootingranges:server:setStoreState:setRemainingTarget', function(interiorId, remainingTarget)
    updateState(interiorId, 'remainingTarget', remainingTarget)
end)

RegisterNetEvent('pc-shootingranges:server:setStoreState:removeRemainingTarget')
AddEventHandler('pc-shootingranges:server:setStoreState:removeRemainingTarget', function(interiorId)
    local state = GunStoreStates[interiorId]
    state.remainingTarget = state.remainingTarget - 1
    broadcastToPlayers(interiorId, 'pc-shootingranges:client:setStoreState:removeRemainingTarget')
end)

RegisterNetEvent('pc-shootingranges:server:getStoreState')
AddEventHandler('pc-shootingranges:server:getStoreState', function(interiorId)
    TriggerClientEvent('pc-shootingranges:client:setStoreState', source, GunStoreStates[interiorId])
end)