--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP UI
--====================================================================================
local M = {}
print("Loading Carp Dealership UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local dealershipName = nil
local groupedVehicles = {}

local colors = {
  bought = im.ImColorByRGB(26, 240, 119, 255),
  buy = im.ImColorByRGB(255, 192, 18, 255),
  locked = im.ImColorByRGB(247, 54, 54, 255)
}
local headingFont = "cairo_semibold_large"
local skip_confirm = im.BoolPtr(false)
--================ Vehicle Drawing Functions ================--
local function drawLockedVehicle(vehicle)
  base.uiIconImageButton(base.icons.lock, nil, colors.locked.Value)

  if im.IsItemHovered() then
    im.SetTooltip(
      "This vehicle is locked. Purchase at least one vehicle in all levels below in the same class to unlock this one."
    )
  end

  im.SameLine()

  im.Text("$" .. vehicle.price) -- im.Text("Locked")

  if im.IsItemHovered() then
    im.SetTooltip(
      "This vehicle is locked. Purchase at least one vehicle in all levels below in the same class to unlock this one."
    )
  end
end

local function drawPurchasableVehicle(vehicle)
  local pressed = base.uiIconImageButton(base.icons.shopping_cart, nil, colors.buy.Value)

  im.SameLine()
  im.Text("$" .. vehicle.price)
  if pressed then
    if skip_confirm[0] then
      UI.chatSend("/buy " .. vehicle.jbeamName)
      return
    end

    carp_ui_confirmationwindow.showConfirmationPopup(
      true,
      {
        windowTitle = "Confirm Vehicle Purchase",
        confirmationHeading = string.format("Purchasing %s.", vehicle.name),
        confirmationText = string.format("This would cost you $%d.\nAre you sure?", vehicle.price),
        onConfirmationFn = function()
          UI.chatSend("/buy " .. vehicle.jbeamName)
        end
      }
    )
  end
end

local function drawOwnedVehicle(vehicle)
  base.uiIconImageButton(base.icons.check or base.icons.done, nil, colors.bought.Value)
  im.SameLine()

  if vehicle.isProLicensed then
    im.Text("Prolicensed")
  else
    if im.Button("Prolicense $" .. vehicle.prolicensePrice .. "##" .. vehicle.jbeamName) then
      if skip_confirm[0] then
        UI.chatSend("/prolicense " .. vehicle.jbeamName)
        return
      end
      carp_ui_confirmationwindow.showConfirmationPopup(
        true,
        {
          windowTitle = "Confirm Prolicense Purchase",
          confirmationHeading = string.format("Purchasing Prolicense for %s.", vehicle.name),
          confirmationText = string.format("This would cost you $%d.\nAre you sure?", vehicle.prolicensePrice),
          onConfirmationFn = function()
            UI.chatSend("/prolicense " .. vehicle.jbeamName)
          end
        }
      )
    end
  end
end

local function drawVehicleItem(vehicle)
  im.BeginGroup()

  im.Text(vehicle.name)

  if vehicle.isOwned then
    drawOwnedVehicle(vehicle)
  elseif vehicle.canBeBought then
    drawPurchasableVehicle(vehicle)
  else
    drawLockedVehicle(vehicle)
  end

  im.EndGroup()

  --if _ < #vehicleGroup then im.Separator() end -- wish this worked as intended
end

local function drawVehicleGroup(vehicleGroup)
  im.BeginGroup()

  for _, vehicle in ipairs(vehicleGroup) do
    drawVehicleItem(vehicle)
  end

  im.EndGroup()
end
--============ END Vehicle Drawing Functions END ============--

--=============== Dealership Layout Functions ===============--
local function drawTierText(tierString)
  for i = 1, groupedVehicles.maxTier do
    base.textWithFont(tierString .. tostring(i), headingFont)

    im.NextColumn()
  end
end

local function drawDealershipRow(vehicleCategoryRow)
  for i = 1, groupedVehicles.maxTier do
    if vehicleCategoryRow[i] then
      drawVehicleGroup(vehicleCategoryRow[i])
    end
    im.NextColumn()
  end
end

local function buildDealershipLayout()
  im.Columns(groupedVehicles.maxTier + 1, "dealershipList") -- +1 because pico is 0
  -- Print tier text
  im.NextColumn() -- skip pico
  drawTierText("A")

  --im.Text('A') im.NextColumn()
  im.NextColumn() -- skip pico
  drawDealershipRow(groupedVehicles.a)

  im.Separator()

  --im.Text('B') im.NextColumn()
  drawVehicleGroup(groupedVehicles.a[0]) -- pico
  im.NextColumn()
  drawDealershipRow(groupedVehicles.b)

  -- Print tier text
  im.NextColumn() -- skip pico
  drawTierText("B")

  im.Columns(1, "dealershipList")
end

local function drawDealershipUI()
  if not base.beginWindow("CarpDealershipUI", "Dealership", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))
  base.textWithFont("Welcome to " .. (dealershipName or "[insert funny dealership name]") .. "!", headingFont, true)

  -- still loading, show loading message:
  if not groupedVehicles.maxTier then
    base.textWithFont("Loading data...", headingFont, true)
    base.endWindow()
    return
  end
  im.Checkbox("Skip Purchase Confirmation", skip_confirm)
  buildDealershipLayout()

  base.endWindow()
end
--=========== END Dealership Layout Functions END ===========--

local function showWindow(show, name)
  if show then
    dealershipName = name
    base.showWindow("CarpDealershipUI")
  else
    base.hideWindow("CarpDealershipUI")
  end
end

local function onReceiveDealershipData(data)
  local keyValuePair = jsonDecode(data)
  local vehicleArray = {}

  -- turn incoming data sortable
  local maxTier = 1
  for k, v in pairs(keyValuePair) do
    v.jbeamName = k
    if v.tier.level > maxTier then
      maxTier = v.tier.level
    end
    table.insert(vehicleArray, v)
  end

  -- sort vehicles
  table.sort(
    vehicleArray,
    function(v1, v2)
      return v1.price < v2.price
    end
  ) -- price decreasing
  
  groupedVehicles = {maxTier = maxTier, a = {}, b = {}}
  local a, b = {}, {}
  for k, v in ipairs(vehicleArray) do
    local classname = v.tier.class == "A" and "a" or "b"
    if not groupedVehicles[classname][v.tier.level] then
      groupedVehicles[classname][v.tier.level] = {
        name = v.tier.class .. v.tier.level,
        class = v.tier.class,
        level = v.tier.level,
      }
    end
    table.insert(groupedVehicles[classname][v.tier.level], v)
  end
end

local function onExtensionLoaded()
  base.registerWindow("CarpDealershipUI", im.ImVec2(450, 300)) -- dealership stuff, shows up at a car dealer

  AddEventHandler("onReceiveDealershipData", onReceiveDealershipData)

  log("I", "onExtensionLoaded", "Dealership UI initialized.")
end

local function onUpdate()
  drawDealershipUI()
end

M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate
M.showWindow = showWindow

print("Carp UI loaded")
return M
