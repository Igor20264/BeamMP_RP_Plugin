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
				 log("failed to load file: " .. data.namefile.."\nLoad old file",5)
                SendMessage(-1,"Файл не сохраняется, НЕМЕДЛЕННО ОПОВЕСТИТЕ АДМИНИСТРАТОРА")
            else
                log("failed to load file: " .. data.namefile.."\nLoad old file",5)
                SendMessage(-1,"Не удалось сохранить базу данных. оповестит администратора и выйдите с сервера. Весь прогресс откатится на 10-20 минут. Приносим свои извенения, за предоставленные неудобства.")
            end
        end
    end
    return true
end

function load_database(namefile)
	log(namefile,3)
	local file, err = io.open (M.pluginPath.."/database/"..namefile,"r")
	if file==nil then
		log("Couldn't open file: "..err,5)
		return nil
	else
	    local read = file:read("*all")
		if read == nil or read == "" then
			file:close()
			return nil
		end
		local _, data = pcall(Util.JsonDecode,read)
		if data == nil then
            log("failed to decode file: " .. namefile,5)
            return nil
        end
		file:close()
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
		local result = Util.JsonDecode(file:read("*all"))
		file:close()
		return result
	end
end

function save_config(namefile,data)
	log(namefile,3)
	local file, err = io.open(M.pluginPath..'/'..namefile..'.json',"w")
	if file==nil then log("Couldn't open file: "..err,5)
	else
		file:write(Util.JsonEncode(data))
		file:close()
	end
end


return M