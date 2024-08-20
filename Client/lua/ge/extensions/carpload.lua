local M = {}

if extensions.isExtensionLoaded("carp") then
  log("E", "carpload", "carp already loaded, skipping")
  return
end

local function loadFromDirectory(directory)
  local filePaths = FS:findFiles(directory, "*.lua", -1, true, false)
  local prefixLen = #"/lua/ge/extensions/"

  for _, file in ipairs(filePaths) do
    if not file then break end
    if FS:fileExists(file) then
      local relativePath = file:sub(prefixLen + 1, -5) -- remove prefix and extension
      local extName = extensions.luaPathToExtName(relativePath)
      if not extensions.isExtensionLoaded(extName) then
        setExtensionUnloadMode(extName, "auto")
        extensions.load(extName)
        log('I', 'carpload', "loaded module " .. extName .. " from " .. file)
      else
        log('W', 'carpload', tostring(extName) .. " already loaded")
      end
    end
  end
end

local onServerReady = function()
  log("I", "onServerReady", "Server ready!")
  carp_ui_settings.sendMissionPreferences()

  log("I", "onServerReady", "Requesting last used vehicle")
  TriggerServerEvent("receiveLastLocationAndVehicle", "a") -- triggering this event any sooner means BeamMP doesn't have time to fix the camera so if the player is new, their pico spawns under the map :)
end

M.onWorldReadyState = function(state)
  if MPCoreNetwork and MPCoreNetwork.isMPSession() then
    AddEventHandler("onServerReady", onServerReady)
    if state == 2 then
      log('I', 'carpload', "onWorldReadyState == 2")
      log('I', 'carpload', "Loading all CaRP Extensions...")
      loadFromDirectory("/lua/ge/extensions/carp")
      log('I', 'carpload', "Loading module carp")
      setExtensionUnloadMode("carp", "auto")
      extensions.load("carp")
      log('I', 'carpload', "Done loading everything. Triggering onPlayerLoaded")
      TriggerServerEvent("onPlayerLoaded", "🅱")
    end
  else
    log("E", "onWorldReadyState", "BeamMP is not loaded or not in session. Aborting CaRP extension load.")
    guihooks.trigger("toastrMsg", {type="error", title="carpload", msg="BeamMP is not loaded or not in session. Aborting CaRP extension load."})
    return
  end
end



return M