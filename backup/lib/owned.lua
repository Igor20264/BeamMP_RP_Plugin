function deleted_vehicle(player_id,vehicle_id)
	MP.TriggerGlobalEvent("DELETE_POS",player_id,vid)
	for i,case in ipairs(ppl) do
		if case[1] == name then
			if case[2] == vid then
				table.remove(ppl,i)
				--pos[i] = {player_id,vid,0,0,0}
			end
		end
	end
end

function get_pos(name,vid) 
	local player_id = get_id(name)
	local cord,text = MP.GetPositionRaw(player_id,vid)
	if text == "Vehicle not found" then
		return -1, -1, -1
	else
		local x = string.format("%.2f",cord["pos"][1])
		local y = string.format("%.2f",cord["pos"][2])
		local z = string.format("%.2f",cord["pos"][3])
		return x,y,z
	end
end

function afk()
	for i,case in ipairs(ppl) do
		if not(get_id(case[1]) == -1) then
			local x,y,z = get_pos(case[1],case[2])
			if x == case[3] and y == case[4] then
				if case[5] == 1 then
					MP.RemoveVehicle(get_id(case[1]), case[2]) 
					MP.SendChatMessage(get_id(case[1]), "Ваш транспорт удалён")
					Del_vid(case[1], case[2])
				else
					MP.SendChatMessage(get_id(case[1]), "Вы неактивны, подвигайтесь")
					ppl[i]={case[1],case[2],x,y,1}
				end
			else
				ppl[i]={case[1],case[2],x,y,0}
			end
		elseif get_id(case[1]) == -1 then
			Del_vid(case[1], case[2])
		end
	end
end