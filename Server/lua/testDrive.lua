--- Created by hlebushek.
--- DateTime: 09.10.2024 12:34

local M = {}

M.info = "Система шеринга авто"
M.ver = "0.9 Beta"

testDriveCars = testDriveCars or load_database("testDriveCars.ixt") or {} -- Загружаем данные о машинах на тест-драйве
testDriveRequests = testDriveRequests or  {} -- Таблица для хранения запросов на тест-драйв
rentalRequests = rentalRequests or {} -- Таблица для хранения запросов на аренду

local old_testDriveCars = {}
local carSellQuore = {}

-- Продать машину другому игроку
function CarsSell(sender_id,sender_name, message)
    local case = split(message," ")
    if case[1] == nil or case[2] == nil or case[3] == nil then
        SendMessage(sender_id,"Использование: /cars sell <никнейм_игрока> <ник машины> <цена>")
        return
    end
    local name = erors(case[1],2)
    local id = cars:getidbynickname(sender_name,case[2])
    if id == nil then
        SendMessage(sender_id,"Такого никнейма нет")
        return
    end
    local coast = tonumber(case[3]) or 0
    carSellQuore[name] = {owner=sender_name, coast = coast,nickname = case[2], id = id}
    local data = cars.database[id]
    SendMessage(sender_id,"Вы отправили предложение о покупке своей машины игроку "..name)
    SendMessage(MP.GetId(name),"Вам отправили предложение о покупке машины: Игрок: "..data.nickname.." | car: "..(data.name or "None")..(data['engine'] or 'None').." "..(data['transmission'] or "None").." "..(data['transfer_case'] or "None").." За "..coast.." "..config.currency)
end

-- Принять предложение о продаже машины
function CarsSellAccept(sender_id,sender_name, message)
    if carSellQuore[sender_name] ~= nil then
        if eco:value(sender_name,"money") >= math.abs(carSellQuore[sender_name].coast) then
            local owner = carSellQuore[sender_name].owner
            local id = carSellQuore[sender_name].id
            cars:transfer(owner,sender_name,id)
            SendMessage(sender_id,"Вы приняли предложение о покупке машины "..carSellQuore[sender_name].owner)
            SendMessage(MP.GetId(carSellQuore[sender_name].owner),"Предложение о продаже машины принято. Вам заплатили "..carSellQuore[sender_name].coast.." "..config.currency)
            eco:add(sender_name,"money",-math.abs(carSellQuore[sender_name].coast))
            eco:add(carSellQuore[sender_name].owner,"money",math.abs(carSellQuore[sender_name].coast))
            carSellQuore[sender_name] = nil
        end
    end
end

-- Показать все предложение о покупке
function CarsSellShow(sender_id,sender_name, message)
    if carSellQuore[sender_name] == nil then
        SendMessage(sender_id,"Нет предложений о покупке")
        return
    else
        local data = carSellQuore[sender_name]
        SendMessage(sender_id,"Предложение о покупке машины от "..data.owner.." | Машину: "..data.nickname.." "..(data['engine'] or 'None').." "..(data['transmission'] or "None").." "..(data['transfer_case'] or "None").." | За:"..data.coast.." "..config.currency)
        SendMessage(sender_id,"Для принятия предложения введите команду "..config.prefix.."car sellaccept")

    end
end

-- Отказать всем предложение о покупке
function CarsSellDecline(sender_id,sender_name, message)
    SendMessage(MP.GetId(carSellQuore.owner), "Предложение о покупке машины было отклонено")
    SendMessage(sender_id, "Вы отказались от предложения о покупке машины")
    carSellQuore[sender_name] = nil
end


-- Функция для передачи машины на тест-драйв
function CarsTestDrive(sender_id, sender_name, message)
    local case = split(message, " ")
    local name = erors(case[1], 2)
    local timed = case[3] or "2h"
    timed = timeConverter(timed)
    if timed == nil then
        SendMessage(sender_id, "Вы указали некорректно время. Попробуйте ещё раз.")
        return
    end

    if timed > config.freeTestDriveTime then
        SendMessage(sender_id, "Вы указали время тест-драйва больше чем разрешено.\nСистемное ограничение применено.")
        timed = config.freeTestDriveTime
    end

    local id = cars:getidbynickname(sender_name, case[2])
    if id == nil then
        SendMessage(sender_id, "Такой машины у вас нет. (Проверте написание никнейма)")
        return
    end

    -- Проверяем, доступна ли машина для тест-драйва
    if testDriveCars[name] ~= nil then
        SendMessage(sender_id, "У вас уже активен тест-драйв. Попробуйте позже.")
        return
    end

    -- Просим пользователя подтвердить тест-драйв
    local requestData = {
        owner = sender_name,
        tester = name,
        carId = id,
        timed = timed
    }
    testDriveRequests[name] = requestData
    local days, hours, minutes, seconds_ret = sectotime(timed)
    SendMessage(MP.GetId(name), "Вам предлагают тест-драйв машины " .. cars:value(sender_name, id, "nickname") .. " на " .. days.."д." .. hours.. "ч."..minutes.."м.")
    SendMessage(MP.GetId(name), "Чтобы принять тест-драйв, введите команду /testdrive accept. Для отказа введите /testdrive decline.")
    SendMessage(sender_id, "Вы отправили запрос на тест-драйв машины " .. cars:value(sender_name, id, "nickname") .. " игроку " .. name .. ". Сроком на " .. days.."д." .. hours.. "ч."..minutes.."м.")
end

-- Функция для обработки запроса на тест-драйв
function CarsTestDriveAccept(sender_id, sender_name, message)
    local requestData = testDriveRequests[sender_name]
    if requestData == nil then
        SendMessage(sender_id, "Нет активных запросов на тест-драйв.")
        return
    end
    -- Передаем машину на тест-драйв
    local success = cars:transfer(requestData.owner, requestData.tester, requestData.carId, true)
    if success then
        local totime = sectotime(requestData.timed)
        testDriveCars[requestData.tester] = requestData.shallow_copy()
        SendMessage(MP.GetId(requestData.owner), "Игрок " .. requestData.tester .. " принял запрос на тест-драйв. Машина " .. cars:value(requestData.owner, requestData.carId, "nickname") .. " передана на " .. totime[1].."д." .. totime[2].. "ч."..totime[3].."м.")
        SendMessage(sender_id, "Вы приняли тест-драйв машины " .. cars:value(requestData.owner, requestData.carId, "nickname") .. " на" .. totime[1].."д." .. totime[2].. "ч."..totime[3].."м.")
        testDriveRequests[sender_name] = nil -- Удаляем запрос
    else
        SendMessage(sender_id, "Ошибка при передаче машины на тест-драйв.")
    end
end

function CarsTestDriveDecline(sender_id, sender_name, message)
    local requestData = testDriveRequests[sender_name]
    if requestData == nil then
        SendMessage(sender_id, "Нет активных запросов на тест-драйв.")
        return
    end
    SendMessage(MP.GetId(requestData.owner), "Игрок " .. requestData.tester .. " отклонил запрос на тест-драйв.")
    SendMessage(sender_id, "Вы отказались от тест-драйва.")
    testDriveRequests[sender_name] = nil -- Удаляем запрос
end

local function CheckTestDrive()
    -- Проверяем время окончания тест-драйва
    for id, data in pairs(testDriveCars) do
        if os.time() >= data.endTime then
            -- Возвращаем машину владельцу
            cars:transfer(data.tester, data.owner, data.carId)
            if MP.check_in_online(data.owner) then
                SendMessage(MP.GetId(data.owner), "Машина " .. cars:value(data.owner, id, "nickname") .. " вернулась с тест-драйва.")

            end
            if MP.check_in_online(data.tester) then
                SendMessage(MP.GetId(data.tester), "Время тест-драйва машины " .. cars:value(data.tester, id, "nickname") .. " истекло.")
            end
            testDriveCars[data.tester] = nil -- Удаляем информацию о тест-драйве
        end
    end
    if testDriveCars ~= nil and (old_testDriveCars == nil or not tables_equal(testDriveCars, old_testDriveCars)) then
        -- Сохраняем данные о тест-драйве
        -- TODO: вынести testDriveCars в отдельный класс!
        save_database("testDriveCars.ixt", testDriveCars)
        old_testDriveCars = shallow_copy(testDriveCars)
    end
    return true
end



function CarsRentOffer(sender_id,sender_name,message)
    local case = split(message, " ")
    if case[1] == nil or case[2] == nil or case[3] == nil or case[4] == nil then
        SendMessage(sender_id, "Использование: /cars rent offer <никнейм_игрока> <ник машины> <цена> <время>")
        return
    end
    local name = erors(case[1], 2)
    local timed = case[4] or "2h"
    timed = timeConverter(timed)

    local cost = tonumber(case[3]) or 0
    if cost == 0 then
        SendMessage(sender_id, "Вы указали некорректную цену. Для бесплатного тест-драйва используйте другую команду !testdrive req")
        return
    end

    if timed == nil then
        SendMessage(sender_id, "Вы указали некорректно время. Попробуйте ещё раз.")
        return
    end

    if timed > config.freeTestDriveTime then
        SendMessage(sender_id, "Вы указали время тест-драйва больше чем разрешено.\nСистемное ограничение применено.")
        timed = config.freeTestDriveTime
    end

    local id = cars:getidbynickname(sender_name, case[2])
    if id == nil then
        SendMessage(sender_id, "Такой машины у вас нет. (Проверте написание никнейма)")
        return
    end

     -- Проверяем, доступна ли машина для тест-драйва
    if testDriveCars[name] ~= nil then
        SendMessage(sender_id, "У вас уже активен тест-драйв. Попробуйте позже.")
        return
    end

    -- Просим пользователя подтвердить тест-драйв
    local requestData = {
        owner = sender_name,
        tester = name,
        carId = id,
        timed = timed,
        cost = cost
    }
    rentalRequests[name] = requestData
    local days, hours, minutes, seconds_ret = sectotime(timed)
    SendMessage(MP.GetId(name), "Вам предлагают тест-драйв машины " .. cars:value(sender_name, id, "nickname") .. " на " .. days.."д." .. hours.. "ч. "..minutes.."м. | За " .. cost .. " "..config.currency .. ".")
    SendMessage(MP.GetId(name), "Чтобы принять тест-драйв, введите команду /carrent acc. Для отказа введите /carrent dec.")
    SendMessage(sender_id, "Вы отправили запрос на тест-драйв машины " .. cars:value(sender_name, id, "nickname") .. " игроку " .. name .. ". Сроком на " .. days.."д." .. hours.. "ч. "..minutes.."м. | За " .. cost .. " "..config.currency .. ".")
end

-- Принять предложение о аренде машины
function CarsRentAccept(sender_id, sender_name, message)
    if rentalRequests[sender_name] ~= nil then
        if eco:value(sender_name, "money") >= math.abs(rentalRequests[sender_name].cost) then
            local owner = rentalRequests[sender_name].owner
            local id = rentalRequests[sender_name].id
            SendMessage(sender_id, "Вы приняли предложение о аренде машины от " .. rentalRequests[sender_name].owner)
            SendMessage(MP.GetId(rentalRequests[sender_name].owner), "Предложение о аренде машины принято. Вам заплатили " .. rentalRequests[sender_name].cost .. " " .. config.currency)
            eco:add(sender_name, "money", -math.abs(rentalRequests[sender_name].cost))
            eco:add(rentalRequests[sender_name].owner, "money", math.abs(rentalRequests[sender_name].cost))
            cars:transfer(owner, sender_name, id, true) -- Передаем машину в аренду
            testDriveCars[sender_name] = rentalRequests[sender_name].shallow_copy()
            rentalRequests[sender_name] = nil
        else
            SendMessage(sender_id, "У вас недостаточно денег для аренды.")
        end
    end
end

-- Отклонить предложение о аренде
function CarsRentDecline(sender_id, sender_name, message)
    if rentalRequests[sender_name] ~= nil then
        SendMessage(MP.GetId(rentalRequests[sender_name].owner), "Предложение о аренде машины было отклонено")
        SendMessage(sender_id, "Вы отказались от предложения о аренде машины")
        rentalRequests[sender_name] = nil
    else
        SendMessage(sender_id, "Нет активных предложений о аренде.")
    end
end

-- Показать все предложения о аренде
function CarsRentShow(sender_id, sender_name, message)
    if rentalRequests[sender_name] == nil then
        SendMessage(sender_id, "Нет предложений о аренде")
        return
    else
        local data = rentalRequests[sender_name]
        SendMessage(sender_id, "Предложение о аренде машины от " .. data.owner .. " | Машина: " .. data.nickname .. " | За: " .. data.cost .. " " .. config.currency)
        SendMessage(sender_id, "Для принятия предложения введите команду " .. config.prefix .. "car rent accept")
    end
end

M.command = {
    { category = "carsell", command = "req", help = "Предложить покупку машины.",args = "[игрок] [nickname_car] [цена]", func = "CarsSell"},
	{ category = "carsell", command = "show", help = "Показать все предложения о покупке.", func = "CarsSellShow"},
    { category = "carsell", command = "dec", help = "Отказать в предложение о покупке. ", func = "CarsSellDecline"},
    { category = "carsell", command = "acc", help = "Принять предложение о покупке. ",args = "[имя игрока]", func = "CarsSellAccept"},
	{ category = "testdrive", command = "req", help = "Предложить тест-драйв машины.", args = "[игрок] [nickname_car] (7d or 1d or 1m or 1h default: 2h)", func = "CarsTestDrive"},
    { category = "testdrive", command = "acc", help = "Принять запрос на тест-драйв.", func = "CarsTestDriveAccept"},
    { category = "testdrive", command = "dec", help = "Отклонить запрос на тест-драйв.", func = "CarsTestDriveDecline"},
    { category = "carrent", command = "offer", help = "Предложить аренду машины.", args = "[игрок] [nickname_car] [цена] [2d or 1d or 1m or 1h]", func = "CarsRentOffer"},
    { category = "carrent", command = "acc", help = "Принять предложение о аренде.", func = "CarsRentAccept"},
    { category = "carrent", command = "dec", help = "Отклонить предложение о аренде.", func = "CarsRentDecline"},
    { category = "carrent", command = "show", help = "Показать все предложения о аренде.", func = "CarsRentShow"},
}

function M.load()
    HeventTimer.addFunc(CheckTestDrive, 300) --, MP.CallStrategy.Precise
    --[[
    MP.RegisterEvent("onVehicleSpawn","CarsCheck")
	MP.RegisterEvent("onVehicleEdited","CarsCheck")
	--]]
end

function M.unload()
end

return M