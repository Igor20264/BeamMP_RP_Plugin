--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP party UI
--====================================================================================
local M = {}
print("Loading Carp party UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local UI_CURRENT_PARTY_NAME = nil
local UI_PUBLIC_PARTY_LIST = nil
local UI_PARTY_INVITES = nil
local UI_CURRENT_POTENTIAL_INVITE_LIST = nil

local inviteDropdownAlreadyOpen = false

-- draw functions: -->
local function drawPartyUI()
  if not base.beginWindow("CarpPartyUI", "Parties") then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  if (UI_CURRENT_PARTY_NAME == nil) then
    im.Columns(2, "Asd")

    if im.Button("Create Public Party") then
      UI.chatSend("/createparty public")
    end

    im.NextColumn()

    if im.Button("Create Private Party") then
      UI.chatSend("/createparty private")
    end

    im.NextColumn()
    im.Separator()

    if (UI_PARTY_INVITES ~= nil) then
      im.Columns(1, "Asd")
      im.TextWrapped("Party Invites:")

      im.NextColumn()
      im.Separator()

      local privateInvites = stringToTable(UI_PARTY_INVITES, "|")

      im.Columns(3, "Asd")

      for _, partyRow in pairs(privateInvites) do
        local rowData = stringToTable(partyRow, ";")
        local partyName = rowData[1]
        local partyMembers = rowData[2]

        im.TextWrapped(partyName)

        im.NextColumn()

        im.TextWrapped(partyMembers)

        im.NextColumn()

        if im.Button("Join##" .. partyName) then
          UI.chatSend("/jp " .. partyName)
        end

        im.NextColumn()
        im.Separator()
      end

      im.Columns(2, "Asd")
    end

    im.TextWrapped("Public Party List")

    im.NextColumn()

    if im.Button("Refresh List") then
      print("attempting a refresh")
      TriggerServerEvent("receiveGetPublicPartyList", "derp")
    end

    im.NextColumn()
    im.Separator()

    if (UI_PUBLIC_PARTY_LIST ~= nil) then
      im.Columns(3, "Asd")

      local partyRows = stringToTable(UI_PUBLIC_PARTY_LIST, "|")

      for _, partyRow in pairs(partyRows) do
        local rowData = stringToTable(partyRow, ";")
        local partyName = rowData[1]
        local partyMembers = rowData[2]

        im.TextWrapped(partyName)

        im.NextColumn()

        im.TextWrapped(partyMembers)

        im.NextColumn()

        if im.Button("Join##" .. partyName) then
          UI.chatSend("/jp " .. partyName)
        end

        im.NextColumn()
        im.Separator()
      end
    end
  else
    im.Columns(2, "Asd")

    im.TextWrapped("Party List:")

    im.NextColumn()

    if im.Button("Leave Party " .. UI_CURRENT_PARTY_NAME) then
      UI.chatSend("/lp")
    end

    im.NextColumn()
    im.Separator()

    im.Columns(1, "Asd")

    if (UI_CURRENT_PARTY_PLAYER_LIST ~= nil) then
      im.TextWrapped(UI_CURRENT_PARTY_PLAYER_LIST)
    end

    im.NextColumn()

    if im.CollapsingHeader1("Invite Players") then
      if not inviteDropdownAlreadyOpen then
        inviteDropdownAlreadyOpen = true
        TriggerServerEvent("receiveGetPotentialInviteList", "derp")
      end

      if im.Button("Refresh List") then
        TriggerServerEvent("receiveGetPotentialInviteList", "derp")
      end

      im.NextColumn()
      im.Separator()

      if (UI_CURRENT_POTENTIAL_INVITE_LIST ~= nil) then
        im.Columns(2, "Asd")
        inviteListString = stringToTable(UI_CURRENT_POTENTIAL_INVITE_LIST, "|")

        for _, playerName in pairs(inviteListString) do
          im.TextWrapped(playerName)

          im.NextColumn()

          if im.Button("Invite##" .. playerName) then
            UI.chatSend("/invite " .. playerName)
            TriggerServerEvent("receivePartyInvite", "Pvt. Parts")
            TriggerServerEvent("receiveGetPotentialInviteList", "derp")
          end

          im.NextColumn()
          im.Separator()
        end
      end
    else
      inviteDropdownAlreadyOpen = false
    end
  end

  --- copying mission info into main menu

  base.endWindow()
end
-- draw functions <--

-- event handlers: -->
local function onClientReceivePublicPartyList(data)
  if (data ~= "") then
    UI_PUBLIC_PARTY_LIST = data
  else
    UI_PUBLIC_PARTY_LIST = nil
  end
end
local function onClientReceiveInvitationData(data)
  if (data ~= "") then
    UI_PARTY_INVITES = data
  else
    UI_PARTY_INVITES = nil
  end
end
local function onClientReceiveCurrentPartyData(data)
  if (data ~= "") then
    local partyInfo = stringToTable(data, "|")
    UI_CURRENT_PARTY_NAME = partyInfo[1]
    UI_CURRENT_PARTY_PLAYER_LIST = partyInfo[2]
  else
    UI_CURRENT_PARTY_NAME = nil
    UI_CURRENT_PARTY_PLAYER_LIST = nil
    TriggerServerEvent("receiveGetPublicPartyList", "derp") -- go ahead and refresh public parties at the same time
  end
end
local function onClientReceivePotentialInviteList(data)
  if (data ~= "") then
    UI_CURRENT_POTENTIAL_INVITE_LIST = data
  else
    UI_CURRENT_POTENTIAL_INVITE_LIST = nil
  end
end
-- event handlers <--

local function onExtensionLoaded()
  base.registerWindow("CarpPartyUI", im.ImVec2(450, 300)) -- party!

  AddEventHandler("onClientReceivePublicPartyList", onClientReceivePublicPartyList)
  AddEventHandler("onClientReceiveCurrentPartyData", onClientReceiveCurrentPartyData)
  AddEventHandler("onClientReceiveInvitationData", onClientReceiveInvitationData)
  AddEventHandler("onClientReceivePotentialInviteList", onClientReceivePotentialInviteList)

  log("I", "onExtensionLoaded", "Carp party UI initialized.")
end

local function showWindow(show)
  if show then
    base.showWindow("CarpPartyUI")
  else
    base.hideWindow("CarpPartyUI")
  end
end

local function onUpdate()
  drawPartyUI()
end

M.showWindow = showWindow
M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate

print("Carp UI loaded")
return M
