local M = {}

function split_parms()
	
end

function M:init()
	local privat = {}  --приватное свойство
		
	local obj= {} --публичное свойство
		obj.groups = load_database("Group.ixt") or {}
	
	function obj:save()
		save_database("Group.ixt",self.groups)
	end
	
	function obj:load()
		self.groups = load_database("Group.ixt") or {}
	end
	
	-- функция для создания группы
	function obj:create(name, Value)
		local value = Value or {Int = 500,Str= "Безработный"}
		self.groups[name] = {  -- создаем новую таблицу для группы 
			Value = value, -- значение по умолчанию для группы
			users = {},  -- список пользователей и их права доступа
			moderators = {},  -- список администраторов группы
			hide = {
			group = false, -- Скрытая ли группа
			hideMod = false -- Скрытый ли администратор
			},
			payday = {
			playerDay = "CMD", -- Кто выплачивает PayDay
			depends_online = false,			-- ЗАВИСИТ ОТ ОНЛАЙНА ? ||Человеку не обязательно быть онлайн что бы получать зп от главного
			},
			leave_only_kick = false
			
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

	function obj:setValue(groupName, newValue, type) -- поменять, что бы не по типам работало, а на лету.
		if self.groups[groupName] then
			if type == "Int" or type == "int" or type == "1" then
				self.groups[groupName].Value.Int = tonumber(newValue)  -- устанавливаем новое значение по умолчанию
			elseif type == "Str" or type == "str" or type == "2" then
				self.groups[groupName].Value.Str = tostring(newValue)  -- устанавливаем новое значение по умолчанию
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
		local Moderator = Moderator or false
		if self.groups[groupName] then
			self.groups[groupName].users[userName] = Moderator  -- добавляем пользователя в списо
			if Moderator then table.insert(self.groups[groupName].moderators, userName) end; -- добавляем пользователя в список администраторовend
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
	
	function obj:getPaid(userName)
		local Paid = 0
		for groupName in pairs(self.groups) do
			for memberIdInGroup,Moderator in pairs(self.groups[groupName].users) do
				if memberIdInGroup == userName then
					Paid = Paid + self.groups[groupName].Value.Int
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
	
	log("TEST CREATE GROUP",2)
	Groups:create("myG1roup")
	Groups:create("my1Group")
	Groups:create("myGroup1")
	Groups:create("nyGroup")
	Groups:create("myGroup")
	log("END TEST CREATE GROUP",2)

	log("TEST remove GROUP",2)
	Groups:create("myGroup")
	Groups:create("my1roup")
	Groups:remove('myGroup')
	--log(Groups.groups,2)
	log("END TEST remove GROUP",2)

	log("TEST SETVALUE GROUP",2)
	Groups:create("myG1roup")
	Groups:setValue("myG1roup",1500,"int")
	log(Groups.groups['myG1roup'].Value,2)
	Groups:addUser("myG1roup","Igor20264")
	Groups:addUser("my1Group","Igor20264")
	print(Groups:getPaid("Igor20264"))
	Groups:setAdmin("myG1roup","Igor20264",true)
	log("END TEST SETVALUE GROUP",2)
end

return M:init()

