-- notifications.lua

local M = {}

local DB = require("lib.database")

local Notifications = {}
--Notifications:extended(DB)
extended(Notifications, DB)
function Notifications:init(path)
    local db_instance = DB:init(path) -- Инициализация DB

    -- Копируем поля из db_instance в self
    for key, value in pairs(db_instance) do
        self[key] = value
    end

    return self
end
function Notifications:addNotification(playerName, message)
    self.database[playerName] = self.database[playerName] or {}
    table.insert(self.database[playerName], message)
    self:save()
end

function Notifications:getNotifications(playerName)
    return self.database[playerName] or {}
end

function Notifications:clearNotifications(playerName)
    self.database[playerName] = nil
    self:save()
end

-- Функция для отправки уведомлений через минуту после захода
function sendNotificationsDelayed(playerId, notifications)
    -- Отправляем уведомления
    text = "У вас новые уведомления: \n"
    for _, message in ipairs(notifications) do
        text = text..message.."\n"
    end
    -- if endswith(text, "\n") then remove last \n
    if text:sub(-1) == "\n" then
        text = text:sub(1, -2)
    end
    SendMessage(playerId, text)
end

local notifications = Notifications:init("notifications.ixt")

function Notifications:onPlayerJoin(playerId)
    local playerName = MP.GetPlayerName(playerId)
    local notify = notifications:getNotifications(playerName)

    if #notifications > 0 then
        -- Используем task для отправки уведомлений через 60 секунд
        HeventTimer.Createtask(90, sendNotificationsDelayed, playerName.."notifications", playerId, notify)
        notifications:clearNotifications(playerName)
    end
end

function Notify_on_PlayerJoin(playerId)
    notifications:onPlayerJoin(playerId)
end

MP.RegisterEvent("onPlayerJoin", 'Notify_on_PlayerJoin')

return notifications