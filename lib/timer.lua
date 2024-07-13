local M = {}
function M:init()
	local privat = {}  --приватное свойство
	local obj= {} --публичное свойство

	function obj:get()
		return os.time()
	end

	function obj:corrector(base)
        return base
    end

	function obj:isCooldown(data) -- в целых секундах
		if data<=obj:Get() then
			return true
		else
			return false
		end
	end
	
	function obj:getCooldown(s)
		return obj:Get()+s
	end	
	
	--чистая магия!
    setmetatable(obj, self)
    self.__index = self
	return obj
end

function get_hour()
	local dt_object = os.date("*t", timestamp)
	local hour = dt_object.hour+config.corrector
	if hour < 0 then hour = hour+24
	elseif hour > 23 then hour = hour-24 end
	return hour
end

return M:init()
