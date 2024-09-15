local M = {}

function M:init()
	local privat = {}  --приватное свойство
		privat.mods = {}
	local obj= {} --публичное свойство
		obj.groups = load_database("Group.ixt") or {}
		obj.levaa = 2
	
	function obj:mods()
		for groupName in pairs(self.groups) do
			for memberIdInGroup,Moderator in pairs(self.groups[groupName].users) do
				if Moderator then
					privat.mods[#privat.mods+1] = memberIdInGroup
				end
			end
		end
		return privat.mods
	end
	
	function obj:save()
		save_database("Group.ixt",self.groups)
	end
	
	function obj:load()
		self.groups = load_database("Group.ixt") or {}
	end
	
	function obj:lEva(groupName)
		for case in pairs(self.groups) do
			if lev_iter(groupName,case) <= self.levaa then 
				return case 
			end
		end
		return false
	end
	
	-- функция для создания группы
	function obj:create(name, Value)
		local value = Value or 500
		self.groups[name] = {  -- создаем новую таблицу для группы 
			Value = value, -- значение по умолчанию для группы
			users = {test = false},  -- список пользователей и их права доступа
			moderators = {test = false},  -- список администраторов группы
			hide = false,
			playerDay = "CMD", -- Кто выплачивает PayDay
			leave_only_kick = false,
			blocked_group = {null = false},
			Reqvaer = {A = true},
			description = "Введите описание группы. Можно почитать через !group info [name]"
		}
		obj:save()
		return true
	end
	
	-- функция для удаления группы
	function obj:remove(groupName)
		if self.groups[groupName] ~= nil then
			self.groups[groupName] = nil
			obj:save()
			return true
		else
			return false
		end
	end

	function obj:setValue(groupName, newValue, type) -- [зп,скрытая ли,кто платит,можно самому ходить,block free]
		type = tonumber(type)
		if self.groups[groupName] then
			if type == 1 then
				self.groups[groupName].Value = tonumber(newValue)
				SendMessage(sender_name,self.groups[groupName].Value)
			elseif type == 2 then
				self.groups[groupName].hide = toboolean(newValue)
				SendMessage(sender_name,self.groups[groupName].hide)
			elseif type == 3 then
				self.groups[groupName].playerDay = newValue
				SendMessage(sender_name,self.groups[groupName].playerDay)
			elseif type == 4 then
				self.groups[groupName].leave_only_kick = toboolean(newValue)
				SendMessage(sender_name,self.groups[groupName].leave_only_kick)
			elseif type == 5 then
				obj:BlockFreeGroup(groupName,toboolean(newValue))
				SendMessage(sender_name,"Люди из свободных групп не смогут зайти")
			else
				SendMessage(sender_name,"Такого значения не существует")
				return false
			end
			obj:save()
			return true
		end
		return false
	end
		
	function obj:isModerator(groupName, userName)
		local groupName = groupName or nil
		local userName = userName or "CMD"
		
		if ThisIsAdmin(userName) then
			return true 
		elseif self.groups[groupName] and self.groups[groupName].users[userName] then
			return self.groups[groupName].users[userName]
		else
			return false
		end
	end
		
	function obj:addUser(groupName, userName, Moderator)
		local s = obj:getGroupsForName(userName)
		if s ~= nil then
			for i,case in ipairs(s) do
				if self.groups[groupName].blocked_group[case] then
					return false
				end
			end
		end
		print("OK")
		if s ~= nil and self.groups[groupName].Reqvaer ~= nil then
			log("S!=nil and req != nil",2)
			req = #self.groups[groupName].Reqvaer
			log (self.groups[groupName].Reqvaer,2)
			if not(req < 0) then
				for z,gg in ipairs(s) do
					for case in pairs(self.groups[groupName].Reqvaer) do
						if gg == case then
							req = req-1
						end
						print(gg,case)
					end
				end
			end
			if req >= 0 then
				return false
			end

		end
		
	
		local Moderator = Moderator or false
		if self.groups[groupName] then
			self.groups[groupName].users[userName] = Moderator  -- добавляем пользователя в списо
			--privat:payroll(userName)
			obj:save()
			obj:payroll(userName)
			return true
		else
			return false
		end
	end 

	function obj:setAdmin(groupName,userName,newValue)
		if self.groups[groupName] ~= nil and self.groups[groupName].users[userName] ~= nil then
			self.groups[groupName].users[userName] = newValue
			self.groups[groupName].moderators[userName] = true
			local isAdmin = self.groups[groupName].users[userName]
			
			return true
		else
			return false
		end
	end

	function obj:removeUser(groupName, userName)
		if self.groups[groupName] ~= nil and self.groups[groupName].users[userName] ~= nil then
			if self.groups[groupName].users[userName] then 
				for i, moderator in ipairs(self.groups[groupName].moderators) do
					if moderator == userName then table.remove(self.groups[groupName].moderators, i);break; end  -- удаляем пользователя из списка администраторов
				end
			end
			self.groups[groupName].users[userName] = nil  -- удаляем пользователя из списка
			obj:save()
			obj:payroll(userName)
			return true
		else
			return false
		end
	end	
		
	function obj:getGroupsForName(userName)
		local userGroups = {}
		for groupName in pairs(self.groups) do
			for memberIdInGroup,Moderator in pairs(self.groups[groupName].users) do
				if memberIdInGroup == userName then
					table.insert(userGroups, groupName)
					break
				end
			end
		end
		return userGroups
	end
	
	function obj:BlockFreeGroup(groupName,bool)
		for case in pairs(self.groups) do
			if self.groups[case].leave_only_kick and case ~= groupName then
				if bool == false or bool == nil then 
					self.groups[groupName].blocked_group[case] = nil
				end
				if bool == true then
					self.groups[groupName].blocked_group[case] = true
				end
			end
		end
	end
	
	function obj:BlockGroup(groupName,BlokedGroup,value)
		if value == false or value == nil then
			self.groups[groupName].blocked_group[BlokedGroup] = nil
		end
		if value == true then 
			self.groups[groupName].blocked_group[BlokedGroup] = true
		end
	end
	
	function obj:getPaid(userName)
		local Paid = 0
		for groupName in pairs(self.groups) do
			for memberIdInGroup,Moderator in pairs(self.groups[groupName].users) do
				if memberIdInGroup == userName then
					Paid = Paid + self.groups[groupName].Value
					break
				end
			end
		end
		return Paid
	end
	
	function obj:payroll(userName) -- уставка новой зп
		local old = eco:bal(userName,3)
		local new = eco:set(userName,3,obj:getPaid(userName))
		log('old: '..old..' new: '..new,2)		
	end

	--чистая магия!
    setmetatable(obj, self)
    self.__index = self;
	log("Модуль [Group] Успешно инициализированн",3)
	 return obj
end

function M.TEST()
	Groups = M:init()

	Groups:create("Police")
	Groups:create("Drive")
	Groups:create("Taxi")
	Groups:create("Bus-Driver")
	
	Groups:setValue("Drive","true",4)
	Groups:setValue("Taxi","true",4)
	Groups:setValue("Bus-Driver","true",4)
	
	
	Groups:BlockFreeGroup("Police","true")
	Groups:BlockFreeGroup("Drive","true")
	Groups:BlockFreeGroup("Taxi","true")
	Groups:BlockFreeGroup("Bus-Driver","true")
	
	Groups:setValue("Police",2500,1)
	Groups:setValue("Drive",2000,1)
	Groups:setValue("Taxi",2500,1)
	Groups:setValue("Bus-Driver",2100,1)
end

return M:init()

