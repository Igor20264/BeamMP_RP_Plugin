--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP spawn UI
--====================================================================================
local M = {}
print("Loading Carp VehicleInventory UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local gui_module = require("ge/extensions/editor/api/gui")
local gui = {setupEditorGuiTheme = nop}
local im = ui_imgui
local base = carp_ui_base

local buf_size = 64
local headingFont = "cairo_semibold_large"
local icon_size = base.getIconSize()

local currentInventory = {}
local focusedItem = nil
local currentLocation = nil

local sellAmount = im.IntPtr(40)

local MIN_SELL_AMOUNT = 1
local MAX_SELL_AMOUNT = 40

local inventorySlotsCount = nil
local usedInventorySlots = nil

local MISSION_ITEM_SLUG = "MISSION_ITEM"

local itemIcons = {
  default = "ab_asset_prefab",
  heart = "favorite",
  briefcase = "business_center",
  treeadd = "forest_add_mesh",
  fuel = "fg_barrel",
  drink = "local_bar",
  coffee = "local_cafe",
  pizza = "local_pizza",
  truck = "local_shipping",
  shoppingcart = "shopping_cart",
  missionItem = "assignment_returned"
}

local selectedSlugs = {}

local function clearCurrentLocation()
  currentLocation = nil
end

local function updateUsedInventorySlots()
  if not inventorySlotsCount or not (#currentInventory) then
    usedInventorySlots = 0
    return
  end

  usedInventorySlots = 0
  for _, item in pairs(currentInventory) do
    local itemCargoUsage = item.cargoUsage or 1

    usedInventorySlots = usedInventorySlots + itemCargoUsage
  end
end
--

-- draw functions: -->
local function drawDummyItem()
  im.Dummy(im.ImVec2(icon_size.x / 2, icon_size.y / 2))
end

local function renderInventoryBar()
  if not inventorySlotsCount or not usedInventorySlots then
    return
  end

  return im.ProgressBar(
    usedInventorySlots / inventorySlotsCount,
    im.ImVec2(im.GetWindowWidth() * 0.7, 20),
    string.format("%d/%d slots used", usedInventorySlots, inventorySlotsCount)
  )
end

local function renderInventoryItem(idx, item)
  local destinationString =
    (item.prettyDestination or item.destination) and (": " .. (item.prettyDestination or item.destination)) or ""

  local buttonLabel = (item and item.name or "Item") .. destinationString

  local itemIcon = nil
  if not item.itemSlug then
    itemIcon = itemIcons["default"]
  elseif item.itemSlug == "missionItem" then
    itemIcon = itemIcons["missionItem"]
  else
    if selectedSlugs[item.itemSlug] then
      itemIcon = selectedSlugs[item.itemSlug]
    else
      local keys = {}
      for key, _ in pairs(itemIcons) do
        table.insert(keys, key)
      end

      local slug = keys[math.random(1, #keys)]

      selectedSlugs[item.itemSlug] = itemIcons[slug]
      itemIcon = itemIcons[slug]
    end
  end

  if base.uiIconImageButton(base.icons[itemIcon], icon_size) then
    if focusedItem ~= idx then
      focusedItem = idx
    else
      focusedItem = nil
    end
  end

  if im.IsItemHovered() then
    im.SetTooltip(buttonLabel)
  end
end

local function renderDeleteButton(item)
  if base.uiIconImageButton(base.icons.delete, icon_size) then
    TriggerServerEvent("deleteItemFromInventory", item.id)
  end
end

local function renderFocusedItem()
  if focusedItem and currentInventory[focusedItem] then
    local item = currentInventory[focusedItem]

    local displayName = item.name

    if item.itemSlug == MISSION_ITEM_SLUG then
      displayName = displayName .. " (Mission Item)"
    end

    base.uiIconImage(base.icons.ab_asset_prefab)

    im.SameLine()
    base.textWithFont(displayName, headingFont)

    local destinationString =
      (item.prettyDestination or item.destination) and
      ("Take " .. item.name .. " to " .. (item.prettyDestination or item.destination) .. ". ") or
      ""

    im.TextWrapped(destinationString .. "Worth $" .. item.price .. ". " .. "Weight: " .. (item.weight or 1) .. "kg.")

    if (item.prettyDestination or item.destination) then
      if im.Button("Set navigation to " .. (item.prettyDestination or item.destination)) then
        TriggerServerEvent("receiveGetNavigationToWaypoint", item.destination)
      end
    end

    if
      currentLocation and item.itemSlug ~= MISSION_ITEM_SLUG and
        carp_ui_trader.itemCanBeTraded(item, currentLocation.requests)
     then
      im.SliderInt(
        "Amount to sell",
        sellAmount,
        MIN_SELL_AMOUNT,
        (math.floor(usedInventorySlots / item.cargoUsage) or 1) or MAX_SELL_AMOUNT
      )

      if not tonumber(sellAmount[0]) or not MIN_SELL_AMOUNT then
        print("sellAmount", tonumber(sellAmount[0]))
        print("MIN_SELL_AMOUNT", MIN_SELL_AMOUNT)
      elseif
        im.Button("Sell##" .. item.name .. " to " .. currentLocation.name) and
          tonumber(sellAmount[0]) >= MIN_SELL_AMOUNT
       then
        TriggerServerEvent("sellItemToTrader", item.itemSlug .. "|" .. sellAmount[0])
      end

      if im.Button("Sell All") then
        TriggerServerEvent(
          "sellItemToTrader",
          item.itemSlug .. "|" .. ((usedInventorySlots / item.cargoUsage) or MIN_SELL_AMOUNT)
        )
      end
    end

    im.TextWrapped("Throw away:")
    im.SameLine()
    renderDeleteButton(item)

    im.TextWrapped("")
  end
end

local function renderVehicleInventoryItems(location)
  if not currentLocation then
    currentLocation = location
  end

  if not currentInventory or not (#currentInventory) or #currentInventory == 0 then
    return
  end

  -- render 5x5 grids by doing im.SameLine :^)
  local sameLineCounter = 0

  -- draw inventory item blocks
  for idx, item in pairs(currentInventory) do
    if currentLocation and item.itemSlug == MISSION_ITEM_SLUG then
      return
    end

    renderInventoryItem(idx, item)

    if sameLineCounter < 4 then
      im.SameLine()
      sameLineCounter = sameLineCounter + 1
    else
      sameLineCounter = 0
    end
  end
end

local function drawVehicleInventoryPopup()
  if not base.beginWindow("VehicleInventoryUI", "Vehicle Inventory", nil, false) or not carp.currentIsOwned then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  im.Spacing()

  renderInventoryBar()

  -- draw focused item
  renderFocusedItem()

  im.BeginChild1("InventoryItemsChild", im.ImVec2(0, 250), true)
  renderVehicleInventoryItems()
  im.EndChild()

  im.End()
end
-- draw functions <--

local function showVehicleInventoryPopup(show, name)
  if show then
    base.showWindow("VehicleInventoryUI")
  else
    base.hideWindow("VehicleInventoryUI")
  end
end

local function showWindow(show)
  if show then
    base.showWindow("VehicleInventoryUI")
  else
    base.hideWindow("VehicleInventoryUI")
  end
end

local function onUpdate()
  drawVehicleInventoryPopup()
end

local function clearVehicleInventory()
  currentInventory = {}
  inventorySlotsCount = 0

  updateUsedInventorySlots()
  carp_vehicleinventory.updateInventoryWeight(currentInventory)
end

local function updateVehicleInventorySize(payload)
  if tonumber(payload) then
    inventorySlotsCount = tonumber(payload)

    updateUsedInventorySlots()
  end
end

local function onClientUpdateInventory(inventory)
  -- base.showWindow("VehicleInventoryUI")
  base.saveUISetting("hide_window_VehicleInventoryUI", false)

  print("inventory updated:", type(inventory), inventory)
  if not inventory or inventory == "null" then
    return
  end

  local jsonPayload = jsonDecode(inventory)

  for _, item in pairs(jsonPayload) do
    table.insert(currentInventory, item)
  end

  carp_vehicleinventory.updateInventoryWeight(currentInventory)
  updateUsedInventorySlots()
end

local function onClientEndMission()
  focusedItem = nil

  carp_poi.deleteObjectByName("mission-delivery-destination_icon")
  carp_poi.deleteObjectByName("mission-delivery-destination_marker")
  carp_poi.deleteObjectByName("mission-delivery-destination_trigger")
end

local function onExtensionLoaded()
  base.registerWindow("VehicleInventoryUI", im.ImVec2(500, 200))

  AddEventHandler("onClientUpdateInventory", onClientUpdateInventory)
  AddEventHandler("clearVehicleInventory", clearVehicleInventory)
  AddEventHandler("updateVehicleInventorySize", updateVehicleInventorySize)
  AddEventHandler("onClientEndMission", onClientEndMission)

  log("I", "onExtensionLoaded", "VehicleInventory UI initialized.")
end

local function getCurrentInventory()
  return currentInventory
end

local function getUsedInventorySlots()
  return usedInventorySlots
end

local function getInventorySlotsCount()
  return inventorySlotsCount
end

local function getItemAmountInInventory(slug)
  local count = 0

  if not currentInventory[1] then
    return count
  end

  for _, item in pairs(currentInventory) do
    if item and item.itemSlug and item.itemSlug == slug then
      count = count + 1
    end
  end

  return count
end

M.onExtensionLoaded = onExtensionLoaded
M.showVehicleInventoryPopup = showVehicleInventoryPopup
M.showWindow = showWindow
M.onUpdate = onUpdate
M.renderVehicleInventoryItems = renderVehicleInventoryItems
M.clearCurrentLocation = clearCurrentLocation
M.getCurrentInventory = getCurrentInventory
M.getUsedInventorySlots = getUsedInventorySlots
M.getInventorySlotsCount = getInventorySlotsCount
M.getItemAmountInInventory = getItemAmountInInventory
M.MIN_SELL_AMOUNT = MIN_SELL_AMOUNT

print("VehicleInventory UI loaded")
return M
