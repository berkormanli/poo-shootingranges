math = lib.math

local function interpolateTable(start, finish, factor)
    local interp = math.interp
    local result = {}

    for k, v in pairs(start) do
        result[k] = interp(v, finish[k], factor)
    end

    return result
end

-- Quadratic easing function
local function easeQuadratic(t)
    return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2)^2 / 2
end

-- Cubic easing function
local function easeCubic(t)
    return t < 0.5 and 4 * t * t * t or 1 - (-2 * t + 2)^3 / 2
end

---Quadratically interpolates between two values over a specified duration, returning an iterator function that will run once per game-frame.
---@generic T : number | table | vector2 | vector3 | vector4
---@param start T -- The starting value of the interpolation.
---@param finish T -- The ending value of the interpolation.
---@param duration number -- The duration over which to interpolate over in milliseconds.
---@return fun(): T, number
function math.lerpQuadratic(start, finish, duration)
    local startTime = GetGameTimer()
    local typeStart = type(start)
    local typeFinish = type(finish)

    if typeStart ~= 'number' and typeStart ~= 'vector2' and typeStart ~= 'vector3' and typeStart ~= 'vector4' and typeStart ~= 'table' then
        error(("expected argument 1 to have type '%s' (received %s)"):format('number | table | vector2 | vector3 | vector4', typeStart))
    end

    assert(typeFinish == typeStart, ("expected argument 2 to have type '%s' (received %s)"):format(typeStart, typeFinish))

    local interpFn = typeStart == 'table' and interpolateTable or math.interp
    local step

    return function()
        if not step then
            step = 0
            return start, step
        end

        if step == 1 then return end

        Wait(0)
        step = math.min((GetGameTimer() - startTime) / duration, 1)

        if step < 1 then
            local easedStep = easeQuadratic(step)
            return interpFn(start, finish, easedStep), step
        end

        return finish, step
    end
end

---Cubically interpolates between two values over a specified duration, returning an iterator function that will run once per game-frame.
---@generic T : number | table | vector2 | vector3 | vector4
---@param start T -- The starting value of the interpolation.
---@param finish T -- The ending value of the interpolation.
---@param duration number -- The duration over which to interpolate over in milliseconds.
---@return fun(): T, number
function math.lerpCubic(start, finish, duration)
    local startTime = GetGameTimer()
    local typeStart = type(start)
    local typeFinish = type(finish)

    if typeStart ~= 'number' and typeStart ~= 'vector2' and typeStart ~= 'vector3' and typeStart ~= 'vector4' and typeStart ~= 'table' then
        error(("expected argument 1 to have type '%s' (received %s)"):format('number | table | vector2 | vector3 | vector4', typeStart))
    end

    assert(typeFinish == typeStart, ("expected argument 2 to have type '%s' (received %s)"):format(typeStart, typeFinish))

    local interpFn = typeStart == 'table' and interpolateTable or math.interp
    local step

    return function()
        if not step then
            step = 0
            return start, step
        end

        if step == 1 then return end

        Wait(0)
        step = math.min((GetGameTimer() - startTime) / duration, 1)

        if step < 1 then
            local easedStep = easeCubic(step)
            return interpFn(start, finish, easedStep), step
        end

        return finish, step
    end
end