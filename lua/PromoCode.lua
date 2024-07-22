local Module = {}
Module.info = "Система Промокодов"
Module.ver = "BETA 0.1"

local Promo = {}

function Promo:init()
    -- свойства
    local privat = {}  --приватное свойство
        privat.codes = load_database("promo_codes.ixt") or {}
    local obj = {} --публичное свойство
    -- метод

    function obj:all()
        return privat.codes
    end

    function obj:new(code,money,limit)
        privat.codes[code] = {money = tonumber(money),limit=tonumber(limit)}
        obj:save()
    end

    function obj:delete(code)
        privat.codes[code] = nil
        obj:save()
    end

    function obj:validate(code)
        if privat.codes[code] ~= nil and (privat.codes[code].limit == -1 or #privat.codes[code].user < privat.codes[code].limit) then
            return true
        else
            if #privat.codes[code].user >= privat.codes[code].limit then
                obj:delete(code)
            end
            return false
        end
    end

    function obj:isUsed(code,username)
        if privat.codes[code].used[username] == nil then
            return false
        else
            return true
        end

    end

    function obj:use(username,code)
        if obj:validate(code) then
            if not obj:isUsed(code,username) then
                privat.codes[code].used[username] = true
                eco:add(username,"money",privat.codes[code].money)
                obj:save()
                return privat.codes[code].money
            else
                return "Промокод уже использован"
            end
        else
            return "Промокод недействительный"
        end
        return false
    end

    function obj:save()
       request_save_database("promo_codes.ixt", privat.codes)
    end

    --чистая магия!
    setmetatable(obj, self)
    self.__index = self
	return obj
end

--promo = Promo:init()

function USE_PROMO(sender_id,sender_name, message)
    local case = split(message," ")
    local code = case[1]
    local egg = promo:use(sender_name,code)
    log({egg,case,sender_name,message},4)
    if egg ~= false then
        if tonumber(egg) ~= nil then
            SendMessage(sender_id,"Вы использовали промо код. Приз:["..egg.." "..config.currency.."]")
        else
            SendMessage(sender_id,egg)
        end
    else
        SendMessage(sender_id,"Промокод не найден")
    end
end

function CREAT_PROMO(sender_id,sender_name,message)
    local case = split(message," ")
    local name = case[1]
    local money = case[2]
    local limit = case[3]
    promo:new(name,tonumber(money),tonumber(limit))
    SendMessage(sender_id,"Промокод создан")
end

function DELETE_PROMO(sender_id,sender_name,message)
    local case = split(message," ")
    local name = case[1]
    promo:delete(name)
end

function GET_ALL_PROMO(sender_id,sender_name,message)
    local ret = ""
    local data = promo:all()
    for i,data in pairs(data) do
        if data.limit == -1 then
            SendMessage(sender_id,i..": "..(data.money or "Error").." "..config.currency.." | Осталось: Нет ограничений.")
        else
            SendMessage(sender_id,i..": "..data.money.." "..config.currency.." | Осталось: "..data.limit-#data.used+1)
        end

    end
end

Module.command = {}
	--{category = "promo" ,command = "use", help = "Использовать промокод.",args = "[promoname]", func = "USE_PROMO"},
	--{category = "promo" ,command = "create", help = "Создать промокод.",args = "[promoname] [money] [limit]", func = "CREAT_PROMO", roles = {"admin"}},
	--{category = "promo" ,command = "delete", help = "Удалить промокод.",args = "[promoname]", func = "DELETE_PROMO", roles = {"admin"}},
	--{category = "promo" ,command = "all", help = "Показать все промокоды.", func = "GET_ALL_PROMO", roles = {"admin"}},
	--}

function Module.load()
end

function Module.unload()
end

return Module