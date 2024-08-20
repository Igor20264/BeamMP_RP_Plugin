local M = {}

local commodities = nil

local function onReceiveCommodities(payload)
  local decodedData = jsonDecode(payload)

  commodities = decodedData
end

local function getCommodityBySlug(slug)
  if not commodities or not commodities[slug] then
    return {
      name = "COMMODITY NOT FOUND",
      weight = 0
    }
  end

  return commodities[slug]
end

local function onExtensionLoaded()
  AddEventHandler("onReceiveCommodities", onReceiveCommodities)
  log("I", "carp_commodities", "onExtensionLoaded")
end

M.onExtensionLoaded = onExtensionLoaded
M.getCommodityBySlug = getCommodityBySlug

return M
