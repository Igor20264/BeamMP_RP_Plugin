lev_iter = (require 'lib/levinshetin')

-- small func
log("Load_Small_Fucn",3)
function split(inputstr, sep) 
	if sep == nil then sep = "%s" end 
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
	return t
end

function toboolean(str)
    local bool = false
    if str == "true" or str == "1" or str == "True" or str == "TRUE" then
        bool = true
    end
    return bool
end

function generateRandomData(size)
  local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZабвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ0123456789'
  local charTable = {}
  for c in chars:gmatch"." do
	  table.insert(charTable, c)
  end
  local res = ''
  for i = 1, size do
	res = res .. charTable[math.random(1, #charTable)]
  end
  return res
end

function erors(name,levenhtein)
	for i,case in pairs(MP.GetPlayers()) do
		if lev_iter(name,case) <= levenhtein then 
			return case 
		end
	end
	return name
end
function erors2(name,levenhtein)
	for name_inDB,_ in pairs(eco.database) do
		if lev_iter(name,name_inDB) <= levenhtein then
			return name_inDB
		end
	end
	return false
end


function round(numder,p)
	local p = p or 2
	return tonumber(string.format("%."..p.."f",numder)) 
end

function table.shallow_copy(t)
		local t = {}
		for k,v in pairs(t) do
			t[k] = v
		end
		return t
	end

function table.merge(t1,t2)
	for _,v in ipairs(t2) do 
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
	else
		return ret
	end
end

function MP.GetBeamId(name)
	local id = MP.GetId(name)
	local tablinfo = MP.GetPlayerIdentifiers(id)
	return tablinfo.beammp
end

function MP.GetIp(name)
	local id = MP.GetId(name)
	local tablinfo = MP.GetPlayerIdentifiers(id)
	return tablinfo.ip
end

function MP.check_in_online(player_name)
	if type(player_name) == "number" then 
		local player_name = MP.GetPlayerName(player_name) 
	end
	for i,name in pairs(MP.GetPlayers()) do
		if name == player_name then return true end
	end
	return false
	end

--[[
function log(message)
	if M.logs == true then
		if M.debugs then print(debug.traceback()) end
		printRaw("["..M.pluginName.."] ["..debug.getinfo(1).what.."] " .. tostring(message))
	end
end
--]]
-- Server Config

function ServerConfigToml_Get()
	local function getMapName(s)
		local c = s:match( "^%s*Map%s*=%s*(.-)%s*$" )
		if not c then return nil end
		c =c:sub(2,#c-1) 
		c = c:match( "^/-levels/(.+)/" )
		return c
	end 
	for line in io.lines("ServerConfig.toml") do
		print(line)
		if getMapName(line) then
			mapName = getMapName(line)
			break
		end
	end
end


-- обработчик сообщений
function MessageParser(message, sep, levenhtein) -- return Name:str, message:table
	local box = split(message,sep)
	local player = box[1]
	table.remove(box, 1)
	if player == nil or player == "" then
		return player,box
	else
		local player = erors(player,levenhtein)
		return player,box
	end
end
 