--====================================================================================
-- All work by deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP custom UI
--====================================================================================
local M = {}
print("Loading Carp custom UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local activeItems = {}
local previewItem = nil
local previewName = nil
local editingLayout = false

local windowOpen = im.BoolPtr(true)

-- draw functions: -->
local function drawDummyItem()
  local icon_size = base.getIconSize()
  im.Dummy(im.ImVec2(icon_size.x / 2, icon_size.y / 2))
end

local function drawCustomUI()
  if not base.beginWindow("CarpCustomUI", "Custom CaRP window") then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))
  local icon_size = base.getIconSize()

  local availableItems = base.getAvailableDrawItems()

  if editingLayout then
    if base.uiIconImageButton(base.icons.cancel, icon_size) then
      editingLayout = false
    end
    im.SameLine()
    if base.uiIconImageButton(base.icons.save, icon_size) then
      editingLayout = false
    end
  end

  for index, itemKey in ipairs(activeItems) do
    if editingLayout then
      --local cursor_x = im.GetCursorPosX()
      local col_text = im.GetStyleColorVec4(im.Col_Text)
      local col_disabled = im.ImVec4(col_text.x, col_text.y, col_text.z, col_text.w * 0.25)
      if index > 1 then -- up arrow
        if base.uiIconImageButton(base.icons.keyboard_arrow_up, icon_size) then
          local itemabove = activeItems[index - 1]
          activeItems[index - 1] = itemKey
          activeItems[index] = itemabove
          base.saveUISetting("customMenuItems", activeItems)
        end
      else
        base.uiIconImageButton(base.icons.keyboard_arrow_up, icon_size, col_disabled)
      end
      im.SameLine()

      --im.SetCursorPosX(cursor_x + icon_size.x + im.GetStyle().ItemSpacing.x)
      if index < #activeItems then -- down arrow
        if base.uiIconImageButton(base.icons.keyboard_arrow_down, icon_size) then
          local itembelow = activeItems[index + 1]
          activeItems[index + 1] = itemKey
          activeItems[index] = itembelow
          base.saveUISetting("customMenuItems", activeItems)
        end
      else
        base.uiIconImageButton(base.icons.keyboard_arrow_down, icon_size, col_disabled)
      end
      im.SameLine()

      --im.SetCursorPosX(cursor_x + (icon_size.x+im.GetStyle().ItemSpacing.x)*2)
      if base.uiIconImageButton(base.icons.delete, icon_size) then
        table.remove(activeItems, index)
        base.saveUISetting("customMenuItems", activeItems)
      end
      im.SameLine()
      im.Text(availableItems[itemKey] and availableItems[itemKey].title or "Can't find item '" .. itemKey .. "'")
      im.Separator()
    else
      if availableItems[itemKey] and availableItems[itemKey].draw then
        if availableItems[itemKey].isVisible() then
          im.BeginGroup()
          availableItems[itemKey].draw()
          im.EndGroup()
          im.Separator()
        end
      else
        --print(itemKey .. "=>")
        dump(availableItems[itemKey])
        im.Text("Can't draw item '" .. itemKey .. "'")
        im.Separator()
      end
    end
  end

  if editingLayout then
    im.Spacing()
    if im.BeginCombo("Select item to add", previewName or "") then
      for itemKey, item in pairs(availableItems) do
        if im.Selectable1(item.title) then
          previewItem = itemKey
          previewName = item.title
        end
      end
      im.EndCombo()
    end
    if previewItem and previewItem ~= "" then
      if base.uiIconImageButton(base.icons.add, icon_size) then
        table.insert(activeItems, previewItem)
        previewItem = nil
        previewName = nil
        base.saveUISetting("customMenuItems", activeItems)

        im.End()
        return
      end
      if im.IsItemHovered() then
        im.SetTooltip("Add")
      end
      im.SameLine()

      im.BeginGroup()
      if availableItems[previewItem].draw then
        availableItems[previewItem].draw()
      end
      im.EndGroup()

      im.TextWrapped("Don't forget to click the '+' button!")
    end
  end

  im.TextWrapped("Welcome to CaRP's custom UI!")
  im.TextWrapped("You can customize this window to show your most frequent actions!")

  if not editingLayout then
    if base.uiIconImageButton(base.icons.mode_edit, icon_size) then
      editingLayout = true
    end
  end

  base.endWindow()
end
-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("CarpCustomUI", im.ImVec2(450, 300))

  base.registerDrawItem("dummy", "Spacer", drawDummyItem)

  activeItems = base.getUISetting("customMenuItems") or {}
  log("I", "onExtensionLoaded", "Carp custom UI initialized.")
end

local function showWindow(show)
  if show then
    base.showWindow("CarpCustomUI")
  else
    base.hideWindow("CarpCustomUI")
  end
end

local function onUpdate()
  drawCustomUI()
end

M.showWindow = showWindow
M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate

print("Carp UI loaded")
return M
