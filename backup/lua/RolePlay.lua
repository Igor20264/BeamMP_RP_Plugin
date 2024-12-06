local M = {}
M.info = "Команды связанные с РП"
M.ver = "BETA 0.4"

function TRY(sender_id, sender_name, message) --Проверка действия
	local random = Util.RandomIntRange(0,1)
    if message == nil then
        if random == Util.RandomIntRange(0,1) then
            SendMessage(-1,"^7"..sender_name.." ^lУспешно ^r^7сделал некое действие")
        else
            SendMessage(-1,"^7"..sender_name.." ^lНеудачно ^r^7сделал некое действие")
        end
    else
        if random == Util.RandomIntRange(0,1) then
            SendMessage(-1,"^7"..sender_name.." ^lУспешно ^r^7 " .. message)
        else
            SendMessage(-1,"^7"..sender_name.." ^lНеудачно ^r^7 " .. message)
        end
    end
end

function DM(sender_id, sender_name, message) --Личное сообщение
    local target_name = erors(split(message," ")[1],2)
    local message2 = message:sub(#target_name+1,#message)
    log(target_name, 3)
    local target_id = MP.GetId(target_name)
    log(target_id, 3)
    if target_id ~= -1 then
        if sender_id ~= target_id then
            MP.SendChatMessage(sender_id,"^5Для -> ^r" .. target_name .. " : " .. message2)
            MP.SendChatMessage(target_id,"^5От -> ^r" .. sender_name .. " : " .. message2)
        else
            MP.SendChatMessage(sender_id, "^7Вы не можете писать самому себе")
        end
    end
end

function NRP_Chat(sender_id, sender_name, message) --НРП Информация
    SendMessage(-1, sender_name..":^7(( " .. message .. " ))")
end

function ME(sender_id, sender_name, message) --действия от 3-го лица
    SendMessage(-1, sender_name..":^3 " .. message)
end

M.command = {
    {command = "try", help = "Проверка действия", args = "[Что сделал?]", func = "TRY"},
    {command = "dm", help = "Отправить сообщение другому игроку.", args = "[ник] [сообщение]", func = "DM"},
    {command = "b", help = "НРП Информация", args = "[сообщение]", func = "NRP_Chat"},
    {command = "me", help = "Действия от 3-го лица", args = "[действие]", func = "ME"},
}
function M.load()
end

function M.unload()
end

return M

