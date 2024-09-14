local M = {}
M.info = "Система ролей"
M.ver = "0.1 Beta"
local cache = {}

local Permissions = {}
Permissions.__index = Permissions
function Permissions:init()
    local public = setmetatable({}, self)

    local private = {}
    private.cache = {}
    function public:init_user(username)
        if eco.database[username] ~= nil and eco.database[username]["roles"] == nil then
            eco:set(username, "roles", {"player"})
        end
    end
    function public:get_roles(username)
        if username == nil then
            return nil
        end
        if eco.database[username] == nil then
            return nil
        end
        if eco.database[username]["roles"] == nil then
            self:init_user(username)
        end
        return eco.database[username]["roles"]
    end
    function public:set_roles(username, roles) -- roles - {"admin", "player"}
        eco:set(username, "roles", roles)
        public:clear_cache_user(username)
    end
    function public:clear_cache_user(username)
        if private.cache[username] ~= nil then
            private.cache[username] = nil
        end
        if cache[username] ~= nil then
            cache[username] = nil
        end
    end

    function public:clear_cache()
        private.cache = {}
        cache = {}
    end

    function public:add_role(username, role) -- role - "admin"
        local roles = public:get_roles(username) or {}
        table.merge(roles, {role})
        eco:set(username, "roles", roles)
        public:clear_cache_user(username)
    end
    function public:remove_role(username, role)
        local roles = public:get_roles(username) or {}
        for i, v in ipairs(roles) do
            if v == role then
                table.remove(roles, i)
                break
            end
        end
        eco:set(username, "roles", roles)
        public:clear_cache_user(username)
    end
    function public:role_in_roles(role,roles)
        private.cache.role = private.cache.role or {}
        local str_roles = table.concat(roles)
        if private.cache.role[role][str_roles] ~= true then
            return private.cache.role[role][str_roles]
        end

        for _, v in ipairs(roles) do
            if v == role then
                private.cache.role[role][str_roles] = true
                return true
            end
        end
        private.cache.role[role][str_roles] = false
        return false
    end

    function public:has_role(username, role)
        local roles = public:get_roles(username) or {}
        for i, v in ipairs(roles) do
            if v == role then
                return true
            end
        end
        return false
    end

    function public:roles_in_roles(command_roles, user)
        local str_command_roles =table.concat(command_roles)
        if private.cache[user] ~= nil and private.cache[user][str_command_roles] == true then
            return true
        end
        if user == nil then
            return false
        end
        if user == "CMD" then
            return true
        end
        local user_roles = public:get_roles(user)
        if user_roles == nil then
            return false
        end
        for _, v in ipairs(user_roles) do
            for _, w in ipairs(command_roles) do
                if v == w then
                    private.cache[user][str_command_roles] = true
                    return true
                end
            end
        end
        private.cache[user][str_command_roles] = false
        return false
    end

    return public
end


--[[
local function test_permission()
    print(perm:get_roles("Igor20264"))
    print(perm:has_role("Igor20264", "admin"))
    print(perm:has_role("Igor20264", "player"))

    perm:add_role("Igor20264", "admin")

    print(perm:has_role("Igor20264", "admin"))
end
--test_permission()

-- Оригинальная функция
local function sag(x,y,z)
    print(x,y,z)
end
-- Применяем декоратор к оригинальной функции
onlyPlayer = permission_decorator({"player"})

-- Вызываем оригинальную функцию
onlyPlayer(sag, 1, "HHg", 3)
onlyPlayer(sag, 1, "Igor20264", 3)
onlyPlayer(sag, 1, "admin", 3)
onlyPlayer(sag, 1, "CMD", 3)

--]]

-- Декоратор
local function permission_decorator(allowed_roles)
    return function(original_function,...)
        allowed_roles = allowed_roles or {'player'}
        local args = {...}  -- Получаем переданные аргументы
        local user_name = args[3]
        if user_name == "CMD" then
            return original_function(...)
        end
        local user_roles = permissions:get_roles(user_name)
        if cache ~= nil and cache[user_name] and cache[user_name][original_function] then
            return original_function(...)  -- Вызываем оригинальную функцию с измененными аргументами
        end
        -- перенбираем все роли игрока и ищем схожие
        if user_roles ~= nil then
            for _, role in ipairs(user_roles) do
                for _, allowed_role in ipairs(allowed_roles) do
                    if role == allowed_role then
                        cache[user_name] = cache[user_name] or {}
                        cache[user_name][original_function] = true
                        return original_function(...)  -- Вызываем оригинальную функцию с измененными аргументами
                    end
                end
            end
        end
        local user_id = args[2]
        SendMessage(user_id,"Вы не можете использовать эту команду")
    end
end

function DELETEALLROLES(sender_id,sender_name, message)
    for _,player in MP.GetPlayers() do
        if permissions:has_role(player, "admin") then
            permissions:remove_role(player, "admin")
        end
        if permissions:has_role(player, "moderator") then
            permissions:remove_role(player, "moderator")
        end
    end
end

function ROLESADD(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    permissions:add_role(name,case[2])
    SendMessage(sender_id,"Роль "..case[2].." добавлена игроку "..name)
end

function ROLESREMOVE(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    permissions:remove_role(name,case[2])
    SendMessage(sender_id,"Роль "..case[2].." удалена игроку "..name)
end

function ROLESSET(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    local roles = load(case[2])
    permissions:set_roles(name,roles)
    SendMessage(sender_id,"Роли "..case[2].." установлены игроку "..name)
end

function ROLESLIST(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    if name == nil or name == "" then
        name = sender_name
    end

    local roles = permissions:get_roles(name)
    local ret = "Роли игрока "..name..":"
    if roles ~= nil then
        ret = ret.."\n"..table.concat(roles,"\n")
    end
    SendMessage(sender_id,ret)
end

M.command = {
    {category = "roles",command = "add", help = "Давабивть роль",args = "[имя] [роль]",func = "ROLESADD",roles = {"admin"}},
    {category = "roles",command = "remove", help = "Удалить роль",args = "[имя] [роль]",func = "ROLESREMOVE",roles = {"admin"}},
    --{category = "roles",command = "set", help = "Установить список ролей",args = "[имя] {'роль','роль'}!!БЕЗ ПРОБЕЛОВ!!",func = "ROLESSET",roles = {"admin"}},
    {category = "roles",command = "list", help = "Список ролей",args = "[имя]",func = "ROLESLIST",roles = {"admin"}},
}

function M.load()
    permissions = Permissions:init()
end

function M.unload()
end

M.decorator = permission_decorator
return M