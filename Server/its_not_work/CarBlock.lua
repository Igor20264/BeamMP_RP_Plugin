logging = 'both' --both, file only, console only, none

json = require('json')

MP.RegisterEvent('onVehicleSpawn', 'SpawnHandler')
MP.RegisterEvent('onVehicleEdited', 'EditHandler')

--All allowed spawnables, remove any of them to stop people from spawning them
DefaultCars = {'autobello', 'barstow', 'bastion', 'bluebuck', 'bolide', 'burnside', 'citybus', 'coupe', 'covet','etk800', 'etkc', 'etki', 'fullsize', 'hopper', 'legran', 'midsize', 'miramar', 'pessima', 'pickup', 'pigeon', 'roamer', 'sbr', 'scintilla', 'semi', 'sunburst', 'van', 'vivace', 'wendover', 'wigeon'}
DefaultTrailers = {'boxutility', 'boxutility_large', 'caravan', 'dryvan', 'flatbed', 'tanker', 'tsfb'}
Props = {'ball', 'barrels', 'barrier', 'blockwall', 'bollard', 'cannon', 'cardboard_box', 'chair', 'christmas_tree', 'cones', 'couch', 'flail', 'flipramp', 'fridge', 'gate', 'haybale', 'inflated_mat', 'kickplate', 'large_angletester', 'large_bridge', 'large_cannon', 'large_crusher', 'large_hamster_wheel', 'large_roller', 'large_spinner', 'large_tilt', 'mattress', 'metal_box', 'metal_ramp', 'piano', 'roadsigns', 'rocks', 'rolloverr', 'sawhorse', 'shipping_container', 'streetlight', 'suspensionbridge', 'testroller', 'tirestacks', 'tirewall', 'trafficbarrel', 'tube', 'tv', 'wall', 'weightpad', 'woodcrate', 'woodplanks'}

--change placeholder to any car to whitelist that mod E.G. AllowedModdedCars = {'etkk', 'gavril_vertex'} to whitelist the old school K-series and the Gavril Vertex
ModdedCars = {'placeholder'}

AllSpawnables = {DefaultCars, DefaultTrailers, Props, ModdedCars}

local function parseData(data)
	local s, e = data:find('%{')
    
	data = data:sub(s)

	local sucessful, tempData = pcall(json.parse, data)
	if not sucessful then
		return false
	end
	data = tempData
    
	if data[4] ~= nil then
		local sucessful, tempData = pcall(json.parse, data[4])
		if not sucessful then
			return false
		end
		data.info = tempData 
	end
	return data
end

function EditHandler(id, car_id, rawData)
    local player = MP.GetPlayerName(id)
    data = parseData(rawData)
    car = data.jbm
    for i, Category in ipairs(AllSpawnables) do
    	for i, spawnable in ipairs(Category) do
    		if string.find(car, spawnable) then
                return 0
            end
        end
    end
    if string.match(logging, 'both') or string.match(logging, 'file only') then 
    	local logs = io.open("logs.txt", "a")
    	logs:write(player, " Tried using a modded/blacklisted ", car, "\n")
    	logs:close()
	end
    if string.match(logging, 'both') or string.match(logging, 'console only') then
    	print(player, 'tried spawning a modded/blacklisted', car)
	end
    return 1
end

function SpawnHandler(id, car_id, rawData)
    data = parseData(rawData)
    car = data.jbm
    for i, Category in ipairs(AllSpawnables) do
    	for i, spawnable in ipairs(Category) do
    		if string.find(car, spawnable) then
                return 0
            end
        end
    end
    if string.match(logging, 'both') or string.match(logging, 'file only') then 
    	local logs = io.open("logs.txt", "a")
    	logs:write(player, " Tried using a modded/blacklisted ", car, "\n")
    	logs:close()
	end
    if string.match(logging, 'both') or string.match(logging, 'console only') then
    	print(player, 'tried spawning a modded/blacklisted', car)
	end
    return 1
end
