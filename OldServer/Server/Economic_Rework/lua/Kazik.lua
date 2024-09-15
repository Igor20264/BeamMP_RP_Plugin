local M = {}

function roll(sender_id,sender_name, message)
	local r = math.random(1, 100) 
	if (eco:bal(sender_name,4)-tonumber(message) >= 0) and tonumber(message) >= M.config.minimal_roll then
		if r <= M.config.win then
			local ssr = tonumber(message)*math.random(M.config.minX, M.config.maxX) 
			eco:add(sender_name,4,ssr)
			local ret = "Вы выйграли "..ssr
			eco.world_balans.money = eco.world_balans.money-ssr
			SendMessage(sender_id,ret)
		else
			local ret = "Вы проиграли"
			eco:add(sender_name,4,-(tonumber(message)))
			eco.world_balans.money = eco.world_balans.money+(tonumber(message))
			SendMessage(sender_id,ret)
		end
	else
		SendMessage(sender_id,"Вам нехватает денег для ролла (Min: 1000)")
	end
end
M.config = load_config("settings/kazono")
local prefix = M.config.prefix

M.command = {
	{command = prefix.."roll",help = "Это не казино! , вроде.. "..prefix.."roll [money]",func = "roll",admin = false,hide = false}
}

function M.load()
	M.command = RegEvent(M.command)
end

function M.unload()
end

return M