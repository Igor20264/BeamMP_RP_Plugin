--====================================================================================
-- All work by Pastry.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP gas station UI
--====================================================================================
local M = {}
print("Loading Carp Gas Station UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local lastPressed = 0

local traderName = nil
local traderInventory = nil
local fuelAmount = nil
local fuelMap = nil

local LITERS_PER_FUEL_UNIT = 2.5
local TOTAL_TRADER_CAPACITY = 500

-- draw functions: -->
local function drawGasStationUI()
  if not base.beginWindow("GasStationUI", "Gas Station Menu", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  if not fuelMap then
    fuelMap = carp_vehicle.getCurrentFuelMap()
  end

  if not traderName then
    traderName = carp_ui_trader.getCurrentTraderName()
  end

  if not traderInventory then
    traderInventory = carp_ui_trader.getCurrentTraderInventory()
  end

  if not fuelAmount then
    if
      traderInventory and traderInventory.inventory and traderInventory.inventory[1] and
        traderInventory.inventory[1].amount
     then
      fuelAmount = tonumber(traderInventory.inventory[1].amount) or 0
    else
      fuelAmount = 0
    end
  end

  im.TextWrapped("Welcome to " .. (traderName or "this gas station") .. "!")

  im.Columns(2)
  im.SetColumnWidth(0, 100)

  local arr = im.ArrayFloatByTbl({fuelAmount})
  im.PlotHistogram1(
    "",
    arr,
    im.GetLengthArrayFloat(arr),
    0,
    tonumber(fuelAmount) * LITERS_PER_FUEL_UNIT .. "/" .. TOTAL_TRADER_CAPACITY * LITERS_PER_FUEL_UNIT .. " Liters",
    0.0,
    500.0,
    im.ImVec2(90, 80)
  )

  im.NextColumn()

  if lastPressed < os.clock() - 0.5 then
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.local_gas_station,
        tooltip = "Refill 5 liters of fuel (or electricity!)",
        text = "Fuel (5 liters)",
        size = 16,
        func = function()
          carp_vehicle.requestRefuel(5)

          lastPressed = os.clock()
        end
      }
    )
    --im.SameLine()
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.local_gas_station,
        tooltip = "Fully refill your fuel tank (or Battery!)",
        text = "Fuel (Max)",
        size = 16,
        func = function()
          carp_vehicle.requestRefuel(fuelMap.capacity - fuelMap.current)

          lastPressed = os.clock()
        end
      }
    )

    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.flash_on,
        tooltip = "Refill your nitrous bottle",
        text = "Nitrous (5 liters)",
        size = 16,
        func = function()
          carp_vehicle.requestNitrousRefuel(5)

          lastPressed = os.clock()
        end
      }
    )
    --im.SameLine()
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.flash_on,
        tooltip = "Fully refill your nitrous bottle",
        text = "Nitrous (Max)",
        size = 16,
        func = function()
          carp_vehicle.requestNitrousRefuel(fuelMap.nitrousCapacity - fuelMap.nitrousRemaining)

          lastPressed = os.clock()
        end
      }
    )
  else
    im.TextDisabled("Fuel (5 liters)")
    im.TextDisabled("Fuel (Max)")
    im.TextDisabled("N*trous (5 liters)")
    im.TextDisabled("N*trous (Max)")
  end

  im.Columns(1)

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("GasStationUI", im.ImVec2(300, 450))

  log("I", "onExtensionLoaded", "Gas Station UI initialized.")
end

local function resetTraderVariables()
  traderName = nil
  traderInventory = nil
  fuelAmount = nil
end
local function resetFuelMap()
  fuelMap = nil
end

local function showGasStationUI(show)
  if show then
    resetTraderVariables()
    resetFuelMap()
    base.showWindow("GasStationUI")
  else
    base.hideWindow("GasStationUI")
  end
end

local function onUpdate()
  drawGasStationUI()
end

M.onExtensionLoaded = onExtensionLoaded
M.showGasStationUI = showGasStationUI
M.onUpdate = onUpdate

print("Gas Station UI loaded")
return M
