RecievedToken = nil

RegisterNetEvent("trappin_moneywash:client:token:recieve")
AddEventHandler("trappin_moneywash:client:token:recieve", function(token)
    RecievedToken = token
end)

function UID()
    local template = 'xxxx-xxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

---@return string
local function GenerateResponseEventName()
    local uuid = UID()

    return "MoneyWash-response-" .. uuid
end

---@param eventName string
function TriggerSvEvent(eventName, ...)
    local promise = promise.new()
    local respName = GenerateResponseEventName()
    local handler

    -- Shouldn't Ever Happen but just incase
    if not RecievedToken then
        return {
            status = "error",
            data = "Client Auth Token not recieved, Please restart FiveM."
        }
    end

    local function onEventRecieved(data)
        RemoveEventHandler(handler)

        print("NETWORK", ("Event %s complete"):format(eventName))

        promise:resolve(data)
    end

    local function onTimeout()
        RemoveEventHandler(handler)
        promise:resolve({
            status = "error",
            data = "An error occurred while processing your request."
        })
    end

    RegisterNetEvent(respName)
    handler = AddEventHandler(respName, onEventRecieved)
    TriggerServerEvent(eventName, respName, RecievedToken, ...)
    SetTimeout(5000, onTimeout)

    return Citizen.Await(promise)
end
