M = {}
local function set_lightbar_signal(state)
  if state == lightbarState then
    return
  end
  lightbarState = state % (sirenSound ~= nil and 3 or 2)

  -- 1 = lights, no sound
  -- 2 = lights + sound
  toggleSound(lightbarState == 2, sirenSound)
end

local function toggle_lightbar_signal()
  set_lightbar_signal(lightbarState + 1)
end

M.toggle_lightbar_signal = toggle_lightbar_signal
M.set_lightbar_signal = set_lightbar_signal

return M