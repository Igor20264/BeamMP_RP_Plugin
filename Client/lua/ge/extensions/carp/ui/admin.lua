--====================================================================================
-- All work by Pastry.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP UI
--====================================================================================
local M = {}
print("Loading Carp Admin UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local buf_size = 64
local playerIDBuffer = im.ArrayChar(buf_size)
local playerNameBuffer = im.ArrayChar(buf_size)
local testData = ""

local playerIDArray = {}
local playerNameArray = {}
local playerDataArray = {}
local playerHWIDArray = {}

local currentPlayerBalance = 0

local APPEAL_CHANNEL_NAME = "#reports-appeals"
local PERMABAN_MSG = "You have been permanently restricted from CaRP."
local APPEAL_MSG = "You have been temporarily restricted from CaRP. Please appeal in "..APPEAL_CHANNEL_NAME.." from our discord server."
local CHEAT_MSG = "You have been permanently restricted from CaRP. Reason: Cheating"

-- draw functions: -->
local function drawAdminUI()
  if not base.beginWindow("AdminUI", "Admin Menu", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  im.Columns(2, "Asd")
  im.TextWrapped("Name:")
  im.SameLine()
  im.InputText("##searchPlayerName", playerNameBuffer, buf_size)
  im.NextColumn()
  if im.Button("Search by Name") then
    TriggerServerEvent("adminSearchPlayerName", ffi.string(playerNameBuffer))
  end
  im.NextColumn()
  im.Separator()

  for index, pid in pairs(playerIDArray) do
    im.TextWrapped(playerNameArray[index])
    im.NextColumn()
    if im.Button(pid) then
      playerIDArray = {}
      playerIDBuffer = im.ArrayChar(buf_size, pid)
      TriggerServerEvent("adminGetPlayerBalance", ffi.string(playerIDBuffer))
      TriggerServerEvent("adminGetPlayerInfo", ffi.string(playerIDBuffer))
      TriggerServerEvent("adminGetPlayerHWIDList", ffi.string(playerIDBuffer))
    end
    im.NextColumn()
  end

  if (playerIDArray ~= {}) then
    im.Separator()
  end

  im.TextWrapped("Player ID:")
  im.SameLine()
  im.InputText("##searchPlayerID", playerIDBuffer, buf_size)
  im.NextColumn()
  if im.Button("Search") then
    TriggerServerEvent("adminGetPlayerBalance", ffi.string(playerIDBuffer))
    TriggerServerEvent("adminGetPlayerInfo", ffi.string(playerIDBuffer))
    TriggerServerEvent("adminGetPlayerHWIDList", ffi.string(playerIDBuffer))
  end
  im.NextColumn()
  im.Separator()
  for column, value in pairs(playerDataArray) do
    im.TextWrapped(column)
    im.NextColumn()
    im.TextWrapped(value)
    im.NextColumn()
    im.Separator()
  end

  im.TextWrapped("Current Balance: ")
  im.NextColumn()
  im.TextWrapped("$" .. currentPlayerBalance)

  im.Columns(1, "Asd")
  im.TextWrapped("Ban Options: ")
  im.SameLine()
  if im.Button("Permanent") then
    TriggerServerEvent("adminBanPlayer", ffi.string(playerIDBuffer) .. "|false|" .. PERMABAN_MSG)
    for _, value in pairs(playerHWIDArray) do
      TriggerServerEvent("adminBanHWID", value[1] .. "|false")
    end
  end
  im.SameLine()
  if im.Button("Appealable") then
    TriggerServerEvent("adminBanPlayer", ffi.string(playerIDBuffer) .. "|false|" .. APPEAL_MSG)
  end
  im.SameLine()
  if im.Button("Cheating") then
    TriggerServerEvent("adminBanPlayer", ffi.string(playerIDBuffer) .. "|false|" .. CHEAT_MSG)
    for _, value in pairs(playerHWIDArray) do
      TriggerServerEvent("adminBanHWID", value[1] .. "|false")
    end
  end
  im.SameLine()
  if im.Button("Unban") then
    TriggerServerEvent("adminBanPlayer", ffi.string(playerIDBuffer) .. "|true")
    for _, value in pairs(playerHWIDArray) do
      TriggerServerEvent("adminBanHWID", value[1] .. "|true")
    end
  end

  if im.CollapsingHeader1("HWID Management") then
    im.Columns(3, "Asd")
    im.TextWrapped("Hardware ID")
    im.NextColumn()
    im.TextWrapped("Player ID List")
    im.NextColumn()
    im.TextWrapped("Banned")
    im.NextColumn()
    im.Separator()

    for _, value in pairs(playerHWIDArray) do
      im.Text(value[1])
      im.NextColumn()
      im.Text(value[2])
      im.NextColumn()
      if im.Button(string.upper(value[3]).."##"..value[1]) then
        TriggerServerEvent("adminBanHWID", value[1] .. "|" .. value[3])
      end
      im.NextColumn()
      im.Separator()
    end
  end

  im.Columns(1, "Asd")

  if im.Button("Hide Admin Window") then
    base.hideWindow("AdminUI")
  end

  base.endWindow()
end

-- draw functions <--

local function showAdminUI(show)
  if show then
    base.showWindow("AdminUI")
  else
    base.hideWindow("AdminUI")
  end
end

-- event handlers: -->
local function showAdminWindow()
  showAdminUI(true)
end

local function receiveAdminPlayerBalance(balance)
  currentPlayerBalance = balance
end

local function receiveAdminPlayerInfo(data)
  playerDataArray = {}

  local processArray = stringToTable(data, "|")

  for _, values in pairs(processArray) do
    local sValues = stringToTable(values, ":")

    playerDataArray[sValues[1]] = sValues[2]
  end
end

local function receiveAdminPlayerNameID(pidNames)
  playerIDArray = {}
  playerNameArray = {}

  local processArray = stringToTable(pidNames, "|")

  for index, values in pairs(processArray) do
    local sValues = stringToTable(values, ":")

    playerIDArray[index] = sValues[1]
    playerNameArray[index] = sValues[2]
  end
end

local function receiveAdminPlayerHWIDList(hwidList)
  playerHWIDArray = {}

  local processArray = stringToTable(hwidList, "|")

  for index, values in pairs(processArray) do
    local sValues = stringToTable(values, ":")

    playerHWIDArray[index] = {sValues[1], sValues[2], sValues[3] or "false"}
  end
end

local function receiveAdminHWIDListRefreshCommand(command)
  TriggerServerEvent("adminGetPlayerHWIDList", ffi.string(playerIDBuffer))
end

-- event handlers <--

local function onExtensionLoaded()
  base.registerWindow("AdminUI", im.ImVec2(300, 450))

  AddEventHandler("showAdminWindow", showAdminWindow)
  AddEventHandler("receiveAdminPlayerBalance", receiveAdminPlayerBalance)
  AddEventHandler("receiveAdminPlayerNameID", receiveAdminPlayerNameID)
  AddEventHandler("receiveAdminPlayerInfo", receiveAdminPlayerInfo)
  AddEventHandler("receiveAdminPlayerHWIDList", receiveAdminPlayerHWIDList)
  AddEventHandler("receiveAdminHWIDListRefreshCommand", receiveAdminHWIDListRefreshCommand)

  log("I", "onExtensionLoaded", "Admin UI initialized.")
end

local function onUpdate()
  drawAdminUI()
end

M.onExtensionLoaded = onExtensionLoaded
M.showAdminUI = showAdminUI
M.onUpdate = onUpdate

return M
