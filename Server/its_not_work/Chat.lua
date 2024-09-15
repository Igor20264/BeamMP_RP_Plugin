local M = {}
local DB = require "lib.database"

M.info = "Система чатов"
M.ver = "0.9 Beta"

local function TeamSendMessage(team_name,message)
    for i,player in ipairs(GetPlayersInTeam(team_name)) do
        SendMessage(MP.GetId(player),message)
    end
    return
end



local function vehicle_parser(data)
	local jbm = finds(data,"jbm")
    local per_data = data
    local data = string.gsub(data, jbm.."_",'')
    local engine = finds(data,"engine") or "Неизвестный двигатель"
    local data = string.gsub(data, engine..'_',"")
    local data = string.gsub(data, '_'..engine,"")
    local mainPartName = finds(data,"mainPartName")
    local transmission = finds(data, "transmission")
    local transfer_case = finds(data,"transfer_case")
    local body = finds(data,"body")
    return {engine=engine,transmission=transmission,mainPartName=mainPartName,transfer_case=transfer_case,body=body,per_data=per_data,color_name=color_name,jbm=jbm}
end

local Cars = {}

--[[
Сделать join to work
При этом проверка на разные странности в конфиге работы.
Создание работ через команду
Уйти из работы по команде
Закончить работу если более N минут
--]]

extended(Cars,DB)

function Cars:new(owner,ret)
    self.database = self.database or {}
    self.database[owner] = self.database[owner] or {}
    self.database[owner][Gen.uuid()] = {licenss_plate="0NNN00N00",engine=ret.ret.engine,transmission = ret.ret.transmission,transfer_case=ret.ret.transfer_case,configuration=ret.config,body=ret.ret.body,color=ret.ret.color_name,price=ret.ret.price,former_owners={},name=ret.ret.mainPartName,nickname=ret.ret.jbm}
    --[[self.database[owner][#self.database[owner]+1] = {licenss_plate="0NNN00N00",
                                                        engine=ret.ret.engine,
                                                        transmission = ret.ret.transmission,
                                                        transfer_case=ret.ret.transfer_case,
                                                        configuration=ret.config,
                                                        body=ret.ret.body,
                                                        color=ret.ret.color_name,
                                                        price=ret.ret.price,
                                                        former_owners={},
                                                        name=ret.ret.mainPartName,
                                                        nickname=ret.ret.jbm
                                                        }
                                                     --]]
    self:save()
    return #self.database[owner]+1
end

function Cars:transfer(owner,new_owner,id)
    if self.database[owner][id] == nil then
        SendMessage(owner,"Нет такой машины")
        return false
    else
        self.database[new_owner] = self.database[new_owner] or {}
        self.database[new_owner][id] = self.database[owner][id]
        self.database[owner][id] = nil
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

function Cars:is_doesnt(owner,data)
    for i,datas in pairs((self.database[owner] or {})) do
        if datas.configuration == data then
            return true
        end
    end
    return false
end

-- User Command
function ShowAllCars(sender_id,sender_name, message)
    local data = cars:get_all(sender_name)
    if data == nil then
        SendMessage(sender_id,"У вас нету машин!")
    else
        for i,data in pairs(data) do
        SendMessage(sender_id,"nick: "..data['nickname'].." "..(data['name'] or "None").." "..(data['engine'] or "None").." "..(data['transmission'] or "None").." "..(data['transfer_case'] or "None"))
        end
    end
end

-- Купить машину
function CarsBuy(sender_id,sender_name, message)
    local coast = lastCar[sender_name].price
    if eco:value(sender_name,"money") >= coast then
        eco:add(sender_name,"money",-coast)
        local num = cars:new(sender_name,lastCar[sender_name])
        SendMessage(sender_id,"Вы купили машину.")
    else
        SendMessage(sender_id,"У вас недостаточно денег")
        return
    end
end

function SetNickname(sender_id,sender_name, message)
    local case = split(message," ")
    local id = tonumber(case[1]) or cars:getidbynickname(sender_name,case[1])
    local nickname = case[2]
    cars:setnick(sender_name,id,nickname)
    SendMessage(sender_id,"Никнейм изменен, теперь никнейм"..cars:value(sender_name,id,"nickname"))
end

-- Передать машину
function CarsGive(sender_id,sender_name, message)
    local case = split(message," ")
    local name = case[1]
    local id = cars:getidbynickname(sender_name,case[2])
    local data = cars:transfer(sender_name,name,id)
    if data then
        SendMessage(sender_id,"Вы передали машину "..name)
        SendMessage(MP.GetId(name),"вам передал машину "..sender_name)
    else
        SendMessage(sender_id,"Не удалось передать машину. У вас небыло машины! ")
        SendMessage(MP.GetId(name),"Не удалось передать машину от игрока "..sender_name)
    end

end

-- Продать машину другому игроку
function CarsSell(sender_id,sender_name, message)
    local case = split(message," ")
    local name = case[1]
    local id = tonumber(case[2]) or cars:getidbynickname(sender_name,case[2])
    local coast = tonumber(case[3]) or 0
    carSellQuore[name] = {owner=sender_name,coast=coast,id=id}
    SendMessage(sender_id,"Вы отправили предложение о покупке своей машины игроку "..name)
end

-- Принять предложение о продаже машины
function CarsSellAccept(sender_id,sender_name, message)
    local case = split(message," ")
    local name = case[1]
    if carSellQuore[sender_name] ~= nil then
        if eco:value(sender_name,"money") >= carSellQuore[name].coast then
            cars:transfer(carSellQuore[name].owner,name,carSellQuore[name].id)
            carSellQuore[name] = nil
            SendMessage(sender_id,"Вы приняли предложение о покупке машины "..name)
            SendMessage(MP.GetId(name),"Предложение о продаже машины принято. Вам заплатили "..carSellQuore[name].coast.." "..config.currency)
        end
    end
    carSellQuore[name] = nil
end

-- Показать все предложения о покупке
function CarsSellShow(sender_id,sender_name, message)
    for i,data in pairs(carSellQuore[sender_name]) do
        SendMessage(sender_id,"Предложение о покупке машины от "..data.owner.." | За:"..data.coast.." "..config.currency)
    end
    SendMessage(sender_id,"Для принятия предложения введите команду "..config.prefix.."sellaccept [имя игрока]")
end

-- Отказать всем предложение о покупке
function CarsSellDecline(sender_id,sender_name, message)
    carSellQuore[sender_name] = nil
    SendMessage(sender_id,"Вы отказались от предложения о покупке машины")
end

-- Заспавнить машину

-- Admin
-- Получить все машины пользователя
function CarsGetAll(sender_id,sender_name, message)
    local case = split(message," ")
    local name = case[1]
    local ret = ""
    if cars.database[name] == nil then
        SendMessage(sender_id,"У вас нету машин")
    else
        for i,data in pairs(cars.database[name]) do
            ret = ret ..""..i..": "..data['mainPartName'].." "..data['engine'].." "..data['transmission'].." "..data['transfer_case'].." "..data['body'].."\n"
        end
        SendMessage(sender_id,ret)
    end

end

-- Обновить машини
function CarsUpdate(sender_id,sender_name, message)
    local case = split(message," ")
    local name = case[1]
    local id = cars:getidbynickname(name,case[2])
    cars:update(name,id,lastCar[name].config)
    SendMessage(sender_id,"Машина обновлена")
end

-- Удалить машину игрока в игре
function CarsDelete(sender_id,sender_name, message)
    local case = split(message," ")
    local name = case[1]
    -- SEND CLIENT COMMAND
    SendMessage(sender_id,"Машина удалена")
end

-- Установить стоймость машины
function CarsSetPrice(sender_id,sender_name, message)
    local case = split(message," ")
    log({case},3)
    local name = case[1]
    local price = tonumber(case[2])
    lastCar[name].price = price
    CarCoast[lastCar[name].path] = price
    save_database("cars_coast.ixt",CarCoast)
    SendMessage(MP.GetId(name),"Машина стоит "..price)
    SendMessage(sender_id,"Вы установили стоимость "..price)
end

-- конец основых функций
function CarsCheckCreate(player_id,vehicle_id,data)
    local name = MP.GetPlayerName(player_id)
	local data = UDV(data)
	local ret = vehicle_parser(data)
	local adata = Util.JsonDecode(data)
	local path_to_cp = adata.config.vcf.partConfigFilename
	lastCar[name] = {}
	lastCar[name].config = Util.JsonEncode(adata.config.vcf)
	lastCar[name].price = CarCoast[path_to_cp] or nil
	lastCar[name].path = path_to_cp
	lastCar[name].ret = ret

	if lastCar[name].price ~= nil and (ret.jbm ~= "unicycle" or cars:is_doesnt(name,lastCar[name].config) or work:stats(name))  then
        SendMessage(player_id,"Стоимость вашей машины в диллерском центре. "..lastCar[name].price..""..config.currency)
    end

	if ret.jbm == "unicycle" then
	    return 0
	else
	    if cars:is_doesnt(name,lastCar[name].config) then
            return 0
        elseif work:stats(name) then
            SendMessage(player_id,"Т.к Вы работаете можете взять служебную машину, или обьекты для своей работы.\nЕсли будет замечено что вы пользуетесь своей машиной, то администрация в праве выдать ШТРАФ, ВРЕМЕННОЕ ОТСТРАНЕНИЕ ОТ РП или БАН")
            return 0

        elseif block_ignore[name] ~= nil then
            SendMessage(player_id,"У вас осталось "..block_ignore[name].." спавнов/изменеий.")
            if lastCar[name].price == nil then
                SendMessage(player_id,"[Только для машин из магазина] Сообщите администратору, что для данной модели не установлена стоимость.")
            end
            return 0
        else
            SendMessage(player_id,"Вы не владеете этим обьектом. "..ret['mainPartName'])
            if lastCar[name].price == nil then
                SendMessage(player_id,"[Только для машин из магазина] Сообщите администратору, что для данной модели не установлена стоимость.")
            end
            return 1
        end
	end
end

function CarsCheckUpdate(player_id,vehicle_id,data)    local name = MP.GetPlayerName(player_id)
    log({name,vehicle_id,data},4)
	local data = UDV(data)
	local ret = vehicle_parser(data)
	local adata = Util.JsonDecode(data)
	local path_to_cp = adata.config.vcf.partConfigFilename
	log({path_to_cp},4)
end



cars = Cars:init("cars.ixt")

M.command = {
    {category = "car",command = "all",help = "Показать все машины.", func = "ShowAllCars", admin = false,hide = false},
}

function M.load()
    MP.RegisterEvent("onVehicleSpawn","CarsCheckCreate")
	MP.RegisterEvent("onVehicleEdited","CarsCheckUpdate")
end

function M.unload()
end

return M