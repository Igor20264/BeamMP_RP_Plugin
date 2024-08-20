local M = {}

local CARP_TO_WCUSA_STATION_NAMES = {
  ["contact-near-hospital"] = "apex",
  ["contact-trilobite"] = "trilobite_city",
  ["contact-far-trilobite"] = "trilobite_garage",
  ["contact-spearleaf-trilobite"] = "tyranos_island"
}

local gasStationPrices = nil

local function getGasStationByID(id)
  local stations = extensions.freeroam_facilities.getFacilities("west_coast_usa").gasStations

  local toRet = {}
  for k, v in pairs(stations) do
    if v.id == id then
      toRet = v
    end
  end

  return toRet
end

local function setGasStationDisplayValue(id, fueltype, value, enabled, ustax)
  local station = getGasStationByID(id)
  if not station or not station.prices or not station.prices[fueltype] then
    return
  end

  station.prices[fueltype].priceBaseline = value
  station.prices[fueltype].priceRandomnessBias = 0
  station.prices[fueltype].priceRandomnessGain = 0
  station.prices[fueltype].disabled = not enabled

  station.prices[fueltype].us_9_10_tax = ustax

  if ustax then
    station.prices[fueltype].priceBaseline = value - 0.01
  end
end

local function updateGasStationPrices(data)
  gasStationPrices = data

  if not gasStationPrices then
    return
  end

  -- deactivated station
  setGasStationDisplayValue("nodeoline", "gasoline", 0, false, false)
  setGasStationDisplayValue("nodeoline", "diesel", 0, false, false)

  for name, price in pairs(gasStationPrices) do
    local beamngStationId = CARP_TO_WCUSA_STATION_NAMES[name]

    if beamngStationId then
      local fuelPrice = (price and tonumber(price)) or nil

      if price == 999 then -- inventory empty value
        fuelPrice = nil
      end

      local pricePerGal = nil
      if fuelPrice then
        pricePerGal = (fuelPrice / 10) / 3.78541
      end

      setGasStationDisplayValue(beamngStationId, "gasoline", pricePerGal, pricePerGal ~= nil, false)
      setGasStationDisplayValue(beamngStationId, "diesel", pricePerGal, pricePerGal ~= nil, false)
    -- setGasStationDisplayValue(beamngStationId, "gasoline2", pricePerGal, pricePerGal ~= nil, false)
    -- setGasStationDisplayValue(beamngStationId, "gasoline3", pricePerGal, pricePerGal ~= nil, false)
    end
  end

  print("Finished, pushing prices")

  extensions.freeroam_facilities_fuelPrice.setDisplayPrices()
end

M.updateGasStationPrices = updateGasStationPrices

return M
