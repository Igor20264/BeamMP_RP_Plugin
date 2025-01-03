M = {}

local req_save_database = req_save_database or {}

local function gettime() -- return in seconds
    return os.time()-1.69981e+09
end

-- Запрос на сохранение базы данных в файл
function request_save_database(namefile,data)
    log(namefile,3)
    req_save_database[namefile] = {data=data,time=gettime()+config.REQUEST_SAVE_DATABASE_TIME_SEC}
end

-- public function
save_database = request_save_database

local function save_database(namefile,data)
	log(namefile,3)
	local file, err = io.open(M.pluginPath .."/database/"..namefile,"w")
	if file==nil then
		log("Couldn't open file: "..err,5)
		return false
	else
		file:write(Util.JsonEncode(data))
		file:close()
		return true
	end
end

local function verify(namefile,new_data)
    local backup = load_database(namefile)
    local err = save_database(namefile,new_data)
    local checl = load_database(namefile)
	if err == false or backup == nil then
	    return 'write_error'
	end 
    if checl == nil then
        save_database(namefile,backup)
        return false
    else
        return true
    end
end

function forced_save_database(namefile,data)
	log(namefile,3)
	local file, err = io.open(M.pluginPath .."/database/"..namefile,"w")
	if file==nil then
		log("Couldn't open file: "..err,5)
		return false
	else
		data = Util.JsonEncode(data)
		--file:write(Util.JsonPrettify(data))
		file:write(data)
		file:close()
		return true
	end
end

function check_request_save_database()
    for namefile,data in pairs(req_save_database) do
        if gettime() >= data.time then
			local rin = verify(namefile,data.data)
            if rin == true then
                log("Сохранение базы данных " .. namefile .. " прошло успешно",2)
                req_save_database[namefile] = nil
			elseif rin == 'write_error' then 
				log("failed to load file: " .. namefile.." \nLoad old file",5)
                SendMessage(-1,"Файл не сохраняется, НЕМЕДЛЕННО ОПОВЕСТИТЕ АДМИНИСТРАТОРА")
            else
                log("failed to load file: " .. namefile.." \nLoad old file",5)
                SendMessage(-1,"Не удалось сохранить базу данных. оповестит администратора и выйдите с сервера. Весь прогресс откатится на 10-20 минут. Приносим свои извенения, за предоставленные неудобства.")
            end
        end
    end
    return true
end

local function try_read_config(path)
    path = FS.ConcatPaths(M.pluginPath, "database",path)
    log(namefile,3)
	local file, err = io.open(path,"r")
	if file==nil then log("Couldn't open file: "..err,5)
	else
		local read = file:read("*all")
		file:close()
	
		-- Попробуем декодировать JSON
		local result, json_err = Util.JsonDecode(read)


		if not result then
			result = dkjson.decode(read)
		end

		if result == nil then
			read = read:gsub('"%s*:%s*"%s*%S+%s*"%s*%s*[\n\r]', '%0,')
			read = read:gsub(',%s*}', '}')
			result, json_err = Util.JsonDecode(read)
	
			if not result then
				if json_err then
					print("Ошибка декодирования JSON после исправления: " .. json_err)
				else
					print("Ошибка декодирования JSON после исправления: неизвестная ошибка")
				end
			end
		end
		return result
	end
end

function load_database(namefile)
	log(namefile,3)
	local file, err = io.open (M.pluginPath.."/database/"..namefile,"r")
	if file==nil then
		log("Couldn't open file: "..err,5)
		return nil
	else
	    local read = file:read("*all")
		file:close()
		if read == nil or read == "" then
			return nil
		end
		local _, data = pcall(Util.JsonDecode,read)
		if data == nil then
            log("failed to decode file: " .. namefile,5)
            return nil
        end
		return data
	end
end

function read_td(namefile)
	log(namefile,3)
	local file = io.open ("/beammp/Resources/Server/transf_data/"..namefile,"r")
	local result = file:read("*all")
	file:close()  
	MP.Sleep(10)
	local error, error_message = FS.Remove("/beammp/Resources/Server/transf_data/"..namefile)
	if error or error_message then
		log("failed to delete file: " .. error_message,5)
	end
	return result
end
 
function load_config(namefile)
	log(namefile,3)
	local file, err = io.open(M.pluginPath..'/'..namefile..'.json',"r")
	if file==nil then log("Couldn't open file: "..err,5) 
	else	
		local read = file:read("*all")
		file:close()
		local result = Util.JsonDecode(read)
		return result
	end
end

function save_config(namefile,data)
	log(namefile,3)
	local file, err = io.open(M.pluginPath..'/'..namefile..'.json',"w")
	if file==nil then log("Couldn't open file: "..err,5)
	else
		local jdata = Util.JsonEncode(data)
		file:write(jdata)
		file:close()
	end
end

local ClassBD = {}

function ClassBD:init(namefile)
	local obj = setmetatable({}, self)

	local private = {}
		private.namefile = namefile
		private.data = nil

	function private:check_err(file,error)
		if not file then
            log("Couldn't open file: " .. error, 5)
            return nil
        end
        return file
	end

	function obj:forced_save_database(data)
		log(private.namefile, 3)
        private.data = data
        local file, err = io.open(M.pluginPath .. "/database/" .. private.namefile, "w")
        file = private:check_err(file, err)
        if file then
            file:write(Util.JsonEncode(data))
            file:close()
            return true
        end
        return false
	end

	function obj:save(data)
		if data == nil then
            log({ "Data is nil", private.namefile }, 5)
            return
        end
        log(private.namefile, 3)
        private.data = data
        req_save_database[private.namefile] = {
            data = private.data,
            time = gettime() + config.REQUEST_SAVE_DATABASE_TIME_SEC
        }
	end

	function obj:load()
		log(private.namefile, 3)
        local file, err = io.open(M.pluginPath .. "/database/" .. private.namefile, "r")
        file = private:check_err(file, err)
        if file then
            local read = file:read("*all")
            file:close()
            if read == nil or read == "" then
                return nil
            end
            local _, data = pcall(Util.JsonDecode, read)
            if data == nil then
                log("Failed to decode file: " .. private.namefile, 5)
                return nil
            end
            return data
        end
        return nil
	end

	return obj
end
M.try_read_config = try_read_config
M.verify = verify
M.ClassBD = ClassBD

return M