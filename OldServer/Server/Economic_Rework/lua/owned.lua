local M = {}
M.info = "Система владения"
M.ver = "BETA 0.2"

function spawn_vehicle(player_id,vehicle_id,data)
	local name = MP.GetPlayerName(player_id)
	ppl[#ppl+1]={name,vid,0,0,0}
	vehicle_parser(data)
	return 0
end

function update_vehicle(player_id,vehicle_id,data)
	return 1
end

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

function user_quit(player_id)
end

function user_join(player_id)
	player_list[#player_list+1] = {player_id,vehicle_id = {}} 
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

function finds(data,part_name)
	local y,x,part = string.find(data, part_name..'":"(.-)"')
	--local y,x,name_part = string.find(data, '"(.)":"'..part..'"')
	--log(part_name..":"..part)
	local status, part1 = pcall(string.gsub, part,part_name.."_","")
	if (status) then
		print(part_name..":"..part1)
		return part1
	else
		if part == nil then 
			print(part_name..": nill")
			return 0
		else
			print(part_name..":"..part)
			return part
		end
	end
end

function vehicle_parser(data)
	local data = string.gsub(data,'(%a+):(.-):(%d+)-(%d+)','{"config"',1)
	local data = string.gsub(data,'(%d+)-(%d+)','{"config"',1)
	local data =  data..'}'

	local jbm = finds(data,"jbm")
	if jbm == "unicycle" then
		print("Это снеговик")
	else
		local data = string.gsub(data, jbm.."_",'')
		
		local engine = finds(data,"engine")
		local data = string.gsub(data, engine..'_',"")
		local data = string.gsub(data, '_'..engine,"")
		local fueltank = finds(data, "fueltank")
		local data = string.gsub(data, '_'..fueltank,"")
		local data = string.gsub(data, fueltank..'_',"")
		
		local transmission = finds(data, "transmission")
		local transfer_case = finds(data,"transfer_case")
		local ratiator =  finds(data, "radiator")
		
		local steering = finds(data,"steer")
		local body = finds(data,"body")
		local lightbar = finds(data,"lightbar")
		local enginemounts = finds(data,"enginemounts")
		
		local differential_R = finds(data,"differential_R") 
		local differential_F = finds(data,"differential_F") 
		
		local turbo = finds(data,"turbo")
		local roofrack_accessory = finds(data, "roofrack_accessory")
		local intake = finds(data,"intake")
		local ecu =finds(data,"ecu")
		local it_men = finds(data,"meshes")
		--print(data)
		local pre_pars = Util.JsonDecode(data)
		print(pre_pars.config)
	end
	--[==[
	local data = string.gsub(data, Util.JsonDecode(data).config.jbm.."_","") 
	--print(pre_pars)
	--print(pre_pars.config.vcf.parts)
	--print(pre_pars.config.vcf.parts.engine)
	--print(pre_pars.config.vcf.parts.transmission)
	for i,case in ipairs(pre_pars.config.vcf.parts) do
	 print(i,case)
	end
	engine = string.gsub(pre_pars.config.vcf.parts,"(.-)_engine_(.-)","%1,%2")
	transmission = string.gsub(pre_pars.config.vcf.parts.transmission,"transmission_(.-)","%1")
	print(engine,transmission)
	--local data = string.gsub(data, "_"..string.gsub(pre_pars.config.vcf.parts.engine,"engine_(.-)","%1"),"")
	--print(data)
	--local datas = string.gsub(data,'"(%a+)":"(%a+)",',"|%1:%2|,")
	--local data = split(data,":") 
	--for i,case in pairs(data) do
		--print(i)
	--end
	--print(data)
	--]==]
end

M.command = {{reg = "test",command = "@#$test",help="Test",func = "asdqwdwad",admin= true,hide = true}}
function M.load()
	print(M.group)
	ppl = {}
	MP.RegisterEvent("onVehicleSpawn","spawn_vehicle")
	MP.RegisterEvent("onVehicleEdited","update_vehicle")
end

function M.unload()
end

return M