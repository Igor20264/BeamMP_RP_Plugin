local M = {}
M.info = "Система Прав на машину"
M.ver = "1.0"

function AutoDriveAllPrava(sender_id, sender_name, message)
    local ret = "Все права, и стоимость: \n"
    for name1,value1 in pairs(config.drivelicence_cost) do
        ret = ret..name1..": "..value1.."\n"
    end
    SendMessage(sender_id, ret)
end

function AutoDriveAddPrava(sender_id, sender_name, message)
    local case = split(message, " ")
    local name = case[1]
    local category = string.upper(case[2])
    eco.database[name]["drivelicence"] = eco.database[name]["drivelicence"] or {}
    if eco.database[name]["drivelicence"][category] == true then
        SendMessage(MP.GetId(name), "У вас уже есть права на категорию: "..category)
        SendMessage(sender_id, "У человека уже есть права на категорию: "..category)
        return
    end
    if config.drivelicence_cost[category] == nil then
        log({"drivelicence_cost", category, "not found"}, 5)
        SendMessage(sender_id, "Категории '"..category.."' не существует.")
        return
    end
    if eco.database[name]["money"] < config.drivelicence_cost[category] then
        SendMessage(MP.GetId(name), "У вас не хватает денег на права. Стоимость: "..config.drivelicence_cost[category].." "..config.currency)
        SendMessage(sender_id, "У человека не хватает денег на права. Стоимость: "..config.drivelicence_cost[category].." "..config.currency)
        return
    end
    eco.database[name]["drivelicence"][category] = true
    eco:add(name, 'money', -math.abs(config.drivelicence_cost[category]))
    SendMessage(MP.GetId(name), "Вам выдали права на категорию: "..category.."\nС вашего счёта снята сумма: "..config.drivelicence_cost[category].." "..config.currency)
    eco:save()
end

function AutoDriveRemovePrava(sender_id, sender_name, message)
    local case = split(message," ")
    local name = case[1]
    local category = string.upper(case[2])
    eco.database[name]["drivelicence"][category] = false
    SendMessage(MP.GetId(name), "У вас отобрали права на категорию: "..category)
    eco:save()
end

-- Admin Command


M.command = {
    { category = "prava", command = "add", help = "Добавить категорию. (У игрока должны быть деньги)", args = "[name] [category]", func = "AutoDriveAddPrava", roles = {"police","moder","admin"}},
    { category = "prava", command = "remove", help = "Забрать категорию.", args = "[name] [category] ", func = "AutoDriveRemovePrava", roles = {"police","admin","moder"}},
    { category = "prava", command = "all", help = "Показать все категории.", func = "AutoDriveAllPrava"},
}

function M.load()
end

function M.unload()
end

return M
