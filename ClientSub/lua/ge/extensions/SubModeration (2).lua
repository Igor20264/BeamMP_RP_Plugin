-- Приватный мод для рп сервера Subter Role Play. Версия v0.0.1
-- Автор Jastickon. Дискорд jastickon.
-- Вся логика вынесена на сторону сервера.

local M = {}

local logTag = "SubModeration";


function playSound(Name, volume)
	sound = "audio/".. Name ..".ogg"
	Engine.Audio.playOnce("AudioGui", sound, {volume = volume})
end

local function banned(data)
	playSound("tobycon", 1)
end

local function onExtensionLoaded()
	log('D', 'Working Started', "")
	AddEventHandler("PacketBannedSub",               banned)
	
end;

M. banned =  banned
M.onExtensionLoaded = onExtensionLoaded

return M;