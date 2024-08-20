local M = {}

local red = ColorF(1, 1, 0, 1)
local green = ColorF(0, 1, 0, 1)
local magenta = ColorF(1, 0, 1, 1)
local gray = ColorF(0, 0, 0, 0.3)

local function drawRect(position, width, length, height, color, forward)
  if not position or not width or not length or not height or not color then
    print("ERROR: not enough parameters")
    return
  end

  local primaryAxis = forward:z0():normalized() -- front, no Z, short
  local secondaryAxis = primaryAxis:cross(vec3(0, 0, 1)) -- rotates primary by 90deg on a flat surface

  primaryAxis = primaryAxis * (width / 2)
  secondaryAxis = secondaryAxis * (length / 2)

  local corners = {}

  -- debugDrawer:drawLine(position, position + primaryAxis, red, 2)
  -- debugDrawer:drawLine(position + primaryAxis, position + primaryAxis + secondaryAxis, green, 2)
  -- debugDrawer:drawLine(position + primaryAxis + secondaryAxis,position + primaryAxis + secondaryAxis + vec3(0, 0, height),magenta,2)

  corners[1] = position + primaryAxis + secondaryAxis
  corners[2] = position - primaryAxis + secondaryAxis
  corners[3] = position - primaryAxis - secondaryAxis
  corners[4] = position + primaryAxis - secondaryAxis

  corners[5] = corners[1] + vec3(0, 0, height)
  corners[6] = corners[2] + vec3(0, 0, height)
  corners[7] = corners[3] + vec3(0, 0, height)
  corners[8] = corners[4] + vec3(0, 0, height)

  debugDrawer:drawQuadSolid(corners[1], corners[2], corners[3], corners[4], color)
  debugDrawer:drawQuadSolid(corners[5], corners[6], corners[7], corners[8], color)

  debugDrawer:drawQuadSolid(corners[1], corners[2], corners[2 + 4], corners[1 + 4], color)
  debugDrawer:drawQuadSolid(corners[2], corners[3], corners[3 + 4], corners[2 + 4], color)
  debugDrawer:drawQuadSolid(corners[3], corners[4], corners[4 + 4], corners[3 + 4], color)
  debugDrawer:drawQuadSolid(corners[4], corners[1], corners[1 + 4], corners[4 + 4], color)
end

M.drawRect = drawRect

return M
