local M = {}
local DB = require "lib.database"
M.info = "Система для Полиции"
M.ver = "2.0"
--
local Police = {}
--extended(Police,DB)
Police:extended(DB)
--[[
Система Полиции
1. Звания (Другой плагин)
2. Штрафы
2.1 Создание
2.2 Редактирование
2.3 Удаление
3. Конфискация Авто
3
4. Розыск
--]]

-- Manhunt

function Police:CreateManhunt(reason,description)
    Police.database["manhunt"][Gen.uuid()] = {no = tostruing(#Police.database["manhunt"]+1),reason = reason,description=description,closed = false}
end

function Police:GetManhunt(active)
    local active = active or false
    local ret = {}
    if active then
        for i,data in pairs(Police.database["manhunt"]) do
            if data.closed == false then
                ret[i] = data
            end
        end
    else
        ret = self.database["manhunt"]
    end
    return ret
end

function Police:GetManhuntByNo(no)
    for i,data in pairs(self.database["manhunt"]) do
        if data.no == no then
            return data
        end
    end
    return nil
end

function Police:CloseManhunt(name,id)
    self.set("manhunt",id,"closed",true)
end

-- Confiscation
function Police:CreateConfiscation(name,from,price,reason,carname)
    Police.database[name]["confiscation"][Gen.uuid()] = {no = tostruing(#Police.database[name]["confiscation"]+1),price = price,reason = reason,from = from,car = carname,closed = false}
    cars:set(name,cars:getidbynickname(name,carname),"confiscation",true)
end

function Police:CloseConfiscation(name,id)
    self.set(name,"confiscation",id,"closed",true)
    cars:set(name,cars:getidbynickname(name,self.get(name,"confiscation",id,"carname"),"confiscation",false))
end
--[[
function Police:GetConfiscation(name,active)
    local active = active or false
    local ret = {}
    if active then
        for i,data in pairs(Police.database[name]["confiscation"]) do
            if data.closed == false then
                ret[i] = data
            end
        end
    else
        ret = self.database[name]["confiscation"]
    end
    return ret
end
--]]
function Police:GetConfiscationByNo(name,no)
    for i,data in pairs(Police.database[name]["confiscation"]) do
        if data.no == no then
            return data
        end
    end
    return nil
end

-- fines
function Police:CreateFines(name,from,price,reason,caruuid)
    Police.database[name]["fines"][Gen.uuid()] = {no = tostring(#Police.database[name]["fines"]+1),price = price,reason = reason,from = from,car = caruuid,closed = false}
    self:save()
end

function Police:CloseFines(name,id)
    self.set(name,"fines",id,"closed",true)
end

function Police:EditFines(name,id,...)
    self.set(name,"fines",id,...)
end

function Police:GetFinesByNo(name,no)
    for i,data in pairs(Police.database[name]["fines"]) do
        if data.no == no then
            return data
        end
    end
    return nil
end

function Police:GetFines(name,active)
    local active = active or false
    local ret = {}
    if active then
        for i,data in pairs(Police.database[name]["fines"]) do
            if data.closed == false then
                ret[i] = data
            end
        end
    else
        ret = self.database[name]["fines"]
    end
    return ret
end

local triggerPlaces = {
    [1] = "Западная улица 1-Мкр",
    [2] = "Западная улица 1-Мкр",
    [3] = "Окружная улица 2-Мкр",
    [4] = "Окружная улица 2-Мкр",
    [5] = "Автострада",
    [6] = "Автострада",
    [7] = "Highway в деревне",
    [8] = "Highway в деревне",
    [9] = "Солнечные панели",
    [10] = "Солнечные панели",
    [11] = "Окружная улица 4-Мкр",
    [12] = "Окружная улица 4-Мкр",
    [13] = "Центральная улица 5-Мкр",
    [14] = "Центральная улица 5-Мкр"
}

working = {}

function speedTrap(player_id, data)
    local speedTrapData = Util.JsonDecode(data)
    local triggerName = speedTrapData.triggerName
    local triggerNumber = tonumber(string.match(triggerName, "%d+"))
    local triggerPlace = triggerPlaces[triggerNumber] or "Неизвестно"

    local penalty = string.format("%.1f км/ч в зоне %.0f км/ч. Превышение на: %.1f км/ч. Место: %s. Транспортное средство: %s. Номер: %s",
        speedTrapData.playerSpeed * 3.6, speedTrapData.speedLimit * 3.6, speedTrapData.overSpeed * 3.6, triggerPlace, speedTrapData.vehicleModel, speedTrapData.licensePlate)

    local penalty_time = os.date("%H:%M:%S")  -- Запоминаем время штрафа

    table.insert(penalties, {penalty = penalty, time = penalty_time})  -- Добавляем штраф в переменную

    if #penalties > 10 then  -- Если количество штрафов превышает 10, удаляем старые штрафы
        for i = 1, #penalties - 10 do
            table.remove(penalties, 1)  -- Удаляем старые штрафы
        end
    end
    -- Отправить сообщение о штрафе всем полицейским, если игрок работает
    MP.SendChatMessage(-1, "Нарушение: " .. penalty)
end

function ShowPenalties(sender_id, sender_name, message)
    local penalties_found = false
    for i, penalty_data in ipairs(penalties) do -- TODO: replace to economica
        penalties_found = true
        SendMessage(sender_id, "[" .. penalty_data.time .. "] " .. penalty_data.penalty)
    end
    if not penalties_found then
        SendMessage(sender_id, "Нет штрафов с камер.")
    end

    return 0
end



-- ADMIN COMMAND

-- System Commands [[

-- USER COMMAND [[


-- LOAD PEREMENNI
police = Police:init("police.ixt")

M.police = police
M.command = {
	{category = "police" ,command = "info", help = "Узнать информацию о себе, или предоставить ее другому игроку. ", args = "[name]",func = "GETINFO"}
}

function M.load()
    MP.RegisterEvent("speedTrap", "speedTrap")
    MP.RegisterEvent("redLight", "redLight")
end

function M.unload()
end

return M