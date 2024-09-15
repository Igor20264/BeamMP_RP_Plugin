local M = {}
function M:init()
	local privat = {}  --приватное свойство
		privat.time = os.time()
	local obj= {} --публичное свойство
		
	function obj:Get()
		return os.time()
	end
	
	function obj:isCooldown(data) -- в целых секундах
		if data<=obj:Get() then
			return true
		else
			return false
		end
	end
	
	function obj:GetCooldown(s)
		return obj:Get()+s
	end	
	
	--чистая магия!
    setmetatable(obj, self)
    self.__index = self
	return obj
end
return M:init()
