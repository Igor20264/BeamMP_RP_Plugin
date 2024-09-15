-- Приватный мод для рп сервера Subter Role Play. Версия v0.0.1
-- Автор Jastickon. Дискорд jastickon.
-- Вся логика вынесена на сторону сервера.

local M = {}

local function openparkingcef(data)

    
end

local function onExtensionLoaded()
    AddEventHandler("PacketOpenParkingCef", openparkingcef)
end



M.openparkingcef = openparkingcef
M.onExtensionLoaded = onExtensionLoaded

return M;