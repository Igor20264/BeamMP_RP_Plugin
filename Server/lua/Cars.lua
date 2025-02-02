local M = {}
local DB = require "lib.database"

testDriveCars = testDriveCars or load_database("testDriveCars.ixt") or {} -- Загружаем данные о машинах на тест-драйве
testDriveRequests = testDriveRequests or  {} -- Таблица для хранения запросов на тест-драйв
rentalRequests = rentalRequests or {} -- Таблица для хранения запросов на аренду
lastCarName = lastCarName or {}
block_ignore = block_ignore or {}
off = off or {}
local Compare = require "lib.ComparetesCar"
local VehicleParser = require "lib.ExtendetParser"
local Generator = require "lib.Generator"
M.info = "Система владения машинами"
M.ver = "0.9 Beta"
local perBuy = {}


local function add_number_info(number)
    local sl = [[if be:getPlayerVehicle(0):getJBeamFilename() ~= 'unicycle' then be:getPlayerVehicle(0):queueLuaCommand("beamstate.save('\\\\settings\\\\BeamMP\\\\Server\\\\BeamMP_RP_Plugin\\\\]]..number..[[.save.json')"); end;]]
    return sl
end

---@class Car
local Car = {}
Car.__index = Car
function Car:init(player_id,carId,data)
    local obj = setmetatable({}, self)
    obj.player_id = player_id
    obj.carId = carId
    obj.data = VehicleParser.vehicleParser(data)
    obj.username = obj.data.username
    return obj
end

---@param newData table
---@return boolean
function Car:is_doesnt(newData)
    local partOld = self.data.vcf
    local partNew = newData.vcf

    if partOld == partNew then
        return true
    end

    local changed, added, removed = Compare.comparete(partOld, partNew)
    print(changed, added, removed)
    -- Проверьте, есть ли значительные изменения (например, больше 10 изменений)
    if #changed + #added + #removed > 10 then
        log({#changed + #added + #removed,changed, added, removed}, 1)
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

function Car:check(disableCheck)
    if self.data.jbm == "unicycle" then
        return 0
    end
    self.data = VehicleParser.AdditionalInfo(self.data)
    if disableCheck == true then
        return 0
    end
    local owned_this_car = cars:is_doesnt(self.username,self.data)
    if owned_this_car == true then
        return 0
    elseif self.data.coast ~= nil then
        perBuy[self.username] = self.data
        SendMessage(self.player_id,"Вы не владеете этим обьектом. "..self.data.jbm)
        SendMessage(self.player_id,"Стоимость машины в диллерском центре. "..self.data.coast..""..config.currency)
        return 1,self.data
    elseif self.data.coast == nil then
        SendMessage(self.player_id,"Вы не владеете этим обьектом. "..self.data.jbm)
        SendMessage(self.player_id,"[Только для машин из магазина] Сообщите администратору, что для данной модели не установлена стоимость.")
        return 1, "nil"
    else
        local owned_this_carStr = ""
        if owned_this_car == false then
            owned_this_carStr = "False"
        else
            owned_this_carStr = "True"
        end
        log("lastCar[name][carLastName].coast:"..(self.data.coast or "nil").." | owned_this_car:"..owned_this_carStr,4)
        return 0
    end
end

function Car:update(data, disableCheck)
    data = VehicleParser.updateParts(data)
    if self.data.jbm == "unicycle" then
        return 0
    elseif data.jbm == self.data.jbm then
        if disableCheck == true then
            self.data = data
            return 0
        end
        if self:is_doesnt(data) == true then
            self.data = data
            return 0
        else
            return 1
        end
    else
        return 1
    end
end

---@class CarsManager
local CarsManager = {}
CarsManager.__index = CarsManager
function CarsManager:init()
    local obj = setmetatable({}, self)
        obj.lastCar = {}
        obj.lastCarId = {}
        obj.posCar = load_database("position_on_lic_plate.ixt") or {}
    return obj
end

---@param player_id number
---@param carId number
---@param data string
---@return boolean
function CarsManager:spawn(player_id,carId,data)
    local username = MP.GetPlayerName(player_id)
    local strCarId = "Car"..tostring(carId)
    self.lastCar[username] = self.lastCar[username] or {}
    self.lastCar[username][strCarId] = Car:init(player_id,carId,data)
    self.lastCarId[username] = strCarId
    local spawn_bool, Sdata = self.lastCar[username][strCarId]:check(block_ignore[username])
    if block_ignore[username] == true then
        block_ignore[username] = false
    end
    if spawn_bool == 0 then
        return 0
    elseif spawn_bool == 1 and Sdata ~= "nil" then
        perBuy[username] = self.lastCar[username][strCarId]
        return 1
    elseif spawn_bool == 1 and Sdata == "nil" then
        return 1
    else
        return 1
    end
end

---@param player_id number
---@param carId number
---@param data string
---@return boolean
function CarsManager:update(player_id,carId,data)
    local username = MP.GetPlayerName(player_id)
    local strCarId = "Car"..tostring(carId)
    self.lastCarId[username] = strCarId
    local cars = self.lastCar[username][strCarId]
    local status = cars:update(data,block_ignore[username])
    -- если 1 то изменения откатываются
    return status
end

---@param player_id number
---@param carId number
---@return boolean
function CarsManager:delete(player_id,carId)
    local username = MP.GetPlayerName(player_id)
    local strCarId = "Car"..tostring(carId)
    self.lastCar[username][strCarId] = nil
    self.lastCarId[username] = nil
end

function CarsManager:save_pos()
    local olddata = deep_copy(self.posCar)
    for player, carID in pairs(self.lastCarId) do
        local car = self.lastCar[player][carID]
        if car ~= nil and car.jbm ~= "unicycle" and car.licenss_plate ~= nil then
            local vehicles = MP.GetPlayerVehicles(MP.GetId(player))
            if vehicles ~= nil then
                if car.licenss_plate ~= nil then
                    if self.posCar ~= nil and CTS[player] ~= nil and CTS[player].pos ~= nil then
                        self.posCar[car.licenss_plate] = CTS[player].pos
                    end

                    RemoutRun(MP.GetId(player), add_number_info(car.licenss_plate))
                else
                    log("Error. Player: "..tostring(player).." has no license-plate",4)
                end
            end

            car:save_pos()
        end
    end
    if not tables_equal(self.posCar, olddata) and math.random(1,10) == 1 then
        forced_save_database("position_on_lic_plate.ixt",self.posCar)
    end
    return true
end

---@param plate string
---@return table
function CarsManager:get_pos(plate)
    return self.posCar[plate]
end

---@param username string
---@return Car
function CarsManager:get_car(username)
    print(self.lastCarId[username],self.lastCar[username][self.lastCarId[username]])
    return self.lastCar[username][self.lastCarId[username]]
end

local carsManager = CarsManager:init()

local Cars = {}
extended(Cars, DB)
function Cars:init(path)
    local db_instance = DB:init(path) -- Инициализация DB

    -- Копируем поля из db_instance в self
    for key, value in pairs(db_instance) do
        self[key] = value
    end

    return self
end

---@param owner string
---@param sperBuy Car
function Cars:new(owner,sperBuy) --perBuy[sender_name]
    local car = sperBuy.data
    local config = files.try_read_config(car.vcf.partConfigFilename)
    car.vcf.parts = config.parts
    car.vcfStr = Util.JsonEncode(car.vcf)
    self.database = self.database or {}
    self.database[owner] = self.database[owner] or {}


    local uuid
    repeat
        uuid = Gen.uuid()
    until self.database[owner][uuid] == nil

    self.database[owner][uuid] = {
        licenss_plate = Generator.numberPlate(),
        coast = car.coast,
		former_owners = {},
        name = car.carName,
        category = car.category,
        jbm = car.jbm,
        isFull = car.base.isFullConfig,
        data = car,
        nickname=(car.jbm):sub(0,math.min(#(car.jbm)-1,3))..""..Gen.generateRandomData(3)
    }
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

function Cars:get_all_by_jbeam(owner,jbeam)

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

function Cars:is_doesnt(owner,data)

    local newData = data
    --log(self:is_newdoesnt(owner,data),4)
    for _, datas in pairs((self.database[owner] or {})) do
        -- Преобразование конфигураций в нижний регистр для сравнения
        local oldData = datas
        local storedConfig = tostring(oldData.data.vcfStr):lower()
        local newConfig = tostring(newData.vcfStr):lower()

        if storedConfig == newConfig then
            return true
        end

        if oldData.jbm == newData.jbm then
            if oldData.data.base.isFullConfig == false and newData.base.isFullConfig == true then
                oldData.data.vcfStr = newData.vcfStr
                oldData.data.vcf = newData.vcf
                oldData.data.base.isFullConfig = true
                log("isFullConfig == False, config updated, returning true", 4)
                return true
            end
            if oldData.data.base.isFullConfig == nil and newData.base.isFullConfig == true then
                oldData.data.vcfStr = newData.vcfStr
                oldData.data.vcf = newData.vcf
                oldData.data.base.isFullConfig = true
                log("isFullConfig == nil, config updated, returning true", 4)
                return true
            end
            if oldData.data.base.isFullConfig == false and newData.base.isFullConfig == false then
                log("isFullConfig == False, returning true", 4)
                return true
            end

            local t = Util.CompareJson(storedConfig, newConfig)
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
            ret = ret.."nick: "..(item['nickname'] or "Ошибка Сообщите администратору что машина сломалась.").." | car: "..(item.name or "None").." | engine:"..(item.data.base.engine).." | "..(item.data.base.transmission).." "..(item.data.base.transfer_case).."\n"
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
    SendMessage(sender_id, "Никнейм изменен, теперь никнейм: " .. cars.database[sender_name][id].nickname)
end

-- Передать машину
function CarsGive(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    local id = cars:getidbynickname(sender_name,case[2])
    if cars.database[name] ~= nil and cars.database[name][id] ~= nil then
        SendMessage(sender_id,"Вы не можете передать машину игроку. Внутренний конфликт UUID")
        SendMessage(MP.GetId(name),"Вам не могут передать машину. Внутренний конфликт UUID")
        return
    end
    local data = cars:transfer(sender_name,name,id)

    if data then
        SendMessage(sender_id,"Вы передали машину "..name)
        SendMessage(MP.GetId(name),"Вам передал машину "..case[2].." | "..cars.database[name][id].nickname.." | от: "..sender_name)
    else
        SendMessage(sender_id,"Не удалось передать машину.")
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
    if id == nil then
        SendMessage(sender_id,"Указанный никнейм не найден или указана неверно")
        return
    end
    local price = cars.database[sender_name][id].coast
    if CTS[sender_name] == nil then
        SendMessage(sender_id,"Ошибка. Не удалось получить пользователя.")
    end
    if CTS[sender_name].custom ~= nil and CTS[sender_name].custom.repair == nil then
        SendMessage(sender_id,"Ошибка. Не удалось получить стоймость ремонта машины.")
        return
    end
    if price == nil then
        SendMessage(sender_id,"Ошибка. Не удалось получить стоимость машины из данных.")
    end
    if CTS[sender_name].custom ~= nil and CTS[sender_name].custom.repair ~= nil then
        -- Получаем процент повреждения
        local damage = (CTS[sender_name].custom.repair+1)/config.percent_repair
        local price_damage = (damage/2)*price
        price = round(price_damage,1)
    else
        SendMessage(sender_id,"Ошибка. Не удалось получить стоймость ремонта машины.")
        return
    end
    if eco:value(sender_name,"money")-price < 0 then
        SendMessage(sender_id,"У вас не хватает денег, чтобы ремонтировать машину.\n Текущая стоимость ремонта: "..price.." "..config.currency)
        return
    end
    eco:add(sender_name,"money",-price)
    SendMessage(sender_id,"Ваша машина ремонтируется. С вашего счёта было списанно: "..price.." "..config.currency.." | Ремонт завершится через 150 секунд.")
    RemoutRun(sender_id,"extensions.core_input_actionFilter.setGroup('FREEZ', {'accelerate','brake','accelerate_brake','shiftUp','activateStarterMotor','switch_previous_vehicle','switch_next_vehicle','switch_next_vehicle_multiseat','nodegrabberRender','toggleWalkingMode'});extensions.core_input_actionFilter.addAction(0, 'FREEZ', true)") -- freez
    HeventTimer.Createtask(150,UncarFix,sender_id.."Unfreez",sender_id)
end

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
        for i, item in pairs(data) do
            if ret == "" then
                ret = "nick: "..(item['nickname']).." | car: "..(item.name or "None").." | engine:"..(item.data.base.engine).." | "..(item.data.base.transmission).." "..(item.data.base.transfer_case).."\n"
            else
                ret = ret.."nick: "..(item['nickname']).." | car: "..(item.name or "None").." | engine:"..(item.data.base.engine).." | "..(item.data.base.transmission).." "..(item.data.base.transfer_case).."\n"
            end
        end
        SendMessage(sender_id,ret)
    end
end

-- Обновит машину
function CarsUpdate(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    if name == nil then
        SendMessage(sender_id,"Укажите никнейм")
        return
    end
    local money = tonumber(case[3])
    if money == nil then
        SendMessage(sender_id,"Укажите сумму")
        return
    end
    local id = cars:getidbynickname(name,case[2])
    if id == nil then
        SendMessage(sender_id,"Машина не найдена")
        return
    end
    local car = carsManager:get_car(name)

    if car == nil then
        local target = MP.GetId(name)
        if target == sender_id then
            SendMessage(sender_id,"Текущая машина == nil. Возможны ошибки при сохранении машины! (Текущее сохранение было отклонено) Попробуйте еще раз через 5 секунд.")
        else
            SendMessage(sender_id,"Текущая машина == nil. Возможны ошибки при сохранении машины! (Текущее сохранение было отклонено) Попробуйте еще раз через 5 секунд.")
            SendMessage(MP.GetId(name),"Текущая машина == nil. Возможны ошибки при сохранении машины! (Текущее сохранение было отклонено) Попробуйте еще раз через 5 секунд.")
        end
        return
    end

    if eco:value(name, "money") < money then
        local curMoney = eco:value(sender_name, "money")
        SendMessage(MP.GetId(name), "У вас не хватает: "..money-curMoney.." "..config.currency.." для обновления машины")
        SendMessage(sender_name, "У Игрока не хватает: "..money-curMoney.." "..config.currency.." для обновления машины")
    end
    cars.database[name][id].data.vcfStr = car.data.vcfStr
    cars.database[name][id].data.vcf = car.data.vcf
    cars.database[name][id].coast = round(cars.database[name][id].coast + (money/4),2)
    cars.database[name][id].data.base = car.data.base
    cars:save()
    eco:add(name, "money", -math.abs(money))
    SendMessage(MP.GetId(name),"Вы заплатили "..money.." "..config.currency.." за обновление машины")
    eco:add(sender_name, "money", math.abs((money/100)*5))
    SendMessage(sender_id,"Машина обновлена | Вам заплатили за обновление машины "..math.abs((money/100)*5).." "..config.currency)

end

function CarsChekEdit(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    local id = cars:getidbynickname(name,case[2])
    local text = "Изменения:\n"
    local car = carsManager:get_car(name)
    local carg = cars.database[name][id]
    if carg == nil then
        SendMessage(sender_id,"Машина не найдена")
        return
    else
        local carLastName = lastCarName[name]
        local rt = Util.CompareJson(carg.data.vcfStr,car.vcfStr)
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
    elseif carg.confiscation ~= nil and carg.confiscation == true then
        SendMessage(sender_id, "Машина в конфискации")
        return
    else
        local adata = carg.data.vcf
        adata.format = 2

        adata.mainPartName = carg.data.vcf.mainPartName
        adata.jbm = carg.data.jbm

        --local configuration = Util.JsonEncode(adata)
        --adata.vehicleName = id
        --adata.vars = adata.vars or {}
        --adata.vars["$fuel"] = 20

        local send_data = {
            data = {
                autoEnterVehicle = false,
                config = adata
            },
            model = adata.jbm,
            run_queue = "dump('vehicle not loaded')",
            cmd = "dump('vehicle not loaded')"
        }
        if carg.licenss_plate then
            send_data.run_queue = "beamstate.load('\\\\settings\\\\BeamMP\\\\Server\\\\BeamMP_RP_Plugin\\\\"..(carg.licenss_plate)..".save.json'); dump('settings\\\\BeamMP\\\\Server\\\\BeamMP_RP_Plugin\\\\" .. carg.licenss_plate .. ".save.json LOADED')"
            send_data.cmd = "core_vehicles.setPlateText('"..(carg.licenss_plate).."', ids);"
            local positionCar = carsManager:get_pos(carg.licenss_plate)
            if positionCar then
                send_data.cmd = send_data.cmd .. "be:getObjectByID(ids):setPosition(vec3("..positionCar.x..", "..positionCar.y..", "..positionCar.z.."))"
            end
        else
            cars.database[sender_name][id].licenss_plate = Generator.numberPlate() -- TODO Переделать из за системы номеров
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

    local config_name = cars.database[sender_name][id].data.vcf.partConfigFilename
    local price = cars.database[sender_name][id].coast or nil
    if price == nil then
        SendMessage(sender_id, "Не установлена стоимость "..(config_name or "корпус неизвестен"))
        return
    end

    local pc = math.random(30,40)
    price = price*(pc/100)
    eco:add(sender_name, "money", price)
    cars.database[sender_name][id] = nil
    cars:save()
    SendMessage(sender_id, "Машина продана. Вам заплатили за утилизацию "..pc.."% от стоимости. "..price..""..config.currency)
end

-- Установить стоймость машины
function CarsSetPrice(sender_id, sender_name, message)
    local case = split(message, " ")
    if #case ~= 2 then
        SendMessage(sender_id, "Неверное количество аргументов")
        return
    end
    
    local name = case[1]
    local coast = tonumber(case[2])

    local car = carsManager:get_car(sender_name)
    if not car then
        SendMessage(sender_id, "Нет данных о последней машине для данного имени")
        return
    end
    
    -- Устанавливаем цену в CarCoast
    car.coast = coast
    local CarCoast = load_database("cars_coast.ixt")
    CarCoast[car.data.vcf.partConfigFilename] = coast
    save_database("cars_coast.ixt", CarCoast)
    if name ~= sender_name then
        SendMessage(MP.GetId(name), "Администратор установил стоимость, теперь машина стоит " .. coast .. " " .. config.currency)
    end
    SendMessage(sender_id, "Вы установили стоимость " .. coast .. " " .. config.currency)
end

function BuyCar(sender_id, sender_name, message)
    if not perBuy[sender_name] then
        SendMessage(sender_id, "Ошибка: не удалось найти данные о последней машине.")
        return
    end
    local car = perBuy[sender_name].data
    if not car.coast then
        SendMessage(sender_id, "Ошибка: не удалось найти данные о стоймости машины.")
        return
    elseif not car.vcf.partConfigFilename then
        SendMessage(sender_id, "Ошибка: не удалось найти данные о модели машины.")
        return
    elseif car.vcf.partConfigFilename ~= nil and files.try_read_config(car.vcf.partConfigFilename) == nil then
        SendMessage(sender_id, "Ошибка: Данная модель машины не существует. Свяжитесь с администратором. Код ошибки: '"..car.vcf.partConfigFilename.." is nil'")
        return
    end
    if not perBuy[sender_name].view then
        local send_message = "Модель машины: "..car.carName .."\nСтоймость машины: "..car.coast.." "..config.currency.."\nКонфигурация: "..car.vcf.partConfigFilename
        send_message = send_message.."\n\nДля покупки введите команду !car buy еще раз"
        perBuy[sender_name].view = true
        SendMessage(sender_id, send_message)
        return
    else
        local coast = car.coast
        if eco:value(sender_name, "money") >= coast then
            eco:add(sender_name, "money", -coast)
            local num = cars:new(sender_name, perBuy[sender_name])
            SendMessage(sender_id, "Вы купили машину "..car.carName.." за "..coast .. " "..config.currency)
        else
            SendMessage(sender_id, "У вас недостаточно денег")
            return
        end
    end
end

function FixMyCars(sender_id, sender_name, message)
    for id, car in pairs(cars.database[sender_name]) do
        car.data.base = VehicleParser.updateBaseData(car.data.vcf)
        if car.nickname == nil then
            car.nickname=(car.jbm):sub(0,math.min(#(car.jbm)-1,3))..""..Gen.generateRandomData(3)
            SendMessage(sender_id,"Сгенерирован новый никнейм: "..car.nickname.." | Игрок: "..sender_name)
        end
    end
    cars:save()
end

-- Функции вызываемые при тригере

function EventCarsSpawn(player_id,vehicle_id,data)
    local cancel = carsManager:spawn(player_id,vehicle_id,data)

    if cancel == false or cancel == 0 then
        cancel = 0
    else
        cancel = 1
    end
    log("EventCarsSpawn end responce for player: "..player_id.." : "..cancel,4)
    return cancel
end

function EventCarsUpdate(player_id,vehicle_id,data)
    local cancel = carsManager:update(player_id,vehicle_id,data)
    if cancel == false or cancel == 0 then
        cancel = 0
    else
        cancel = 1
    end
    log("EventCarsUpdate end responce for player: "..player_id.." : "..cancel,4)
    return cancel
end

function EventCarsDelete(player_id,vehicle_id)
    carsManager:delete(player_id,vehicle_id)
end

function SaveCarEveryXsec()
    carsManager:save_pos()
end

cars = Cars:init("cars.ixt")

M.command = {
    {category = "car", command = "repair", help = "Показать стоимость ремонта.", func = "CarsFix", args = "[nickname_car]"},
    {category = "car", command = "list", help = "Показать все машины.", func = "ShowAllCars"},
    {category = "car", command = "buy", help = "Купить машину из дилер центра для покупки нужен администратор!", func = "BuyCar"},
    {category = "car", command = "setnick", help = "Установить ник машины.", args = "[nickname_car] [new nickname_car]", func = "SetNickname",},
    {category = "car", command = "transfer", help = "Передать машину. ", args = "[new_owner_name] [nickname_car]", func = "CarsGive"},
    {category = "car",command = "allforuser", help = "Показать все машины определенного игрока. ",args = "[имя игрока]", func = "CarsGetAll",roles = {"moder","admin"}},
    {category = "car",command = "update", help = "Обновить машину. ",args = "[игрок] [nickname_car]" , func = "CarsUpdate", roles = {"moderator","admin"}},
    {category = "car",command = "viewedit", help = "Показать изменения машины. ",args = "[игрок] [nickname_car]", func = "CarsChekEdit"},
    {category = "car",command = "delete", help = "Удалить машину на которой ездит игрок. ",args = "[игрок]", func = "CarsDelete",roles = {"moder","admin"}},
    {category = "car",command = "setprice", help = "Установить стоймость машины. ",args = "[игрок] [цена]", func = "CarsSetPrice", roles = {"admin"}},
    {category = "car",command = "spawn", help = "Создать машину по никнейму.",args="[nickcar]",func = "CarsSpawn"},
    {category = "car",command = "fixnick", help = "Починить ники машин и обновить значение двигателя, коробки, трансмиссии.",func = "FixMyCars"},
    {category = "car",command = "sellgos", help = "Отправить предложение о покупке. ",args = "yes [имя машины]", func = "CarsSellGos"},
}

function M.load()
    MP.RegisterEvent("onVehicleSpawn","EventCarsSpawn")
	MP.RegisterEvent("onVehicleEdited","EventCarsUpdate")
    MP.RegisterEvent("onVehicleDeleted","EventCarsDelete")
    --[[
    MP.RegisterEvent("onVehicleSpawn","CarsCheck")
	MP.RegisterEvent("onVehicleEdited","CarsCheck")
	--]]
end

function M.unload()
end

return M
