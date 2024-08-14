local ESX = exports['es_extended']:getSharedObject()

OnEvent("trappin_moneywash:washMoney", function(source, resp, slot, amount)
    local xPlayer = ESX.GetPlayerFromId(source)

    local blackMoney = exports.ox_inventory:Search(source, 'count', 'black_money')
    if not blackMoney or blackMoney < amount then
        return resp({
            status = 'error',
            data = 'You do not have enough dirty money'
        })
    end

    local slotItem = exports.ox_inventory:GetSlot(xPlayer.source, slot)
    if not slotItem or slotItem.name ~= 'laundrycard2' then
        return resp({
            status = 'error',
            data = 'Invalid card'
        })
    end

    local credit = slotItem.metadata.washing_credit
    local removeCard = credit - amount <= 0

    if removeCard then
        exports.ox_inventory:RemoveItem(xPlayer.source, 'laundrycard2', 1, nil, slot)
    else
        slotItem.metadata.washing_credit = credit - amount
        exports.ox_inventory:SetMetadata(xPlayer.source, slot, slotItem.metadata)
    end

    exports.ox_inventory:RemoveItem(xPlayer.source, 'black_money', amount)
    exports.ox_inventory:AddItem(xPlayer.source, 'money', amount)

    resp({
        status = 'success',
        data = 'Money washed'
    })
end)
