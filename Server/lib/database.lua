local Database = {}
Database.__index = Database

function Database:init(namedb) -- свойства
	local private = {}  --приватное свойство
	    private.database_name = namedb
    local obj = setmetatable({},self) --публичное свойство
        obj.database = load_database(namedb) or {}
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
        database = database or obj.database
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
    if obj.database ~= nil then
        private:clear_template(obj.database)
    end
    end--]]
	function obj:getTable(name)
		for i,data in pairs(obj.database) do
		    if name == i then return data end
		end
		return nil 
	end

    function obj:delete(name) -- return state delete : bool
        if obj.database[name] ~= nil then
            obj.database[name] = nil
            obj:save()
            return true
        else
            return false
        end
    end

    function obj:value(name, ...)
        local args = {...}
        local lastArgIndex = #args
        local currentTable = obj.database[name]
        for i =1, lastArgIndex do
            local key = args[i]
            currentTable[key] = currentTable[key] or {}
            currentTable = currentTable[key]
        end
        return currentTable
    end

	function obj:set(name,...)
        local args = {...}
        local currentTable = obj.database[name]

         -- Проверяем, существует ли таблица для данного имени
        if currentTable == nil then
            currentTable = {} -- Создаем таблицу, если её нет
            obj.database[name] = currentTable
        end

        for i = 1, #args - 2 do
            local key = args[i]
            currentTable[key] = currentTable[key] or {}
            currentTable = currentTable[key]
        end
        -- Устанавливаем последний ключ
        local lastKey = args[#args - 1]
        local lastValue = args[#args]

        if type(lastValue) == "table" then
            currentTable[lastKey] = lastValue -- Устанавливаем таблицу
        else
            if lastValue == "{}" then
                currentTable[lastKey] = {fixed_path = 1} -- Устанавливаем фиксированный путь
            else
                currentTable[lastKey] = tonumber(lastValue) or lastValue -- Устанавливаем значение
            end
        end

        obj:save()

        -- Возвращаем текущее значение
        local ts = {}
        for _,data in pairs(args) do
            ts[#ts+1] = data
        end
        table.remove(ts,#ts)
        return obj:value(name, table.unpack(ts))
    end

	function obj:add(name,...)
        local args = {...}
        local currentTable = obj.database[name]

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
	    request_save_database(private.database_name,obj.database)
	end

	return obj
end

return Database