function lev_iter(strA,strB) -- Creates a 2D matrix
    local function matrix(row,col)
        local m = {}
        for i = 1,row do m[i] = {}
            for j = 1,col do m[i][j] = 0 end
        end
        return m
    end

    local M = matrix(#strA+1,#strB+1)
    local cost
    local row,col = #M,#M[1]
    for i = 1,row do M[i][1] = i-1 end
    for j = 1,col do M[1][j] = j-1 end

    for i = 2,row do
        for j = 2,col do
            if (strA:sub(i-1,i-1) == strB:sub(j-1,j-1)) then
                cost = 0
            else
                cost = 1
            end
            M[i][j] = math.min(M[i-1][j]+1,M[i][j-1]+1,M[i-1][j-1]+cost)
        end
    end
    return M[row][col]
end

Gen = Gen or {}
Color = Color or {}
Format = Format or {}
--[[
Добавляет деньги пока игроки не играют. А если денег много снимает
function SaS(id,percent_cfg,limit_percent)
	if eco.s[id][4] >= limit_percent then 
		local procent = round(((eco.s[id][4]+1)/100)*percent_cfg)
		eco.s[id][4] = eco.s[id][4]-procent
	else	
		local procent = round(((eco.s[id][4]+1)/100)*percent_cfg)
		eco.s[id][4] = eco.s[id][4]+procent
	end
	return eco.s[id][3]
end
]]
--

function Format.Money(amount) -- str or int
    local formatted = tostring(amount)
    local data = split(formatted,'.')
    if #data[2] > 2 then
        formatted = data[1]..'.'..data[2]:sub(1,2)..' '..config.currency
    elseif #data[2] <= 2 then
        formatted = data[1]..'.'..data[2]..' '..config.currency
    else
        formatted = data[1]..' '..config.currency
    end
    return formatted
end


-- "2023-10-05 14:30:00"
function parseDate(dateString)
    local pattern = "(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)"
    local year, month, day, hour, min, sec = dateString:match(pattern)
    return { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end


function split(inputstr, sep) 
	if sep == nil then sep = "%s" end 
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
	return t
end

function string:split(sep)
    if sep == nil then sep = "%s" end
    local t={}
    for str in string.gmatch(self, "([^"..sep.."]+)") do table.insert(t, str) end
    return t
end

local RegCaches = RegCaches or {}

local function GenReg()
	while true do
		local dts = Gen.generateRandomData(6)
		if RegCaches[dts] == nil then
			RegCaches[dts] = dts
		    return dts
		end
	end
end

function RegEvent(KRF)
	local cmd = {}
	for i,case in ipairs(KRF) do
	    if case.client then
	        MP.RegisterEvent(case.reg,case.func)
        else
            local rego = GenReg()
            MP.RegisterEvent(rego,case.func)
		    cmd[i] = {category = case.category or nil,reg = rego,command = case.command,args=case.args or "",help = case.help,func=case.func,admin=case.admin or false,hide = case.hide or false, roles= case.roles or {"player"}}
        end
	end
	return cmd
end

-- Generator

function Gen.uuid()
    local seed={'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
    local tb={}
    math.randomseed(os.clock()*os.clock())
    for i=1,32 do
        table.insert(tb,seed[Util.RandomIntRange(1,16)])
    end
    local sid=table.concat(tb)
    return string.format('%s-%s-%s-%s-%s',
        string.sub(sid,1,8),
        string.sub(sid,9,12),
        string.sub(sid,13,16),
        string.sub(sid,17,20),
        string.sub(sid,21,32)
    )
end

function Gen.generateRandomData(size)
  local chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ0123456789'
  local charTable = {}
  for c in chars:gmatch"." do
	  table.insert(charTable, c)
  end
  local res = ''
  for i = 1, size do
	res = res .. charTable[Util.RandomIntRange(1, #charTable)]
  end
  return res
end

-- Color
function is_integer(data)
    if type(data) == "number" then
        return true
    end
    local status, result = pcall(tonumber,data)
	if not status or result == nil then
		return false
	end
	return data == tostring(math.floor(result))
end

function string:is_integer()
	local status, result = pcall(tonumber,self)
	if not status or result == nil then
		return false
	end
	return self == tostring(math.floor(result))
end

function levi(name,list,len_iter)
    len_iter = len_iter or 1
	for _,case in ipairs(list) do
		if lev_iter(name,case) <= len_iter then
			return case
		end
	end
	return name
end

function erors(name,levenhtein)
	for i,case in pairs(MP.GetPlayers()) do
		if lev_iter(name,case) <= levenhtein then 
			return case 
		end
	end
	return name
end

function concat(...)
    local result = {}
        for i, tbl in ipairs({...}) do
            for k, v in pairs(tbl) do
            if type(k) ~= "number" then
                result[k] = v
            else
                result[i] = v
            end
        end
    end

    return result
end

function try_exept(func,...)
    local status, result = pcall(func,...)
    if not status then
        --local s = split(debug.getinfo(func).source,"\\")
        --log({"file: "..s[#s].." "..result},4)
        log({"file: "..result},4)
        return falselu
    end
    return result
end
--[[
function number:round(p)
    p = p or 2
    return tonumber(string.format("%."..p.."f",self))
end
--]]

function round(numder,p)
	local p = p or 2
	return tonumber(string.format("%."..p.."f",numder)) 
end

function table.shallow_copy(self)
		local t = {}
		for k,v in pairs(self) do
			t[k] = v
		end
		return t
	end

function table.merge(t1, t2)
    -- Проверяем, что t1 является таблицей
    if type(t1) ~= "table" then
        t1 = {}  -- Если нет, инициализируем t1 как пустую таблицу
    end

    -- Проверяем, что t2 является таблицей
    if type(t2) ~= "table" then
        return t1  -- Если t2 не таблица, просто возвращаем t1
    end

    for _, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function MP.GetId(name)
	local ret = MP.GetPlayerIDByName(name)
	if ret == -1 then 
		log("Error. Player: "..name.." is missing",4)
		return nil
	elseif nmae == "CMD" then
        return -2
	else
		return ret
	end
end

function timeConverter(time)
    local oldtime = time

    local time = time:lower()
    local time = time:gsub(" ", "")
    local time = time:gsub("s", "")
    local time = time:gsub("m", "")
    local time = time:gsub("h", "")
    local time = time:gsub("d", "")
    local time = tonumber(time)
    if time == nil then
        return nil
    end
    if oldtime:lower():find("s") then
        return time
    elseif oldtime:lower():find("m") then
        return time * 60
    elseif oldtime:lower():find("h") then
        return time * 60 * 60
    elseif oldtime:lower():find("d") then
        return time * 60 * 60 * 24
    else
        return nil
    end
end

function sectotime(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds - (days * 86400)) / 3600)
    local minutes = math.floor((seconds - (days * 86400) - (hours * 3600)) / 60)
    local seconds = seconds - (days * 86400) - (hours * 3600) - (minutes * 60)
    return days, hours, minutes, seconds
end

function MP.GetBeamId(name)
	local id = MP.GetId(name)
	local tablinfo = MP.GetPlayerIdentifiers(id)
	return tablinfo.beammp or -1
end

function MP.GetIp(name)
	local id = MP.GetId(name)
	local tablinfo = MP.GetPlayerIdentifiers(id)
	return tablinfo.ip
end

function MP.check_in_online(player_name)
	if type(player_name) == "number" then
        log("This function is not supported for numbers",4)
		return nil
	end
	for _,name in pairs(MP.GetPlayers()) do
		if name == player_name then return true end
	end
	return false
	end

-- обработчик сообщений
function MessageParser(message, sep, levenhtein) -- return Name:str, message:table
	local box = split(message,sep)
	local player = box[1]
	table.remove(box, 1)
	if player == nil or player == "" then
		return player,box
	else
        if player == "CMD" then
            return player,box
        else
            player = erors(player,levenhtein)
            return player,box
        end
	end
end

-- api


-- Color
--[[

^r 	reset
^p 	newline (descriptions only)
^n 	underline
^l 	bold
^m 	strike-through
^o 	italic
^0 	black
^1 	blue
^2 	green
^3 	light blue
^4 	red
^5 	pink
^6 	orange
^7 	grey
^8 	dark grey
^9 	light purple
^a 	light green
^b 	light blue
^c 	dark orange
^d 	light pink
^e 	yellow
^f 	white
--]]