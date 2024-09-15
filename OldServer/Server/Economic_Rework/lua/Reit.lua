local M = {}
M.info = "Экономическая система"
M.ver = "0.6"

players = load_database("rpdb.ixt")

local function save()
	save_database("rpdb.ixt",players)
end

function player_new(id)
		local name = MP.GetPlayerName(id)
		if players[name] == nil then
			players[name] = {bal = M.config.start_bal, cool=1} -- name,$,payday,bank$,WorkName,taxIP
			save_database("rpdb.ixt",players)
		end 
	end

function GETREIT(sender_id,sender_name, message)
	local case = split(message," ")
	SendMessage(sender_id,case[1]..''..players[case[1]].bal)
end

function GETMYREIT(sender_id,sender_name, message)
	SendMessage(sender_id,"Ваш рейтинг: "..players[sender_name].bal)
end

function VOTE(sender_id,sender_name, message)
	local p2,case = MessageParser(message," ",2)
	if p2 == sender_name then
		return false
	end
	if case[1] == "+" then
		z = 1
	elseif case[1] == "-" then
		z = -1
	else 
		SendMessage(sender_id,"vote [name] [+|-]")
		return true
	end	
		
	local lt = players[p2].cool
	if timer:isCooldown(lt) then
		players[p2].bal = players[p2].bal+z
		players[p2].cool = timer:GetCooldown(M.config.sec_to_vote)
		SendMessage(sender_id,"Вы изменили рейтинг игрока на "..z)
		SendMessage(MP.GetId(p2),"Ваш рейтинг изменили на "..z)
		save()
	else
		SendMessage(sender_id,"Ждите еще "..lt-timer:Get())
	end
end
M.config = load_config("settings/rank")
local prefix = M.config.prefix

M.command = {
	{command = prefix.."vote",    help = "+|- рейтинг игроку. "..prefix.."vote [name] [+|-]",func = "VOTE",admin = false,hide = false},
	{command = prefix.."rank",    help = "Узнать свой рейтинг "..prefix.."rank",func = "GETMYREIT",admin = false,hide = false},
	{command = prefix.."whyrank", help = "Узнать чужой рейтинг. "..prefix.."chekrank",      func = "GETREIT",admin = true,hide = false}
}


function M.load()
	M.command = RegEvent(M.command)
	MP.RegisterEvent("onPlayerConnecting","player_new")
end

function M.unload()
end

return M