local M = {}
local BanSystem = {}
BanSystem.__index = BanSystem
function BanSystem:init()
    local obj= setmetatable({},self)
    local privat = {}  --приватное свойство

        privat.Class = {}

        privat.Class.join_history = files.ClassBD:init("join_history.ixt") -- name:{{ip="ip",jointime=os.time()},{ip="ip",jointime=os.time()}}
        privat.Class.banlist = files.ClassBD:init("banlist.ixt")
        privat.Class.whitelist = files.ClassBD:init("whitelist.ixt")

        privat.join_history = privat.Class.join_history:load() or {} --
        privat.database = privat.Class.banlist:load() or {}
        privat.whitelist = privat.Class.whitelist:load() or {}

        privat.cache = {}
        privat.cache.ban = {}



    function obj:check(name,role,is_guest,data)
        if is_guest == true and config.guest_ban == true then
            return "[GUEST] Для игры на сервере вам необходимо зарегистрироваться в BeamMP и Discord: "..config.url
        end
        obj:add_history(name,data,role)
        if config.withelist == true then
            local is_whitelisted = privat:check_whitelist(name)
            if is_whitelisted ~= true then
                return is_whitelisted
            end
        end

        local is_banned = privat:check_ban(name,role,is_guest,data)
        if is_banned ~= true then
            return is_banned
        end

        if config.ip_ban == true then
            local is_ip_banned = privat:check_ip(data.ip)
            if is_ip_banned ~= true then
                return is_ip_banned
            end
        end

        return true
    end

     function obj:update_cache()
         privat.cache.ban = {}
         if config.ip_ban == true then
             privat:gen_cache_ban()
         end
     end

    -- WHITELIST --
    function privat:check_whitelist(name)
        if privat.whitelist[name] == true then
            return true
        else
            return privat:message_whitelist(name)
        end
    end

    function obj:is_whitelisted(name)
        return privat.whitelist[name] or false
    end

    function obj:add_whitelist(name)
        if privat.whitelist[name] == true then
            return false
        else
            privat.whitelist[name] = true
            privat.Class.whitelist:save(privat.whitelist)
            return true
        end

    end

    function obj:remove_whitelist(name)
        if privat.whitelist[name] == nil then
            return false
        else
            privat.whitelist[name] = nil
            privat.Class.whitelist:save(privat.whitelist)
            return true
        end
    end

    function privat:message_whitelist(name)
        local msg = "К сожалению, "..name.." нет в белом списке. Для получения доступа авторизируйтесь на сервере: "..config.url
        return msg
    end

    -- ip --
    function privat:is_ip_addres(name)
        local ip
        ip = privat:to_ip(name)
        if ip ~= false then
            return ip
        else
            return name
        end
    end

    function privat:to_ip(ip)
        if string.find(ip,".") == nil then
            return false
        end
        local data = string.split(ip,".")
        if data == nil or #data ~= 4 then
            return false
        end
        return data[1].."."..data[2].."."..data[3]..".X"
    end

    function privat:ip_eq_ip(ip1,ip2)
        if string.find(ip1,".") == nil then
            return false
        end
        local data1 = string.split(ip1,".")
        if data1 == nil or #data1 ~= 4 then
            return false
        end

        if string.find(ip2,".") == nil then
            return false
        end
        local data2 = string.split(ip2,".")
        if data2 == nil or #data2 ~= 4 then
            return false
        end

        if data1[1] == data2[1] and data1[2] == data2[2] and data1[3] == data2[3] then
            return true
        end
        return false
    end

    function privat:check_ip(ip)
        if privat.cache.ip[ip] ~= nil then
            return privat:message_ip(ip)
        else
            return true
        end
    end

    function privat:message_ip(name)
        name = privat:to_ip(name)
        local msg = "К сожалению, пул ip: "..name.." заблокирован. Для выяснения подробностей обратитесь к администратору: "..config.url
        return msg
    end

    function privat:gen_cache_ban()
        local cache_ip = {}
        local banned = {}
        for name, data in pairs(privat.database) do
            banned[name] = true
        end
        -- {name:{{data,data},{data,data}},name:{{data,data},{data,data}}}
        for name, data in pairs(privat.join_history) do
            if banned[name] then
                for i,v in pairs(data) do
                    if v.ip ~= nil then
                        cache_ip[v.ip] = name
                    end
                end
            end
        end
        privat.cache = {}
        privat.cache.ip = cache_ip
        return cache_ip
    end
    -- BANS --
    function privat:check_ban(name,role,is_guest,identifiers)
        if obj:is_banned(name) == true then
            return privat:ban_message(name)
        end
        local ip = identifiers.ip
        if ip ~= nil and privat.cache.ip ~= nil and privat.cache.ip[ip] ~= nil then
            name = privat.cache.ip[ip]
            if obj:is_banned(name) == true then
                return privat:ban_message(name)
            end
        end
    end

    function obj:add_ban(name,duration,reason)
        -- duration - в секундах
        name = privat:is_ip_addres(name)
        local time = os.time() + duration
        privat.database[name] = {endtime = time,reason=reason or "Не указано. Для получения подробностей обратитесь к администратору: "..config.url}
        privat.Class.banlist:save(privat.database)
    end

    function obj:remove_ban(name)
        privat.database[name] = nil
        privat.Class.banlist:save(privat.database)
    end

    function obj:is_banned(name)
        if privat.database[name] == nil then
            return false
        end
        if os.time() >= privat.database[name].endtime then
            privat.database[name] = nil
            return false
        end
        return true
    end

    function obj:update_bans()
        for name,data in pairs(privat.database) do
            if os.time() >= data.endtime then
                privat.database[name] = nil
            end
        end
        privat.Class.banlist:save(privat.database)
    end

    function obj:get_endtime(name)
        if privat.database[name] == nil then
            return false
        end
        return privat.database[name].endtime
    end

    function privat:ban_message(name)
        local msg = "Вы были заблокированы. \nПричина: "..privat.database[name].reason.." \nОсталось: "..os.date("%d.%m.%Y %H:%M:%S",privat.database[name].endtime-os.time()).." \nОбжаловать бан можно в Дискорде: "..config.url
        return msg
    end

    -- JOIN HISTORY --
    function obj:get_join_history(name)
        return privat.join_history[name] or {}
    end

    function obj:add_history(name,data,role)
        privat.join_history[name] = privat.join_history[name] or {}
        privat.join_history[name][#privat.join_history[name]+1] = {data=data,time=os.time(),role = role}
        privat.Class.join_history:save(privat.join_history)
    end

    --чистая магия!
    return obj
end

MutedPlayers = MutedPlayers or {} -- {name:endtime}

local banSystem = BanSystem:init()

function onPlayerAuth(name, role, is_guest, identifiers)
    local result = banSystem:check(name,role,is_guest,identifiers)
    if result ~= true then
        return result
    end
end

function WHITELIST_ADD(sender_id, sender_name, message)
    local res = banSystem:add_whitelist(message)
    if not res then
        SendMessage(sender_id, "Пользователь "..message.." добавлен в белый список.")
    else
        SendMessage(sender_id, "Пользователь "..message.." уже в белом списке.")
    end
end

function WHITELIST_DEL(sender_id, sender_name, message)
    local res = banSystem:remove_whitelist(message)
    if not res then
        SendMessage(sender_id, "Пользователь "..message.." удален из белого списка.")
    else
        SendMessage(sender_id, "Пользователь "..message.." не в белом списке.")
    end
end
--

function UNBAN(sender_id, sender_name, message)
    banSystem:remove_ban(message)
	SendMessage(sender_id, "Пользователь "..message.." разблокирован.")
	return 1
end

function KICK(sender_id, sender_name, message)
	MP.DropPlayer(MP.GetId(message))
    statistic:addInfo(message,"KICK",1)
	SendMessage(sender_id,message.." был кикнут.")
end

local function NextBan(player_id,reason)
    MP.DropPlayer(player_id, reason)
end


function MUTEPLAYER(sender_id, sender_name, message)
    -- todo: !mute <name> <duration> <reason>
    local case = split(message, " ")
    if case == nil or #case < 1 then
        SendMessage(sender_id,"Неверное количество аргументов")
    end
    local name = erors2(case[1],1)
    if name == false then
        SendMessage("Игрок "..case[1].." не найден.")
        return
    end
    if MutedPlayers[name] ~= nil then
        SendMessage(sender_id,"Игрок "..name.." уже замьючен. Длительность: "..os.date("%d.%m.%Y %H:%M:%S",MutedPlayers[name]-os.time()))
        return
    end
    local duration = timeConverter(case[2]) or timeConverter("3h")
    table.remove(case, 1)
    table.remove(case, 1)
    local reason = "Узнать подробности можно в Дискорде. "..M.config.url
    if case ~= nil and #case >= 1 then
        reason = table.concat(case, " ")
    end
    MutedPlayers[name] = os.time()+duration
    SendMessage(sender_id,"Игрок "..name.." замьючен. Длительность: "..os.date("%d.%m.%Y %H:%M:%S",duration))
    SendMessage(MP.GetId(name),name.." - Вам выдана блокировка. Причина: "..reason)
end

function UNMUTEPLAYER(sender_id, sender_name, message)
    local name = erors2(message,1)
    if name == false then
        SendMessage("Игрок "..message.." не найден.")
        return
    end
    if MutedPlayers[name] == nil then
        SendMessage(sender_id,"Игрок "..name.." не замьючен.")
        return
    end
    MutedPlayers[name] = nil
    SendMessage(sender_id,"Игрок "..name.." размьючен.")
end

function BAN(sender_id, sender_name, message)
    -- todo: !ban <name> <duration> <reason>
    local case = split(message, " ")
    if case == nil or #case < 1 then
        SendMessage(sender_id,"Неверное количество аргументов")
    end
    local name = erors2(case[1],1)
    if name == false then
        SendMessage("Игрок "..case[1].." не найден.")
        return
    end
    local duration = timeConverter(case[2]) or timeConverter("3d")
    table.remove(case, 1)
    table.remove(case, 1)
    local reason = "Узнать подробности можно в Дискорде. "..M.config.url
    if case ~= nil and #case >= 1 then
        reason = table.concat(case, " ")
    end
    banSystem:add_ban(name,duration,reason)
    SendMessage(sender_id,name.." был забанен. Причина: "..reason..". Осталось: "..os.date("%d.%m.%Y %H:%M:%S",banSystem:get_endtime(name)-os.time()))
	if MP.check_in_online(name) == true then
        -- todo: тут какая то странная ошибка.
        --> [Economic_Plugin] [WARN] [GetId] "Error. Player: BeamMP_RP_Plugin is missing"  - из за бана. Хз как чинить
        --> [08/12/24 23:17:43] [LUA ERROR] TriggerLocalEvent: stack index 1, expected number, received nil: not a numeric type that fits exactly an integer (number maybe has significant decimals) (bad argument into 'sol::basic_table_core<false, sol::basic_reference<false> >(int)') - из за бана. Хз как чинить
        HeventTimer.Createtask(15,NextBan,sender_id.."BAN",{player_id,reason})
		--MP.DropPlayer(player_id,reaseon)
		local mess = name.." был забанен"
		SendMessage(-1,mess)
        statistic:addInfo(name,"BANNED",1)
	else
        SendMessage(sender_id, name.." был забанен")
	end
end

function checkUnban()
    banSystem:update_bans()
end

M.config = config
M.command = {
	{command = "unban", help ="Разбан игрока. ",args="[name]",func ="UNBAN",roles = {"admin"}},
    {command = "unmute", help ="Размьют игрока. ",args="[name]",func ="UNMUTEPLAYER",roles = {"moderator","admin","moder"}},
    {command = "mute", help ="Заткнуть игрока. ",args="[name] <duration> <reason можно не в 1 слово>",func ="MUTEPLAYER",roles = {"moderator","admin","moder"}},
	{command = "kick", help ="Кик Игрока. ",args="=[name]",func ="KICK",roles = {"moderator","admin","moder"}},
	{command = "ban", help ="Бан со ссылкой на сервер. ",args="[name] <duration> <reason можно не в 1 слово>",func ="BAN",roles = {"admin"}},
    {category = "whitelist",command = "add", help ="Добавить в белый список. ",args="[name]",func ="WHITELIST_ADD",roles = {"admin"}},
    {category = "whitelist",command = "del", help ="Удалить из белого списка. ",args="[name]",func ="WHITELIST_DEL",roles = {"admin"}},
}
function M.load()
    HeventTimer.addFunc(checkUnban, 60*30) -- 30 мин
	MP.RegisterEvent("onPlayerAuth","onPlayerAuth")
end

-- Ban.ixt
-- {ip={"127.0.0.1"="reason",},name={"lox"="reason",},beamid = {"dasd"="reason",}}
-- local temporaryBanIp = {} -- Бан на 1 запуск сервера

--getUserApi
function getBeamIDFromApi(name)
    local apiurl = "https://forum.beammp.com/u/"
    local response = httpRequest(apiurl .. name .. ".json")
    if response ~= "" then
        local jsonResponse = Util.JsonDecode(response)
        return jsonResponse.user.id -- beam id
    else
        return nil
    end
end

local PREVIOUS_POSITION = {}
local AFK_TIMER = {}

function CheckAFK()
    local function compareFloats(a, b, epsilon)
        return math.abs(a - b) < epsilon
    end
    local players = MP.GetPlayers()

    for k, v in pairs(players) do
    local playerveh = MP.GetPlayerVehicles(k)
        for _, v2 in pairs(playerveh or {}) do
            local username, num1, num2 = string.match(v2, '(%w+):(%d+)-(%d+)')
            local vehRaw = MP.GetPositionRaw(tonumber(num1), tonumber(num2))
            if vehRaw ~= nil then
                local previousPos = PREVIOUS_POSITION[num2]

                if previousPos ~= nil and
                    compareFloats(previousPos[1], vehRaw.pos[1], 0.001) and
                    compareFloats(previousPos[2], vehRaw.pos[2], 0.001) and
                    compareFloats(previousPos[3], vehRaw.pos[3], 0.001) then
                    local afkTime = (AFK_TIMER[num2] or 0) + 1
                    if afkTime >= 60*config.StopWork and afkTime <= (60*config.StopWork)+2 then
                        pay = work:stop(v)
                        SendMessage(k,"Вы ^lПРИНУДИТЕЛЬНО^r закончили работать. Вам заплатили: "..pay.." "..config.currency)
                    end
                    if afkTime >= 60*config.DeleteCarWithAFK then
                        MP.RemoveVehicle(k, tonumber(num2))
                        MP.SendChatMessage(k, "Ваш транспорт удалён по причине отсутствия движения.")
                        AFK_TIMER[num2] = nil
                    else
                        AFK_TIMER[num2] = afkTime
                    end
                else
                    AFK_TIMER[num2] = 0
                    PREVIOUS_POSITION[num2] = {vehRaw.pos[1], vehRaw.pos[2], vehRaw.pos[3]}
                end
            end
        end
    end
end
--HeventTimer.addFunc("CheckAFK", 1000)
return M

