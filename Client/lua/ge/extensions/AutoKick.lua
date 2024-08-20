local M = {}

function showNotice(msg)
	local msg = MPHelpers.b64decode(msg) -- uses game own mime libary
	local msg = jsonDecode(msg)
	
	local data = {}
	data.showDataImmediately = true
	data.introType = "htmlOnly"
	data.name = msg.name
	data.buttonText = msg.buttonText
	data.description = msg.description -- https://www.systutorials.com/tools/bbeditor/
	guihooks.trigger('ChangeState', {state = 'scenario-start', params = {data = data}})
end

-- adding events later.. 0.31 mod loading makes it tho that functions of other mods
-- are sometimes not available during this mods loading.
local function onWorldReadyState(state)
	if state == 2 then
		-- only load if BeamMP is present
		if AddEventHandler then
			AddEventHandler("autokick_warning", showNotice)
		end
	end
end

M.onWorldReadyState = onWorldReadyState
return M
