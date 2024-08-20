--====================================================================================
-- All work by Pastry.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP Charging station UI
--====================================================================================
local M = {}
print("Loading Carp Charging Station UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local lastPressed = 0

local fuelMap = nil

--local CHARGE_PER_CLICK = 2.5 -- 2.5 here == 10 liter in game??? -- the hell?
--local TOTAL_TRADER_CAPACITY = 500

-- draw functions: -->
local function drawChargingStationUI()
  if not base.beginWindow("ChargingStationUI", "Charging Station Menu", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  if not fuelMap then
    fuelMap = carp_vehicle.getCurrentFuelMap()
  end

  im.TextWrapped("Welcome to " .. ("this Charging station") .. "!") -- #TODO get name

  --im.Columns(2)
  --im.SetColumnWidth(0, 100)

  --im.NextColumn()

  if lastPressed < os.clock() - 0.5 then
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.flash_on,
        tooltip = "Recharge your electric vehicle.",
        text = "Recharge (5 kWh)",
        size = 16,
        func = function()
          carp_vehicle.requestCharge()

          lastPressed = os.clock()
        end
      }
    )
    --im.SameLine()
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.flash_on,
        tooltip = "Recharge your electric vehicle.",
        text = "Recharge (Max)",
        size = 16,
        func = function()
          carp_vehicle.requestCharge(fuelMap.capacity - fuelMap.current)

          lastPressed = os.clock()
        end
      }
    )
  else
    im.TextDisabled("Recharge (5 kWh)")
    im.TextDisabled("Recharge (Max)")
  end

  im.Columns(1)

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("ChargingStationUI", im.ImVec2(300, 450))

  log("I", "onExtensionLoaded", "Charging Station UI initialized.")
end

local function resetFuelMap()
  fuelMap = nil
end

local function showChargingStationUI(show)
  if show then
    resetFuelMap()
    base.showWindow("ChargingStationUI")
  else
    base.hideWindow("ChargingStationUI")
  end
end

local function onUpdate()
  drawChargingStationUI()
end

M.onExtensionLoaded = onExtensionLoaded
M.showChargingStationUI = showChargingStationUI
M.onUpdate = onUpdate

print("Charging Station UI loaded")
return M
