--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP spawn UI
--====================================================================================
local M = {}
print("Loading Carp CaRPTrader UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local gui_module = require("ge/extensions/editor/api/gui")
local gui = {setupEditorGuiTheme = nop}
local im = ui_imgui
local base = carp_ui_base

local buf_size = 64
local headingFont = "cairo_semibold_large"
local icon_size = base.getIconSize()

local currentTrader = nil
local currentTraderName = nil

local purchaseAmounts = {}

local minPurchaseAmount = 1
local maxPurchaseAmount = 40

local inventorySlotsCount = nil
local usedInventorySlots = nil

local traderOwners = nil

local function getCurrentTraderInventory()
  return currentTrader
end

--================ Item Drawing Functions ================--
local function drawDummyItem()
  im.Dummy(im.ImVec2(icon_size.x / 2, icon_size.y / 2))
end

local function itemCanBeTraded(item, commodityList)
  if not currentTrader or not item or not commodityList then
    return false
  end

  if tableContainsValue(commodityList, item.itemSlug) then
    return true
  end

  return false
end

local function renderSellableItem(item, requestedItems)
  local amountInInventory = carp_ui_vehicleinventory.getItemAmountInInventory(item.itemSlug)

  if tonumber(amountInInventory) > 0 then
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.file_upload,
        iconColor = im.ImVec4(0.5, 1, 0.5, 1),
        tooltip = "Sell all of this item to this trader at once",
        text = "Sell " .. amountInInventory .. "x " .. item.name .. " to trader for: $" .. (item.sellPrice or "999999"),
        size = 16,
        func = function()
          TriggerServerEvent(
            "sellItemToTrader",
            item.itemSlug .. "|" .. (amountInInventory or carp_ui_vehicleinventory.MIN_SELL_AMOUNT)
          )
        end
      }
    )
  end
end

local function renderInventoryItem(item)
  local itemNameLabel = (item.name or "Item")
  local buyingLabel = "You can buy it here for: $" .. (item.buyPrice or "999")
  local weightLabel = "Weight: " .. (item.weight or "999") .. "kg per item"
  local cargoUsageLabel = "Cargo: uses " .. (item.cargoUsage or "1") .. " slot(s)"

  -- if it can't be traded, or there's no stock, just stop it here
  -- and don't render the sell/buy buttons
  --[[   if not itemCanBeTraded(item, currentTrader.produces) or tonumber(item.amount) == 0 then
    return
  end ]]
  base.drawSmallIconWithText(
    {
      icon = base.icons.ab_asset_prefab,
      text = itemNameLabel
    }
  )

  if itemCanBeTraded(item, currentTrader.produces) then
    if im.BeginTable(item.itemSlug, 2) then
      im.TableNextColumn()
      base.drawSmallIconWithText(
        {
          icon = base.icons.symbol_dollar,
          iconColor = im.ImVec4(1, 0.5, 0.5, 1),
          text = "$" .. tostring(truncateNumber(tonumber(item.buyPrice), 0)),
          tooltip = buyingLabel,
          size = 16
        }
      )

      im.TableNextColumn()
      base.drawSmallIconWithText(
        {
          icon = base.icons.simobject_occlusion_volume,
          text = item.weight .. "kg",
          tooltip = weightLabel,
          size = 16
        }
      )

      im.TableNextColumn()
      base.drawSmallIconWithText(
        {
          icon = base.icons.ab_asset_mesh,
          text = item.cargoUsage .. " slot(s)",
          tooltip = cargoUsageLabel,
          size = 16
        }
      )

      im.EndTable()
    end

    if not purchaseAmounts[item.itemSlug]then
      purchaseAmounts[item.itemSlug] = im.IntPtr(inventorySlotsCount or 40)
    end
    local purchaseAmount = purchaseAmounts[item.itemSlug]
    im.SliderInt("Amount to buy##"..item.itemSlug, purchaseAmount, minPurchaseAmount, inventorySlotsCount or maxPurchaseAmount)

    if not tonumber(purchaseAmount[0]) or not minPurchaseAmount then
      -- do nothing!
      im.TextWrapped("bad")
      print("tonumber(purchaseAmount[0])")
      print(tonumber(purchaseAmount[0]))
      print("minPurchaseAmount")
      print(minPurchaseAmount)
      return
    end

    base.drawSmallIconWithText(
      {
        icon = base.icons.attach_money,
        iconColor = im.ImVec4(1, 0.9, 0.4, 1),
        text = "Buy",
        tooltip = "Buys this amount from the trader",
        func = function()
          if tonumber(purchaseAmount[0]) >= minPurchaseAmount then
            TriggerServerEvent("buyItemFromTrader", item.itemSlug .. "|" .. purchaseAmount[0])
          end
        end
      }
    )

    im.SameLine()
    im.TextWrapped("")
    im.SameLine()

    base.drawSmallIconWithText(
      {
        icon = base.icons.symbol_dollar,
        iconColor = im.ImVec4(1, 0.9, 0.4, 1),
        text = "Buy Max",
        tooltip = "Buys the maximum amount from the trader that will fit in your inventory",
        func = function()
          TriggerServerEvent(
            "buyItemFromTrader",
            item.itemSlug ..
              "|" .. math.floor(((inventorySlotsCount - usedInventorySlots) / item.cargoUsage) or minPurchaseAmount)
          )
        end
      }
    )
  end

  if itemCanBeTraded(item, currentTrader.requests) then
    local costLabel = "You can sell it here for: $" .. (item.sellPrice or "999")

    renderSellableItem(item, currentTrader.requests)
  end
end

local function renderInventoryItems()
  if not currentTrader then
    im.TextWrapped("Loading inventory for this location...")
    return
  end

  if not currentTrader.inventory then
    im.TextWrapped("Trader inventory is empty.")
    return
  end

  inventorySlotsCount = carp_ui_vehicleinventory.getInventorySlotsCount()
  usedInventorySlots = carp_ui_vehicleinventory.getUsedInventorySlots()

  base.drawSmallIconWithText(
    {
      text = "Stock:",
      textColor = {0.9, 0.95, 1}
    }
  )

  -- draw inventory item blocks
  if im.BeginTable("traderItems", 2) then
    for idx, item in pairs(currentTrader.inventory) do
      im.TableNextColumn()
      renderInventoryItem(item)
      im.Separator()
    end
    im.EndTable()
  end
  im.Spacing(im.ImVec2(0, 16)) -- spacing to avoid resizing triangle blocking button
end

--================ Inventory Mission Drawing Functions ================--
local function renderMissionUI()
  local missionLabel = "Get a mission"
  local helpText =
    "Missions are easy point-A-to-point-B deliveries " ..
    "for when you don't have enough money to do business by yourself." ..
      " They don't pay as well as trading, but are a good starting point. "

  base.drawSmallIconWithText(
    {
      icon = base.icons.stars,
      text = missionLabel,
      tooltip = helpText,
      func = function()
        carp.sendMissionRequest()
      end
    }
  )

  im.Separator()
end

--=============== Trader Layout Functions ===============--
local function printDemandedProducedItems()
  if not currentTrader or not currentTrader.inventory then
    return
  end

  local largestAmount =
    math.max(
    (currentTrader and currentTrader.produces and #currentTrader.produces or 0),
    (currentTrader and currentTrader.requests and #currentTrader.requests) or 0
  )

  im.Columns(2)

  -- draw heading for produced
  base.drawSmallIconWithText(
    {
      text = "Produces:",
      textColor = {0.9, 1, 0.9}
    }
  )

  im.NextColumn()

  -- draw heading for requested
  im.TextWrapped("")
  base.drawSmallIconWithText(
    {
      text = "Buys:",
      textColor = {1, 1, 0.9}
    }
  )

  im.NextColumn()

  local currentIndex = 1
  while currentTrader and
    ((currentTrader.produces and currentTrader.produces[currentIndex]) or
      (currentTrader.requests and currentTrader.requests[currentIndex])) do
    -- loop through produced items
    if currentTrader.produces and currentTrader.produces[currentIndex] then
      local commodity = currentTrader.produces[currentIndex]
      local commodityName = carp_commodities.getCommodityBySlug(commodity).name

      base.drawSmallIconWithText(
        {
          icon = base.icons.ab_asset_prefab_open,
          text = commodityName
        }
      )

      im.NextColumn()
    else
      im.NextColumn()
    end

    -- loop through requested items
    if currentTrader.requests and currentTrader.requests[currentIndex] then
      local commodity = currentTrader.requests[currentIndex]
      local commodityName = carp_commodities.getCommodityBySlug(commodity).name

      base.drawSmallIconWithText(
        {
          icon = base.icons.shopping_basket,
          text = commodityName
        }
      )

      im.NextColumn()
    else
      im.NextColumn()
    end

    currentIndex = currentIndex + 1
  end

  im.Columns(1)

  im.Separator()
end

local function renderCorporationSkills(turfData)
  local currentCorp = carp_ui_corporation.getCurrentCorporation()

  if
    currentCorp and currentCorp.corporationName and turfData and turfData.corporationName and
      currentCorp.corporationName == turfData.corporationName
   then
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.flash_on,
        tooltip = "For 10 minutes, drastically increases commodities produced per tick, and removes the limit on this trader's stock.",
        text = "Production Boost (C$100,000)",
        iconColor = im.ImVec4(.65, .65, .15, 1),
        func = function()
          TriggerServerEvent("activateWaypointProductionBoost", turfData.waypointName)
        end
      }
    )
  end
end

local function renderCorporationInfo()
  if currentTrader and currentTrader.controllingCorporations then
    if currentTrader.controlledBy then
      local controllingCorpsString = ""

      for name, percentage in pairs(currentTrader.controllingCorporations) do
        controllingCorpsString =
          controllingCorpsString .. name .. ": " .. string.format("%.1f", tostring(percentage)) .. "%%" .. "\n"
      end

      if traderOwners and traderOwners[currentTraderName] then
        local turfInfo = traderOwners[currentTraderName]

        local name = turfInfo.corporationName or ""
        local tag = turfInfo.corporationTag or ""
        local color = turfInfo.corporationColor or ""
        local tagline = turfInfo.corporationTagline or ""
        local location = turfInfo.location or ""

        local splitColor = splitString(color, "|")
        local colorR = (splitColor[1] and tonumber(splitColor[1])) or 1
        local colorG = (splitColor[2] and tonumber(splitColor[2])) or 1
        local colorB = (splitColor[3] and tonumber(splitColor[3])) or 1

        if tagline and tagline == "" then
          tagline = nil
        end

        base.drawSmallIconWithText({icon = base.icons.store_mall_directory, size = 16})

        im.SameLine(16, 20)

        im.TextWrapped("This trader is controlled by:")
        if im.IsItemHovered() then
          im.SetTooltip(controllingCorpsString)
        end

        uiTextColoredWithFont(im.ImVec4(colorR, colorG, colorB, 1), "   " .. "[" .. tag .. "] " .. name, "cairo_bold")

        if tagline then
          uiTextColoredWithFont(
            im.ImVec4(math.min(1, colorR * 1.3), math.min(1, colorG * 1.3), math.min(1, colorB * 1.3), 1),
            "   " .. tagline
          )
        end

        renderCorporationSkills(turfInfo)
      end
    end
  end
end

local function drawTraderInventoryPopup()
  local tickText = ""

  if currentTrader and currentTrader.nextTickIn then
    tickText = (currentTrader.nextTickIn < 0 and "very soon!") or ("in " .. currentTrader.nextTickIn .. " seconds!")

    tickText = "Next tick: " .. tickText
  end

  if
    not base.beginWindow("CarpTraderUI", "Trading", nil, false) or not currentTrader or not currentTrader.name or
      not currentTrader.type
   then
    base.endWindow()
    return
  end

  im.Columns(1, "tradercolumns")
  im.SetWindowFontScale(base.getUISetting("window_scale"))

  im.Spacing()

  base.textWithFont("Welcome to " .. currentTrader.name .. "!", headingFont, true)
  im.SameLine()
  base.textWithFont(" (" .. currentTrader.type .. ")", "cairo_bold")

  renderCorporationInfo()

  im.Separator()

  renderMissionUI()

  im.Separator()

  --
  printDemandedProducedItems()

  --
  renderInventoryItems()
  --

  -- ||
  im.NextColumn()
  -- ||

  base.endWindow()
end

--=============== Imgui Render Functions ===============--
local function showTraderInventoryPopup(show, name)
  if show then
    base.showWindow("CarpTraderUI")
  else
    base.hideWindow("CarpTraderUI")
  end
end

local function showWindow(show)
  if show then
    base.showWindow("CarpTraderUI")
  else
    base.hideWindow("CarpTraderUI")
  end
end

local function onUpdate()
  if not currentTrader or not currentTrader.name or not currentTrader.type then
    return
  end
  drawTraderInventoryPopup()
end

--=============== BeamMP Integration Functions ===============--
local function onReceiveTraderInventory(inventory)
  if not inventory or inventory == "null" then
    return
  end

  currentTrader = jsonDecode(inventory)

  currentTraderName = currentTrader.locationName

  currentTrader.controlledBy = nil
  local highestControl = 0
  if currentTrader.controllingCorporations then
    for name, percentage in pairs(currentTrader.controllingCorporations) do
      if percentage >= highestControl then
        highestControl = percentage
        currentTrader.controlledBy = name
      end
    end
  end

  traderOwners = carp.getTraderOwners()
  --print("got this traderOwners")
  --dump(traderOwners)

  base.showWindow("CarpTraderUI")
end

local function clearInventory()
  currentTrader = {}
  currentTraderName = nil
end

local function getCurrentTraderName()
  return currentTraderName
end

local function onExtensionLoaded()
  gui_module.initialize(gui)
  base.registerWindow("CarpTraderUI", im.ImVec2(1200, 600))

  AddEventHandler("onReceiveTraderInventory", onReceiveTraderInventory)

  log("I", "onExtensionLoaded", "CaRPTrader UI initialized.")
end

M.onExtensionLoaded = onExtensionLoaded
M.showTraderInventoryPopup = showTraderInventoryPopup
M.showWindow = showWindow
M.onUpdate = onUpdate
M.clearInventory = clearInventory
M.getCurrentTraderName = getCurrentTraderName
M.itemCanBeTraded = itemCanBeTraded
M.getCurrentTraderInventory = getCurrentTraderInventory

print("CaRPTrader UI loaded")
return M
