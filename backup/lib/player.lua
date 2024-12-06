local Player = {}
local conifg = config

function Player:init(id,shablon,database,oten)
   -- свойства
    shablon = shablon or {}
    oten = oten or false
	local privat = {}  --приватное свойство
    local obj= {} --публичное свойство
    local temp = {} -- Временные данные не сохраняемые между сессиями
        temp.id = id
    local universal = {} -- Свойство для определения класса

    if MP.GetPlayerName(id) == '' then
        universal.name = "CMD"
    else
        universal.name = MP.GetPlayerName(id)
    end

    function privat:inList(name)
        for i,case in pairs(eco.database) do
            if name == i then -- name,$,payday,bank$,WorkName,taxIP
				return true
			end
        end
        return false
    end

    function obj:import()
        if privat:inList(universal.name) then
            privat = eco.database[universal.name]
        else
            privat = shablon
            log(universal.name.." Впервые на сервере!",4)
        end
        eco.database[universal.name] = table.shallow_copy(privat)
    end

    function obj:create(name,table)
        universal.name = name
        privat = table
        log(universal.name.." Впервые на сервере!",4)
        eco.database[universal.name] = table.shallow_copy(privat)
    end

    if oten == false then
        obj:import()
    end

    --чистая магия!
    setmetatable(obj, self)
    self.__index = self
    return obj
end
return Player