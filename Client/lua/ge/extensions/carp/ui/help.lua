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

-- draw functions: -->
local function drawTeleportToGarage()
  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.reply_all,
      tooltip = "You should only use this if you have exhausted all other options.",
      text = "Teleport to a random garage (tow costs apply)",
      size = 24,
      func = function()
        carp_ui_confirmationwindow.showConfirmationPopup(
          true,
          {
            windowTitle = "Confirm Tow",
            confirmationHeading = "Towing can be *VERY* expensive. Are you sure?",
            confirmationText = "You should only do this if you've already tried every other method of recovery. If you haven't yet pressed AND held Insert for a few seconds, do that now. If you're unsure of how to continue, join the Discord and ask for help.",
            onConfirmationFn = function()
              carp.teleportToRandomGarage()
            end
          }
        )
      end
    }
  )
end

local function drawEmergencyRefuel()
  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.local_gas_station,
      tooltip = "Emergency Refuel: way more expensive!",
      text = "Refuel",
      size = 24,
      func = function()
        UI.chatSend("/refuel")
      end
    }
  )
end

local function drawNearestLocationMenu()
  local icon_size = base.getIconSize()

  --im.Columns(2, "carpnearestlocations")

  -- dont show self-service GPS stuff if you have a mission
  if not carp.getCurrentMission().missionDestination and not carp_race.isInRace() then
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.my_location,
        text = "Set route to:"
      }
    )

    local entries = {
      {key = "contact", title = "Trader Spot (Missions)", icon = "person_pin_circle"},
      {key = "garage", title = "Garage (Repairs/Parts)", icon = "build"},
      {key = "gas", title = "Gas (Refueling)", icon = "local_gas_station"},
      {key = "charger", title = "Charger (Recharging)", icon = "flash_on"},
      {key = "cardealership", title = "Dealership (New Cars)", icon = "fg_vehicle_sports_car"}
    }

    for _, entry in pairs(entries) do
      if base.uiIconImageButton(base.icons[entry.icon], icon_size) then
        carp.getNearestPOI(entry.key)
      end
      im.SameLine() --im.TextWrapped(entry.title) --simply using the 'label' parameter removes the icon bg
      if im.IsItemHovered() then
        im.SetTooltip(entry.title)
      end
    end

    im.Text("")
  end
end

local function drawNodegrabMenu()
  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.directions_run,
      tooltip = "Enable weak node grabbing: push it out yourself!",
      text = "Weak node grabbing",
      size = 24,
      func = function()
        carp.enableNodegrab("yourself")
      end
    }
  )

  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.fitness_center,
      tooltip = "Enable strong node grabbing: pay for help!",
      text = "Strong node grabbing",
      size = 24,
      func = function()
        carp.enableNodegrab("locals")
      end
    }
  )

  im.Separator()
end

local function drawHelpUI()
  if not base.beginWindow("CarpHelpUI", "Help") then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  im.Columns(2)

  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.poi_exclamationmark_round,
      tooltip = "Help, tutorials and more: join our Discord!",
      size = 24,
      text = "Join our Discord!",
      func = function()
        openWebBrowser("https://www.beamng.com/proxy.php?link=https://discord.gg/carp")
      end
    }
  )

  im.NextColumn()

  drawNodegrabMenu()

  im.NextColumn()

  drawEmergencyRefuel()

  im.NextColumn()

  drawNearestLocationMenu()

  im.NextColumn()

  drawTeleportToGarage()

  im.NextColumn()

  if not carp.getCurrentMission().missionDestination and not carp_race.isInRace() then
    im.Separator()
  end

  base.endWindow()
end
-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("CarpHelpUI", im.ImVec2(450, 300), nil, false)

  base.registerDrawItem(
    "nearestLocations",
    "Nearest locations",
    drawNearestLocationMenu,
    function()
      return not carp.getCurrentMission().missionDestination and not carp_race.isInRace()
    end
  )
  base.registerDrawItem("emergencyRefuel", "Emergency refuel", drawEmergencyRefuel)
  base.registerDrawItem("nodegrabMenu", "Rescue system", drawNodegrabMenu)

  if not base.getUISetting("hide_window_CarpHelpUI") then
    base.showWindow("CarpHelpUI")
  end

  log("I", "onExtensionLoaded", "Carp help UI initialized.")
end

local function showWindow(show)
  if show then
    base.showWindow("CarpHelpUI")
  else
    base.hideWindow("CarpHelpUI")
  end
end

local function onUpdate()
  drawHelpUI()
end

M.showWindow = showWindow
M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate

print("Carp UI loaded")
return M
