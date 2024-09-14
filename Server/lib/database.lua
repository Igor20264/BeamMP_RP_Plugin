local Database = {}

function Database:init(namedb) -- свойства
	local private = {}  --приватное свойство
	    private.database = load_database(namedb) or {}
	    private.database_name = namedb
    local obj= {} --публичное свойство
        obj.database = private.database
    -- метод

    -- Метод для генерации шаблона или же всех свойст в базе
    function private:genSchema(table, prefix)
        prefix = prefix or ""
        local template = {}

        if type(table) == "table" then
            for key, value in pairs(table) do
                if type(value) == "table" then
                    -- Проверяем, является ли таблица списком
                    local isList = #value > 0 and value[1] ~= nil
                    if isList then
                        template[prefix .. key] = "list of " .. private:genSchema(value[1], key .. ".")
                    else
                        local subTemplate = private:genSchema(value, key .. ".")
                        for subKey, subValue in pairs(subTemplate) do
                            template[prefix .. subKey] = subValue
                        end
                    end
                else
                    template[prefix .. key] = type(value)
                end
            end
        else
            return type(table)
        end

        return template
    end
    --[[
    function private:clear_template(database)
        database = database or private.database
        local data = private:genSchema(database)
        local clear_template = {}
        for key, value in pairs(data) do
            local sdata = split(key,".")
            sdata[1] = nil
            local keys = ""
            for i = 2, #sdata do
                keys = keys .. "." .. sdata[i]
            end
            clear_template[keys] = value
        end
        local egg = {}
        for key, value in pairs(clear_template) do
            egg['username' .. key] = value
        end
        -- save file
        --save_config("pattern/"..split(private.database_name,'.')[1], egg)
    if private.database ~= nil then
        private:clear_template(private.database)
    end
    end--]]
	function obj:getTable(name)
		for i,data in pairs(obj.database) do
		    if name == i then return data end
		end
		return nil 
	end

    function obj:delete(name) -- return state delete : bool
        if private.database[name] ~= nil then
            private.database[name] = nil
            obj:save()
            return true
        else
            return false
        end
    end

    function obj:value(name, ...)
        local args = {...}
        local lastArgIndex = #args
        local currentTable = private.database[name]
        for i =1, lastArgIndex do
            local key = args[i]
            currentTable[key] = currentTable[key] or {}
            currentTable = currentTable[key]
        end
        return currentTable
    end

	function obj:set(name,...)
        local args = {...}
        local currentTable = private.database[name]

        for i = 1, #args - 3 do
            local key = args[i+1]
            currentTable[key] = currentTable[key] or {}
            currentTable = currentTable[key]
        end

        local lastKey = args[#args - 1]

        if type(args[#args]) == "table" then
            currentTable[lastKey] = args[#args]
        else
            if args[#args] == "{}" then
                currentTable[lastKey] = {fixed_path = 1}
            else
                 currentTable[lastKey] = tonumber(args[#args]) or args[#args]
            end
        end
        obj:save()
        local ts = {}
        for _,data in pairs(args) do
            ts[#ts+1] = data
        end
        table.remove(ts,#ts)
        return obj:value(name, table.unpack(ts))
    end

	function obj:add(name,...)
        local args = {...}
        local currentTable = private.database[name]

        for i = 1, #args - 3 do
            local key = args[i+1]
            currentTable[key] = currentTable[key] or {}
            currentTable = currentTable[key]
        end

        local lastKey = args[#args - 1]
        currentTable[lastKey] = currentTable[lastKey] + tonumber(args[#args]) or args[#args]
        obj:save()
        local ts = {}
        for i,data in pairs(args) do
            ts[#ts+1] = data
        end
        table.remove(ts,#ts)
        return obj:value(name, table.unpack(ts))
    end

	function obj:save()
	    request_save_database(private.database_name,private.database)
	end

    --чистая магия!
    setmetatable(obj, self)
    self.__index = self
	return obj
end

return Database