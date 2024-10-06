--paintSync (SERVER) by Dudekahedron, 2024

function onInit()
	MP.RegisterEvent("paintUpdate", "paintUpdateHandler")
	print(" --------------------------------- paintSync Loaded!")
end

function paintUpdateHandler(player_id, data)
	local paintData = Util.JsonDecode(data)
	MP.TriggerClientEventJson(-1, "rxPaint", {paintData[1], paintData[2]})
end
