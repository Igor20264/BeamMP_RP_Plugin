local M = {}
local DB = require "lib.database"

M.info = "Система владения машинами"
M.ver = "0.9 Beta"
local cars_name = load_config("settings/car_name")
local cars_category = load_config("settings/car_category")
block_ignore = block_ignore or {}
off = off or {}
local lastCar = {}
local CarCoast =  CarCoast or load_database("cars_coast.ixt") or {}
local lisPlate = load_database("lisPlate.ixt") or {}
local transfered = {}
local carSellQuore = {}

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
        local letter = letters[Util.RandomIntRange(1,#letters)]
        return letter
    end
    -- Формат номера: X000XX00, где X - буква, 0 - цифра, 7 - цифра
    local carNumber = randomLetter()..""..tostring(Util.RandomIntRange(0,9))..""..tostring(Util.RandomIntRange(0,9))..""..tostring(Util.RandomIntRange(0,9))..""..randomLetter()..""..randomLetter().."91"
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

extended(Cars, DB)

function Cars:new(owner,ret)
    self.database = self.database or {}
    self.database[owner] = self.database[owner] or {}
    self.database[owner][Gen.uuid()] = {licenss_plate = CarPlate(),engine = ret.ret.engine,
        transmission = ret.ret.transmission, transfer_case = ret.ret.transfer_case,
        configuration = ret.config,body = ret.ret.body,color = ret.ret.color_name,confiscation = false,
		former_owners = {},name = cars_name[ret.ret.jbm] or ret.ret.mainPartName,
        nickname=ret.ret.jbm:sub(0,math.min(#ret.ret.jbm-1,3))..""..Gen.generateRandomData(3)}
    self:save()
    return #self.database[owner]+1
end

function Cars:transfer(owner,new_owner,id)
    if self.database[owner][id] == nil then
        SendMessage(owner,"Нет такой машины")
        return false
    else
        local tables = self.database[owner][id]
        self.database[new_owner] = self.database[new_owner] or {}
        self.database[owner][id] = nil
        self.database[new_owner][id] = tables
        self:save()
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

-- Функция для сравнения двух JSON-объектов
Util.CompareJson = function(original, modified)
    if original == nil or modified == nil then
        return false
    end
    local original = Util.JsonDecode(original)
    local modified = Util.JsonDecode(modified)
    if original.model ~= modified.model then
        return false
    end
    if modified.model == "unicycle" and modified.mainpartname == "unicycle" then
        return true
    else
        log("model: "..modified.model)
        log("mainpartname: "..modified.mainpartname)
    end
    local function compareTables(tab1, tab2, path)
        local changes = {}
        local path = path or ""
        for k, v1 in pairs(tab1) do
            local v2 = tab2[k]
            if type(v2) == "table" then
                compareTables(v1, v2, path .. "." .. k)
            else
                if v1 ~= v2 then
                    table.insert(changes, path .. "." .. k)
                end
            end
        end
        return changes
    end



    return compareTables(original, modified)
end

function Cars:is_doesnt(owner,data)
    for i, datas in pairs((self.database[owner] or {})) do
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
        log(t,4)
        if t and #t <= 10 then
            local ts = true
            log("Differences found:", 4)
            for i, v in ipairs(t) do
                log("Difference: " .. v, 4)
                local case = split(v, '.')
                if case[1] ~= "paints" and case[#case] ~= "licenseText" then
                    log("Non-allowed difference: " .. case[#case], 4)
                    ts = false
                    break
                end
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
    else
        for i, data in pairs(data) do
        if data ~= nil and data['nickname'] ~= nil and (data['confiscation'] == nil or data['confiscation'] == false) then
            ret = ret.."nick: "..(data['nickname'] or "Ошибка Сообщите администратору что машина сломалась.").." | car: "..(data['name'] or "None").." | engine:"..(data['engine'] or "None").." | "..(data['transmission'] or "None").." "..(data['transfer_case'] or "None").."\n"
        end
    end

    if ret == "Ваши машины: \n" then
        SendMessage(sender_id,"У вас нет машин")
    end
    SendMessage(sender_id,ret)
    end
end

-- Купить машину
function CarsBuy(sender_id, sender_name, message)
    if not lastCar[sender_name] then
        SendMessage(sender_id, "Ошибка: не удалось найти данные о последней машине.")
        print("Ошибка: lastCar[sender_name] не существует")
        return
    end
    
    local coast = lastCar[sender_name].price
    if not coast then
        SendMessage(sender_id, "Ошибка: цена машины не установлена.")
        print("Ошибка: lastCar[sender_name].price не существует")
        return
    end
    
    if eco:value(sender_name, "money") >= coast then
        eco:add(sender_name, "money", -coast)
        local num = cars:new(sender_name, lastCar[sender_name])
        SendMessage(sender_id, "Вы купили машину.")
        print("Покупка успешна: " .. sender_name .. " купил машину за " .. coast .. " денег.")
    else
        SendMessage(sender_id, "У вас недостаточно денег")
        print("Ошибка: недостаточно денег у " .. sender_name)
        return
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

-- Продать машину другому игроку
function CarsSell(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    local id = cars:getidbynickname(sender_name,case[2])
    local coast = tonumber(case[3]) or 0
    carSellQuore[name] = {sender_name, coast = coast,nickname = cars:value(sender_name, id, "nickname"), id = id}
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

-- Показать все предложения о покупке
function CarsSellShow(sender_id,sender_name, message)
    for i,data in pairs(carSellQuore) do
        if i == sender_name then
            SendMessage(sender_id,"Предложение о покупке машины от "..data.owner.." | Машину: "..data.nickname.." "..(data['engine'] or 'None').." "..(data['transmission'] or "None").." "..(data['transfer_case'] or "None").." | За:"..data.coast.." "..config.currency)
        end
    end
    SendMessage(sender_id,"Для принятия предложения введите команду "..config.prefix.."car sellaccept")
end

-- Отказать всем предложение о покупке
function CarsSellDecline(sender_id,sender_name, message)
    SendMessage(MP.GetId(carSellQuore.owner), "Предложение о покупке машины было отклонено")
    SendMessage(sender_id, "Вы отказались от предложения о покупке машины")
    carSellQuore[sender_name] = nil
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
    cars.database[name][id].configuration = lastCar[name].config
    cars.database[name][id].engine = lastCar[name].ret.engine
    cars.database[name][id].transmission = lastCar[name].ret.transmission
    cars.database[name][id].transfer_case = lastCar[name].ret.transfer_case
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
            text = text..data.."\n"
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

        if adata.model == nil then
            adata.model = adata.mainPartName
        end

        cars.configuration = Util.JsonEncode(adata)
        MP.TriggerClientEventJson(sender_id, "SPAWNCAR", adata)
        --MP.Sleep(200)

        -- Проверьте, существует ли машина перед вызовом RemoutRun
        --if carg.licenss_plate then
            --RemoutRun(sender_id, "dump(be:getPlayerVehicle(0):queueLuaCommand(\"beamstate.load('" .. carg.licenss_plate .. ".save.json')\"))")
        --else
            --SendMessage(sender_id, "Не удалось найти номерной знак машины")
        --end
    end
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

local function runs(data)
	local res = assert(load(data))()
end

-- конец основых функций
function CarsCheckCreate(player_id,vehicle_id,data)
    local name = MP.GetPlayerName(player_id)
    if block_ignore[name] == true then
        return 0
    end
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
	lastCar[name].config = Util.JsonEncode(adata)
	lastCar[name].price = CarCoast[adata.partConfigFilename]
	lastCar[name].path = adata.partConfigFilename
	lastCar[name].ret = ret
    lastCar[name].name = cars_name[ret.jbm] or ret.mainPartName
    lastCar[name].category = cars_category[ret.jbm]
    lastCar[name].licenss_plate = adata.licenseText or adata.licenss_plate or cars_name[ret.jbm] or ret.mainPartName
    
	local isd = cars:is_doesnt(name,lastCar[name].config)

    if isd==false and lastCar[name].price~= nil and ret.jbm ~= "unicycle" then
        SendMessage(player_id,"Стоимость машины в диллерском центре. "..lastCar[name].price..""..config.currency)
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
    if block_ignore[name] == true then
        return 0
    end
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

function SaveCarEveryXsec()
    for i, name in pairs(MP.GetPlayers()) do
        if lastCar[name] ~= nil and lastCar[name].ret.jbm ~= "unicycle" and lastCar[name].licenss_plate ~= nil then
            local vehicles = MP.GetPlayerVehicles(tonumber(i))
            if vehicles ~= nil then
                if lastCar[name].licenss_plate ~= nil then
                    RemoutRun(MP.GetId(name), "be:getPlayerVehicle(0):queueLuaCommand(\"beamstate.save(\'".. lastCar[name].licenss_plate ..".save.json\')\")")
                else
                    log("Error. Player: "..tostring(name).." has no license-plate",4)
                end
            end
        end
    end
    return true
end

function CarDeleted(...)
    print(...)

end

cars = Cars:init("cars.ixt")

local prefix = config.prefix
M.command = {
    { category = "car", command = "list", help = "Показать все машины.", func = "ShowAllCars"},
    { category = "car", command = "buy", help = "Купить машину из дилер центра для покупки нужен администратор!", func = "CarsBuy"},
    { category = "car", command = "setnick", help = "Установить ник машины.", args = "[nickname_car] [new nickname_car]", func = "SetNickname",},
    { category = "car", command = "transfer", help = "Передать машину. ", args = "[new_owner_name] [nickname_car]", func = "CarsGive"},
    {category = "car",command = "allforuser", help = "Показать все машины определенного игрока. ",args = "[имя игрока]", func = "CarsGetAll",roles = {"moderator","admin"}},
    {category = "car",command = "update", help = "Обновить машину. ",args = "[игрок] [nickname_car]" , func = "CarsUpdate", roles = {"moderator","admin"}},
    {category = "car",command = "viewedit", help = "Показать изменения машины. ",args = "[игрок] [nickname_car]", func = "CarsChekEdit"},
    {category = "car",command = "delete", help = "Удалить машину на которой ездит игрок. ",args = "[игрок]", func = "CarsDelete",roles = {"moderator","admin"}},
    {category = "car",command = "setprice", help = "Установить стоймость машины. ",args = "[игрок] [цена]", func = "CarsSetPrice", roles = {"admin"}},
    {category = "car",command = "spawn", help = "Создать машину по никнейму.",args="[nickcar]",func = "CarsSpawn"},
    {category = "car",command = "fixnick", help = "Востановить сломанные ники.",func = "RegenerateNick", roles = {"moderator","admin"}},
	{category = "car",command = "sell", help = "Предложить покупку машины.",args = "[игрок] [nickname_car] [цена]", func = "CarsSell"},
	{category = "car",command = "sellshow", help = "Показать все предложения о покупке.", func = "CarsSellShow"},
    {category = "car",command = "selldecline", help = "Отказать в предложение о покупке. ", func = "CarsSellDecline"},
    {category = "car",command = "sellaccept", help = "Принять предложение о покупке. ",args = "[имя игрока]", func = "CarsSellAccept"}
	
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