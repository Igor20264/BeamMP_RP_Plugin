-- notifications.lua

local M = {}

local DB = require("lib.database")

local Notifications = {}

extended(Notifications, DB)

function Notifications:init(databasePath)
    self.database = self.database or {}
    self:load(databasePath)

    function self:addNotification(playerId, message)
        self.database[playerId] = self.database[playerId] or {}
        table.insert(self.database[playerId], message)
        self:save()
    end

    function self:getNotifications(playerId)
        return self.database[playerId] or {}
    end

    function self:clearNotifications(playerId)
        self.database[playerId] = nil
        self:save()
    end

    return self
end

-- Функция для отправки уведомлений через минуту после захода
local function sendNotificationsDelayed(playerId, notifications)
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

function Notifications:onPlayerJoin(playerId)
    local playerName = MP.GetPlayerName(playerId)
    local notifications = self:getNotifications(playerName)

    if #notifications > 0 then
        -- Используем task для отправки уведомлений через 60 секунд
        HeventTimer.Createtask(60, sendNotificationsDelayed, playerName.."notifications", playerId, notifications)
        self:clearNotifications(playerName)
    end
end

local notifications = Notifications:init("notifications.ixt")
MP.RegisterEvent("onPlayerJoin", function(playerId)
    notifications:onPlayerJoin(playerId)
end)

return notifications