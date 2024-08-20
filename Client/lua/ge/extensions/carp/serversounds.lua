local M = {}

local function onClientReceivePlaySound(soundType)
  if soundType == "fail" then
    local soundName = "audio/failure/fail" .. math.random(1, 4) .. ".ogg"

    playCarpSound(soundName)
  else
    local soundName = "audio/" .. soundType .. ".ogg"

    playCarpSound(soundName)
  end
end

local function onExtensionLoaded()
    AddEventHandler("onClientReceivePlaySound", onClientReceivePlaySound)
    log("I", "onExtensionLoaded", "carp_serversounds loaded.")
end

M.onExtensionLoaded = onExtensionLoaded

return M
