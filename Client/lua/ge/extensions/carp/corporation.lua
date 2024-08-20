local M = {}

local corporationData = nil

local function receiveCorporationData(payload)
  carp_ui_corporation.updateCorporationsUi(json.decode(payload))
end

M.receiveCorporationData = receiveCorporationData

return M

--[[ 
  {
    canCreateCorporation = nil,
    isInCorporation = true,
    isCorporationOwner = true,
    corporationName = nil,
    corporationTag = nil,
    corporationMissionEarnings = nil,
    corporationSpent = nil,
    corporationMembers = {},
    corporationCommoditiesTraded = {
      ["DVDs"] = 150133,
      ["Fish"] = 150133
    },
    corporationEarners = {
      ["LiterallyAPastry"] = 42069,
      ["Deer"] = 50,
      ["ToxicX15"] = 18004,
      ["O1LER"] = 42000,
      ["SeaRaider"] = 140000
    },
    inviteSearchResults = {
      ["42069"] = "LiterallyAPastry",
      ["50"] = "Deer",
      ["18004"] = "ToxicX15",
      ["42000"] = "O1LER",
      ["140000"] = "SeaRaider"
    }
  }
 ]]
