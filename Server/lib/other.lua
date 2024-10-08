function lev_iter(strA,strB) -- Creates a 2D matrix
    local function matrix(row,col)
        local m = {}
        for i = 1,row do m[i] = {}
            for j = 1,col do m[i][j] = 0 end
        end
        return m
    end

    local M = matrix(#strA+1,#strB+1)
    local i,j,cost
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


function split(inputstr, sep) 
	if sep == nil then sep = "%s" end 
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
	return t
end

function extended(child, parent)
    setmetatable(child,{__index = parent})
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

function Color.purple(text)
    return "^c"..text.."^f"
end

function Color.cyan(text)
    return "^6"..text.."^f"
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

function Util:hex2rgb(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

function Util:rgb2hex(r,g,b)
    return string.format("#%02x%02x%02x",
        math.floor(r),
        math.floor(g),
        math.floor(b))
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

local function off_checkForUpdates()

    -- Récupérer la version actuelle de votre script local à partir de version.txt
    local oldversion = io.open(VERSIONPATH, "r")
    local localVersion = oldversion:read()
    oldversion:close()

    --retire les deux premier caractères de localVersion (--)
    localVersion = string.sub(localVersion, 3)



    --this go to this https://api.github.com/repos/boubouleuh/Nickel-BeamMP-Plugin/releases/latest

    local response = Util.JsonDecode(httpRequest("https://nickel.martadash.fr/version.txt"))

    if response == nil then
        log("Get remote version failed to check update !",5)
        return
    end
    -- Récupérer la version distante à partir de la réponse

    local remoteVersion = response.tag_name

    if remoteVersion == nil then
        log("Get remote version failed to check update (Check server probably down) ! Try again later ! If it keep happening ask for help in the discord : https://discord.gg/h5P84FFw7B",5)
        return
    end

    -- Comparer les versions locales et distantes
    if remoteVersion > localVersion then
        -- Effectuer la mise à jour
        if getConfigValue("AUTOUPDATE") == "false" then

            log("An update is available ! " .. localVersion .. " -> " .. remoteVersion .. "\nAUTOUPDATE is deactivated in " .. CONFIGPATH .. " if you want to update automatically, set it to true",4)

            return
        else
            local url = "https://raw.githubusercontent.com/boubouleuh/Nickel-BeamMP-Plugin/" .. remoteVersion .. "/main.lua"
            local response = httpRequest(url)
            --if download fail
            if response == nil then
                log("Update failed !",5)
                return
            else
                log("Update downloaded !",3)
            end
            -- Écrire la réponse dans un fichier pour mettre à jour votre script
            local main = io.open(script_path() .. "main.lua", "w")
            main:write(response)
            main:close()

            -- Mettre à jour la version locale dans version.txt
            local newversion = io.open(VERSIONPATH, "w")
            newversion:write("--" .. remoteVersion)
            newversion:close()

            log("Update done !",3)
        end

    end

end

function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and io.close(f)
end

local function off_httpRequest(url)
    if MP.GetOSName() == "Windows" then
        local cmd = 'powershell -Command "Invoke-WebRequest -Uri ' .. url .. ' -OutFile temp.txt"'
        local response = os.execute(cmd)

        if response then
            local file = io.open("temp.txt", "r")
            local content = file:read("*all")
            file:close()
            os.remove("temp.txt")
            return content
        else
            return ""
        end
    else
        -- Utiliser une méthode non-Windows (par exemple, wget)
        local response = os.execute("wget -q -O temp.txt " .. url)
        if response then
            local file = io.open("temp.txt", "r")
            local content = file:read("*all")
            file:close()
            os.remove("temp.txt")
            return content
        else
            return ""
        end
    end
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


function emessage(message,key)
    local function bxor(a, b)
        local r = 0
        for i = 0, 31 do
            local x = a / 2 + b / 2
            if x ~= math.floor (x) then
                r = r + 2^i
            end
            a = math.floor (a / 2)
            b = math.floor (b / 2)
        end
        return r
    end

    local function xor(message, key)
        if type(message) ~= "string" then
            error("bad argument #1 to 'xor' (string expected, got "..type(message)..")")
        end
        if type(key) ~= "string" then
            error("bad argument #2 to 'xor' (string expected, got "..type(key)..")")
        end
        nKey =''
        for i=1, #key do
            nKey = nKey..key:byte(i)
        end
        math.randomseed(tonumber(nKey) % 0x100000000)

        tKey = {}
        sNewKey = ''
        for j = 1, #message do
            tKey[j] = ''
            while string.len(tKey[j]) ~= string.len(message.byte(j)) do
                tKey[j] = tKey[j]..math.random(0, 9) -- создаем рандомный код для ключа
            end
            sNewKey = sNewKey..string.char(bxor(message:byte(j), tKey[j])) -- записваем результат
        end
        return sNewKey
    end
    return xor(message,key)
end

function print_color(message, color)
	local colors = {
		black = "\27[30m",
		red = "\27[31m",
		green = "\27[32m",
		yellow = "\27[33m",
		blue = "\27[34m",
		magenta = "\27[35m",
		cyan = "\27[36m",
		white = "\27[37m",
		gray = "\27[90m",
	}
    if not colors[color] then
      color = "white"
    end
    return colors[color] .. message .. "\27[0m"
end

function decimalToHex(decimal)
    return string.format("%X", decimal)
end

function hexToDecimal(hex)
	print(type(hex),hex)
    return tonumber(hex, 16)
end

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

-- Server Config

function Util.ServerConfigToml_Get()
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