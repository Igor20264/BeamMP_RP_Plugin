local M = {}
local DB = require "lib.database"

testDriveCars = testDriveCars or load_database("testDriveCars.ixt") or {} -- Загружаем данные о машинах на тест-драйве
testDriveRequests = testDriveRequests or  {} -- Таблица для хранения запросов на тест-драйв
rentalRequests = rentalRequests or {} -- Таблица для хранения запросов на аренду

M.info = "Система владения машинами"
M.ver = "0.9 Beta"
local cars_name = load_config("settings/car_name")
local cars_category = load_config("settings/car_category")
block_ignore = block_ignore or {}
off = off or {}
local lastCar = {}
local CarCoast =  CarCoast or load_database("cars_coast.ixt") or {}
local lisPlate = load_database("lisPlate.ixt") or {}
local perBuy = {}
local posCar = load_database("position_on_lic_plate.ixt") or {}

local function UDV(data)
    local data = string.gsub(data,'(%a+):(.-):(%d+)-(%d+)','{"config"',1)
	local data = string.gsub(data,'(%d+)-(%d+)','{"config"',1)
	local data =  data..'}'
    return data
end

local function finds(data,part_name)
	local y,x,part = string.find(data, part_name..'":"(.-)"')
	local status, part1 = pcall(string.gsub, part,part_name.."_","")
	if (status) then
		return part1
	else
		if part == nil then
			return nil
		end
	end
	return part
end

local function vehicle_parser(data)
    local jbm = finds(data, "jbm")
    local per_data = data
    data = string.gsub(data, jbm.."_", '')
    local engine = finds(data, "engine") or "Неизвестный двигатель"
    data = string.gsub(data, engine..'_', "")
    data = string.gsub(data, '_'..engine, "")
    local mainPartName = finds(data, "mainPartName")
    local transmission = finds(data, "transmission")
    local transfer_case = finds(data, "transfer_case")
    local body = finds(data, "body")
    return {engine = engine,
            transmission = transmission,
            mainPartName = mainPartName,
            transfer_case = transfer_case,body = body,
            per_data = per_data,color_name = "цвет",jbm = jbm}
end

local Cars = {}

function CarPlate()
    local letters = {'A', 'B', 'C', 'E', 'H', 'K', 'M', 'O', 'P', 'T', 'X', 'Y'}
    local function randomLetter()
        local letter = letters[math.random(1,#letters)]
        return letter
    end
    -- Формат номера: X000XX00, где X - буква, 0 - цифра, 7 - цифра
    local carNumber = randomLetter()..""..tostring(math.random(0,9))..""..tostring(math.random(0,9))..""..tostring(math.random(0,9))..""..randomLetter()..""..randomLetter().."91"  -- todo уточнить по поводуномера
    if lisPlate[carNumber] then
        carNumber = CarPlate()
    else
        lisPlate[carNumber] = true
        save_database("lisPlate.ixt",lisPlate)
        return carNumber
    end
end


--[[
Сделать join to work
При этом проверка на разные странности в конфиге работы.
Создание работ через команду
Уйти из работы по команде
Закончить работу если более N минут
--]]
--Cars:extended(DB)
extended(Cars, DB)

function Cars:new(owner,sperBuy) --perBuy[sender_name]
    local config = files.try_read_config(sperBuy.path)
    config.vars = sperBuy.vars
    config.paints = sperBuy.color
    config.partConfigFilename = sperBuy.path
    config = Util.JsonEncode(config)
    local udv = UDV(config)
    log(udv)

    self.database = self.database or {}
    self.database[owner] = self.database[owner] or {}
    local s = true
    local uuid = Gen.uuid()
    while s do
        if self.database[owner][uuid] == nil then
            s = false
        else
            uuid = Gen.uuid()
        end
    end

    self.database[owner][uuid] = {
        licenss_plate = CarPlate(),coast = sperBuy.price, configuration = config,confiscation = false,
		former_owners = {},name = sperBuy.model,category = cars_category[udv.jbm],engine=udv.engine,transmission=udv.transmission,transfer_case=udv.transfer_case,body=udv.body,
        path = sperBuy.path,jbm = udv.jbm,
        nickname=(sperBuy.model):sub(0,math.min(#(sperBuy.model)-1,3))..""..Gen.generateRandomData(3)}
    self:save()
    return #self.database[owner]+1
end

function Cars:transfer(owner,new_owner,id, isTestDrive)
    if self.database[owner][id] == nil then
        SendMessage(owner,"Нет такой машины")
        return false
    else
        if testDriveCars[id] ~= nil then -- Проверка на тест-драйв
            SendMessage(owner, "Эта машина сейчас на тест-драйве. Передача невозможна.")
            return false
        end
        local tables = self.database[owner][id]
        self.database[new_owner] = self.database[new_owner] or {}
        self.database[owner][id] = nil
        self.database[new_owner][id] = tables
        self:save()

        -- Если это тест-драйв, добавляем информацию в таблицу testDriveCars
        if isTestDrive then
            testDriveCars[id] = {
                owner = owner,
                tester = new_owner,
                endTime = os.time() + (testDriveRequests[new_owner].timed or rentalRequests[new_owner].timed or config.freeTestDriveTime) -- Время окончания тест-драйва (7 дней)
            }
        end

        return true
    end
end

function Cars:get_all(owner)
    return self.database[owner]
end

function Cars:get_for_id(owner,id)
    return self.database[owner][id]
end

function Cars:setnick(owner,id,nick)
    self.database[owner][id].nickname = nick
    self:save()
end

function Cars:getidbynickname(owner,nickname)
    if self.database[owner] == nil then
		return nil
	end
    for i,data in pairs(self.database[owner]) do
        if data.nickname == nickname then
            return i
        end
    end
    return nil
end

function Cars:update(owner,id,...)
    self.set(owner,id,...)
end

Util.CompareJsonNew = function(original, modified)
    if original == nil or modified == nil then
        return {}, {}, {} -- Возвращаем пустые таблицы, если один из аргументов nil
    end

    original = Util.JsonDecode(original)
    modified = Util.JsonDecode(modified)

    -- Проверка на unicycle
    if modified.model == "unicycle" and modified.mainpartname == "unicycle" then
        return {}, {}, {}
    end

    local function compareTables(tab1, tab2, path)
        local changed = {}
        local added = {}
        local removed = {}
        path = path or ""

        -- Проверка на изменения и добавленные элементы
        for k, v1 in pairs(tab1) do
            local v2 = tab2[k]
            if type(v1) == "table" and type(v2) == "table" then
                local ch, ad, rm = compareTables(v1, v2, path .. "." .. k)
                for _, v in pairs(ch) do table.insert(changed, v) end
                for _, v in pairs(ad) do table.insert(added, v) end
                for _, v in pairs(rm) do table.insert(removed, v) end
            elseif v2 == nil then
                table.insert(removed, {path = path .. "." .. k, value = v1})
            elseif v1 ~= v2 then
                table.insert(changed, {path = path .. "." .. k, original = v1, modified = v2})
            end
        end

        -- Проверка на удаленные элементы
        for k, v2 in pairs(tab2) do
            if tab1[k] == nil then
                table.insert(added, {path = path .. "." .. k, value = v2})
            end
        end

        return changed, added, removed
    end

    return compareTables(original, modified)
end

function Cars:is_newdoesnt(owner,data)
    for i, datas in pairs((self.database[owner] or {})) do
        -- Преобразование конфигураций в нижний регистр для сравнения
        local storedConfig = tostring(datas.configuration):lower()
        local newData = tostring(data):lower()

        if storedConfig == newData then
            return true
        end

        local changed, added, removed = Util.CompareJsonNew(storedConfig, newData)

        -- Проверьте, есть ли значительные изменения (например, больше 10 изменений)
        if #changed + #added + #removed > 10 then
            log({#changed + #added + #removed,changed, added, removed}, 4)
            log("Слишком много изменений", 4)
            return false
        end

        -- Проверка на недопустимые изменения
        for _, change in ipairs(changed) do
            local path = change.path
            local case = split(path, '.')
            if case[1] ~= "paints" and case[#case] ~= "licenseText" and case[#case] ~= "licensetext" and case[#case] ~= "licenseplate" and case[#case] ~= "mainpartname" then
                log("Недопустимое изменение: " .. path, 4)
                return false
            end
        end

        -- Проверка на недопустимые добавления
        for _, add in ipairs(added) do
            local path = add.path
            local case = split(path, '.')
            if case[1] ~= "paints" and case[#case] ~= "licenseText" and case[#case] ~= "licensetext" and case[#case] ~= "licenseplate" and case[#case] ~= "mainpartname" then
                log("Недопустимое добавление: " .. path, 4)
                return false
            end
        end

        -- Если все проверки пройдены, конфигурации считаются достаточно похожими
        return true
    end

    log("Сходств не обнаружено, returning false", 4)
    return false
end

-- Функция для сравнения двух JSON-объектов
Util.CompareJson = function(original, modified)
    if original == nil or modified == nil then
        return false
    end
    original = Util.JsonDecode(original)
    modified = Util.JsonDecode(modified)
    if (original.model ~= modified.model and original.mainpartname ~= modified.mainpartname) and (original.model ~= nil or modified.model ~= nil) then
        return false
    end
    if modified.model == "unicycle" and modified.mainpartname == "unicycle" then
        return true
    else
        if modified.model == nil or modified.mainpartname == nil then
            log({"model or mainpartname is nil",modified},4)
        end

    end
    local function compareTables(tab1, tab2, path)
        local changes = {}
        path = path or ""
        for k, v1 in pairs(tab1) do
            local v2 = tab2[k]
            if type(v2) == "table" then
                local nestedChanges = compareTables(v1, v2, path .. "." .. k)
                for _, change in ipairs(nestedChanges) do
                    table.insert(changes, change)
                end
            else
                if v1 ~= v2 then
                    table.insert(changes, {path = path .. "." .. k, original = v1, modified = v2})
                end
            end
        end
        return changes
    end
    return compareTables(original, modified)
end

function Cars:is_doesnt(owner,data)
    log(self:is_newdoesnt(owner,data),4)
    for _, datas in pairs((self.database[owner] or {})) do
        -- Преобразование конфигураций в нижний регистр для сравнения
        local storedConfig = tostring(datas.configuration):lower()
        local newData = tostring(data):lower()
        
        if storedConfig == newData then
            return true
        end
    
        local t = Util.CompareJson(storedConfig, newData)
        if t == true then
            return true  
        end

        if t and #t <= 20 then
            local ts = true
            for _, v in ipairs(t) do
                if v.path ~= ".partconfigfilename" or v.path ~= ".vars "then
                    local case = split(v.path, '.')
                    if case[1] ~= "paints" and case[#case] ~= "licenseText" and case[#case] ~= "vars" and case[#case] ~= ".part" then
                        log({"Non-allowed difference: ",case[#case],v}, 4)
                        ts = false
                        break
                    end
                end
            end
            if ts == false then
                log(t,4)
            end
            return ts
        end
    end
    
    log("Сходств не обнаружено, returning false", 4)
    return false
end
-- User Command
function ShowAllCars(sender_id,sender_name, message)
    local data = cars:get_all(sender_name)
    local ret = "Ваши машины: \n"
    if data == nil then
        SendMessage(sender_id,"У вас нет машин")
        return
    else
        for _, item in pairs(data) do
        if item ~= nil and item['nickname'] ~= nil and (item['confiscation'] == nil or item['confiscation'] == false) then
            ret = ret.."nick: "..(item['nickname'] or "Ошибка Сообщите администратору что машина сломалась.").." | car: "..(item['name'] or "None").." | engine:"..(item['engine'] or "None").." | "..(item['transmission'] or "None").." "..(item['transfer_case'] or "None").."\n"
        end
    end

    if ret == "Ваши машины: \n" then
        SendMessage(sender_id,"У вас нет машин")
    end
    SendMessage(sender_id,ret)
    end
end

function SetNickname(sender_id,sender_name, message)
    local case = split(message," ")
    local id = cars:getidbynickname(sender_name,case[1])
    if id == nil then
        SendMessage(sender_id,"Такого никнейма нет")
        return
    end
    local nickname = case[2]
    if nickname == nil or nickname == "" or nickname == " " then
        SendMessage(sender_id, "Новый никнейм не может быть пустым")
        return
    end
    cars:setnick(sender_name,id,nickname)
    SendMessage(sender_id, "Никнейм изменен, теперь никнейм: " .. cars:value(sender_name, id, "nickname"))
end

-- Передать машину
function CarsGive(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    local id = cars:getidbynickname(sender_name,case[2])
    local data = cars:transfer(sender_name,name,id)
    if data then
        SendMessage(sender_id,"Вы передали машину "..name)
        SendMessage(MP.GetId(name),"вам передал машину "..case[2].." | игрок: "..sender_name)
    else
        SendMessage(sender_id,"Не удалось передать машину. У вас небыло машины! ")
        SendMessage(MP.GetId(name),"Не удалось передать машину от игрока "..sender_name)
    end

end

function RegenerateNick(sender_id,sender_name,message)
    local case = split(message," ")
    for nick, uuid in pairs(cars.database) do
        for id, data in pairs(cars.database.uuid) do
            if data['nickname'] == nil then
                cars:set(sender_name,uuid,"nickname",Gen.generateRandomData(4))
                SendMessage(sender_id,"Сгенерирован новый никнейм: "..cars:value(sender_name,uuid,"nickname").." | Игрок: "..nick)

            end
        end
    end
end

function CarsTeleportToRepair(sender_id,sender_name, message)
    RemoutRun(sender_id,"extensions.core_input_actionFilter.setGroup('FREEZ', {'accelerate','brake','accelerate_brake','shiftUp','activateStarterMotor','switch_previous_vehicle','switch_next_vehicle','switch_next_vehicle_multiseat','nodegrabberRender','toggleWalkingMode'});extensions.core_input_actionFilter.addAction(0, 'FREEZ', true)") -- freez
    HeventTimer.Createtask((60*1+1),CarsTeleport,sender_id.."UnTeleport",sender_id)
end

function CarsTeleport(user_id)
     --RemoutRun(user_id,"local rot = be:getPlayerVehicle(0):getRotation(); spawn.safeTeleport(be:getPlayerVehicle(0), vec3(-7, 6.8, -22), rot, nil, nil, nil, nil, false))")
    RemoutRun(user_id,"spawn.safeTeleport(be:getPlayerVehicle(0), vec3(550, 669, -17), quat(0,0,0.7,-0.5), nil, nil, nil, nil, false)")
    RemoutRun(user_id,"extensions.core_input_actionFilter.addAction(0, 'FREEZ', false)") -- unfreez
end

function UncarFix(user_id)
    RemoutRun(user_id, "be:getPlayerVehicle(0):queueLuaCommand('recovery.startRecovering() recovery.stopRecovering()')")
    RemoutRun(user_id,"extensions.core_input_actionFilter.addAction(0, 'FREEZ', false)") -- unfreez
end

function CarsFix(sender_id,sender_name, message)
    local id = cars:getidbynickname(sender_name,message)
    local price = cars.database[sender_name][id].coast
    if CTS[sender_name].custom ~= nil and CTS[sender_name].custom.repair ~= nil then
        price = ((CTS[sender_name].custom.repair/config.percent_repair)*price):round(1)
    else
        SendMessage(sender_id,"Ошибка. Не удалось получить стоймость ремонта машины.")
        return
    end
    if eco:value(sender_name,"money")-price < 0 then
        SendMessage(sender_id,"У вас не хватает денег, чтобы ремонтировать машину.\n Текущая стоимость ремонта: "..price.." "..config.currency)
        return
    end
    eco:add(sender_name,"money",-price)
    SendMessage(sender_id,"Ваша машина ремонтируется. С вашего счёта было списанно: "..price.." "..config.currency.." | Ремонт будет завершится через 150 секунд.")
    RemoutRun(sender_id,"extensions.core_input_actionFilter.setGroup('FREEZ', {'accelerate','brake','accelerate_brake','shiftUp','activateStarterMotor','switch_previous_vehicle','switch_next_vehicle','switch_next_vehicle_multiseat','nodegrabberRender','toggleWalkingMode'});extensions.core_input_actionFilter.addAction(0, 'FREEZ', true)") -- freez
    HeventTimer.Createtask(150,UncarFix,sender_id.."Unfreez",sender_id)
end

-- Заспавнить машину

-- Admin
-- Получить все машины пользователя
function CarsGetAll(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    local ret = ""

    local data = cars:get_all(name)
    if data == nil then
        SendMessage(sender_id,"У него нету машин!")
    else
        for i, data in pairs(data) do
            SendMessage(sender_id,"nick: "..data['nickname'].." | car: "..(data['name'] or "None").." | "..(data['engine'] or "None").." | "..(data['transmission'] or "None").." "..(data['transfer_case'] or "None"))
        end
    end
end

-- Обновит машину
function CarsUpdate(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    local id = cars:getidbynickname(name,case[2])
    local money = tonumber(case[3])
    cars.database[name][id].configuration = lastCar[name].config or "UNKNOWN"
    cars.database[name][id].coast = cars.database[name][id].coast + (money/4) or cars.database[name][id].coast+ (cars.database[name][id].coast/10)
    cars.database[name][id].engine = lastCar[name].ret.engine or "UNKNOWN"
    cars.database[name][id].transmission = lastCar[name].ret.transmission or "UNKNOWN"
    cars.database[name][id].transfer_case = lastCar[name].ret.transfer_case or "UNKNOWN"
    cars:save()
    SendMessage(sender_id,"Машина обновлена")
end

function CarsChekEdit(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    local id = cars:getidbynickname(name,case[2])
    local text = "Изменения:\n"
    local carg = cars.database[name][id]
    if carg == nil then
        SendMessage(sender_id,"Машина не найдена")
        return
    else
        local rt = Util.CompareJson(carg.configuration,lastCar[name].config)
        for i,data in ipairs(rt) do
            text = text..data.path.." | "..tostring(data.original).." -> "..tostring(data.modified).."\n" -- Выводим только измененные значения
        end
        SendMessage(sender_id,text)
    end
end

-- Удалить машину игрока в игре
function CarsDelete(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    RemoutRun(MP.GetId(name),"be:getPlayerVehicle(0):delete()")
    SendMessage(sender_id,"Машина удалена")
end

function CarsSpawn(sender_id, sender_name, message)
    if message:find(" ") ~= nil then
        SendMessage("Никнейм машины должны быть в одно слово!")
        return
    end
    local id = cars:getidbynickname(sender_name, message)
    local carg = cars.database[sender_name][id]
    
    if carg == nil then
        SendMessage(sender_id, "Машина не найдена")
        return
    elseif carg.confiscation == true then
        SendMessage(sender_id, "Машина в конфискации")
        return
    else
        local adata = Util.JsonDecode(carg.configuration)
        adata.format = 2
        adata.licenseText = carg.licenss_plate
        lastCar[sender_name] = lastCar[sender_name] or {}
        lastCar[sender_name].licenss_plate = carg.licenss_plate
        adata.licensePlate = carg.licenss_plate
        lastCar[sender_name].ret = lastCar[sender_name].ret or {}
        lastCar[sender_name].ret.jbm = adata.jbm

        for i, v in pairs(adata.paints) do
            if type(v) == "table" then
                for i2, v2 in ipairs(adata.paints[i].baseColor) do
                    if v2 == 0 then
                        adata.paints[i].baseColor[i2] = 0.0001
                    end
                    if i2 ~= 4 and v2 > 1 then
                        adata.paints[i].baseColor[i2] = 1
                    end
                end
            end
        end

        if adata.mainPartName == nil and adata.model == nil then
            SendMessage(sender_id,"Car Error: mainPartName and model is missing. Обратитесь к администратору.")
        end

        if adata.model == nil and adata.mainPartName ~= nil then
            adata.model = adata.mainPartName
        end

        cars.configuration = Util.JsonEncode(adata)
        --adata.vehicleName = id
        --adata.vars = adata.vars or {}
        --adata.vars["$fuel"] = 20

        local send_data = {
            data = {
                autoEnterVehicle = false,
                config = adata
            },
            model = adata.model,
            run_queue = "dump('vehicle not loaded')",
            cmd = "dump('vehicle not loaded')"
        }
        if carg.licenss_plate then
            send_data.run_queue = "beamstate.load('\\\\settings\\\\BeamMP\\\\Server\\\\BeamMP_RP_Plugin\\\\"..(carg.licenss_plate)..".save.json'); dump('settings\\\\BeamMP\\\\Server\\\\BeamMP_RP_Plugin\\\\" .. carg.licenss_plate .. ".save.json LOADED')"
            send_data.cmd = "core_vehicles.setPlateText('"..(carg.licenss_plate).."', ids);"
            if posCar[carg.licenss_plate] then
                send_data.cmd = send_data.cmd .. "be:getObjectByID(ids):setPosition(vec3("..posCar[carg.licenss_plate].x..", "..posCar[carg.licenss_plate].y..", "..posCar[carg.licenss_plate].z.."))"
            end
        else
            cars.database[sender_name][id].licenss_plate = CarPlate() -- TODO Переделать из за системы номеров
            SendMessage(sender_id, "При спавне машины была обнаружена ошибка выдачи номера. Вам выдан номер "..cars.database[sender_name][id].licenss_plate)
            CarsSpawn(sender_id, sender_name, message)
            return
        end
        MP.TriggerClientEventJson(sender_id, "SPAWNCAR", send_data)
    end
end

function CarsSellGos(sender_id, sender_name, message)
    local case = split(message, " ")
    local yes = case[1]
    if yes ~= "yes" then
        SendMessage(sender_id, "Отказ. Вы не согласились.\n!car sellgos yes [nickname]")
        return
    end
    local id = cars:getidbynickname(sender_name,case[2])
    if id == nil then
        SendMessage(sender_id, "Машина не найдена")
        return
    end
    local config_name = Util.JsonDecode(cars.database[sender_name][id].configuration).partConfigFilename
    local price = CarCoast[config_name] or nil
    if price == nil then
        SendMessage(sender_id, "Не установлена стоимость "..(config_name or "корпус неизвестен"))
        return
    end
    local pc = math.random(30,40)
    eco:add(sender_name, "money", price*(pc/100))
    cars.database[sender_name][id] = nil
    cars:save()
    SendMessage(sender_id, "Машина продана. Вам заплатили за утилизацию "..pc.."% от стоимости. "..price*(pc/100)..""..config.currency)
end

-- Установить стоймость машины
function CarsSetPrice(sender_id, sender_name, message)
    local case = split(message, " ")
    if #case ~= 2 then
        SendMessage(sender_id, "Неверное количество аргументов")
        return
    end
    
    local name = case[1]
    local price = tonumber(case[2])
    
    -- Проверяем, существует ли запись в lastCar
    if not lastCar[name] then
        SendMessage(sender_id, "Нет данных о последней машине для данного имени")
        return
    end
    
    -- Устанавливаем цену в lastCar и CarCoast
    lastCar[name].price = price
    CarCoast[lastCar[name].path] = price
    
    -- Сохраняем обновленные данные в базе данных
    local success, err = pcall(function()
        save_database("cars_coast.ixt", CarCoast)
    end)
    
    if not success then
        SendMessage(sender_id, "Ошибка при сохранении базы данных: " .. tostring(err))
        return
    end
    
    -- Уведомляем пользователя об успешной установке цены
    SendMessage(MP.GetId(name), "Администратор установил стоимость, теперь машина стоит " .. price .. " " .. config.currency)
    SendMessage(sender_id, "Вы установили стоимость " .. price .. " " .. config.currency)
end

function BuyCar(sender_id, sender_name, message)
    if not perBuy[sender_name] then
        SendMessage(sender_id, "Ошибка: не удалось найти данные о последней машине.")
        print("Ошибка: perBuy[sender_name] не существует")
        return
    end
    if not perBuy[sender_name].price then
        SendMessage(sender_id, "Ошибка: не удалось найти данные о стоймости машины.")
        print("Ошибка: CarCoast[perBuy[sender_name].path] не существует")
        return
    end
    if perBuy.path == nil then
        SendMessage(sender_id, "Ошибка: не удалось найти данные о модели машины.")
        print(perBuy)
        return
    end
    if perBuy.path ~= nil and files.try_read_config(perBuy.path) == nil then
        SendMessage(sender_id, "Ошибка: Данная модель машины не существует. Свяжитесь с администратором. Код ошибки: '"..perBuy.path.." is nil'")
        print("Ошибка: files.try_read_config(perBuy.path) == nil")
        return
    end

    if not perBuy[sender_name].view then
        local send_message = "Модель машины: "..perBuy[sender_name].model.."\nСтоймость машины: "..perBuy[sender_name].price.." "..config.currency.."\nКонфигурация: "..perBuy[sender_name].path
        send_message = send_message.."\n\nДля покупки введите команду !car buy еще раз"
        perBuy[sender_name].view = true
        SendMessage(sender_id, send_message)
        return
    else
        local coast = perBuy[sender_name].price
        if eco:value(sender_name, "money") >= coast then
            eco:add(sender_name, "money", -coast)
            local num = cars:new(sender_name, perBuy[sender_name])
            SendMessage(sender_id, "Вы купили машину "..perBuy[sender_name].model.." за "..coast .. " "..config.currency)
        else
            SendMessage(sender_id, "У вас недостаточно денег")
            return
        end
    end
end

-- Функции вызываемые при тригере

function CarsCheckCreate(player_id,vehicle_id,data)
    local name = MP.GetPlayerName(player_id)
    if block_ignore[name] == true then
        return 0
    end
	local ret = vehicle_parser(data)
	if ret.jbm == "unicycle" then
	    return 0
	end
    data = UDV(data)
	local status, adata = pcall(Util.JsonDecode,data)
	if adata == nil then
		return 1
	end
	adata = adata.config.vcf
    local price = CarCoast[adata.partConfigFilename]

	lastCar[name] = {}
	lastCar[name].config = Util.JsonEncode(adata)
	lastCar[name].price = CarCoast[adata.partConfigFilename]
	lastCar[name].path = adata.partConfigFilename
	lastCar[name].ret = ret
    lastCar[name].name = cars_name[ret.jbm] or ret.mainPartName
    lastCar[name].category = cars_category[ret.jbm]
    lastCar[name].licenss_plate = adata.licenseText or adata.licenss_plate or cars_name[ret.jbm] or ret.mainPartName
    
	local isd = cars:is_doesnt(name,lastCar[name].config)
    if isd==false and price ~= nil and ret.jbm ~= "unicycle" then
        perBuy[name] = {path = adata.partConfigFilename, price=CarCoast[adata.partConfigFilename],color = adata.paints,vars = adata.vars,model = adata.model or adata.mainPartName}
        SendMessage(player_id,"Стоимость машины в диллерском центре. "..price..""..config.currency)
    end

	if isd == true then
		return 0
	elseif block_ignore[name] == true then
		block_ignore[name] = false
		return 0
	else
		SendMessage(player_id,"Вы не владеете этим обьектом. "..ret['mainPartName'])
		if lastCar[name].price == nil then
			SendMessage(player_id,"[Только для машин из магазина] Сообщите администратору, что для данной модели не установлена стоимость.")
		end
		return 1
	end
end

function CarsCheckUpdate(player_id,vehicle_id,data)
    local name = MP.GetPlayerName(player_id)
	local ret = vehicle_parser(data)
	if ret.jbm == "unicycle" then
        return 0
    end
    local data = UDV(data)
	local status, adata = pcall(Util.JsonDecode,data)
	if adata == nil then
		return 1
	end
	local adata = adata.config.vcf
	lastCar[name] = {}
	lastCar[name].price = CarCoast[adata.partConfigFilename] or nil
	lastCar[name].config = Util.JsonEncode(adata)
	lastCar[name].path = adata.partConfigFilename
	lastCar[name].ret = ret
    lastCar[name].name = cars_name[ret.jbm] or ret.mainPartName
    lastCar[name].category = cars_category[ret.jbm]
	if cars:is_doesnt(name,lastCar[name].config) == true then
	    return 0
	elseif block_ignore[name] == true then
	    return 0
	end
    return 1
	--cars:set(name,id,"configuration",adata)
	--MP.TriggerClientEvent(player_id,"SPAWNCAR",Util.JsonEncode(adata))
end

-- Cucle every Function sec

local function add_number_info(number)
    local sl = [[if be:getPlayerVehicle(0):getJBeamFilename() ~= 'unicycle' then be:getPlayerVehicle(0):queueLuaCommand("beamstate.save('\\\\settings\\\\BeamMP\\\\Server\\\\BeamMP_RP_Plugin\\\\]]..number..[[.save.json')"); end;]]
    return sl
end

function SaveCarEveryXsec()
    for i, name in pairs(MP.GetPlayers()) do
        if lastCar[name] ~= nil and lastCar[name].ret.jbm ~= "unicycle" and lastCar[name].licenss_plate ~= nil then
            local vehicles = MP.GetPlayerVehicles(tonumber(i))
            if vehicles ~= nil then
                if lastCar[name].licenss_plate ~= nil then
                    if posCar ~= nil and CTS[name] ~= nil and CTS[name].pos ~= nil then
                        posCar[lastCar[name].licenss_plate] = CTS[name].pos
                    end

                    RemoutRun(MP.GetId(name), add_number_info(lastCar[name].licenss_plate))
                else
                    log("Error. Player: "..tostring(name).." has no license-plate",4)
                end
            end
        end
    end
    if math.random(1,100) == 10 then
        forced_save_database("position_on_lic_plate.ixt",posCar)
    end
    return true
end

function CarDeleted(...)
    print(...)
end

cars = Cars:init("cars.ixt")

M.command = {
    {category = "car", command = "repair", help = "Показать стоимость ремонта.", func = "CarsFix", args = "[nickname_car]"},
    {category = "car", command = "list", help = "Показать все машины.", func = "ShowAllCars"},
    {category = "car", command = "buy", help = "Купить машину из дилер центра для покупки нужен администратор!", func = "BuyCar"},
    {category = "car", command = "setnick", help = "Установить ник машины.", args = "[nickname_car] [new nickname_car]", func = "SetNickname",},
    {category = "car", command = "transfer", help = "Передать машину. ", args = "[new_owner_name] [nickname_car]", func = "CarsGive"},
    {category = "car",command = "allforuser", help = "Показать все машины определенного игрока. ",args = "[имя игрока]", func = "CarsGetAll",roles = {"moderator","admin"}},
    {category = "car",command = "update", help = "Обновить машину. ",args = "[игрок] [nickname_car]" , func = "CarsUpdate", roles = {"moderator","admin"}},
    {category = "car",command = "viewedit", help = "Показать изменения машины. ",args = "[игрок] [nickname_car]", func = "CarsChekEdit"},
    {category = "car",command = "delete", help = "Удалить машину на которой ездит игрок. ",args = "[игрок]", func = "CarsDelete",roles = {"moderator","admin"}},
    {category = "car",command = "setprice", help = "Установить стоймость машины. ",args = "[игрок] [цена]", func = "CarsSetPrice", roles = {"admin"}},
    {category = "car",command = "spawn", help = "Создать машину по никнейму.",args="[nickcar]",func = "CarsSpawn"},
    {category = "car",command = "fixnick", help = "Востановить сломанные ники.",func = "RegenerateNick", roles = {"moderator","admin"}},
    {category = "car",command = "sellgos", help = "Отправить предложение о покупке. ",args = "yes [имя машины]", func = "CarsSellGos"},
}

M.lastCar = lastCar
function M.load()
    MP.RegisterEvent("onVehicleSpawn","CarsCheckCreate")
	MP.RegisterEvent("onVehicleEdited","CarsCheckUpdate")
    MP.RegisterEvent("onVehicleDeleted","CarDeleted")
    --[[
    MP.RegisterEvent("onVehicleSpawn","CarsCheck")
	MP.RegisterEvent("onVehicleEdited","CarsCheck")
	--]]
end

function M.unload()
end

return M

--[[


Cars.ixt

--

Cars.hex.ixt
```
id = {player,nickname_car,path}
```
Cars/{id}.ixt



--]]