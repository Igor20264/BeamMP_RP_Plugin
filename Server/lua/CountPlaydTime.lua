local M = {}
local PlaydTime = {}
M.info = "Система счетчика времени"
M.ver = "BETA 0.1"


function PlaydTime:init()
    local private = {}
    local public = {}
    function public:init_user(username)
        if eco.database[username] ~= nil and eco.database[username]["playdtime"] == nil then
            eco:set(username, "playdtime", 0) -- Каждые 10 минут
            return true
        elseif eco.database[username] ~= nil and eco.database[username]["playdtime"] ~= nil then
            return true
        end
        return false
    end

    function public:getall()
        local ret = {}
        for i,data in pairs(eco.database) do
            if data["playdtime"] ~= nil then
                ret[#ret+1] = {playd = data["playdtime"], name = i}
            end
        end
        return ret
    end

    function public:get(player)
        if public:init_user(player) then
            return eco:value(player, "playdtime")
        end
        return nil
    end

    function public:add(player,time)
        if public:init_user(player) then
            eco:add(player, "playdtime", time)
        end
    end

    function public:set(player,time)
        if public:init_user(player) then
            eco:set(player, "playdtime", time)
        end
    end

    --чистая магия!
    setmetatable(public, self)
    self.__index = self
    return public
    end
-- Посмотреть список игроков которые отыграли более x часов (адм)

function GET_PLAYTIME(sender_id,sender_name, message)
    -- message = 1 -- час
    if message == nil then
        SendMessage(sender_id,"Отстутствует параметр. Пример: 1")
        return
    end

    local ret = playdtimeexmp:getall()
    local s = ''
    for i,data in ipairs(ret) do
        if i >= 150 then break end
        if data.playd >= message*60*60 then
            s = s..data.name..' - '..round(data.playd/(60*60),0)..' h\n'
        end
    end
    if s == '' then
        SendMessage(sender_id,"Никто столько не играл.")
    else
        SendMessage(sender_id,s)
    end

end

function GET_TOP(sender_id,sender_name, message)
    local ret = playdtimeexmp:getall()
    table.sort(ret,function(a,b) return a.playd>b.playd end)
    local s = ''
    for i,data in ipairs(ret) do
        if i >= 10 then break end
        s = s..data.name..' - '..round(data.playd/(60*60),0)..' h\n'
    end
    if s == '' then
        SendMessage(sender_id,"Никто не играл.")
    else
        SendMessage(sender_id,s)
    end

end

function GET_PLAYTIME_Player(sender_id,sender_name, message)
    local name = erors(message,2)
    local ret = playdtimeexmp:get(name)
    if ret == nil then
        SendMessage(sender_id,"Игрок мало наиграл.")
    else
        if type(ret) == "string" then
            ret = tonumber(ret)
        end
        SendMessage(sender_id,name.." наиграл "..round(ret/(60*60),0).." h")
    end
end

function GET_MY_PLAYTIME(sender_id,sender_name, message)
    local ret = playdtimeexmp:get(sender_name)
    if ret == nil then
        SendMessage(sender_id,"Вы мало поиграли.")
    else
        if type(ret) == "string" then
            ret = tonumber(ret)
        end
        SendMessage(sender_id,"Вы играли "..round(ret/(60*60),0).." h")
    end
end

playdtimeexmp = PlaydTime:init()

function AddPlayTime()
    for _, player in pairs(MP.GetPlayers()) do
        playdtimeexmp:add(player, 10*60)
        local ret = playdtimeexmp:get(sender_name) or 0
        if ret ~= nil then
            if type(ret) == "string" then
                ret = tonumber(ret)
            end
            RemoutRun(-1, "setPlayerNickPrefix('"..player.."', '"..(eco:value(player, "playdtime")).."h')")
        end
    end
end

M.command = {
    {category = "time", command = "my", help = "Узнать сколько времени наиграл",func= "GET_MY_PLAYTIME"},
    {category = "time", command = "get", help = "Узнать сколько времени наиграл игрок",func= "GET_PLAYTIME_Player", args = "[name]",roles={"admin","moderator"}},
    {category = "time", command = "top", help = "Узнать топ игроков",func= "GET_TOP"},
    {category = "time", command = "more", help = "Узнать сколько времени наиграл всех",func= "GET_PLAYTIME", args = "[time]",roles={"admin","moderator"}},
}
function M.load()
    HeventTimer.addFunc(AddPlayTime, 10*60) -- функ, сек
end

function M.unload()
end

return M