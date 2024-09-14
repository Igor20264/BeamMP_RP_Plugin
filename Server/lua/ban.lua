local M = {}
local temporaryBanIp = {}
local last_join = {name={ip="ip",jointime=os.time()}} -- если пользователей с одним ip, несколько (3 и более), то ip отлетает в бан
local withelist = load_database("whitelist.ixt") or {}
local ban = load_database("banlist.ixt") or {name={},ip={}}
config.withelist = true
local ignore_ip = {"89.250.2.140"}
local function check_ip_duplication()
    local ips = {}
    for name,data in pairs(last_join) do
        if not ips[data.ip] then
            ips[data.ip] = 1
        elseif ips[data.ip] >= 2 then
            log("ip "..data.ip.." is duplicate NAKRUTKA",5)
            temporaryBanIp[data.ip] = true
        end
    end
end

local function add_whitelist(name)
    withelist[name] = true
    save_database("whitelist.ixt",withelist)
end
local function remove_whitelist(name)
    withelist[name] = nil
    save_database("whitelist.ixt",withelist)
end
local function bans(type, data, reason)
    reason = reason or "Узнать подробности бана можно в Дискорде. " .. config.url
    ban[type][data] = reason
    save_database("banlist.ixt",ban)
end
local function unban(type, data)
    ban[type][data] = nil
    save_database("banlist.ixt",ban)
end

function onPlayerAuth(name, role, is_guest, identifiers)
    local ip = identifiers.ip
    ban.name = ban.name or {}
    ban.ip = ban.ip or {}
    last_join[name] = {ip=ip,jointime=os.time()}
    if temporaryBanIp[ip] == true and ignore_ip[ip] == nil then
        return "[TIP] Узнать подробности блокировки можно в Дискорде. "..M.config.url
    end
    if is_guest == true then return "Для игры на этом сервере необходимо иметь аккаунт BeamMP. \nПожалуйста, зарегистрируйтесь." end
    if config.withelist == true then
        if withelist[name] == nil then
            return "Для игры на этом сервере вам необходимо пройти проверку на сервере. " .. config.url
        end
    end
    if type(ban.name[name]) ~= "nil" then
        return ban.name[name] or "[NA] Узнать подробности бана можно в Дискорде: " .. config.url
    end
    if type(ban.ip[ip]) ~= "nil" then
        return ban["ip"][ip] or "[IP] Узнать подробности бана можно в Дискорде. "..M.config.url
    end
    check_ip_duplication()
end
 
function UNBAN(sender_id, sender_name, message)
	local name = split(message, " ")[1]
	unban("name", name)
	SendMessage(sender_id, message)
	return 1
end

function WHITELIST_ADD(sender_id, sender_name, message)
    if withelist[message] == nil then
        add_whitelist(message)
        SendMessage(sender_id, "Пользователь "..message.." добавлен в белый список.")
    else
        SendMessage(sender_id, "Пользователь "..message.." уже в белом списке.")
    end
end

function WHITELIST_DEL(sender_id, sender_name, message)
    if withelist[message] ~= nil then
        remove_whitelist(message)
        SendMessage(sender_id, "Пользователь "..message.." удален из белого списка.")
    else
        SendMessage(sender_id, "Пользователь "..message.." не в белом списке.")
    end
end

function CLEARTEMPBANIP(sender_id, sender_name, message)
    temporaryBanIp = {}
    return 1
end

function UBNANIP(sender_id, sender_name, message)
    local name = split(message, " ")[1]
    unban("ip", name)
    if temporaryBanIp[name] ~= nil then
        temporaryBanIp[name] = nil
    end
    SendMessage(sender_id, message)
    return 1
end

function GETALLBANIP(sender_id, sender_name, message)
    local mess = ""
    for k,v in pairs(ban.ip) do
        mess = mess..k.."\n"
    end
    SendMessage(sender_id, mess)
    return 1
end

function KICK(sender_id, sender_name, message)
	MP.DropPlayer(MP.GetId(message))
	SendMessage(sender_id,message.." был кикнут.")
end

function BAN(sender_id, sender_name, message)
	local name = erors(split(message," ")[1],2)
	local reaseon = split(message," ")[2] or ("Узнать подробности можно в Дискорде. "..M.config.url)
	if MP.check_in_online(name) == true then
        bans("name", name, reaseon)
        bans("ip", MP.GetIp(name), reaseon)
        temporaryBanIp[MP.GetIp(name)] = true
		MP.DropPlayer(MP.GetId(name),reaseon)
		local mess = name.." был забанен"
		SendMessage(-1,mess)
	else 
		bans("name", name, reaseon)
        temporaryBanIp[MP.GetIp(name)] = true
        SendMessage(sender_id, name.." был забанен")
	end
end

M.config = config
command = {
	{command = "unban", help ="Разбан игрока. ",args="[name]",func ="UNBAN",roles = {"admin"}},
	{command = "kick", help ="Кик Игрока. ",args="=[name]",func ="KICK",roles = {"moderator","admin"}},
	{command = "ban", help ="Бан со ссылкой на сервер. ",args="[name] [reason_slovo_slovo_slov]",func ="BAN",roles = {"admin"}},
    {command = "unip", help ="Разбан IP. ",args="[ip]",func ="UBNANIP",roles = {"admin"}},
    {command = "getallip", help ="Получить все забаненные IP. ",func ="GETALLBANIP",roles = {"admin"}},
    {command = "cleartempip", help ="Очистить список забаненных IP. ",func ="CLEARTEMPBANIP",roles = {"admin"}},
    {category = "whitelist",command = "add", help ="Добавить в белый список. ",args="[name]",func ="WHITELIST_ADD",roles = {"admin"}},
    {category = "whitelist",command = "del", help ="Удалить из белого списка. ",args="[name]",func ="WHITELIST_DEL",roles = {"admin"}},
}
M.command = command
function M.load()
	MP.RegisterEvent("onPlayerAuth","onPlayerAuth")
end

function M.unload()
	save_database("banlist.ixt",ban)
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

