--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP spawn UI
--====================================================================================
local M = {}
print("Loading Carp Corporation UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base
local headingFont = "cairo_semibold_large"

local UI_CURRENT_POTENTIAL_INVITE_LIST = nil
local inviteDropdownAlreadyOpen = false
local corporationData = nil

--
local buf_size = 64
local tag_buf_size = 5
local tagline_buf_size = 80
local corporationNameBuffer = im.ArrayChar(buf_size)
local corporationTagBuffer = im.ArrayChar(tag_buf_size)
local inviteFieldBuffer = im.ArrayChar(buf_size)
local corporationTaglineBuffer = im.ArrayChar(tagline_buf_size)

local corporateColorPtr = im.ArrayFloat(3)
corporateColorPtr[0] = im.Float(1.0)
corporateColorPtr[1] = im.Float(0.0)
corporateColorPtr[2] = im.Float(0.2)

local UI_CURRENT_POTENTIAL_INVITE_LIST = nil

local function updateCorporationsUi(data)
  corporationData = data
end

local function onClientReceivePotentialInviteList(data)
  if (data ~= "") then
    UI_CURRENT_POTENTIAL_INVITE_LIST = data
  else
    UI_CURRENT_POTENTIAL_INVITE_LIST = nil
  end
end

local function getCurrentCorporation()
  return corporationData
end

-- tabs: -->
local function renderCorpoInfoTab()
  if im.BeginTabItem("Information##CorpoInfoTab", nil, 0) then
    if not corporationData then
      im.TextWrapped("")
    else
      im.Columns(2)

      -- Mission Earnings
      carp_ui_base.drawSmallIconWithText(
        {
          icon = carp_ui_base.icons.simobject_bng_waypoint,
          size = 16,
          text = "$" .. corporationData.corporationMissionEarnings,
          tooltip = "Mission Earnings"
        }
      )

      im.NextColumn()

      -- Corporate Account Balance
      carp_ui_base.drawSmallIconWithText(
        {
          icon = carp_ui_base.icons.monetization_on,
          size = 16,
          text = "$" .. corporationData.corporationBalance,
          tooltip = "Balance"
        }
      )

      im.Columns(1)

      im.TextWrapped("")

      carp_ui_base.drawSmallIconWithText(
        {
          icon = carp_ui_base.icons.fg_box_utility_trailer,
          size = 16,
          text = "Trading Earnings:"
        }
      )
      im.SameLine()
      im.TextWrapped("")

      if im.BeginTable("#corpoearningstats", 2) then
        -- im.TableSetupScrollFreeze(0, 1)
        im.TableSetupColumn("Commodity")
        im.TableSetupColumn("Earnings")
        im.TableHeadersRow()
        im.TableNextColumn()

        if corporationData.corporationCommoditiesTraded then
          for _, item in pairs(corporationData.corporationCommoditiesTraded) do
            im.TextUnformatted(M.commodityNameMap[item.commoditySlug] or "Unknown")
            im.TableNextColumn()
            im.TextUnformatted(string.format("$%s", item.earnings))
            im.TableNextColumn()
          end
        end
      end
    end
    im.EndTable()

    im.TextWrapped("")
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.person_add,
        text = "Biggest Earners:",
        size = 16
      }
    )
    im.SameLine()
    im.TextWrapped("")

    if im.BeginTable("#corpoplayerstats", 2) then
      -- im.TableSetupScrollFreeze(0, 1)
      im.TableSetupColumn("Player")
      im.TableSetupColumn("Earnings")
      im.TableHeadersRow()
      im.TableNextColumn()

      if corporationData and corporationData.corporationEarners then
        for player, earnings in pairs(corporationData.corporationEarners) do
          im.TextUnformatted(player)
          im.TableNextColumn()
          im.TextUnformatted(string.format("$%s", earnings))
          im.TableNextColumn()
        end
      end
    end
    im.EndTable()
    im.EndTabItem()
  end
end

local function renderCorpoMembersTab()
  if not corporationData then
    return
  end

  if im.BeginTabItem("Members##CorpoMembersTab", nil, 0) then
    im.TextWrapped("Manage Members:")
    if im.BeginTable("##corpoplayermanage", 2) then
      -- im.TableSetupScrollFreeze(0, 1)
      im.TableSetupColumn("Player")
      im.TableSetupColumn("Manage")
      im.TableHeadersRow()
      im.TableNextColumn()

      if corporationData.corporationMembers then
        local whoAmI = getPlayers()[MPConfig.getPlayerServerID()]
        local whatsMyName = ""
        if whoAmI then
          whatsMyName = '"'..whoAmI.name..'"' -- how did the double quote get in the name
        end
        for memberID, name in pairs(corporationData.corporationMembers) do
          im.Text((name and tostring(name)) or "FAILED")
          im.TableNextColumn()

          local isSelf = whatsMyName == name
          if corporationData.isCorporationOwner and not isSelf then -- no kicking self as owner
            if im.Button("Kick##" .. memberID) then
              TriggerServerEvent("removePlayerFromCorporation", memberID)
            end
          end
          if not corporationData.isCorporationOwner and isSelf then -- can kick self as non-owner
            if im.Button("Leave##" .. memberID) then
              TriggerServerEvent("removePlayerFromCorporation", memberID)
            end
          end

          im.TableNextColumn()
        end
      end
    end
    im.EndTable()
    im.EndTabItem()
  end
end

local function renderCorpoInvitesTab()
  if im.BeginTabItem("Invites##CorpoInvitesTab", nil, 0) then
    if
      corporationData ~= nil and corporationData.currentCorporationPop ~= nil and
        corporationData.maxCorporationPop ~= nil
     then
      im.TextWrapped(
        "You currently have " ..
          corporationData.currentCorporationPop .. "/" .. corporationData.maxCorporationPop .. " members."
      )
    end
    im.TextWrapped("You can expand your corporation by increasing your profits.")
    im.Text("")

    im.TextWrapped("Manage Invites:")

    if im.CollapsingHeader1("Invite Players") then
      if not UI_CURRENT_POTENTIAL_INVITE_LIST and not inviteDropdownAlreadyOpen then
        inviteDropdownAlreadyOpen = true
        TriggerServerEvent("receiveGetCorporationInviteList", "derp")
      end

      if im.Button("Refresh List") then
        TriggerServerEvent("receiveGetCorporationInviteList", "derp")
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
            TriggerServerEvent("invitePlayerToCorporation", playerName)
          end

          im.NextColumn()
          im.Separator()
        end
      end
    else
      inviteDropdownAlreadyOpen = false
    end

    im.EndTabItem()
  end
end

local function renderCorpoSettingsTab()
  if im.BeginTabItem("Settings##CorpoSettingsTab", nil, 0) then
    if not corporationData then
      return
    end

    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.format_paint,
        size = 16,
        text = "Corporate Branding Color ($50,000)",
        tooltip = "You can set a color for your turf here."
      }
    )
    im.ColorEdit3("Corporate Color", corporateColorPtr)

    if im.Button("Purchase Color") then
      local r = corporateColorPtr[0]
      local g = corporateColorPtr[1]
      local b = corporateColorPtr[2]
      TriggerServerEvent("setCorporationColor", r .. "|" .. g .. "|" .. b)
    end

    im.Text("")

    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.fingerprint,
        size = 16,
        text = "Corporate Tagline ($25,000)",
        tooltip = "Choose a tagline that embodies your corporation's core beliefs."
      }
    )

    im.TextWrapped("Tagline:")
    im.InputText("##Tagline", corporationTaglineBuffer, tagline_buf_size)

    if im.Button("Purchase Tagline") then
      TriggerServerEvent("setCorporationTagline", ffi.string(corporationTaglineBuffer))
    end

    im.EndTabItem()
  end
end

-- draw functions: -->
local function renderReceivedInvites()
  im.TextWrapped("You have been invited to the following corporations:")
  im.TextWrapped("")

  if not corporationData or not corporationData.corporationInvites then
    return
  end

  for _, invite in pairs(corporationData.corporationInvites) do
    im.TextWrapped(invite.name .. " ")
    im.SameLine()
    if im.Button("Accept##" .. invite.corporationID) then
      TriggerServerEvent("acceptCorporationInvite", invite.corporationID)
    end
  end
end

local function renderNotInCorporation()
  base.uiIconImageButton(base.icons.sentiment_dissatisfied, im.ImVec2(26, 26))
  im.SameLine()
  base.textWithFont("You are not in a corporation.", headingFont)

  if corporationData and corporationData.canCreateCorporation then
    im.TextWrapped("Corporations are groups that you can create to play with friends and track stats together.")
    im.TextWrapped("You can create a corporation for $250,000.")

    im.TextWrapped("")

    base.uiIconImageButton(base.icons.fiber_new, im.ImVec2(16, 16))
    im.SameLine()
    im.TextWrapped("Corporation Name:")
    im.InputText("##Name", corporationNameBuffer, buf_size)

    base.uiIconImageButton(base.icons.fiber_new, im.ImVec2(16, 16))
    im.SameLine()
    im.TextWrapped("Corporation Tag:")
    im.InputText("##Tag (4 characters)", corporationTagBuffer, tag_buf_size)

    if im.Button("Create") then
      local corpName = trim(ffi.string(corporationNameBuffer))
      local corpTag = trim(ffi.string(corporationTagBuffer))
      if corpName == "" or corpTag == "" then
        carp_ui_confirmationwindow.showConfirmationPopup(
          true,
          {
            windowTitle = "Blank Corporation Creation",
            confirmationHeading = string.format("Creating [%s] %s.", corpTag, corpName),
            confirmationText = "You can't create a blank corporation. :)"
          }
        )
      else
        carp_ui_confirmationwindow.showConfirmationPopup(
          true,
          {
            windowTitle = "Confirm Corporation Creation",
            confirmationHeading = string.format("Creating [%s] %s.", corpTag, corpName),
            confirmationText = "This would cost you $250,000.\nAre you sure?",
            onConfirmationFn = function()
              TriggerServerEvent("createCorporation", string.format("%s|%s", corpName, corpTag))
            end
          }
        )
      end

    end
  else
    im.TextWrapped("You need to be level 25 or higher to be able to create a corporation.")
    im.TextWrapped("Creating a corporation costs $250,000.")
    im.TextWrapped("Alternatively, you can try to get yourself invited into one, once you are level 5 or higher.")
  end

  renderReceivedInvites()
end

local function renderCorporation()
  if not corporationData or not corporationData.isInCorporation then
    return renderNotInCorporation()
  end

  local corpName = "[" .. corporationData.corporationTag .. "] " .. corporationData.corporationName

  base.uiIconImageButton(base.icons.location_city, im.ImVec2(26, 26))
  im.SameLine()
  base.textWithFont(corpName, headingFont)

  if corporationData.isCorporationOwner then
    im.TextWrapped("This is your corporation!")
  end

  if im.BeginTabBar("##CorpoTabBar") then
    renderCorpoInfoTab()
    renderCorpoMembersTab()
    renderCorpoInvitesTab()
    renderCorpoSettingsTab()
    im.EndTabBar()
  end
end

local function drawCorporationPopup()
  if not base.beginWindow("CorporationUI", "Corporations", nil, false) then
    base.endWindow()
    return
  end
  im.SetWindowFontScale(base.getUISetting("window_scale"))

  renderCorporation()

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("CorporationUI", im.ImVec2(75, 215))

  AddEventHandler("onClientReceivePotentialInviteList", onClientReceivePotentialInviteList)

  if base.isWindowVisible("CorporationUI") then
    M.showWindow("CorporationUI")
    M.saveUISetting("hide_window_" .. "CorporationUI", false)
  end

  log("I", "onExtensionLoaded", "Corporation UI initialized.")
end

local function onUpdate()
  drawCorporationPopup()
end

M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate
M.updateCorporationsUi = updateCorporationsUi
M.getCurrentCorporation = getCurrentCorporation

print("Corporation UI loaded")

M.commodityNameMap = {
  missionItem = "MISSION_ITEM",
  ironore = "Iron Ore",
  goldore = "Gold Ore",
  emptybarrel = "Empty Barrel",
  silicaore = "Silica Ore",
  basaltrock = "Basalt Rock",
  uncutdiamonds = "Uncut diamonds",
  diamonds = "Diamonds",
  fuel = "Fuel",
  waterbarrel = "Water Barrel",
  ironingot = "Iron Ingot",
  goldingot = "Gold Ingot",
  concrete = "Concrete",
  silicasand = "Silica Sand",
  slag = "Slag",
  rebar = "Rebar",
  toolsteel = "Tool Steel",
  jewelry = "Jewelry",
  goldscraps = "Gold Scraps",
  rockwool = "Rockwool",
  silicon = "Silicon",
  boxoffasteners = "Box Of Fasteners",
  tools = "Tools",
  shed = "Shed",
  heavyequipment = "Heavy Equipment",
  miningmap = "Mining Map",
  logs = "Logs",
  ecopackaging = "Eco Packaging",
  wheat = "Wheat",
  milk = "Milk",
  spice = "Spice",
  rawmeat = "Raw Meat",
  carp = "Carp",
  woodbark = "Wood Bark",
  woodplanks = "Wood Planks",
  bottledwater = "Bottled Water",
  flour = "Flour",
  packagedfish = "Packaged Fish",
  packagedmeat = "Packaged Meat",
  woodenbox = "Wooden Box",
  woodpulp = "Wood Pulp",
  pastry = "Pastry",
  lunch = "Lunch",
  gift = "Gift",
  paper = "Paper",
  toiletpaper = "Toilet Paper",
  deluxemeals = "Deluxe Meals",
  patents = "Patents",
  book = "Book",
  highendshed = "High-End Shed",
  copperore = "Copper Ore",
  crudeoil = "Crude Oil",
  researchnote = "Research Note",
  sand = "Sand",
  recycledplastic = "Recycled Plastic",
  copperingots = "Copper Ingots",
  oillubricants = "Oil Lubricants",
  rubber = "Rubber",
  glass = "Glass",
  rubberparts = "Rubber Parts",
  carparts = "Car Parts",
  carvinyls = "Car Vinyls",
  tires = "Tires",
  animefigures = "Anime Figures",
  electronics = "Electronics",
  heavydutyparts = "Heavy Duty Parts",
  offroadtires = "Offroad Tires",
  rosegoldjewelry = "Rose Gold Jewelry",
  diamondtiptools = "Diamond-Tip Tools",
  racingparts = "Racing Parts"
}

return M
