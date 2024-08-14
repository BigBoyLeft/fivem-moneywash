local ServerAuthToken = ""

local function GenerateServerAuthToken()
    local token = ''
    for i = 1, 32 do
        token = token .. string.char(math.random(65, 90))
    end
    return token
end

---@param source number
---@param token string
---@param event string
function AuthenticateAuthToken(source, token, event)
    if token == ServerAuthToken then
        return true
    end

    print("SECURITY",
        ("Player %s attempted to trigger event %s with an invalid token."):format(source, event))

    return false
end

function SendServerAuthToken(source)
    TriggerClientEvent("trappin_moneywash:client:token:recieve", source, ServerAuthToken)
end

Citizen.CreateThread(function()
    ServerAuthToken = GenerateServerAuthToken()
    Wait(1000)
    TriggerClientEvent("trappin_moneywash:client:token:recieve", -1, ServerAuthToken)
end)

local function IsValidResponseEventName(respName)
    return type(respName) == "string" and string.match(respName, "^MoneyWash%-response%-.+$")
end

---@param eventName string
---@param cb function
function OnEvent(eventName, cb)
    RegisterNetEvent(eventName)
    AddEventHandler(eventName, function(respName, token, ...)
        if not IsValidResponseEventName(respName) then
            return
        end

        local src = source
        local time = GetGameTimer()

        if not AuthenticateAuthToken(src, token, eventName) then return end

        local function PromiseResponse(data)
            local endTime = GetGameTimer()
            local diff = endTime - time + 0.0

            TriggerClientEvent(respName, src, data)
            print("NETWORK",
                ('Event %s took %s to complete'):format(eventName, DynamicSecondsToClock(diff)))
        end

        local success, error = pcall(cb, src, PromiseResponse, ...)

        if not success then
            print("ERROR", ("Event %s failed with error: %s"):format(respName, error))
            PromiseResponse({
                status = "error",
                data = error
            })
        end
    end)
end

---@param seconds number
function DynamicSecondsToClock(seconds)
    local seconds = tonumber(seconds)
    if seconds <= 0 then
        return "00:00:00"        -- Format: HH:MM:SS for 0 or negative inputs
    elseif seconds <= 86400 then -- Less than or equal to 24 hours
        local hours = string.format("%02.f", math.floor(seconds / 3600))
        local mins = string.format("%02.f", math.floor(seconds % 3600 / 60))
        local secs = string.format("%02.f", math.floor(seconds % 60))
        return hours .. ":" .. mins .. ":" .. secs -- Format: HH:MM:SS
    else
        local output = ""

        if seconds >= 60 * 60 * 24 * 30 then
            local months = math.floor(seconds / (60 * 60 * 24 * 30))
            seconds = seconds % (60 * 60 * 24 * 30)
            output = output .. months .. "M "
        end

        if seconds >= 60 * 60 * 24 * 7 then
            local weeks = math.floor(seconds / (60 * 60 * 24 * 7))
            seconds = seconds % (60 * 60 * 24 * 7)
            output = output .. weeks .. "W "
        end

        if seconds >= 60 * 60 * 24 then
            local days = math.floor(seconds / (60 * 60 * 24))
            seconds = seconds % (60 * 60 * 24)
            output = output .. days .. "D "
        end

        local hours = math.floor(seconds / (60 * 60))
        seconds = seconds % (60 * 60)

        local mins = math.floor(seconds / 60)
        local secs = seconds % 60

        -- Format for more than 24 hours: [M Months] [W Weeks] [D Days] HH:MM:SS
        output = output .. string.format("%02.f:%02.f:%02.f", hours, mins, secs)

        return output
    end
end
