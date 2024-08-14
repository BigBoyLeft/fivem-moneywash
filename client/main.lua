local ESX = exports['es_extended']:getSharedObject()
local washing = false

---@param items SlotWithItem[]
local function formatItemsByType(items)
    local cards = {}

    table.sort(items, function(a, b) return a.metadata.washing_credit > b.metadata.washing_credit end)
    for k, v in pairs(items) do
        local credit = v.metadata.washing_credit
        table.insert(cards, { label = ("%s Card - $%s"):format(v.metadata.washing_rarity, credit), value = v.slot })
    end

    return cards
end

local function getCreditLimit(items, slot)
    for k, v in pairs(items) do
        if v.slot == slot then
            return v.metadata.washing_credit
        end
    end
end

function ShowDialog()
    if washing then return end

    local rawitems = exports.ox_inventory:Search('slots', 'laundrycard2')
    local items = formatItemsByType(rawitems)

    local input = lib.inputDialog("Money Wash", {
        { type = 'select', label = 'Select Card', options = items,                    required = true, searchable = true },
        { type = 'number', label = 'Amount',      description = 'Enter money amount', required = true }
    })

    if not input or not input[1] or not input[2] then return end

    local slot = input[1]
    local amount = tonumber(input[2])
    local credit = getCreditLimit(rawitems, slot)

    if not amount or amount < 1 then
        return lib.notify({
            type = 'error',
            title = 'Error',
            description =
            'Cannot wash less than $1'
        })
    end

    if amount > credit then
        return lib.notify({
            type = 'error',
            title = 'Error',
            description =
                'This amount exceeds the card limit of $' .. credit
        })
    end

    local success = lib.skillCheck({ 'easy', 'easy' })

    if not success then
        return lib.notify({
            type = 'error',
            title = 'Error',
            description = 'Failed to wash money'
        })
    end

    washing = true
    local result = TriggerSvEvent('trappin_moneywash:washMoney', slot, amount)

    if result.status == 'success' then
        lib.notify({
            type = 'success',
            description = 'Successfully washed $' .. amount
        })
    else
        lib.notify({
            type = 'error',
            description = result.data
        })
    end
    washing = false
end

Citizen.CreateThread(function()
    exports.ox_inventory:displayMetadata({
        washing_rarity = "Card Type",
        washing_credit = "Credit Remaining"
    })

    while not ESX.IsPlayerLoaded() do Wait(500) end
    for k, v in pairs(Config.Blips) do
        if v.enable then
            local blip = AddBlipForCoord(v.pos.x, v.pos.y, v.pos.z)
            SetBlipSprite(blip, v.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, v.size)
            SetBlipColour(blip, v.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(v.name)
            EndTextCommandSetBlipName(blip)
        end
    end

    for k, v in pairs(Config.Locations) do
        lib.zones.sphere({
            coords = v.xyz,
            radius = v.w,
            debug = false,
            onEnter = function()
                lib.showTextUI("Press E to wash money")
            end,
            onExit = function() lib.hideTextUI() end,
            inside = function()
                if not washing and IsControlJustPressed(0, 38) then ShowDialog() end
            end
        })
    end
end)
