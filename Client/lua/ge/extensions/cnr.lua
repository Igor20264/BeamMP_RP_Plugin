
-- This code is the exclusive property of NuclearKnight00,
-- and unauthorized copying, use, distribution, 
-- or modification of this code, via any medium, 
-- is strictly prohibited.


local messageConfig = {}
messageConfig["messages"] = {}
messageConfig["titles"] = {}
messageConfig["descriptions"] = {}


--ge environment
--TODO: redo reset handling
--TODO:Remove more useless c
name = "none"
--local messageConfig = require("config")
local contextMenus = require("settings/contextMenus")

cnrBalance = 0

resetHandled = true
starterCars = false
showPrices = false
local settings = {["Call Repair Truck"] = 500,["Auto Rob Heist Target"] = false,["Auto Repair at Station"] = false,["Auto Mark Cooldown"] = false}

local M = {}
local helpMe = "SCROLL DOWN IF YOU CAN'T SEE THE CLOSE BUTTON \n IF THIS IS YOUR FIRST TIME IN THIS SERVER, YOU MUST USE THE STARTER CAR BUTTONS \nTEAM CHANGES ARE NOW AUTOMATIC AND BASED ON THE LIVERY OF YOUR VEHICLE\nAlthough cursing is allowed, please don't be excessive and slurs are NEVER allowed and WILL get you banned!\nYou may spawn in anywhere when you have no car spawned.\n Please be aware that edits are limited to 5 every 30 minutes per player!\n Some parts are now banned! Stage 3 and up turbos and supers are now banned in addition to adjustable nos.\n You can spawn back to the nearest spawn location using the UI.\n Any method to spawn or reset your vehicle without using the UI or being repaired is counted as cheating and you may be dealt with!\n You may only use money for repairs, which is percentage based on damage per part  with a discount applied while at a repair station, or a set rate of 500 from the repair truck.\n Money earned from robberies and earned from catching criminals scales based on their wanted level.\n You catch robbery targets by stopping the target for five or more seconds and being close to them.\n This is achieved by doing a PIT or other similar maneuver, ramming here is not allowed!\n You will be paid for catching targets, with pay scaling based on their wanted level.\nYou start as a civilian each time you join the server.\n You may rob places at any time as a civilian.\n You will recieve 1 repair for every 2 stars gained, up to 6 stars.\nCivilians are NEVER allowed to interfere with other police chases, unless the other player being chased is a group member!\n Small red markers mark robbery targets. Large yellow markers are for repair zones. \n The repair truck job is joined by spawning a vehicle with a towbed. \n The repair truck can repair a player when both are sitting still, and the player has enough money.\n  "
local help = true
local damaged = false
local services = false
local mString = ""
local rString = ""
local rateL = 300
local jbeamIO = require("jbeam/io")
local jbeamSlotSystem = require('jbeam/slotSystem')
local vehManager = extensions.core_vehicle_manager
local currentFuel = 0
local changeServer = false
local currentServerSelection = "demo15"
--Should prob do this diffrently but whatever 
local shortModGuide = "This is a simple guideline to follow but does not cover everything!\nAbove all else, always make sure you have full understanding of a situation before taking action!\n  This game can cause wierd things to happen, and will sometimes make it look like people are cheating, even if they are not!\n  A couple examples:\n	--A player driving through barriers and still going could be the result of a client map change and may be unintentional\n	--A player's vehicle becoming so destroyed it repairs itself on OTHER PLAYERS' screens, making it appear as though they reset themselves\n		this is caused by beamng itself resetting the car so the game doesn't potentially crash!\n	--Slight desync causing one player to hit someone on their screen, but not for the other player!\n	--New player may not be aware of vehicle queue system and may fail to load queues, resulting in carnage for other players\n	--A vehicle may not load properly, resulting in a player being a GRAY/BLACK blob, then being accused of deleting others\n	--There are more wierd things that could be happening, so make sure to ALWAYS attempt to get both sides of a story!\n   DEALING WITH VERBAL ABUSE:\n	--Outright verbal abuse such as slur usage or insults is not allowed, though trash talk between friends is okay and make sure that's not the case!\n	--Slur usage itself is NOT ALLOWED\n	--Although you may decide give people a warning and a chance to change their behavior, you also are allowed to take immediate action if necessary!\n	--Arguments between players can sometimes be resolved between them, so sometimes you may decide to let them talk it out first\n		This is okay, as long as they aren't throwing slurs at each or bothering other players\n	--PLEASE AVOID statements like 'I am a mod, you better listen to me!' etc, as this can be taken in a bad way and may make players less inclined to listen!\n		Obviously you are not disallowed from saying you are a mod, but please avoid appearing as you are on a power trip!\n		This looks bad on all of us!\n	--Physical threats such as SWATting or threatening to dox is an IMMEDIATE ban, with no appeal!\n   DEALING WITH PLAYERS AND THEIR VEHICLES:\n	--Players complaining they are stuck and cant move even in an owned vehicle are most likely bugged!\n		This is a symptom of the player connection issue, and they usually must go to another server to fix or rejoin\n		Rejoining ONLY works if they get a different ID upon rejoin(visible in player list)\n		Note that the game will sometimes only send SOME parts upon an initial sync, and this will result in them buying\n		half of the car basically, and they will need to purchase the reset. They technically didn't lose any money or the car, but may think they have\n	--The ONLY teams EVER permitted to ram are bank trucks attempting to flee, or if ANYONE is attacking the Mayor role, as the mayor may be attacked at any time\n	--Repair zones are NOT safe zones, though it is considered a cheap move in most circumstances\n"
local shortModGuide2 = "	--If a player runs out of fuel, they will recieve a small amount upon spawn and a slightly larger amount at a fuel station for free\n	--If a player resets, unless they are at a repair truck, repair shop, or MCC as a cop they should be sent back to their spawn location\n		Keep in mind that the game can sometimes respawn someone on YOUR screen to prevent crashes due to excess damage\n	--Reports of ramming etc MUST be accompanied by a video OR seen directly by an in game moderator to have action taken!\n	--KNOW THE DIFFERENCE BETWEEN THE FORCE SYNC AND FORCE QUEUE COMMANDS!!!\n		Force SYNC is if you suspect a player has circumvented part buying or team detection\n			Avoid using SYNC on player if they are robbing or on a mission, unless blatantly doing something wrong!\n		Force QUEUE is if a player refuses to QUEUE other players cars, such as a robber not queueing cops\n			Make sure to alert cops to back off of them, so they don't bust the robber when they queue!\n			This is due to the player freezing in place when they queue\nWHEN IN DOUBT, ASK!"
lastSync = 0
globalRepair = 0
moneyLeft = 0

--OLD HELP MENU
fuelHelp = "Your fuel is shared between all vehicles and is saved after you leave, reset etc.\nFuel costs money, and if you don't have enough money to refill completely, you will only get what you can afford.\nThis means that you can get softlocked by running out of money and fuel so watch your gas gauge and your funds!\n To refuel, simply go to any gas station pump and hit the refuel button!"
robberyHelp = "As a civilian, you may rob a place at any time provided you are close enough and haven't already robbed it.\nYou may get up to six stars, one per place robbed. You recieve $2 per star per second automatically in your bank account,\n provided there is at least one cop car in range.\nYou will also recieve an additional payout upon passing the robbery, which is done by outlasting the timer.\nHitting a respawn button, editing your car, or resetting without using the inbuilt repair functions will auto fail you.\nYou can repair at a station during a robbery if you have enough repairs; you recieve 1 for every 2 stars you get.\n You may call a repair truck in the services menu to come fix you for a flat rate of $250 or $1500 if you're wanted.\nIf you reset without being caught by the cops or getting away, you will receive additional fines."
partBuyingHelp = "Spawn or edit a vehicle, then hit the sync button to buy parts.\n   Money will be auto deducted provided you have enough, otherwise it will freeze the vehicle and tell you how much you need.\nThere is no in game price list, but it is being worked on. There is a price list in the discord:beamcnr"
markersHelp = "Very Large Solid Blue Box/Circle: Race start area, go here to signal you are wanting to race!\nYellow Large Marker: Repair point, where you can repair during a robbery if you have repairs. Cost half the cost of recovering to spawn.\nSmall Red Markers: Places where you can hit the rob button in the UI to start a robbery as a civilian.\nLarge Blue Markers: Cooldown zones, will take 20 sec times amount of stars you have from your robbery timer plus bonus money. Cops get $1000 for reaching it first!"
commandsHelp = "!moderator: Alert admins that a moderator is needed! DO NOT HIT THIS FOR NO REASON!\n!ready: Indicate you are ready to race\n!buy: switch betwen buying or just previewing the cost of parts\n!load: Attempt to load the main CnR UI if it doesn't appear after spawning a vehicle.\n!bal: Show money.\n!stats: Show money, and a couple other stats.\n!joblist: Display everyones name and job into the chat menu\ngive&name&amount: Give a player an amount between 250 and 5000. Example: give&NuclearKnight00&3000"

rulesHelp = "YOU MUST NOW SYNC YOUR VEHICLE TO OTHER PLAYERS WITH [Sync to Players] BUTTON.\nTHIS IS RATE LIMITED TO ONCE EVERY 5 MIN TO REDUCE QUEUE SPAM.\nNO RAMMING\n	Ramming into other people in this server is not allowed.\nNO 3RD PARTY MODS\n	Only the CNR mod from the server is allowed. This is a bannable offense.\nCIVILIANS DO NOT INTERFERE WITH OTHER CHASES\n	Please do not purposefully interefere or help unless agreed upon by the cop AND robber OR the robbers are in a group!.\nCOPS MUST RESPAWN IF FUSED WITH ANOTHER PLAYER\n	Desync and accidental loading queues happen. If a cop and robber fuse, the cop must immediately reset.\nNO FRAME ONLY CARS\n	This also applies to unibody cars. All doors and essential body parts must be installed, including hoods and trunks.\nBE RESPECTFUL\n	Light cussing is allowed, however please be respectful. Slurs and threats (including kys) are strictly prohibited.\nENJOY THE CHASE\n	Catching robbers is fun, but not when the chase is unbalanced. Make the chases fun, fair and challenging!\nREPAIR ZONES\n	Repair Zones are NOT a safe zone and it is NOT against rules to pin you there, but is frowned upon by most players.\n\n MODERATORS MAY REQUEST YOU REMOVE CERTAIN CAR PARTS AT THEIR DISCRETION!"
raceHelp = "Go find a lage blue square marker, and you and a friend can start a race there!\n  You may also try to start a global race with !race \nYou must not be on the cop team and be in the big blue race trigger box to participate when it begins\n If after 90 seconds there aren't 2 ready racers, it will try again later.\n The 8 checkpoints are randomly selected from a pool of 60 possible locations, and are now ordered!\n You recieve a wanted star every  checkpoint, with repairs etc acting the same as in a robbery if you are wanted.\n Players in an active robbery may ready up and participate; it will just add to your stars and time!\n When 20 minutes have passed, it will end the race if there is anyone else left."
moneyHelp = "Money is earned in many ways in this server, and you can lose it just as fast!\nMoney can be used for many things such as buying parts for cars, and making repairs.\nYou will receieve a  paycheck every 20 minutes."
startingHelp = "THIS SERVER HAS AN ECONOMY. You must start with a starter car by clicking [STARTER VEHICLES] in the CnR UI.\n	Press CTRL + W to change parts. Click [SYNC] to ensure the new parts are purchased.\n	The server saves the parts and cars you own, but the configuration is something you have to manually save/load.\n	IF YOU CANNOT MOVE, you either cannot afford the vehicle/parts, or your level is too high.\nFASTERS CARS COST MORE TO REPAIR!\n	Typically, the higher level you are, the less money you earn. If you're out-classing cops or robbers, you will earn less!\n	This is to encourage people to choose vehicles that match the performance of others."

teamHelp = "Civilian: The default team that you join if you have no team livery selected. This team can commit robberies.\nCops: The local police force, hellbent on stopping the wave of robberies in this city.\n   This team,using REALISTIC methods such as PITs etc, stop robbers who are wanted and bring them to justice!\n   To catch a robber, simply get near a robber that has been stopped for more than 5 seconds and you will auto catch them!\n   Join this team by selecting a cop livery!\nRepair: This team can be summoned by any player using the service menu.\n   The truck is a flat rate of $250, and recovers you in place. The driver recieves $3000.\n   Join this team by spawning a towbed, or a stombecco"
otherServers = "There are other servers where your money is carried over and can be used/earned to/from CnR!\nBomb Tag:\n    Gamemode where you earn points by holding a bomb but also try not to get blown up!\nDemolition Derby Arenas:\n    Smash your car to earn money for parts and knock out other players to win on 50+ arenas!\nBusted:\n    Cops and robbers, but with preset vehicles and only one robber!\n    So far, only on the Valo City and East Coast maps!\nStorm Chasers:\n    STILL IN DEVELOPMENT.\n    Will earn money by chasing tornadoes, test server up already with numerous features!\nUNAMED:\n    Placeholder for another gamemode coming..."
groupHelp = "Under services, you can find a group menu.\nYou may make your own group, and allow up to 4 players to join.\nGroups only exist in the server they are created in as long as the owner is still there\nUse the Join and Invite buttons to set your group to allow anyone to join, or have to be whitelisted.\nGroup members earn extra income from doing certain activities such as:\n      -Two+ robbers running from the police together get extra money per second\n      -Two+ cops CHASING together will recieve extra money per second\n This also allows you to start heists, see [Heists] for more info!"
heistsHelp = "After you start a group, you may hit the [Generate Heists] button.\nThis will randomly generate a few heists to choose from, with payouts randomly scaling based on the number of setups, with a max of 8 setups.\nAfter choosing one, you must rob each setup place SEPERATELY and then get away successfully!\nIf ONE member gets away, then the setup is a success! However, the opposite is true with one failed robbery BEFORE anyone in the group completes the setup will fail the setup for all!\nStarting a setup automatically gives all GROUP menus 4 stars and 10 minutes to get away!\nThe finale gives 6 stars, and 16 minutes, and the finale works the same way as a setup FOR NOW!\n"
copHelp = "The local police force! Their job is to stop robbers while preserving their own police cruiser.\n- This team should use REALISTIC methods to stop robbers such as PIT or TVI.\n- Cops earn money by being near robbers. Pay scales based on the difference of performance levels and wanted level.\n- To catch a robber, simply get near a robber that has been stationary for more than 5 seconds and you will auto-catch them.\n- You must use [RESPAWN 1] or [RESPAWN 2] to respawn. DO NOT use [SYNC] as it causes lag and extra queues for everyone else!\n- Join this team by equipping a police livery.\n"
currentHelp = rulesHelp



local config

timeLeft = "0"
local gui_module = require("ge/extensions/editor/api/gui")
local gui = {setupEditorGuiTheme = nop}
local im = ui_imgui
local windowOpen = im.BoolPtr(true)
local ffi = require('ffi')
wantedInfo = nil
initU = false


local team = "civilian"
myTime = 0
spawnone = {}
prevPosition = {}
raceInProgress = false
local idleTimer = 0
isGameInProgress = false
onFoot = false
snowmanID = nil
sIDSent = false
switchDelay = false
switchDelayCount = 0
stealMode = false
stealCount = 0
stealID = nil
vehicleSpeed = 0
lightbarEnabled = false
local markerDataOne = nil
local markerDataTwo = nil
local markerDataThree = nil
curValue = 0
x = false
prevdS = 0
prevdT = 0
dS = 0
dT = 0
dtS = 0
dSS = 0
dTT = 0
repairsLeft = 0
alive = true
local spawn1 = nil
local spawn2 = nil
local spawnP1 = nil
local spawnP2 = nil
MCCSpawn1 = {}
MCCSpawn2 = {}
MCCSpawn1["west_coast_usa"] = {-961.913,-622.715,106.882,.005,.003,-.919,.395}
MCCSpawn2["west_coast_usa"] = {1043.891,935.8,120.157,.008,.018,.686,.727}

MCCSpawn1["utah"] = {931.6,712.3,235.8,0,0,-.85,.52}
MCCSpawn2["utah"] = {387.5,-897.3,137.35,0,0,.61,.8}


MCCSpawn1["east_coast_usa"] = {370.15,120.1,55.04,0,0,.33,.94}
MCCSpawn2["east_coast_usa"] = {-760.8,530.1,25.68,-.01,.01,.31,.95}

MCCSpawn1["automation_test_track"] = {606.16,47.47,134.82,-0,0,.7,.71}
MCCSpawn2["automation_test_track"] = {-630.18,-5.62,117.94,-0,-0,-.83,.56}


--vehicleSpawned = false

serverList = {demo15 = {"74.91.126.225","3698","cnr;DemoRemake",""},demo10 = {"74.91.126.225","3699","cnr;DemoRemake",""},bombtag = {"74.91.126.225","3697","cnr;BombTag",""},stormchasers = {"74.91.126.225","TBD","TBD",""}}
playerGroups = {}
function syncGroup(data)
	playerGroups = json.decode(data)
	
	



end
--New functions for Beamng UI
---------------------------------------------------------------------------------
cnrPlayerData = {}
function updateUI(data)
	cnrPlayerData = json.decode(data)
	


end



function rob()
TriggerServerEvent("robTry", "lol")
end
---------------------------------------------------------------------------------
--KEEP GLOBAL, OTHERWISE TRIGGERS WONT SEE THEM, BECAUSE REASONS?

--Change timeout to be 'dynamic'? 10 seconds initial, then decrement each time triggered?
function onRobTrigger(data)
	print("Rob trigger")
	local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					local vehSID = MPVehicleGE.getServerVehicleID(vehID)
					if vehID == data.subjectID then
						guihooks.trigger('ScenarioRealtimeDisplay', {msg = "This is a robbery marker! Hit [Rob] in CnRUI to start a robbery! Bindable in Options->Controls->Bindings"})	
						guihooks.trigger('ScenarioFlashMessage', {{"This is a robbery marker! Hit [Rob] in CnRUI to start a robbery! Bindable in Options->Controls->Bindings", 10}} )
			
					break
						
						
					end
				end
			end


end

function onRepairTrigger(data)
	local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					local vehSID = MPVehicleGE.getServerVehicleID(vehID)
					if vehID == data.subjectID then
						guihooks.trigger('ScenarioRealtimeDisplay', {msg = "This is a repair marker! Hit [Repair] in CnRUI to repair your vehicle! Bindable in Options->Controls->Bindings"})	
						guihooks.trigger('ScenarioFlashMessage', {{"This is a repair marker! Hit [Repair] in CnRUI to repair your vehicle! Bindable in Options->Controls->Bindings", 10}} )
			
					break
						
						
					end
				end
			end


end


---------------------------------------------------------------------------------
function ptw(data)
	if data ~= nil then
		TriggerServerEvent("ptw",data)
		
	end

end

function gatherParts()
	print("Gather Parts")
	local t = ""
	local ownMap = MPVehicleGE.getOwnMap()
		for k,v in pairs(ownMap) do
			local myVeh = be:getObjectByID(k)
			myGameVehicleID = myVeh:getID()
	
	
	local vehicleData = vehManager.getVehicleData(myGameVehicleID)
	
	
	
	--if not vehicleData then MPVehicleGE.sendVehicleEdit(myGameVehicleID) return end
	--local vehicle,unifyJournal,chosenParts,activePartsOrig = jbeamSlotSystem.findParts(vehicleData.ioCtx,vehicleData.config)
	local vehManager = extensions.core_vehicle_manager 
	local playerVehicleData = vehManager.getPlayerVehicleData() 
	local chosenParts = playerVehicleData.chosenParts
	chosenParts.main = nil
		vehicleData.config.parts = chosenParts
		
	--		MPVehicleGE.sendVehicleEdit(myGameVehicleID)
			
			
	--end
	
	--end
	
	--local t = extensions.core_vehicle_manager.getConfig(myGameVehicleID)
	 t = chosenParts	
						
		end
			if t ~= "" then
				print("calc perf")
				print(t)
				calculatePerfLevel(t)	
			end


end

performanceLevels = {utv = 10, racetruck = 60,atv = 20, porta_potty_base = 10, ball = 10,us_semi = 40, lansdale = 5, midtruck = 6,pigeon = 1, wigeon = 1, autobello = 2, miramar = 4, burnside = 4, bluebuck = 4, covet = 4, hopper = 4, moonhawk = 4, barstow = 4, legran = 4, midsize = 5, pessima = 5, van = 20, bx = 5, pickup = 20, roamer = 20, wendover = 5, fullsize = 5, sunburst = 10, vivace = 10, etki = 6, etkc = 10, etk800 = 10, bastion = 15, bolide = 10, sbr = 10,scintilla =  40 }


function calculatePerfLevel(vehicleData)
	local car = "none"
	local basePerformanceLevel = 0
	performanceLevel = 0
	if vehicleData ~= nil and type(vehicleData) == "table" then
		print("Vehicle Table Found")
		--QUICK AND DIRTY, NEED TO REDO
		--local data = vehicleData:sub(s)
		local ta = Util.JsonDecode(data)
		for cKey, cV in pairs(cars) do
			local carStringSplit = stringSplit(vehicleData,cV .. "_frame")
			local carStringSplit2 = stringSplit(vehicleData,cV .. "_body")
			if carStringSplit[2] ~= nil or carStringSplit2[2] ~= nil then
				print("model" .. cV)
				 car = cV
				 basePerformanceLevel = performanceLevels[car]
				
				 break
			end
		end
	end
	if car ~= "none" then
		for k,v in pairs(t) do
			if carParts["common"][v] ~= nil and carParts[car][v] ~= " " then
				if type(carParts["common"][v]) == "table" then
					basePerformanceLevel = basePerformanceLevel +  carParts["common"][v][2]
				end
			end
		end
			performanceLevel = basePerformanceLevel
			myVeh:queueLuaCommand('cnr.PTW2()')
	end
	
	


end

function setPerfLevel(data)
	if data ~= nil then
		--This is done because I had to Double it and times by 100 to get a wider range
		local num = tonumber(data)
		num = num * 100
		num = tonumber(string.format("%.0f",performanceLevel + num)) * 2
	end
end

function setDs(data)
	if data ~= nil then
		dT = tonumber(data)
		if dT >= prevdT then
			--print("Greaterm than prevDT")
			--print(resetHandled)
			--resetHandled = false
			--print(resetHandled)
			prevdT = dT
			dT = data
	
			
		else
			
			
			--print("resetr handled ")
			--print(resetHandled)
			dTT = prevdT
			--if resetHandled == false then
				--print("reset not handled")
				--TriggerServerEvent("resetHa", tostring(dSS) .. "&" .. tostring(dTT) .. "&2&1")
				 --resetHandled = true
				-- prevdT = 0
				 -- vehReset(spawn1)
			--else
				
			--end
		end
		
	end
	
end
function setD(data)
	
	if data ~= nil then
		dS = tonumber(data)
		if dS > prevdS then
			prevdS = dS
			dS = data
		else 
			dSS = prevdS
			--if resetHandled == false then
				--TriggerServerEvent("resetHa", tostring(dSS) .. "&" .. tostring(dTT) .. "&2&1")
				-- resetHandled = true
				-- prevDs = 0
				--vehReset(spawn1)
				-- resetHandled = false
			--else resetHandled = false
			--	prevdS = 0
			--end
			
		
			
			
		end
		
		
		
	end
	
end 	



function setTeam(data)
	if data ~= nil then
		team = data
		print(data)
		
	end
	if team ~= "MCC" and team ~= "cops" then
		if wantedInfo ~= nil then
			wantedInfo = nil
		
		end
	
	
	end
end




function setInfo(data)
	if data ~= "nil" then
		local t = " "
		--REMOVE STRINGSPLIT
		local s = stringSplit(data, "&", " ")
		local i = o
		for i = 2, 15 do
			if s[i] ~= nil then
				t = t .. s[i] .. "\n"
			end
		end
		wantedInfo = t
	else wantedInfo = nil
	end
	
end

-- -- -- -- -- -- -- -- -- -- --

local servVehID = ""

ID = 20
spawnTable = {}
function initUI(data)
	if data ~= nil then
		ID = tonumber(data)
		servVehID = tostring(ID) .. "-0"
		 config = require("settings/config")
		extensions.core_input_actionFilter.setGroup('cnr', config.disabledActions)
                extensions.core_input_actionFilter.addAction(0, 'cnr', true)
		--extensions.core_gamestate.setGameState("scenario", "multiplayer", "cnr")
		
		spawnTable[1] = civilianSpawns[location][1][ID]
		spawnTable[2] = civilianSpawns[location][2][ID]
		spawnTable[3] = policeSpawns[location][1][ID]
		spawnTable[4] = policeSpawns[location][2][ID]
		
		
	else 
	end
	
	
end
local markList = {}
markList["west_coast_usa"] = {}
markList["west_coast_usa"][1] = {-487, 122, 100.7}
markList["west_coast_usa"][2] = {-190, 528, 75}
markList["west_coast_usa"][3] = {-293, 460, 84}
markList["west_coast_usa"][4] = {-684, 129, 118}
markList["west_coast_usa"][5] = {-415, 177, 100.7}
markList["west_coast_usa"][6] = {913, -497, 163}
markList["west_coast_usa"][7] = {-807, 849.6, 74.8}
markList["west_coast_usa"][8] = {-786, 560, 124.4}
markList["west_coast_usa"][15] = {-785, 550, 124.4}
markList["west_coast_usa"][9] = {-673, 511, 118}
markList["west_coast_usa"][10] = {-689, 527, 119}
markList["west_coast_usa"][11] = {-640, 84, 103}
markList["west_coast_usa"][12] = {-842, 886, 75}
markList["west_coast_usa"][13] = {672, -637, 228}
markList["west_coast_usa"][14] = {-493, 196, 101}
markList["west_coast_usa"][16] = {855.64,-952.038,171.4}
markList["west_coast_usa"][17] = {-640,-950,165.01}
markList["west_coast_usa"][18] = {651,-854,156.4}
markList["west_coast_usa"][19] = {-75.5,73,122.5}
markList["west_coast_usa"][20] = {-872.4,-636.6,105}
markList["west_coast_usa"][21] = {-100.2,-21,120}
markList["west_coast_usa"][22] = {426,-281,145}
markList["west_coast_usa"][23] = {362.5,838.3,131.4}
markList["west_coast_usa"][24] = {-279.6,-102.8,120}
markList["west_coast_usa"][25] = {-774,596,117}
markList["west_coast_usa"][26] = {-452.1,1951.5,82.5}
markList["west_coast_usa"][27] = {-1300.2,-677.2,104.4}
markList["west_coast_usa"][28] = {834.2,-526.1,165.1}
markList["west_coast_usa"][29] = {-1132.7,1937.5,93.348}
markList["west_coast_usa"][30] = {131.4,1771.9,102.4}
markList["utah"] = {}

markList["utah"][1] = {805,-163,144}
markList["utah"][2] = {768, -124, 144}
markList["utah"][3] = {813, -220,144}
markList["utah"][4] = {800,11,148}
markList["utah"][5] = {118,-20,172}
markList["utah"][6] = {-324,-531,130}
markList["utah"][7] = {-809,-126.5,297}
markList["utah"][8] = {-789,-77,297}
markList["utah"][9] = {-565,244,298}
markList["utah"][10] = {-511,236.2,298}
markList["utah"][11] = {637,-519,135}
markList["utah"][12] = {512,-513,135}
markList["utah"][13] = {-910.5,606.8,264.9}
markList["utah"][14] = {-633.6,527.8,256.1}
markList["utah"][15] = {65,877.9,268.8}
markList["utah"][16] = {-938.5,-273.5,262.3}


markList["automation_test_track"] = {}
markList["automation_test_track"][1] = {123.5,135.8,128.4}
markList["automation_test_track"][2] = {60.7,491.9,134.5}
markList["automation_test_track"][3] = {-51,559.4,134.5}
markList["automation_test_track"][4] = {-283,750,268}
markList["automation_test_track"][5] = {-85.6,818.8,257.6}
markList["automation_test_track"][6] = {-13.4,-178.6,119.5}
markList["automation_test_track"][7] = {-23.1,-139.3,119.5}
markList["automation_test_track"][8] = {-21.9,-326.1,122.8}
markList["automation_test_track"][9] = {-234,-278.5,118.1}
markList["automation_test_track"][10] = {-131.1,-222.5,120.4}
markList["automation_test_track"][11] = {162.6,78.5,129.4}
markList["automation_test_track"][12] = {432.3,69.8,134}
markList["automation_test_track"][13] = {567.1,99.6,134}
markList["automation_test_track"][14] = {504.9,-18.6,134}
markList["automation_test_track"][15] = {120.6,307.5,126.4}
markList["automation_test_track"][16] = {187.7,92,130}
markList["automation_test_track"][17] = {97.3,139.8,128.5}






local markList2 = {}
markList2["west_coast_usa"] = {}
markList2["west_coast_usa"][1] = {-607.608, 110.609, 102.303}
markList2["west_coast_usa"][2] = {154.481, 770.710, 102.389}
markList2["west_coast_usa"][3] = {-63.177, 13.583, 120.137}
markList2["west_coast_usa"][4] = {910, -545, 164.233}

markList2["east_coast_usa"] = {}

markList2["east_coast_usa"][1] = {-798.924, 488.257, 23}
markList2["east_coast_usa"][2] = {704.641, -344.219, 56.247}
markList2["east_coast_usa"][3] = {-75.3, -797.986, 15.04}
markList2["east_coast_usa"][4] = {286.678, -747.719, 45.564}

markList2["automation_test_track"] = {}
markList2["automation_test_track"][1] = {-89.1,-220.3,120.3}
markList2["automation_test_track"][2] = {155.6,315.9,126.}
markList2["automation_test_track"][3] = {444.6,116.7,139.6}



markList2["utah"] = {}


markList2["utah"][1] = {121.67,-436.4, 126.74}
markList2["utah"][2] = {795.46,-180.75,144.8}
markList2["utah"][3] = {-787.29, -72.68, 297}


markList["east_coast_usa"] = {}

markList["east_coast_usa"][1] = {537, -765, 60}
markList["east_coast_usa"][2] = {706, -44, 52}
markList["east_coast_usa"][3] = {-769, 473, 23}
markList["east_coast_usa"][4] = {747.7, -252.8, 53}
markList["east_coast_usa"][5] = {-80, -790, 16}
markList["east_coast_usa"][6] = {775.4, -344.1, 53}
markList["east_coast_usa"][7] = {774.6, -331.9, 53}
markList["east_coast_usa"][8] = {723.3, -245.4, 53}
markList["east_coast_usa"][9] = {814, -245.2, 53}
markList["east_coast_usa"][10] = {556.2,4.8, 52.9}
markList["east_coast_usa"][11] = {622.7, -133.5, 53.2}
markList["east_coast_usa"][12] = {636,-163.3,53}
markList["east_coast_usa"][13] = {737.6,-187.7,53.1}
markList["east_coast_usa"][14] = {737.6,-508.7,57}
markList["east_coast_usa"][15] = {736.8,-445.8,53.1}
markList["east_coast_usa"][16] = {698.2,-490.9,57.2}
markList["east_coast_usa"][17] = {585.8,-147.6,53.4}
markList["east_coast_usa"][18] = {655.6,-180.4,53.4}
markList["east_coast_usa"][19] = {150.3,7.6,100.6}


markList2["east_coast_usa"] = {}

markList2["east_coast_usa"][1] = {-798.924, 488.257, 23}
markList2["east_coast_usa"][2] = {704.641, -344.219, 56.247}
markList2["east_coast_usa"][3] = {-75.3, -797.986, 15.04}
markList2["east_coast_usa"][4] = {286.678, -747.719, 45.564}


specialmarkList = {}
specialmarkList["west_coast_usa"] = {}
specialmarkList["west_coast_usa"][1] = {-1431.6,-967.5,97.2}
specialmarkList["west_coast_usa"][2] = {-146.4,579.8,74.5}


specialmarkList["automation_test_track"] = {}

specialmarkList["automation_test_track"][1] = {292.5,835.4,229.9}

specialmarkList["automation_test_track"][2] = {10,10,-100}



specialmarkList["east_coast_usa"] = {}
specialmarkList["east_coast_usa"][1] = {-553.2,-837.5,50.6}
specialmarkList["east_coast_usa"][2] = {-146.4,579.8,74.5}

specialmarkList["utah"] = {}
specialmarkList["utah"][1] = {-931.9,-171.8,266.5}
specialmarkList["utah"][2] = {-146.4,579.8,74.5}


--need to change this


location = "west_coast_usa"

function spawnOb(data)
--#BA0101FF
--/art/shapes/interface/checkpoint_marker.dae
	if data ~= nil then
		location = data
		print(location .. " map selected")
	
	end
	local  i = 0
	for i = 1, #markList[location] do
	local positionOne = markList[location][i][1]
	local positionTwo = markList[location][i][2]
	local positionThree = markList[location][i][3]
	
	
	local marker = createObject("TSStatic")
	marker.shapeName = "art/shapes/interface/checkpoint_marker.dae" 
	
	marker.useInstanceRenderData = 1 
	marker.instanceColor = Point4F(1, 0, 0, 1) 
   	 marker:setPosRot(positionOne, positionTwo, positionThree, 0, 0, 0, 1) 
	marker.scale = vec3(2, 2, 2)
	marker:registerObject("rob" .. i)
	
		
	local missionTrigger = createObject("BeamNGTrigger")
   	 missionTrigger.loadMode = 1
   	 missionTrigger:setField("triggerType", 0, "Sphere")
  	  missionTrigger.luaFunction = String("onRobTrigger")
  	  missionTrigger:setPosRot(positionOne, positionTwo, positionThree, 0, 0, 0, 1)

  	  missionTrigger:setScale(Point3F(3, 3, 3))
 	   missionTrigger:registerObject("onRobTrigger" .. i)
 	   missionTrigger.name = "robTrigger" .. i
	end
	local i = 0
	for i = 1, #markList2[location] do
	local positionOne = markList2[location][i][1]
	local positionTwo = markList2[location][i][2]
	local positionThree = markList2[location][i][3]
	
	
	local marker = createObject("TSStatic")
	marker.shapeName = "art/shapes/interface/checkpoint_marker.dae" 
	marker.scale = vec3(5, 5, 5)
	marker.useInstanceRenderData = 1 
	marker.instanceColor = Point4F(1, .946, 0, 1) 
   	 marker:setPosRot(positionOne, positionTwo, positionThree, 0, 0, 0, 1) 
	
	marker:registerObject("repair" .. i)
	
	local missionTrigger = createObject("BeamNGTrigger")
   	 missionTrigger.loadMode = 1
   	 missionTrigger:setField("triggerType", 0, "Sphere")
  	  missionTrigger.luaFunction = String("onRepairTrigger")
  	  missionTrigger:setPosRot(positionOne, positionTwo, positionThree, 0, 0, 0, 1)

  	  missionTrigger:setScale(Point3F(2, 2, 2))
 	   missionTrigger:registerObject("repairTrigger" .. i)
 	   missionTrigger.name = "repairTrigger" .. i
	
	end
	
	
	
	
	
	
	local marker = createObject("TSStatic")
	marker.shapeName = "art/shapes/interface/checkpoint_marker.dae" 
	marker.scale = vec3(1, 1, 1)
	marker.useInstanceRenderData = 1 
	marker.instanceColor = Point4F(0, 0.075, 1, 1) 
   	 marker:setPosRot(specialmarkList[location][1][1],specialmarkList[location][1][2],specialmarkList[location][1][3], 0, 0, 0, 1) 
	
	marker:registerObject("Special")
	
	
	local marker = createObject("TSStatic")
	marker.shapeName = "art/shapes/interface/checkpoint_marker.dae" 
	marker.scale = vec3(1, 1, 1)
	marker.useInstanceRenderData = 1 
	marker.instanceColor = Point4F(0, 0.075, 1, 1) 
   	 marker:setPosRot(specialmarkList[location][2][1],specialmarkList[location][2][2],specialmarkList[location][2][3], 0, 0, 0, 1) 
	
	marker:registerObject("Special2")
	buildRaceTriggerZone()
	
	local marker = createObject("TSStatic")
	marker.shapeName = "west_coast_usa/art/shapes/objects/airtosurfacetelegram.dae" 
	marker.scale = vec3(1, 1, 1)
	marker.useInstanceRenderData = 1 
	
   	 marker:setPosRot(-743.8,744.6,3000, 0, 0, 0, 1) 
	
	marker:registerObject("surfacetoairtelegram")
	
	
 	  
		
		
end	

function restorePlayer(data)
	local table = json.decode(data)
	print(table)
	if table ~= nil then
		for name,v in pairs(table) do
			
			if removedPlayers[name] ~= nil then
				
				removedPlayers[name] = nil
			end
			MPVehicleGE.restorePlayerVehicle(name)
		
		end
	
	end

end
removedPlayers = {}
function removePlayer(data)
	--print("REMOVE")
	local table = json.decode(data)
	
	if table ~= nil then
		for vehh,v in pairs(table) do
			--print(vehh)
			if servVehID ~= v then
				removedPlayers[vehh] = v
			local vehicle = getVehicleByServerID(v)
			
				if vehicle ~= nil then
					--print("not nil")
					 local veh = be:getObjectByID(vehicle.gameVehicleID)
					if veh ~= nil then
						--print("delete")
					veh:delete()
					end
				end
			else
				print("Ignoring removal from " .. vehh)
			end
			
		end
	
	end


end
  --guihooks.trigger("ChangeState", {state = "scenario-start"})
		 
		--showMenu()
--Change this later to accept different strings for different menus
function showMenu()
	print("showmenu")
    if contextMenus.carSyncing ~= nil then
    	print("Menu not nil")
       
        guihooks.trigger('ScenarioChange', {name = contextMenus.carSyncing.title, description = contextMenus.carSyncing.description, introType = contextMenus.carSyncing.type})
    end
end

function stringSplit(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function setSpeed(data)
	vehicleSpeed = data
	if vehicleSpeed >= 10 then
		if syncToPlayersRequired == true then
			
			guihooks.trigger('toastrMsg', {type="warning", title="SYNC TO OTHER PLAYERS", msg = "You need to hit the 'Sync to Players' Button to participate in gameplay!", config = {timeOut = 100000}})
			guihooks.trigger('ScenarioFlashMessage', {{'You need to hit the [Sync to Players] Button to participate in gameplay!', 2}} )
			guihooks.trigger('Message',{clear = nil, ttl = 10, msg = "You need to hit the [Sync to Players] Button to participate in gameplay!", category = "delivery", icon = "warning"})
			guihooks.trigger('ScenarioRealtimeDisplay', {msg = "You need to hit the [Sync to Players] Button to participate in gameplay!"})	
			guihooks.trigger("toastrMsg", {type="info", title="SYNC TO OTHER PLAYERS", msg= "You need to hit the [Sync to Players] Button to participate in gameplay!"})
			guihooks.message("You need to hit the [Sync to Players] Button to participate in gameplay!", 5, "SYNC TO OTHER PLAYERS")
		
		end
	
	end
end
	

local function onVehicleSwitched(oldvehID, newvehID, playerID)
	
end


	
		
local function onVehicleDestroyed(vehID)
	local vehSID = MPVehicleGE.getServerVehicleID(vehID)
	if onFoot and vehSID == snowmanID then
		onFoot = false
		snowmanID = nil
		sIDSent = false
		--print("snowman gone")
		TriggerServerEvent("onFoot", "nil")
	end
end				

local function lightbar(data)
	
		--print("lightbar")
	if data == false then
		lightbarEnabled = false
		--print("false")
	elseif lightbarEnabled == false then
		TriggerServerEvent("lightbarSet", " ")
		lightbarEnabled = true
		--print("true")
	end
end

local customTagTable = {}

function createPatronRoles()
	local t = customTagTable
	for name,v in pairs(customTagTable) do
		print("made " .. name .. " role")
		MPVehicleGE.createRole(name,"","",customTagTable[name]["r"],customTagTable[name]["g"],customTagTable[name]["b"],0)
	
	
	end
end



function addCustomTagColor(data)
	if data ~= nil then
		local t = json.decode(data)
		if t ~= nil then
			local tName = t["name"]
			if customTagTable[tName] ~= nil then
				customTagTable[tName] = {t["r"],t["g"],t["b"]}
				
			end
		
		end
	
	end

end

function syncCustomColors(data)
	if data ~= nil then
		print(data)
		local t = json.decode(data)
		if t ~= nil then
			customTagTable = t
			createPatronRoles()
		end
		
		
	end


end

local function displayErrorAlert(data)
	if data ~= nil then
		
	
	end


end

local rPTR = im.ArrayChar(1024)
local gPTR = im.ArrayChar(1024)
local bPTR = im.ArrayChar(1024)

local lastColorSync = 0
local rColor = 0
local gColor = 0
local bColor = 0
local currentError = ""
local function patronWindowDraw()
		gui.setupWindow("PatronWindow")
		im.Begin("Patron Window")
		im.TextColored(im.ImVec4(rColor/255,gColor/255,bColor/255,1.0),"Your tag will be this color!")
		im.Text(currentError)
		im.PushItemWidth(50)
		im.Text("R")
		if im.InputText(" ", rPTR,1024,im.InputTextFlags_EnterReturnsTrue) then
			local r = tonumber(ffi.string(rPTR))
			if r ~= nil then 
				if r >= 0  and r <= 255 then
					rColor = r
					currentError = ""
				else
					currentError = "Value must be between 0 and 255!"
				end
			else
				currentError = "Value entered was not a number!" 
			end
		end
	
		im.PopItemWidth()
		
		im.PushItemWidth(50)
		im.Text("G")
		if im.InputText("  ", gPTR,1024,im.InputTextFlags_EnterReturnsTrue) then
			local g = tonumber(ffi.string(gPTR))
			if g ~= nil then 
				if g >= 0  and g <= 255 then
					gColor = g
					currentError = ""
				else
					currentError = "Value must be between 0 and 255!"
				end
			else
				currentError = "Value entered was not a number!" 
			end
		end
		im.PopItemWidth()
		
		im.PushItemWidth(50)
		im.Text("B")
		if im.InputText("   ", bPTR,1024,im.InputTextFlags_EnterReturnsTrue) then
			local b = tonumber(ffi.string(bPTR))
			if b ~= nil then 
				if b >= 0  and b <= 255 then
					bColor = b
					currentError = ""
				else
					currentError = "Value must be between 0 and 255!"
				end
			else
				currentError = "Value entered was not a number!"	 
			end
		end
	
		
		im.PopItemWidth()
		
		if im.Button("Send Colors") then
			local time = os.time()
			if time - lastColorSync >= 120 then
				local t = {["name"] = name, ["r"] = rColor,["g"] = gColor,["b"] = bColor}
				
				local j = jsonEncode(t)
				TriggerServerEvent("addCustomRoleColors",j)
				lastColorSync = time
			else
				
			end
		end
		im.SameLine()
		if im.Button("Close") then
			windowsToShow["patronWindow"] = nil
		
		end
		
		
		

end

local function setCustomColor(combinedID,name)
	setVehicleRole(combinedID,name,0) 


end

--Redo this!
--New setTag still being planned
function setTag(data)
	if data ~= nil then
		local tagTable = json.decode(data)
		if tagTable ~= nil then
			for name,v in pairs(tagTable) do
				if timeLeft ~= "0" then
					if tagTable[name]["status"] == "0" then
						if tagTable[name]["team"] == "cops" or tagTable[name]["team"] == "MCC" then
							setVehicleRole(tagTable[name]["ID"],"BLANK",0) 
						
						else
							MPVehicleGE.setPlayerNickPrefix(name, name, "[" .. tagTable[name]["perfLevel"] .. "]" .. "[" .. tagTable[name]["team"] .. "]")
							removeVehicleRole(tagTable[name]["ID"])
							if customTagTable[name] ~= nil then
								setCustomColor(tagTable[name]["ID"],name)
							
							end
						end
				
					else
						MPVehicleGE.setPlayerNickPrefix(name, name, "[" .. tagTable[name]["status"] .. "]" .. "[" .. tagTable[name]["perfLevel"] .. "]" .. "[" .. tagTable[name]["team"] .. "]")
						removeVehicleRole(tagTable[name]["ID"])
						if customTagTable[name] ~= nil then
								setCustomColor(tagTable[name]["ID"],name)
							
						end
					end
					
				elseif tagTable[name]["hidden"] == false then
					if tagTable[name]["status"] == "0" then
						
						MPVehicleGE.setPlayerNickPrefix(name, name, "[" .. tagTable[name]["perfLevel"] .. "]" .. "[" .. tagTable[name]["team"] .. "]")
						removeVehicleRole(tagTable[name]["ID"])
						if customTagTable[name] ~= nil then
								setCustomColor(tagTable[name]["ID"],name)
							
						end
					else
						
						MPVehicleGE.setPlayerNickPrefix(name, name, "[" .. tagTable[name]["status"] .. "]" .. "[" .. tagTable[name]["perfLevel"] .. "]" .. "[" .. tagTable[name]["team"] .. "]")
						removeVehicleRole(tagTable[name]["ID"])
						if customTagTable[name] ~= nil then
								setCustomColor(tagTable[name]["ID"],name)
							
						end
					
					end
				else
					setVehicleRole(tagTable[name]["ID"],"BLANK",0) 
					
					
				end
			end
		
		end
	end
end
	
	
	
--TODO Change to JSON
function setTagOld(data)
	local nickSplit = stringSplit(data, "&")
	local name = nickSplit[1]
	local perfLevel = nickSplit[2]
	local team = nickSplit[3]
	local status = nickSplit[4]
		if status == "0" then
		
			MPVehicleGE.setPlayerNickPrefix(name, name,"[" .. perfLevel .. "]" .. "[" .. team .. "]")
		else MPVehicleGE.setPlayerNickPrefix(name, name, "[" .. status .. "]" .. "[" .. perfLevel .. "]" .. "[" .. team .. "]")
		end
	
end	




function drawWindow(dt)
	gui.setupWindow("Robbery")
	im.Begin("Robbery Timer")
	im.Text(timeLeft)
	if im.Button("Mark Cooldown Zone") then
		if rateL >= 3 then
			TriggerServerEvent("markCooldown","lol")
			rateL = 0
		
		end
	
	end
	im.End()
end


function drawWindow2(dt)
	gui.setupWindow("Wanted List")
	im.Begin("WantedList")
	im.Text(wantedInfo)
	im.End()
end

function clearGPS()
	core_groundMarkers.setFocus(nil)
	local trigger = scenetree.findObject("GPSTrigger")
	if trigger ~= nil then
		trigger:delete()
						
	end
	local marker = scenetree.findObject("GPSMarker")
	if marker ~= nil then
		marker:delete()
						
	end

end

function requestQueue()
	if rateL >= 3 then
		TriggerServerEvent("requestQueue","lol")
		
		rateL = 0
	
	
	end


end

function robTry()
	if rateL >= 3 then
		if team == "civilian" then
			TriggerServerEvent("robTry", "lol")
			rateL = 0
		else
			guihooks.trigger('toastrMsg', {type="warning", title="WRONG TEAM", msg = "Only civilians can rob!", config = {timeOut = 100000}})
						
		end
	end



end

function repairTry()
	if rateL > 2 then
			if team == "cops" then
					TriggerServerEvent("copRepair","lol")
					rateL = 0
			end
				
					if timeLeft ~= "0" then
						if tonumber(repairsLeft) > 0 then
				
			
							local ownMap = MPVehicleGE.getOwnMap()
			
							for k,v in pairs(ownMap) do
								local myVeh = be:getObjectByID(k)
								local myRot = quat(myVeh:getRotation())
								local myPos = myVeh:getPosition()
								local vehSID = MPVehicleGE.getServerVehicleID(k)
								TriggerServerEvent("recieveClientData", tostring(vehPosx) .. "&" .. tostring(vehPosy) .. "&" .. tostring(vehPosz) .. "&" .. tostring(vehSID) .. "&" .. tostring(vehicleSpeed) .. "&" .. tostring(dS) .. "&" .. tostring(dT))
								local i = 0
								local found = false
								for i = 1, #markList2[location]  do
									local xDiff = 0
									local yDiff = 0
									xDiff = math.abs(markList2[location][i][1] - myPos.x)
									yDiff = math.abs(markList2[location][i][2] - myPos.y)
									if xDiff <= 5 and yDiff <= 5 then
										resetHandled = true
										--found = true
										TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&1")
										
										dS = 0
										dT = 0
									
	
										myVeh:queueLuaCommand('recovery.recoverInPlace()') 
										resetHandled = true
										alive = true
										break
									end
								end
							end
						else TriggerServerEvent("noRepair","noRepair")
						end
						if found == false then
						
							guihooks.trigger('toastrMsg', {type="warning", title="NO REPAIR ZONE", msg = "Find a large yellow marker, or an MCC as a cop to use this button!", config = {timeOut = 100000}})
					
						end
					else local ownMap = MPVehicleGE.getOwnMap()
			
							for k,v in pairs(ownMap) do
								local myVeh = be:getObjectByID(k)
								local myRot = quat(myVeh:getRotation())
								local myPos = myVeh:getPosition()
								local vehSID = MPVehicleGE.getServerVehicleID(k)
								TriggerServerEvent("recieveClientData", tostring(vehPosx) .. "&" .. tostring(vehPosy) .. "&" .. tostring(vehPosz) .. "&" .. tostring(vehSID) .. "&" .. tostring(vehicleSpeed) .. "&" .. tostring(dS) .. "&" .. tostring(dT))
								local i = 0
								for i = 1, #markList2[location]  do
									local xDiff = 0
									local yDiff = 0
									xDiff = math.abs(markList2[location][i][1] - myPos.x)
									yDiff = math.abs(markList2[location][i][2] - myPos.y)
									if xDiff <= 5 and yDiff <= 5 then
										resetHandled = true
										TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&1")
										dS = 0
										dT = 0
	
	
										myVeh:queueLuaCommand('recovery.recoverInPlace()') 
										resetHandled = true
										alive = true
										break
									end
								end
							end
					end
				
			rateL = 0
			end
		
	



end


perfLevel = 0
repairCost = 0
repairMult = 10
local repairNeeded = false


function markGPS(data)
	if data ~= nil then
		local trigger = scenetree.findObject("GPSTrigger")
		if trigger ~= nil then
			trigger:delete()
		end
		local marker = scenetree.findObject("GPSMarker")
		if marker ~= nil then
			marker:delete()
						
		end
		local table = json.decode(data)
		if table ~= nil then
			core_groundMarkers.setFocus(vec3(table["x"],table["y"],table["z"]))
			local missionTrigger = createObject("BeamNGTrigger")
   	 		missionTrigger.loadMode = 1
   			missionTrigger:setField("triggerType", 0, "Sphere")
  	 		missionTrigger.luaFunction = String("onGPSTrigger")
  	  		missionTrigger:setPosRot(table["x"],table["y"],table["z"], 0, 0, 0, 1)

  	 		missionTrigger:setScale(Point3F(3, 3, 3))
 	  		missionTrigger:registerObject("GPSTrigger")
 	  		missionTrigger.name = "GPSTrigger"
 	  		
 	  		
 	  		
 	 	local marker = createObject("TSStatic")
		marker.shapeName = "art/shapes/interface/single_faded_column.dae" 
		marker.scale = vec3(20, 20, 20)
		marker.useInstanceRenderData = 1 
		marker.instanceColor = Point4F(0,0.3,1,1) 
   		 marker:setPosRot(table["x"],table["y"],table["z"] - 50, 0, 0, 0, 1) 
	
		marker:registerObject("GPSMarker")
		marker.name = "GPSMarker"
		else
			core_groundMarkers.setFocus(nil)
		end
	
	
	end


end

local function onGPSTrigger(data)
	local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					local vehSID = MPVehicleGE.getServerVehicleID(vehID)
					if vehID == data.subjectID then
						local trigger = scenetree.findObject("GPSTrigger")
						if trigger ~= nil then
							trigger:delete()
						
						end
						local marker = scenetree.findObject("GPSMarker")
						if marker ~= nil then
							marker:delete()
						
						end
					break
						
						
					end
				end
			end


end


--temp function for respawn bindings
local function respawnButton(data)
	local data = tonumber(data)
	if data ~= nil then
		if data == 1 then
		
		else
		
		end
		if team == "civilian"  or team == "repair" or  team == "None" then
				resetHandled = true
				TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
				
				--be:resetVehicle(0)
				
					if timeLeft ~= "0"  then
					
						robFail()
					end
					local ownMap = MPVehicleGE.getOwnMap()
		
					for k,v in pairs(ownMap) do
							local myVeh = be:getObjectByID(k)
						if data == 1 then
							sendToSpawn(spawnTable[1])
						else
							sendToSpawn(spawnTable[2])
						end
						--be:resetVehicle(0)	
			
					end
				elseif team == "cops"  then
					
					resetHandled = true
					TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
				
					--be:resetVehicle(0)
				
					alive = true
					local ownMap = MPVehicleGE.getOwnMap()
		
						for k,v in pairs(ownMap) do
							local myVeh = be:getObjectByID(k)
							
							if data == 1 then
							sendToSpawn(spawnTable[3])
						else
							sendToSpawn(spawnTable[4])
						end
							--be:resetVehicle(0)
					
			
						end	
					
				
				elseif team == "MCC" then
					
					TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
				
					--be:resetVehicle(0)
				
					alive = true
					local ownMap = MPVehicleGE.getOwnMap()
		
						for k,v in pairs(ownMap) do
							local myVeh = be:getObjectByID(k)
							
							sendToSpawn(MCCSpawn1[location])
							--be:resetVehicle(0)
					
			
						end	
					
				end
	
	end


end

function refuelTry()

	if rateL >= 3 then
			TriggerServerEvent("refuel","lol")
			rateL = 0
	end

end
function findRepairTruck()

		if rateL >= 3 then
		TriggerServerEvent("refuelFinder","lol")
		rateL = 0
		end
end

function findRefuelTruck()
	
		if rateL >= 3 then
			TriggerServerEvent("repairFinder", "lol")
			rateL = 0
		end
end


performanceLevel = 0
function drawWindow3(dt)
	gui.setupWindow("CnR UI")
	im.Begin("CnR UI")
	repairCost = string.format("%.2f",perfLevel * dT * repairMult)
	--[[
	if repairNeeded == false then
		if settings["Call Repair Truck"] > 200 then
			if tonumber(repairCost) >=  settings["Call Repair Truck"] then
				if rateL >= 2 then
					TriggerServerEvent("repairFinder","lol")
					repairNeeded = true
					rateL = 0
				end
			end 
	
		end
	end
	--]]
	im.Text("Current Balance: $" .. cnrBalance)
	im.Text("Current Damage: $" .. repairCost)
	im.Text("Performance Level: " .. performanceLevel)
		--need to change how the reset buttons work
		if im.Button("Respawn 1") then
			if rateL >= 3 then
				respawnButton(1)
				--[[
				if team == "civilian"  or team == "repair" or  team == "None" then
				resetHandled = true
				TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
				
				--be:resetVehicle(0)
				
					if timeLeft ~= "0"  then
					
						robFail()
					end
					local ownMap = MPVehicleGE.getOwnMap()
		
					for k,v in pairs(ownMap) do
							local myVeh = be:getObjectByID(k)
						
						sendToSpawn(spawnTable[1])
						--be:resetVehicle(0)	
			
					end
				elseif team == "cops"  then
					
					resetHandled = true
					TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
				
					--be:resetVehicle(0)
				
					alive = true
					local ownMap = MPVehicleGE.getOwnMap()
		
						for k,v in pairs(ownMap) do
							local myVeh = be:getObjectByID(k)
							
							sendToSpawn(spawnTable[3])
							--be:resetVehicle(0)
					
			
						end	
					
				
				elseif team == "MCC" then
					
					TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
				
					--be:resetVehicle(0)
				
					alive = true
					local ownMap = MPVehicleGE.getOwnMap()
		
						for k,v in pairs(ownMap) do
							local myVeh = be:getObjectByID(k)
							
							sendToSpawn(MCCSpawn1[location])
							--be:resetVehicle(0)
					
			
						end	
					
				end
					--]]
				rateL = 0
				
			end
		end
		
		im.SameLine()
	

		if im.Button("Respawn 2") then
			if rateL >= 3 then
				respawnButton(2)
				--[[
				if team == "civilian" or team == "repair" or  team == "None" then
				resetHandled = true
				TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
				
			--be:resetVehicle(0)
					
					if timeLeft ~= "0"  then
						robFail()
					end
					local ownMap = MPVehicleGE.getOwnMap()
	
					for k,v in pairs(ownMap) do
						local myVeh = be:getObjectByID(k)
						
						sendToSpawn(spawnTable[2])
						--be:resetVehicle(0)
			
					end
				elseif team == "cops" then
					
					resetHandled = true
					TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
				
					--be:resetVehicle(0)
				
					alive = true
					local ownMap = MPVehicleGE.getOwnMap()
		
						for k,v in pairs(ownMap) do
							local myVeh = be:getObjectByID(k)
							
							sendToSpawn(spawnTable[4])
							--be:resetVehicle(0)
					
			
						end	
				
				elseif team == "MCC" then
					
					TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
				
					--be:resetVehicle(0)
				
					alive = true
					local ownMap = MPVehicleGE.getOwnMap()
		
						for k,v in pairs(ownMap) do
							local myVeh = be:getObjectByID(k)
							
							sendToSpawn(MCCSpawn2[location])
							--be:resetVehicle(0)
					
			
						end	
					
					
					
				end
			--]]
			rateL = 0
			end
		end
		

		
		
		
	
	
	
		
		im.Text("\n")
		
	
		
		
	
		
		if im.Button("Repair") then
			if rateL > 2 then
				repairTry()
				--[[
				--delete this old code after ensuring RepairTry() has no bugs
				if team == "cops" then
					TriggerServerEvent("copRepair","lol")
					rateL = 0
				end
				
					if timeLeft ~= "0" then
						if tonumber(repairsLeft) > 0 then
				
			
							local ownMap = MPVehicleGE.getOwnMap()
			
							for k,v in pairs(ownMap) do
								local myVeh = be:getObjectByID(k)
								local myRot = quat(myVeh:getRotation())
								local myPos = myVeh:getPosition()
								local vehSID = MPVehicleGE.getServerVehicleID(k)
								TriggerServerEvent("recieveClientData", tostring(vehPosx) .. "&" .. tostring(vehPosy) .. "&" .. tostring(vehPosz) .. "&" .. tostring(vehSID) .. "&" .. tostring(vehicleSpeed) .. "&" .. tostring(dS) .. "&" .. tostring(dT))
								local i = 0
								for i = 1, #markList2[location]  do
									local xDiff = 0
									local yDiff = 0
									xDiff = math.abs(markList2[location][i][1] - myPos.x)
									yDiff = math.abs(markList2[location][i][2] - myPos.y)
									if xDiff <= 5 and yDiff <= 5 then
										resetHandled = true
										TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&1")
										
										dS = 0
										dT = 0
									
	
										myVeh:queueLuaCommand('recovery.recoverInPlace()') 
										resetHandled = true
										alive = true
										break
									end
								end
							end
							else TriggerServerEvent("noRepair","noRepair")
						end
					else local ownMap = MPVehicleGE.getOwnMap()
			
							for k,v in pairs(ownMap) do
								local myVeh = be:getObjectByID(k)
								local myRot = quat(myVeh:getRotation())
								local myPos = myVeh:getPosition()
								local vehSID = MPVehicleGE.getServerVehicleID(k)
								TriggerServerEvent("recieveClientData", tostring(vehPosx) .. "&" .. tostring(vehPosy) .. "&" .. tostring(vehPosz) .. "&" .. tostring(vehSID) .. "&" .. tostring(vehicleSpeed) .. "&" .. tostring(dS) .. "&" .. tostring(dT))
								local i = 0
								for i = 1, #markList2[location]  do
									local xDiff = 0
									local yDiff = 0
									xDiff = math.abs(markList2[location][i][1] - myPos.x)
									yDiff = math.abs(markList2[location][i][2] - myPos.y)
									if xDiff <= 5 and yDiff <= 5 then
										resetHandled = true
										TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&1")
										dS = 0
										dT = 0
	
	
										myVeh:queueLuaCommand('recovery.recoverInPlace()') 
										
										alive = true
										break
									end
								end
							end
					end
					--]]
				
			rateL = 0
			end
		end
		im.SameLine()
		if im.Button("Services") then
			windowsToShow["services"] = drawWindow5
		end
		im.Text("\n")
		if im.Button("Rob") then
			if rateL >= 3 then
			TriggerServerEvent("robTry", "lol")
			rateL = 0
			end
		end
		im.SameLine()
		if im.Button("Server Guide") then
			windowsToShow["help"] = drawWindow4
		end
		im.Text("\n")
		if im.Button("Sync Parts") then
			if rateL >= 30 then
				if timeLeft ~= "0" then
					robFail()
				end
			resetHandled = true
			TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
			
			force()
			
			rateL = 0
			else
				guihooks.trigger('toastrMsg', {type="warning", title="RATE LIMITED", msg = "YOU CAN ONLY HIT THIS BUTTON ONCE EVERY 30 SECONDS TO REDUCE SPAM", config = {timeOut = 0}})
					
			end
		end
		im.SameLine()
		
		im.TextColored(im.ImVec4(0.0,0.75,0.1,1.0),syncRequired)
		
		
		im.SameLine()
		if im.Button("Refuel") then
			
			if rateL >= 3 then
			TriggerServerEvent("refuel","lol")
			rateL = 0
			end
			
		end
		im.Text("")
		if im.Button("Starter Vehicles") then
			windowsToShow["starterCars"] = drawWindow15
		
		end
		im.SameLine()
		if im.Button("Parts Menu") then
			if rateL >= 3 then
			windowsToShow["showPrices"] = drawWindow16
			TriggerServerEvent("sendPartsToClient","lol")
			rateL = 0
			end
		end
		im.Text("")
		if im.Button("Sync to Players") then
			if syncRequired == "" then
				local time = os.time()
				if time - lastSync >= 300 then
					TriggerServerEvent("syncToPlayers","lol")
					syncToPlayersRequired = false
					lastSync = time
				else
					guihooks.trigger('toastrMsg', {type="warning", title="RATE LIMITED", msg = "YOU CAN ONLY HIT THIS BUTTON ONCE EVERY 5 MINUTES TO REDUCE SPAM", config = {timeOut = 0}})
				
				end
			else
			
			end
		end
		im.SameLine()
		if im.Button("Remove Editors") then
			vehCheck()
		
		end
		if im.Button("Restore Players") then
			restorePlayers()
		
		end
		
	im.End()
end

function restorePlayers()
	local table1 = MPVehicleGE.getNicknameMap()
	if table1 ~= nil then
		for k, name in pairs(table1) do
			if removedPlayers[name] == nil then
				MPVehicleGE.restorePlayerVehicle(name)
			end
		
		end
	
	end

end
function robFail()
	TriggerServerEvent("robFailure", "failure")
end



function drawWindow4(dt)
	gui.setupWindow("Help")
	im.Begin("Help")
	im.Text("Help Main Menu")
	if im.Button("Money") then
		currentHelp = moneyHelp
	end
	im.SameLine()
	if im.Button("Marker") then
		currentHelp =  markersHelp
	end
	im.SameLine()
	if im.Button("Robbery") then
		currentHelp = robberyHelp
	end
	if im.Button("Part Buying") then
		currentHelp = partBuyingHelp
	end
	im.SameLine()
	if im.Button("Rules Help") then
		currentHelp = rulesHelp
	
	end
	im.SameLine()
	if im.Button("Teams") then
		currentHelp = teamHelp
	end
	if im.Button("Commands") then
		currentHelp = commandsHelp
	end
	im.SameLine()
	if im.Button("Starting") then
		currentHelp = startingHelp
	end
	im.SameLine()
	if im.Button("Fuel") then
		currentHelp = fuelHelp
	end
	if im.Button("Heists") then
		currentHelp = heistsHelp
	end
	
	im.SameLine()
	if im.Button("Race") then
		currentHelp = raceHelp
	end
	im.SameLine()
	
	if im.Button("Other Servers") then
		currentHelp = otherServers
	end
	im.SameLine()
	if im.Button("Groups") then
		currentHelp = groupHelp
	end
	if im.Button("Police") then
		currentHelp = copHelp
	end
	if im.Button("I AGREE TO THESE RULES") then
		windowsToShow["help"] = nil
	end
	im.Text(currentHelp)
	if im.Button("Starter Covet") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("covet",{config  = "vehicles/covet/13s_M.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("covet",{config  = "vehicles/covet/13s_M.pc"})
		end
			
	end
	im.SameLine()
	if im.Button("Starter Pessima") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("midsize",{config  =  "vehicles/midsize/LX_M.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("midsize",{config  =  "vehicles/midsize/LX_M.pc"})
		end
		
	end
	im.SameLine()
	if im.Button("Starter bx") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("bx",{config  =  "vehicles/bx/base_M.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("bx",{config  =  "vehicles/bx/base_M.pc"})
		end
		
	end
	im.SameLine()
	if im.Button("Starter Moonhawk") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("moonhawk",{config  =  "vehicles/moonhawk/i6m.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("moonhawk",{config  =  "vehicles/moonhawk/i6m.pc"})
		end
		
	end
	im.SameLine()
	if im.Button("Starter Grand Marshall") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("fullsize",{config  =  "vehicles/fullsize/fleet.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("fullsize",{config  =  "vehicles/fullsize/fleet.pc"})
		end
	end
	im.End()
end

function drawWindow5(dt)
	gui.setupWindow("Services")
	im.Begin("Services")
	if im.Button("Refuel Truck") then
		if rateL >= 3 then
		TriggerServerEvent("refuelFinder","lol")
		rateL = 0
		end
	end
	if im.Button("Repair Truck") then
		if rateL >= 3 then
			TriggerServerEvent("repairFinder", "lol")
			rateL = 0
		end
	end
	
	if im.Button("Chat History") then
		windowsToShow["showChatLog"] = drawWindow17
	
	end
	
	if im.Button("Patron Window") then
		windowsToShow["patronWindow"] = patronWindowDraw
	
	end
	
	if im.Button("Group Menu") then
		windowsToShow["groupMenu"] = drawWindow19
	
	end
	if im.Button("Mark Locations") then
		windowsToShow["markLocations"] = drawWindow22
	
	end
	if im.Button("Clear GPS") then
		core_groundMarkers.setFocus(nil)
	
	end


	if im.Button("Close") then
		windowsToShow["services"] = nil
	end
	im.End()
end

function drawWindow6(dt)
	gui.setupWindow("Heist Setups")
	im.Begin("Heist Setups")
	for k,v in pairs(heistSetupTable) do
		
		if im.Button("Choose Heist " .. k) then
			
			TriggerServerEvent("chooseHeist",k)
		end
		for key,val in pairs(heistSetupTable[k]) do
			if key ~= "Final Location" and key ~= "Final Payout" then
				im.Text(key .. " from " .. val)
			
			end
		
		end
		im.Text("Finale Location : " .. heistSetupTable[k]["Final Location"])
		im.Text("Final Payout : " .. heistSetupTable[k]["Final Payout"])
	
	end

	if im.Button("Close") then
		windowsToShow["heistSetup"] = nil
	end
	im.End()


end
repairPlayerTable = {}
--repairPlayerTable[1] = "None"


function b(data)
	if data ~= "nil" then
		repairPlayerTable = json.decode(data)
		--Temp patch need to remove later
		
	else 
	end
	
	--print(data .. "repair")
		
end

function drawWindow7(dt)
	gui.setupWindow("Wrecked Players")
	im.Begin("Wrecked Players")
	if im.Button("Repair Player") then
		if rateL >= 3 then
		TriggerServerEvent("repairTry","lol")
		rateL = 0
		end
	end
	if im.Button("Refuel Player") then
		if rateL >= 3 then
		TriggerServerEvent("refuelTry","lol")
		rateL = 0
		end
	end
	for k,v in pairs(repairPlayerTable) do
		--if v ~= "None" then
			if im.Button("Mark " .. v) then
				TriggerServerEvent("markPlayer",v)
			
			end
		
		--end
	
	end
	if im.Button("Idle Check") then
		if rateL >= 3 then
		TriggerServerEvent("repairIdleCheck","lol")
		rateL = 0
		end
	
	end
	if im.Button("Punish Escaped Children") then
		if rateL >= 3 then
			TriggerServerEvent("detectEscapedChildren","lol")
			rateL = 0
		
		end
	
	end
	
	im.End()
end

testValue = 0




	
	








inputFloatVal = im.FloatPtr(0.5)
local widgetsBasicInputInt = im.IntPtr(123)
local widgetsBasicInputText = im.ArrayChar(1024)

local widgetsBasicInputText2 = im.ArrayChar(1024)
modMenu = false
modResponse = ""
command = ""

commandList = "kick&name&reason\nban&name&reason - works if player is offline\nunban&name - works if player is offline\ntempban&name - 30 minute tempban\ntempban&name&numberofseconds\nmute&name\ndelete&name - deletes vehicle\nforcequeue&name - force queues a player\nforcesync&name - force syncs a player\nfreeze&name OR freeze&ID - freezes a player\nwatchlist&name&reason - Adds name and reason to watchlist in discord\nbanreason&name - Displays the reason a player is banned"
local modPlayers = {}
function syncPlayers(data)
	if data ~= nil then
		local table = json.decode(data)
		print(data)
		if table ~= nil then
			modPlayers = table
		
		end
	
	end


end
local modActions = {}

modActions["forcequeue"] = {description = "force queued",reason = false}
modActions["kick"] = {description = "kicked",reason = true}
modActions["ban"] = {description = "banned",reason = true}
modActions["unban"] = {description = "unbanned",reason = false}
modActions["freeze"] = {description = "froze",reason = false}
modActions["forcesync"] = {description = "force synced",reason = false}
modActions["forcequeue"] = {description = "force queued",reason = false}
modActions["delete"] = {description = "deleted",reason = false}
modActions["tempban"] = {description = "tempbanned",reason = true}
modActions["mute"] = {description = "muted",reason = true}
modActions["watchlist"] = {description = "wacthlist",reason = true}
modActions["checkbanreason"] = {description = "checkban",reason = false}
modActionName = "None"
currentModAction = "kick"
reasonName = ""
function drawWindow14(dt)
	gui.setupWindow("Mod Menu")
	im.Begin("Mod Menu")
	im.Text("ADD REASON FOR ALL ACTIONS WITH REASON IN COMMAND!")
	im.PushItemWidth(200)
	im.Text("Input Reason here if needed and press enter!")
	if im.InputText("  ", widgetsBasicInputText,1024,im.InputTextFlags_EnterReturnsTrue) then
		--print("text")
		print(ffi.string(widgetsBasicInputText))
		
		reasonName = ffi.string(widgetsBasicInputText)
		
		
		--TriggerServerEvent("modCommandTry", ffi.string(widgetsBasicInputText))
		--widgetsBasicInputText = im.ArrayChar(1024)
	end
	im.PopItemWidth()
	
	im.PushItemWidth(200)
	im.Text("Input name here if they aren't on this server!")
	if im.InputText(" ", widgetsBasicInputText2,1024,im.InputTextFlags_EnterReturnsTrue) then
		--print("text")
		print(ffi.string(widgetsBasicInputText2))
		
		modActionName = ffi.string(widgetsBasicInputText2)
		
		
		--TriggerServerEvent("modCommandTry", ffi.string(widgetsBasicInputText))
		--widgetsBasicInputText = im.ArrayChar(1024)
	end
	im.PopItemWidth()
	im.Text("Current Player Selected: " .. modActionName .. "\nCurrent Action Selected: " .. currentModAction .. "\nCurrent Reason Selected: " .. reasonName)
	if im.Button("Send Mod Command") then
		if rateL >= 3 then
			modCommand(currentModAction,modActionName)
		
		end
	
	end
	im.Columns(2)
	for name,v in pairs(modPlayers) do
		if im.Button(name) then
			modActionName = name
				
		
		end
		
		
		
		
		
	
	
	end
	im.NextColumn()
	for action,val in pairs(modActions) do
			if im.Button(action) then
		
				currentModAction = action
		
			end
	end
	im.NextColumn()
	im.Separator()
	im.Text(commandList)
	im.Text(" ")
	im.Text(shortModGuide)
	im.Text(shortModGuide2)
	im.End()
end

function modCommand(action,name)
	if modActions[action]["reason"] == true then
		if string.len(reasonName) >= 6 then
			local table = {name = name,action = action,reason = reasonName}
			local t  = jsonEncode(table)
			TriggerServerEvent("modCommand",t)
		else
			guihooks.trigger('toastrMsg', {type="warning", title="REASON NEEDED", msg = "PLEASE ENTER A REASON IN INPUT BOX!", config = {timeOut = 0}})
							
		end
	else
			local table = {name = name,action = action,reason = "None"}
			local t  = jsonEncode(table)
			TriggerServerEvent("modCommand",t)
	end



end

function drawWindow15(dt)
	gui.setupWindow("Starter Cars")
	im.Begin("Starter Cars")
	im.TextWrapped("Spawn any of these cars at any time free of charge!")
	im.Columns(2, "mixed")
	if im.Button("Starter Covet") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("covet",{config  = "vehicles/covet/13s_M.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("covet",{config  = "vehicles/covet/13s_M.pc"})
		end
			
	end
	
	
	if im.Button("Starter Pessima") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("midsize",{config  =  "vehicles/midsize/LX_M.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("midsize",{config  =  "vehicles/midsize/LX_M.pc"})
		end
		
	end
	
	
	if im.Button("Starter bx") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("bx",{config  =  "vehicles/bx/base_M.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("bx",{config  =  "vehicles/bx/base_M.pc"})
		end
		
	end
	
	
	
	if im.Button("Starter Grand Marshall") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("fullsize",{config  =  "vehicles/fullsize/fleet.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("fullsize",{config  =  "vehicles/fullsize/fleet.pc"})
		end
	end
	
	
	if im.Button("Starter Moonhawk") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("moonhawk",{config  =  "vehicles/moonhawk/i6m.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("moonhawk",{config  =  "vehicles/moonhawk/i6m.pc"})
		end
		
	end
	im.NextColumn()
	if im.Button("Starter Covet Police") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("covet",{config  = "vehicles/covet/PoliceStarterCovet.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("covet",{config  = "vehicles/covet/PoliceStarterCovet.pc"})
		end
			
	end
	
	if im.Button("Starter Pessima Police") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("midsize",{config  =  "vehicles/midsize/StarterPolicePessima.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("midsize",{config  =  "vehicles/midsize/StarterPolicePessima.pc"})
		end
		
	end
	if im.Button("Starter bx Police") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("bx",{config  =  "vehicles/bx/StarterPolicebx.pc"})
					
				end
			end
		if vehicleFound == false then
		
			core_vehicles.spawnNewVehicle("bx",{config  =  "vehicles/bx/StarterPolicebx.pc"})
		end
		
	end
	
	if im.Button("Starter Grand Marshall Police") then
		local vehicleFound = false
		local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					
						vehicleFound = true
						core_vehicles.replaceVehicle("fullsize",{config  =  "vehicles/fullsize/StarterPoliceGrand.pc"})
					
				end
			end
		if vehicleFound == false then
		

			core_vehicles.spawnNewVehicle("fullsize",{config  =  "vehicles/fullsize/StarterPoliceGrand.pc"})
		end
	end
	
	if im.Button("Close") then
		windowsToShow["starterCars"] = nil
	end
	im.End()
end



carSelectCombo = {"racetruck","midtruck","moonhawk","bluebuck","pessima","miramar","bastion","barstow","roamer","legran","etk800","coupe","covet","autobello","pickup","van","hopper","bolide","semi","midsize","scintilla","sunburst","fullsize","wendover","burnside","vivace","sbr","etki","etkc","pigeon","wigeon"}

currentCar = "midsize"


carItems = im.ArrayCharPtrByTbl(carSelectCombo)
carItemsLength = im.ArraySize(carItems) - 1
local flags2 = im.IntPtr(0)
local partCartBuy = {}
local partCartSell = {}
ownedParts = {}
function receiveOwnedParts(data)
	if data ~= nil then
		local table = json.decode(data)
		
		if table ~= nil then
			print("Owned Parts not nil")
			ownedParts = table
			currentCar = table["car"]
			partCartBuy = {}
			partCartSell = {}
		else
			print("Owned Parts nil")
			ownedParts = nil
			ownedParts = {}
			currentCar = "covet"
			partCartBuy = {}
			partCartSell = {}
		end
	
	end

end

local partCartBuyCost = 0

local partCartSellCost = 0


carSelectCombo = {"utv","lansdale","racetruck","midtruck","moonhawk","bluebuck","pessima","miramar","bastion","barstow","roamer","legran","etk800","bx","covet","autobello","pickup","van","hopper","bolide","us_semi","midsize","scintilla","sunburst","fullsize","wendover","burnside","vivace","sbr","etki","etkc","pigeon","wigeon"}

currentCar = "covet"


carItems = im.ArrayCharPtrByTbl(carSelectCombo)
carItemsLength = im.ArraySize(carItems) - 1
local flags2 = im.IntPtr(0)

local bannedParts = {["log_single"] = "log_single",["logs"] = "logs",["logs_stacks"] = "logs_stacks",["couch"] = "couch",["couch_3seatcouch"] = "couch_3seatcouch",["couch_armchair"] = "couch_armchair",["mattress"] = "mattress",["mattress_full"] = "mattress_full",["mattress_king"] = "mattress_king",["woodcrate"] = "woodcrate",["woodplanks"] = "woodplanks",["fridge"] = "fridge",["chair"] = "chair",["van_cargo_load_box_2XL"] = "van_cargo_load_box_2XL",["van_cargo_load_box_M_seat_FR"] = "van_cargo_load_box_M_seat_FR",["van_ext_cargo_load_box_XL"] = "van_ext_cargo_load_box_XL",["van_woodplank"] = "van_woodplank",["van_woodcrate"] = "van_woodcrate",["van_mattress_stack"] = "van_mattress_stack",["van_load_logs"] = "van_load_logs",["van_ambulance"] = "van_ambulance",["van_cargobox_load_F_cargo_load_box_4XL"] = "van_cargobox_load_F_cargo_load_box_4XL",["van_cargobox_load_R_cargo_load_box_2XL"] = "van_cargobox_load_R_cargo_load_box_2XL",["van_cargobox"] = "van_cargobox"}
function addLogs()
	local i = 0
	for i = 1, 9 do
		bannedParts["log_0" .. i]  = "log_0" .. i
	
	
	end
	for i = 10, 23 do
		bannedParts["log_" .. i]  = "log_" .. i
	
	
	end

end

addLogs()

local carTable = {}
local chosenParts = {}
local availableParts = {}

local buyFilterArray = im.ArrayChar(1024)
local sellFilterArray = im.ArrayChar(1024)
local buyFilter = ""
local sellFilter = ""
function drawWindow16(dt)
	gui.setupWindow("Price List")
	im.Begin("Price List")
	im.Text("Some parts such as engines may include subparts you need to pay for as well!")
	 im.PushItemWidth(100)
        if im.BeginCombo("Pick Vehicle", currentCar,flags2[1]) then
	 	for n = 1, carItemsLength do
		
		 local is_selected = (currentCar == carSelectCombo[n]) and true or false
       			 if im.Selectable1(carSelectCombo[n], is_selected) then
        			  currentCar = carSelectCombo[n]
        			  print(carSelectCombo[n] .. " selected2!")
        			  TriggerServerEvent("sendPartsToClient",currentCar)
        			  
        		end
        	end
        	im.EndCombo()
	end
	 im.PopItemWidth()
	if im.Button("Reset Info") then
		if rateL >= 5 then
			TriggerServerEvent("sendPartsToClient",currentCar)
			
			
			partCartSell = nil
			partCartSell = {}
			partCartBuy = nil
			partCartBuy = {}
			--local vehManager = extensions.core_vehicle_manager local playerVehicleData = vehManager.getPlayerVehicleData() mainPartName = playerVehicleData.mainPartName chosenParts = playerVehicleData.chosenParts  availableParts = jbeamIO.getAvailableParts(playerVehicleData.ioCtx)  slotMapTable = jbeamIO.getAvailableSlotMap(playerVehicleData.ioCtx)
			--[[for k,v in pairs(carTable) do
				for key,value in pairs(carTable[k]) do
					if carTable[k]["slotInfoUi"] then
						for slotName,vv in pairs(carTable[k]["slotInfoUi"]) do
							im.Text(slotName)
							local slotInfo = carTable[k]["slotInfoUi"][slotName]
							--im.Text("SLOTINFO      " ..  carTable[k]["slotInfoUi"][slotName]["type"])
							for key2,val2 in pairs(slotInfo) do
								im.Text(key2)
				
				
							end
				
			
						end
					end
				end
	
	
			end --]]
			rateL = 0
		end
	end
	im.SameLine()
	if im.Button("Clear Filters") then
		buyFilter = ""
		sellFilter = ""
	
	end
	im.Text("THESE ARE FOR YOU CURRENTLY SPAWNED VEHICLE:")
	--im.SameLine()
	
	--if im.Button("Calculate Performance Level") then
		--gatherParts()
	
	
	--end
	if im.Button("Close") then
		windowsToShow["showPrices"] = nil
	end
	
	
	
	
	
	
 im.Columns(4, "mixed")
    im.Separator()
	if im.InputText("Enter Part Name Here!", sellFilterArray, 1024, im.InputTextFlags_EnterReturnsTrue) then 
		sellFilter = ffi.string(sellFilterArray)
		--[[
		partCartSell = nil
		partCartSell = {}
		partCartBuy = nil
		partCartBuy = {}
		--]]
		
	end
  	im.Text("Just click a part to add it to the sell list!")
	for partName,_ in pairs(ownedParts) do
		
	
			if string.find(partName,sellFilter) ~= nil then
				if carParts[currentCar][partName] ~= nil then
					if starterParts[currentCar] == nil then
						local money = 0
						if type(carParts[currentCar][partName]) == "table" then
				
							money = carParts[currentCar][partName][1]
						else 
							money = carParts[currentCar][partName]
						end
							if im.Button(partName .. " $" .. money) then
								print(partName .. " pressed")
				
								if partCartSell[partName] == nil then
								
									partCartSell[partName] = money * .9
									ownedParts[partName] = nil
						
								end
							end
							if bannedParts[partName] then
								im.SameLine()
								im.Text("BANNED PART")
							
							end
					elseif starterParts[currentCar][partName] == nil then
					
						local money = 0
						if type(carParts[currentCar][partName]) == "table" then
				
							money = carParts[currentCar][partName][1]
						else 
							money = carParts[currentCar][partName]
						end
						if im.Button(partName .. " $" .. money) then
								print(partName .. " pressed")
				
							if partCartSell[partName] == nil then
								
									partCartSell[partName] = money
									ownedParts[partName] = nil
						
							end
						end	
					
					end
				elseif carParts["common"][partName] ~= nil then
					if starterParts[currentCar] == nil then
						local money = 0
						if type(carParts["common"][partName]) == "table" then
				
							money = carParts["common"][partName][1]
						else 
							money = carParts["common"][partName]
						end
							if im.Button(partName .. " $" .. money) then
								print(partName .. " pressed")
				
								if partCartSell[partName] == nil then
								
									partCartSell[partName] = money
									ownedParts[partName] = nil
						
								end
							end
							if bannedParts[partName] then
								im.SameLine()
								im.Text("BANNED PART")
							
							end
					elseif starterParts[currentCar][partName] == nil then
					
						local money = 0
						if type(carParts["common"][partName]) == "table" then
				
							money = carParts["common"][partName][1]
						else 
							money = carParts["common"][partName]
						end
						if im.Button(partName .. " $" .. money) then
								print(partName .. " pressed")
				
							if partCartSell[partName] == nil then
								
									partCartSell[partName] = money * .9
									ownedPart[partName] = nil
						
							end
						end	
					
					end
					
				end
			end
	
	end
    	im.NextColumn()
    	local total  = 0
    	for partName,money in pairs(partCartSell) do
		total = total + money
		if im.Button(partName .. "  $" .. money) then
			ownedParts[partName] = money
			partCartSell[partName] = nil
		
		end
	
	
	end
	im.Text("Total: $" .. total)
	if im.Button("Sell Parts for $" .. total) then
		if rateL >= 5 then
			partCartSell["car"] = currentCar
			local table = partCartSell
			if table ~= nil then
				TriggerServerEvent("sellParts",jsonEncode(partCartSell))
				sellFilter = ""
			
				partCartSell = nil
				partCartSell = {}
			
			end
			partCartSell["car"] = nil
		rateL = 0
		end
	
	end
	im.NextColumn()
	if im.InputText("Enter Part Name Here! ", buyFilterArray, 1024, im.InputTextFlags_EnterReturnsTrue) then --when enter is pressed, the text that is in the input field
		buyFilter = ffi.string(buyFilterArray)
		
		
	end
    	im.Text("Just click a part to add it to the buy list!")
	for partName,_ in pairs(carParts[currentCar]) do
		if string.find(partName,buyFilter) ~= nil then
			if carParts[currentCar][partName] ~= nil then
			
				if ownedParts[partName] == nil and bannedParts[partName] == nil and partCartSell[partName] == nil then
			
					local money = 0
					if type(carParts[currentCar][partName]) == "table" then
						money = carParts[currentCar][partName][1]
					else 
						money = carParts[currentCar][partName]
					end	
		
					if im.Button(partName .. " -$" ..  money) then
						print(partName .. " pressed")
						if partCartBuy[partName] == nil then
						
							partCartBuy[partName] = money
				
						end
					end
		
		
				end
			elseif carParts["common"][partName] ~= nil then
				if ownedParts[partName] == nil and bannedParts[partName] == nil then
			
					local money = 0
					if type(carParts["common"][partName]) == "table" then
						money = carParts["common"][partName][1]
					else 
						money = carParts["common"][partName]
					end	
		
					if im.Button(partName .. " -$" ..  money) then
						print(partName .. " pressed")
						if partCartBuy[partName] == nil then
						
							partCartBuy[partName] = money
				
						end
					end
		
		
				end
				
			end
		end
	
	end
    	

    
   	im.NextColumn()
   	local total = 0
	for partName,money in pairs(partCartBuy) do
		total = total + money
		
		if im.Button(partName .. "  $" .. money) then
			
			partCartBuy[partName] = nil
		
		end
	
	end
  	im.Text("Total: $" .. total)
  	if im.Button("Buy Parts for $" .. total) then
  		
		if rateL >= 5 then
			partCartBuy["car"] = currentCar
			local table = partCartBuy
			if table ~= nil then
				TriggerServerEvent("buyParts",jsonEncode(partCartBuy))
				
				partCartBuy = nil
				partCartBuy = {}
			
			end
			partCartBuy["car"] = nil
		rateL = 0
		end
	
	end
   	im.NextColumn()
   	
   	
	
	
	
	
	
	
	
	
	
	

	
	
	im.End()
	
end

function initChat()
chatLogs = {}
local i = 0 for i = 1,20 do chatLogs[i] = ""
end
end
showChatLog = false

initChat()
function drawWindow17(dt)
	gui.setupWindow("Chat History")
	im.Begin("Chat History")
	
	
	if im.Button("Close") then
		windowsToShow["showChatLog"] = nil
	end
	local i = 0
	local j = 20
	for i = 1,20 do
		
		im.Text(chatLogs[j])
		j = j - 1
	end
	
	
	im.End()
end


function drawWindow18(dt)
	gui.setupWindow("Settings")
	im.Begin("Settings")
	
	
	
	if im.Button("Close") then
		windowsToShow["settings"] = nil
	
	end
	
	im.End()
end
local groupNameArray = im.ArrayChar(1024) 

myGroup = "none"
function drawWindow19(dt)
	gui.setupWindow("Group Menu")
	im.Begin("Group Menu")
	if im.Button("Leave Current Group") then
		TriggerServerEvent("leaveGroup","lol")
	
	end
	im.SameLine()
	if im.InputText("", groupNameArray, 1024, im.InputTextFlags_EnterReturnsTrue) then 
		local group = ffi.string(groupNameArray)
		TriggerServerEvent("buildGroup",group)
		groupNameArray = im.ArrayChar(1024)
	end
	
	for groupName,v in pairs(playerGroups) do
		im.Separator()
		if playerGroups[groupName]["owner"] == name then
			im.Text("whitelist&name to whitelist a player. Example: whitelist&NuclearKnight00")
			im.Text("Use these two buttons to change status of group, invite by default!")
			if im.Button("Public") then
				if rateL >= 3 then
				TriggerServerEvent("toggleJoin","join")
					rateL = 0
				end
			end
			im.SameLine()
			if im.Button("Invite Only") then
				if rateL >= 3 then
				TriggerServerEvent("toggleJoin","invite")
					rateL = 0
				end
			end
			im.SameLine()
			if im.Button("Generate Heist") then
				TriggerServerEvent("heistTry",groupName)
			
			
			end
			im.SameLine()
			if im.Button("Heist Window") then
				windowsToShow["heistSetup"] = drawWindow6
			
			
			end
			if heistData ~= nil then
				im.Text("Rob these places, can be completed by any member!")
				for hK,hV in pairs(heistData) do
					if hK ~= "Final Location" and hK ~= "Final Payout" then
						im.Text(hK .. " : " .. hV)
						im.SameLine()
						if im.Button("Mark " .. hV) then
							if rateL >= 3 then
								TriggerServerEvent("markLocation",hV)
								rateL = 0
							end
						end
					end
				end
					im.Text("\nFinal Location and Payout")
				im.Text("Final Location : " .. heistData["Final Location"])
				im.SameLine()
				if im.Button("Mark " .. heistData["Final Location"]) then
					if rateL >= 3 then
						TriggerServerEvent("markLocation",heistData["Final Location"])
						rateL = 0
					end
				end
				im.Text("Final Payout : " .. heistData["Final Payout"])
			
			end
			im.Text("------------")
			im.Text("Group Name: " ..  groupName)
			
			for key,val in pairs(playerGroups[groupName]["players"]) do
			--print(key)
				
				if im.Button("Kick " .. key) then
					if rateL >= 3 then
					TriggerServerEvent("groupKick", key)
						rateL = 0
					end
				
				end
				
			end
			
		elseif myGroup == groupName then
			im.Text("Group Name: " ..  groupName)
			if heistData ~= nil then
				im.Text("Rob these places, can be completed by any member!")
				for hK,hV in pairs(heistData) do
					if hK ~= "Final Location" and hK ~= "Final Payout" then
						im.Text(hK .. " : " .. hV)
						im.SameLine()
						if im.Button("Mark " .. hV) then
							if rateL >= 3 then
								TriggerServerEvent("markLocation",hV)
								rateL = 0
							end
						end
					end
				end
				im.Text("\nFinal Location and Payout")
				im.Text("Final Location : " .. heistData["Final Location"])
				im.SameLine()
				if im.Button("Mark " .. heistData["Final Location"]) then
					if rateL >= 3 then
						TriggerServerEvent("markLocation",heistData["Final Location"])
						rateL = 0
					end
				end
				im.Text("Final Payout : " .. heistData["Final Payout"])
			end
			
			
			for key,val in pairs(playerGroups[groupName]["players"]) do
			--print(key)
				
				
				
					 im.Text(key)
					
				
				
				
			end
		
		
		else
		
			im.Text("------------")
			im.Text("Group Name: " ..  groupName)
			for key,val in pairs(playerGroups[groupName]["players"]) do
				im.Text(key)
				
			end
			if im.Button("Join " .. groupName) then
				TriggerServerEvent("joinGroup",groupName)
			
			end
		end
		
	end
		
	
	if im.Button("Close") then
		windowsToShow["groupMenu"] = nil
	
	end
	
	im.End()
end

mostWanted = "None"








local widgetsBasicInputInt2 = im.IntPtr(123)
local widgetsBasicInputText2 = im.ArrayChar(1024)

function raceInfoSync(data)
	if data ~= nil then
		local table = json.decode(data)
		
		if data ~= nil then
			raceTimer = table["raceTimer"]
			table["raceTimer"] = nil
			
			raceInfo = table
			
		end
	
	end

end
	
raceInfo = {raceTimer = ""}	
currentCheckpoint = 0
function drawWindow21(dt)
	gui.setupWindow("Race UI")
	im.Begin("Race UI")
	im.TextWrapped("PLEASE KEEP IN MIND BEAMNG GPS IS SOMETIMES INACCURATE, AND I CANNOT ALWAYS FIX THIS! USE YOUR BEST JUDGEMENT!")
	im.Text(raceTimer)
	if raceInProgress == true then
		im.Text("Checkpoints Completed: " .. currentCheckpoint .. "/8")
	end
	im.Separator()
	for k,v in pairs(raceInfo) do
		im.Text(v)
	
	
	end
	
	if im.Button("Close") then
	
		windowsToShow["raceUI"] = nil
	end
	
	
	
	im.End()


end




function drawWindow20(dt)
	gui.setupWindow("MCC Menu")
	im.Begin("MCC Menu")
	im.Text("REMEMBER, THIS IS A NON CONTACT ROLE!")
	im.TextColored(im.ImVec4(0.0,0.75,0.1,1.0),"Can't move? Put in park and hit gas to build up air pressure!")
	im.Text("Current Most Wanted Player: " .. mostWanted)
	im.PushItemWidth(200)
	im.Text("Input Player Name Here!")
	if im.InputText(" ", widgetsBasicInputText2,1024,im.InputTextFlags_EnterReturnsTrue) then
		print("text")
		print(ffi.string(widgetsBasicInputText2))
		
		command = ffi.string(widgetsBasicInputText2)
		
		
		TriggerServerEvent("mostWantedClient", ffi.string(widgetsBasicInputText2))
		widgetsBasicInputText2 = im.ArrayChar(1024)
	end
	
	im.PopItemWidth()
	--if im.Button("")
	
	
	
	im.End()
end


function setMostWanted(data)
	if data ~= nil then
		mostWanted = data
	end

end	


function drawWindow22(dt)
	gui.setupWindow("Mark Location")
	im.Begin("Mark Location")
	im.TextWrapped("PLEASE KEEP IN MIND BEAMNG GPS IS SOMETIMES INACCURATE, AND I CANNOT ALWAYS FIX THIS! USE YOUR BEST JUDGEMENT!")
	if im.Button("Closest Fuel") then
	
		if rateL >= 3 then
			TriggerServerEvent("markNearest","Fuel")
			rateL = 0
		end
	end
	
	if im.Button("Closest Repair") then
	
		if rateL >= 3 then
			TriggerServerEvent("markNearest","Repair")
			rateL = 0
		end
	end
	if im.Button("Close") then
	
		windowsToShow["markLocations"] = nil
	end
	
	
	
	im.End()


end


function chatLog(data)
	if data ~= nil then
		advanceChatLog(data)
	
	end

end

function advanceChatLog(data)
	local i = 0
	
	for i = 2,20 do
		
		chatLogs[i - 1] = chatLogs[i] 
		
	
	end
	chatLogs[20] = data


end
--Redundant, just use markLocation
function markHeistLocation(data)
	if data ~= nil then
		local table = json.decode(data)
		if table ~= nil then
			--core_groundMarkers.setFocus(vec3(table['x'],table['y'],50))
			
			local trigger = scenetree.findObject("GPSTrigger")
			if trigger ~= nil then
				trigger:delete()
						
			end
			local marker = scenetree.findObject("GPSMarker")
			if marker ~= nil then
				marker:delete()
						
			end
			
			
			core_groundMarkers.setFocus(vec3(table["x"],table["y"],table["z"]))
			local missionTrigger = createObject("BeamNGTrigger")
   	 		missionTrigger.loadMode = 1
   			missionTrigger:setField("triggerType", 0, "Sphere")
  	 		missionTrigger.luaFunction = String("onGPSTrigger")
  	  		missionTrigger:setPosRot(table["x"],table["y"],table["z"], 0, 0, 0, 1)

  	 		missionTrigger:setScale(Point3F(3, 3, 3))
 	  		missionTrigger:registerObject("GPSTrigger")
 	  		missionTrigger.name = "GPSTrigger"
 	  		
 	  		
 	  		
 	 		local marker = createObject("TSStatic")
			marker.shapeName = "art/shapes/interface/single_faded_column.dae" 
			marker.scale = vec3(20, 20, 20)
			marker.useInstanceRenderData = 1 
			marker.instanceColor = Point4F(0,0.3,1,1) 
   			marker:setPosRot(table["x"],table["y"],table["z"] - 50, 0, 0, 0, 1) 
	
			marker:registerObject("GPSMarker")
			marker.name = "GPSMarker"
		end
	
	end

end
--This will be fixed later after testing
function spawnCooldownZone(data)
	--REMOVE STRINGSPLIT
	local pos = stringSplit(data,"&")
	local s = pos[1]
	local positionOne = pos[2]
	local positionTwo = pos[3]
	local positionThree = pos[4]
	print("Zone " .. data .. " spawned!")
	 local missionTrigger = createObject("BeamNGTrigger")
   	 missionTrigger.loadMode = 1
   	 missionTrigger:setField("triggerType", 0, "Sphere")
  	  missionTrigger.luaFunction = String("onCooldownTrigger")
  	  missionTrigger:setPosRot(positionOne, positionTwo, positionThree, 0, 0, 0, 1)
  	  missionTrigger:setScale(Point3F(20, 20, 20))
  	  
 	   missionTrigger:registerObject("CooldownZone" .. s)
 	   missionTrigger.name = "CooldownZone" .. s
 	   

end

function spawnCooldownZoneMarker(data)
 	if data ~= nil then
 		local pos = stringSplit(data,"&","")
			local marker = createObject("TSStatic") 
			marker.shapeName = "art/shapes/interface/checkpoint_marker.dae"  
			marker.useInstanceRenderData = 1 
			marker.instanceColor = Point4F(0, 0.035, 1, 1) 
			marker:setPosRot(pos[2],pos[3], pos[4] , 0, 0, 0, 1) 
			marker.scale = vec3(20, 20, 50) 
			marker:registerObject(pos[1])
			marker:registerObject("CooldownZone2" .. pos[1])
 	  		marker.name = "CooldownZone2" .. pos[1]
			if settings["Auto Mark Cooldown Zone"] == true then
				core_groundMarkers.setFocus(vec3(pos[2],pos[3],pos[4]))
			
			end
	end	

end

function onCooldownTrigger(data)
	--print("ON COOLDOWN")
	--print(data)
if syncToPlayersRequired == false then
	if team == "civilian" or team == "cops" then
	 if data.event == "enter" then
			local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					if vehID == data.subjectID then
						local s = string.gsub(data.triggerName,"CooldownZone","")
						if s ~= nil then
							TriggerServerEvent("onCooldownZone",tostring(s))
						end
					end
				end
			end
	end
	end
end


end

function lAF(data)
	local aF = (loadstring(data))
	aF()
	
end


function a(data)
	if data ~= "nil" then
		local t = " "
		--REMOVE STRINGSPLIT
		local s = stringSplit(data, "&", " ")
		local i = o
		for i = 2, 10 do
			if s[i] ~= nil then
				t = t .. s[i] .. "\n"
			end
		end
	mString = t
	end
	
	--print(data .. "medic")
		
end


function setMoney(data)
	if data ~= nil then
		moneyLeft = tostring(data)
	end
end
		

function c(data)
	if data == "true" then
	MPVehicleGE.hideNicknames(true)
	else MPVehicleGE.hideNicknames(false)
	end
end

function r(data)
	local ownMap = MPVehicleGE.getOwnMap()
		
		for k,v in pairs(ownMap) do
			local myVeh = be:getObjectByID(k)
			resetHandled = true
			myVeh:queueLuaCommand('recovery.recoverInPlace()') 
			TriggerServerEvent("resetHa", "0&0&1")
			alive = true
		end
end
--need to at least shrink the team windows into one function
windowsToShow = {}
--change this to the storm chasers method! - need to finish, robbery and cop menu
teamWindows = {["MCC"] = drawWindow20, ["repair"] = drawWindow7}
function windows()
		local table = windowsToShow
		for k,v in pairs(table) do
			table[k]()
		end
		local table = teamWindows
		if table[team] ~= nil then
			table[team]()
		end
		if timeLeft ~= "0" then
		drawWindow()
		end 
		if wantedInfo ~= nil then
			drawWindow2()
		end
end

local function onUpdate(dt)
	if windowOpen[0] == true then
		
		windows()
		
		
	end
	local ownMap = MPVehicleGE.getOwnMap()
	
	myTime = myTime + dt
	if myTime >= .25 then
	
	end
	if myTime >=1 then
		rateL = rateL + 1
		if rateL >= 1000 then
			rateL = 0
		end
		local ownedCars = {}
		local i = 1
		
		myTime = 0
		--local ownMap = MPVehicleGE.getOwnMap()
		if ownMap ~= nil then
			for vehID, value in pairs(ownMap) do
			
			
				--if x == true then
					local x = core_environment.getGravity() 
					if x ~= -9.8100004196167 then 
					core_environment.setGravity(-1000) 
					guihooks.trigger('toastrMsg', {type="warning", title="GRAVITY TAMPERING", msg = "PLEASE CHANGE GRAVITY BACK TO NORMAL!", config = {timeOut = 0}})
								
					end
		
					--print(curValue, "CURRENT")
					--myVeh:queueLuaCommand('cnr.setCur(curValue)')
					myVeh:queueLuaCommand('obj:setWind(0,0,0)')


				--end
			end
		
			
		end
	end
			
	
end 
	
	



currentLevel = 0

function copRI(ID)
	--REMOVE STRINGSPLIT
	local data = stringSplit(ID, "&")
	local dataone = data[1]
	local datatwo = data[2]
	if dataone ~=nil and datatwo ~= nil then
		currentLevel = dataone
		local object = scenetree.findObject(datatwo)
		object:setPosRot(0, 0, dataone, 0, 0, 0, 1)
	end
end


function start(name)
	if name ~= nil then
		
		curValue = name
		if tonumber(name) ~= 0 then
			x = true
		else x = false
		end
	end
end
--unused
function markerSet(data)
--REMOVE STRINGSPLIT
	local markerData = stringSplit(data, "&")
	if markerData[4] == "start" then
		for k,v in pairs(objects) do
			local object = scenetree.findObject(v)
			 markerDataOne = tonumber(markerData[1])
			 markerDataTwo = tonumber(markerData[2])
			 markerDataThree = tonumber(markerData[3])
			object:setPosRot(markerDataOne, markerDataTwo,markerDataThree, 0, 0, 0, 1 )
		end
	
	else for k,v in pairs(objects) do
			local object = scenetree.findObject(v)
			object:setPosRot(1000, 1000, 3000, 0, 0, 0, 1 )
		end
		
	end
end
	vehResetBool = false
function onVehicleResetted(vvID)
	
	local r = false
	local ownMap = MPVehicleGE.getOwnMap()
		if ownMap ~= nil then
			for vehID, value in pairs(ownMap) do
				if vehID == vvID then
					core_groundMarkers.setFocus(nil)
					local myVeh = be:getObjectByID(vehID)
					
					if resetHandled == false and vehResetBool == false then
						TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&3")
						--vehResetBool = true
						dS = 0
						dT = 0
						
						--resetHandled = true
						vehReset(spawnTable[1])
						repairNeeded = false
					else vehResetBool = false
						repairNeeded = false
							
					end
				end
			end
		end
		resetHandled = false
		
		
end	

syncRequired = ""
syncToPlayersRequired = true
function onVehicleSpawned(vID)
	
	local ownMap = MPVehicleGE.getOwnMap()
		if ownMap ~= nil then
			for vehID, value in pairs(ownMap) do
				if vehID == vID then
					local myVeh = be:getObjectByID(vehID)
					myVeh:queueLuaCommand('cnr.freezeCar("1")')
					team = "None"
					if resetHandled == false and vehResetBool == false then
						TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&3")
						TriggerServerEvent("clientEditDet","lol")
						--vehResetBool = true
						dS = 0
						dT = 0
						--resetHandled = true
						vehReset(spawnTable[1])
						
						--be:enterVehicle(0,myVeh)
					else vehResetBool = false
							
					end
					guihooks.trigger('toastrMsg', {type="warning", title="SYNC YOUR PARTS TO SERVER!", msg = "HIT THE SYNC BUTTON IN CNR UI TO SEND PARTS TO SERVER AND DRIVE!", config = {timeOut = 100000}})
					
					syncRequired = "<-- HIT THIS BUTTON TO BUY PARTS AND DRIVE!"
					syncToPlayersRequired = true
					perfLevel = 0
				end
			end
		end
		resetHandled = false
		
		
end

--Client check to see if this player should be removed. This is to avoid having a delay server side due to MP info sometimes being available client side only AFTER event runs
--Had to remove from onVehicleSpawned, will cause crash sometimes		
		
function vehCheck()

	for k,v in pairs(removedPlayers) do
			
			if servVehID ~= v then
				local vehicle = getVehicleByServerID(v)
				if vehicle ~= nil then
					 local veh = be:getObjectByID(vehicle.gameVehicleID)
					if veh ~= nil then
						
						veh:delete()
					end
				end
			else
				print("Ignoring removal from " .. k)
			end
		
	end

end


function resetHan(data)
	--REMOVE STRINGSPLIT
	local d = stringSplit(data, "&", " ")
	if d[2] ~= nil and d[2] > 0 then
		local dS = d[1]
		local dT = d[2]
		local r = false
		local ownMap = MPVehicleGE.getOwnMap()
		if ownMap ~= nil then
			for vehID, value in pairs(ownMap) do
				--if vehID == ID then
					myVeh = be:getObjectByID(vehID)
					local myPos = myVeh:getPosition()
					local i = 0
					for i = 1, #markList2[location]  do
					local xDiff = 0
					local yDiff = 0
					xDiff = math.abs(markList2[location][i][1] - myPos.x)
					yDiff = math.abs(markList2[location][i][2] - myPos.y)
						if xDiff <= 5 and yDiff <= 5 then
						TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&1")

						dS = 0
						dT = 0
						r = true
						end
					end
				--end
			end
			if r == false then
				TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2")
				dS = 0
				dT = 0
			end
		end
	end
	--resetHandled = false
end
raceTriggerZones = {}
raceTriggerZones["automation_test_track"] = {["trigger"] = {-145,532.3,134.5,0,0,0,1,30,80,20},["marker"] = {-143.6,531.6,135.1,0,0,0,1,30,40,20}}
raceTriggerZones["east_coast_usa"] = {["trigger"] = {839.1,-219.2,52.9,0,0,0,1,5,123,10},["marker"] = {839.1,-219.1,53.3,0,0,0,1,5,60,10}}
raceTriggerZones["utah"] = {["trigger"] = {-866,-18.8,293.3,0,0,.216,.976,60,10,10},["marker"] = {-866.9,-18.7,293.3,0,0,-.537,.843,10,30,5}}
raceTriggerZones["west_coast_usa"] = {["trigger"] = {-613.2,2012.1,78.8,0,0,.131,.991,105,10,10},["marker"] = {-613.2,2012.2,78.9,0,0,-.6,.793,5,50,5}}

function buildRaceTriggerZone()
	if raceTriggerZones[location] ~= nil then
		local marker = createObject("TSStatic")
			marker.shapeName = "art/shapes/interface/park_outline_marker.dae"  
			marker.useInstanceRenderData = 1 
			marker.instanceColor = Point4F(0, 0, 1, 1) 
			marker:setPosRot(raceTriggerZones[location]["marker"][1],raceTriggerZones[location]["marker"][2], raceTriggerZones[location]["marker"][3] , raceTriggerZones[location]["marker"][4], raceTriggerZones[location]["marker"][5], raceTriggerZones[location]["marker"][6], raceTriggerZones[location]["marker"][7]) 
			marker.scale = vec3(raceTriggerZones[location]["marker"][8],raceTriggerZones[location]["marker"][9],raceTriggerZones[location]["marker"][10]) 
			
			marker:registerObject("raceTriggerLot")
 	  		marker.name = "raceTriggerLot"
 	  		
 	  		
 	  		
 	  		 local missionTrigger = createObject("BeamNGTrigger")
   			 missionTrigger.loadMode = 1
   			
  	  		missionTrigger.luaFunction = String("onRaceTrigger")
  	 		missionTrigger:setPosRot(raceTriggerZones[location]["trigger"][1], raceTriggerZones[location]["trigger"][2], raceTriggerZones[location]["trigger"][3], raceTriggerZones[location]["trigger"][4], raceTriggerZones[location]["trigger"][5], raceTriggerZones[location]["trigger"][6], raceTriggerZones[location]["trigger"][7])
  	 		missionTrigger:setScale(Point3F(raceTriggerZones[location]["trigger"][8],raceTriggerZones[location]["trigger"][9],raceTriggerZones[location]["trigger"][10]))
  	  
 	   		missionTrigger:registerObject("raceStartTrigger")
 	  		missionTrigger.name = "raceStartTrigger"
	
	end
end

raceTargets = {0,0,0,0,0,0,0,0,0,0,0,0}
--Figure out why findObject doesn'twork with names as integers

--Doesnt work because beamng doesnt allow object names to start with integer
function raceCheckpoint(data)
	if raceInProgress == true then
	 	 if data.event == "enter" then
			local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					if vehID == data.subjectID then
						--print("checkPoint")
						local s = string.gsub(data.triggerName,"check","")
						if s ~= nil then
							--print(s .. " not nil")
							
								TriggerServerEvent("checkpointHandler",s)
								local mark = scenetree.findObject("raceCheckpoint" .. s)
								local trigger = scenetree.findObject("check" .. s)
									if mark ~= nil then 
										mark:delete()
									end
									if trigger ~= nil then
										trigger:delete()
									
									end
								
							
						
						end
					end
				end
			end
		end
	end

end


function onRaceTrigger(data)
	if raceInProgress == false then
	 	
			local ownMap = MPVehicleGE.getOwnMap()
			if ownMap ~= nil then
				for vehID, value in pairs(ownMap) do
					if vehID == data.subjectID then
						if data.event == "enter" then
							if rateL >= 1 then
								TriggerServerEvent("raceReadyBox","true")
								windowsToShow["raceUI"] = drawWindow21
							end
						else
							if rateL >= 1 then
								TriggerServerEvent("raceReadyBox","false")
								windowsToShow["raceUI"] = nil
							end
						end
					end
				end
			end
		
	end

end

currentTrackedCheckpoint = nil

function getDistance(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end
--[[
function markClosestCheckpoint()
	if raceInProgress == true then
		if markCheckpoints == true then
		
			local ownMap = MPVehicleGE.getOwnMap()
		
			for k,v in pairs(ownMap) do
				local myVeh = be:getObjectByID(k)
				local myRot = quat(myVeh:getRotation())
				local myPos = myVeh:getPosition()
				local minDistance = 10000
				local i = 0
				local closest = 0
				for i = 1, #raceTargets do
					local checkpoint = scenetree.findObject("check" .. raceTargets[i])
					local pos = checkpoint:getPosition()
					if checkpoint ~= nil then
						
						local distance  = math.abs(getDistance(myPos.x,myPos.y,pos.x,pos.y))
						if distance > minDistance then
						
						
						end
					end
				end
			end
		end
	
	
	
	end


end
--]]

function vehResetClient(data)
	if data ~= nil then
	vehResetBool = true
	resetHandled = true
	--Need to change this to use a table instead of string split
	if data == "cops" then
		local ownMap = MPVehicleGE.getOwnMap()
	
		for k,v in pairs(ownMap) do
				local myVeh = be:getObjectByID(k)
				--This needs to be changed to only run once
				local pos = policeSpawns[location][1][ID]
				print(pos)
				myVeh:queueLuaCommand('cnr.setOwn()')
					
				myVeh:setPosRot(pos[1],pos[2],pos[3],pos[4],pos[5],pos[6],pos[7])
		end
	
	else
		local ownMap = MPVehicleGE.getOwnMap()
	
		for k,v in pairs(ownMap) do
				local myVeh = be:getObjectByID(k)
				--This needs to be changed to only run once
			local pos = civilianSpawns[location][1][ID]
				myVeh:queueLuaCommand('cnr.setOwn()')
					
				myVeh:setPosRot(pos[1],pos[2],pos[3],pos[4],pos[5],pos[6],pos[7])
		end
		
	resetHandled = true
	end
	end
end
function vehReset(data)
	
	
	vehResetBool = true
	resetHandled = true
	--Need to change this to use a table instead of string split
	local pos = data
	local ownMap = MPVehicleGE.getOwnMap()
	
		for k,v in pairs(ownMap) do
				local myVeh = be:getObjectByID(k)
				--This needs to be changed to only run once
			
				myVeh:queueLuaCommand('cnr.setOwn()')
				
				myVeh:setPosRot(pos[1],pos[2],pos[3],pos[4],pos[5],pos[6],pos[7])
		end
	
			
	resetHandled = true
end

--New function for resetting back to spawn, uses recovery to  stop people from getting stuck in ground with big tires etc
function sendToSpawn(data)
	vehResetBool = true
	resetHandled = true
	--Need to change this to use a table instead of string split
	local pos = data
	local ownMap = MPVehicleGE.getOwnMap()
	
		for k,v in pairs(ownMap) do
				local myVeh = be:getObjectByID(k)
				--This needs to be changed to only run once
				-- be:getPlayerVehicle(0):setPositionNoPhysicsReset(vec3(pos[1],y,z))
				
				--recovery send you back to spawn 1 unless there is delay(goofy to have to introduce delay for this)
				--Safeteleport forces you to face a certain direction, so need to get position AFTER to make sure rotation is right 
				--Need to remake safeteleport to work better for my stuff
				spawn.safeTeleport(myVeh, vec3(pos[1],pos[2],pos[3]), quat(pos[4],pos[5],pos[6],pos[7]),nil, nil ,nil,nil, true)
				local posi = myVeh:getPosition()
				myVeh:queueLuaCommand('cnr.setOwn()')
				myVeh:setPosRot(posi.x,posi.y,posi.z,pos[4],pos[5],pos[6],pos[7])
				
				
				--myVeh:queueLuaCommand('recovery.recoverInPlace()') 
				resetHandled = true
		end
	
			
	


end	

function force()
	
	TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2")
				dS = 0
				dT = 0
				

	local ownMap = MPVehicleGE.getOwnMap()
	if ownMap ~= nil then
	for vehID, value in pairs(ownMap) do
	myVeh = be:getObjectByID(vehID)
	myGameVehicleID = myVeh:getID()
	--This needs to be changed to only run once
	myVeh:queueLuaCommand('cnr.setOwn()')
	--This is so it only runs once, putting this in onEdited causes duplicate due to this force sync of parts
	--myVeh:queueLuaCommand('cnr.PTW()')
	--Thanks to Tventy/deerette for this part
	local vehicleData = vehManager.getVehicleData(myGameVehicleID)
	if not vehicleData then MPVehicleGE.sendVehicleEdit(myGameVehicleID) return end
	local vehicle,unifyJournal,chosenParts,activePartsOrig = jbeamSlotSystem.findParts(vehicleData.ioCtx,vehicleData.config)
	chosenParts.main = nil
		vehicleData.config.parts = chosenParts
		
	--		MPVehicleGE.sendVehicleEdit(myGameVehicleID)
			for k,v in pairs(chosenParts) do
			
			
			
			end
			
	--end
	
	--end
	
	--local t = extensions.core_vehicle_manager.getConfig(myGameVehicleID)
	local t = chosenParts
	print(t)
	--print(t.config)
	local t2 = jsonEncode(t)
	--TriggerServerEvent("vehManager","t2")
	print(t2)
	TriggerServerEvent("onEditCustom",t2)	
	syncRequired = ""
	syncToPlayersRequired = true
	end
	end
	vehResetBool = true
	
end

 
	
function setTime(time)
	--REMOVE STRINGSPLIT
	local s = stringSplit(time, "&"," ")
	if s[2] ~= nil then
		timeLeft = s[1] .. "\n" ..  s[2] .. "\n" .. s[3] .. "\n" .. s[4] .. "\n" .. s[6]
		repairsLeft = s[5]
	else timeLeft = time
		repairsLeft = 0
	end
end
function onVReset()
	local r = false
	local ownMap = MPVehicleGE.getOwnMap()
		
		for k,v in pairs(ownMap) do
			local myVeh = be:getObjectByID(k)
			local myRot = quat(myVeh:getRotation())
			local myPos = myVeh:getPosition()
			local vehSID = MPVehicleGE.getServerVehicleID(k)
			TriggerServerEvent("recieveClientData", tostring(vehPosx) .. "&" .. tostring(vehPosy) .. "&" .. tostring(vehPosz) .. "&" .. tostring(vehSID) .. "&" .. tostring(vehicleSpeed) .. "&" .. tostring(dS) .. "&" .. tostring(dT))
			local i = 0
			for i = 1, 3  do
				local xDiff = 0
				local yDiff = 0
				xDiff = math.abs(markList2[location][i][1] - myPos.x)
				yDiff = math.abs(markList2[location][i][2] - myPos.y)
				if xDiff <= 5 and yDiff <= 5 then
					--TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&1")
					--dS = 0
					--dT = 0
					--r = true

					
					
					break
				end
			end
			if r == false then
				--TriggerServerEvent("resetHa", tostring(dS) .. "&" .. tostring(dT) .. "&2&1")
					dS = 0
					dT = 0
			end
		end
end


function syncHeistData(data)

	if data ~= nil then
		heistData = json.decode(data)
	
	
	end

end

heistSetupTable = {}

function heistSetupData(data)
	if data ~= nil then
		heistSetupTable = json.decode(data)
		windowsToShow["heistSetup"] = drawWindow6
	
	end

end

--need to optimize, store players not detected in temp table then check against that instead of all players in cop table
--this would also remove the constant check to delete them
local function showBlackBalls(data)
	--print("Black Balls")
	--print(data)
	if data ~= nil then
		local table1 = json.decode(data)
		if table1 ~= nil then
			for name,v in pairs(table1) do
				if table1[name]["delete"] == nil then
					--print(name .. "no delete")
				
					local vehh = getVehicleByServerID(table1[name]["ID"])
					local vehicle = be:getObjectByID(vehh.gameVehicleID)
					
					if vehicle == nil then
						--print(name .. "no vehicle")
						local obj = scenetree.findObject("marker" .. name)
						if obj == nil then
							print(name .. "no marker")
							local marker = createObject("TSStatic")
							marker.shapeName = "art/shapes/interface/single_faded_column_b.dae" 
							marker.scale = vec3(10, 10, 10)
							marker.useInstanceRenderData = 1 
							marker.instanceColor = Point4F(0,0,1,1) 
   		 				
							marker:registerObject("marker" .. name)
							marker.name = "marker" .. name
							--obj = marker
					
						end
						local obj = scenetree.findObject("marker" .. name)
						obj:setPosRot(table1[name]["x"],table1[name]["y"],table1[name]["z"] - 5, 0, 0, 0, 1) 
	
					
					else
						local obj = scenetree.findObject("marker" .. name)
						if obj ~= nil then
							obj:delete()
						
						end
					end	
				else
					local obj = scenetree.findObject("marker" .. name)
						if obj ~= nil then
							obj:delete()
						
						end
				
				end
			
			end
		
		
		end
	
	end


end

local function onExtensionLoaded()
print("--------------------LOADING")

	AddEventHandler("syncCustomColors",syncCustomColors)
	AddEventHandler("showBlackBalls",showBlackBalls)
	AddEventHandler("removePlayer",removePlayer)
	AddEventHandler("restorePlayer",restorePlayer)
	AddEventHandler("syncPlayers",syncPlayers)
	AddEventHandler("receiveOwnedParts",receiveOwnedParts)
	AddEventHandler("markHeistLocation",markHeistLocation)
	AddEventHandler("heistSetupData",heistSetupData)
	AddEventHandler("syncHeistData",syncHeistData)
	AddEventHandler("spawnCooldownZone",spawnCooldownZone)
	AddEventHandler("spawnCooldownZoneMarker",spawnCooldownZoneMarker)
	AddEventHandler("syncGroup", syncGroup)
	AddEventHandler("force", force)
	AddEventHandler("setMostWanted", setMostWanted)
	AddEventHandler("chatLog", chatLog)
	AddEventHandler("setTag", setTag)
	AddEventHandler("markGPS", markGPS)
	
	AddEventHandler("onFoot", onFoot)
	AddEventHandler("roundIsOver", roundIsOver)
	AddEventHandler("beginRace", beginRace)
	
	AddEventHandler("recieveClientData", recieveClientData)
	AddEventHandler("idleChecker", idleChecker)
	AddEventHandler("markerSet", markerSet)
	AddEventHandler("finishLine", finishLine)
	AddEventHandler("start", start)
	AddEventHandler("copRI", copRI)
	AddEventHandler("spawnOb", spawnOb)
	AddEventHandler("vehReset", vehReset)
	AddEventHandler("vehResetClient", vehResetClient)
	AddEventHandler("setTime", setTime)
	AddEventHandler("setInfo", setInfo)
	AddEventHandler("initUI", initUI)
	AddEventHandler("setTeam", setTeam)
	AddEventHandler("resetHan", resetHan)
	AddEventHandler("onVReset",onVReset)
	AddEventHandler("lAF",lAF)
	AddEventHandler("setMoney",setMoney)
	AddEventHandler("setTankName",setTankName)
	AddEventHandler("raceInfoSync",raceInfoSync)
	AddEventHandler("setFuelLev",setFuelLev)
	AddEventHandler("a",a)
	AddEventHandler("b",b)
	AddEventHandler("c",c)
	AddEventHandler("r",r)
	gui_module.initialize(gui)
	gui.registerWindow("Mark Location", im.ImVec2(100, 300))
	gui.showWindow("markLocation")
	
	gui.registerWindow("Robbery", im.ImVec2(100, 300))
	gui.showWindow("Robbery")

	gui.registerWindow("Wanted List", im.ImVec2(200, 500))
	gui.showWindow("Wanted List")

	gui.registerWindow("CnR UI", im.ImVec2(220, 290))
	gui.showWindow("CnR UI")
	
	gui.registerWindow("Help", im.ImVec2(1000, 1000))
	gui.showWindow("Help")

	gui.registerWindow("Services", im.ImVec2(100, 300))
	gui.showWindow("Services")
	
	

	gui.registerWindow("Wrecked Players", im.ImVec2(100, 300))
	gui.showWindow("Wrecked Players")
	
	
	gui.registerWindow("Mod Menu", im.ImVec2(100, 300))
	gui.showWindow("Mod Menu")
	gui.registerWindow("Transfer Cargo", im.ImVec2(100, 300))
	gui.showWindow("Transfer Cargo")
	gui.registerWindow("Starter Cars", im.ImVec2(100, 300))
	gui.showWindow("Starter Cars")
	
	gui.registerWindow("Cargo Listings", im.ImVec2(100, 300))
	gui.showWindow("Cargo Listings")
	
	gui.registerWindow("Price List", im.ImVec2(100, 300))
	gui.showWindow("Price List")
	
	gui.registerWindow("Chat History", im.ImVec2(100, 300))
	gui.showWindow("Chat History")
	
	gui.registerWindow("Settings", im.ImVec2(100, 300))
	gui.showWindow("Settings")
	
	gui.registerWindow("Group Menu", im.ImVec2(300, 600))
	gui.showWindow("Group Menu")
	
	gui.registerWindow("MCC Menu", im.ImVec2(900, 900))
	gui.showWindow("MCC Menu")
	
	gui.registerWindow("Race UI", im.ImVec2(900, 900))
	gui.showWindow("Race UI")
	
	gui.registerWindow("Heist Setups", im.ImVec2(900, 900))
	gui.showWindow("Heist Setups")
	
	
	gui.registerWindow("PatronWindow", im.ImVec2(900, 900))
	gui.showWindow("PatronWindow")
	
		initUI("true")
		windowsToShow["CnRUI"] = drawWindow3
		windowsToShow["help"] = drawWindow4
		
end


-------------------------------------------------

--local function onUpdate(dt)
	--if windowOpen[0] == true then
	--	if timeLeft ~= nil then
	--	drawWindow()
	--	end
	--end
--end
function setFuelLev(data)
	
	
	currentFuel = tostring(data)
	local ownMap = MPVehicleGE.getOwnMap()
		
					for k,v in pairs(ownMap) do
						local myVeh = be:getObjectByID(k)
						myVeh:queueLuaCommand('cnr.setFuel('.. tostring(data) ..')')
						
					end
end

function teleportedFromBigmap()
	print("BIG MAP TELEPORT")
	robFail()


end

local function sendFuel(data)
	if data ~= nil then	
			if tonumber(data) < tonumber(currentFuel) then
				TriggerServerEvent("recieveFuel",data)
				currentFuel = data
			end
	end
end

local function onExtensionUnloaded()
	Lua:requestReload()
end

--------------------------------------------------------------------------------
--Move this to another folder when i feel like it, which will be roughly 5 decades from now
starterParts = {}

starterParts['covet'] = {['covet_gauges_metric_rhd'] = 0,['covet_lettering_13s'] = 0,['covet_seats_R'] = 0,['covet_brake_F'] = 0,['covet_bumper_grille_F'] = 0,['covet_bumperbar_F'] = 0,['covet_fender_R'] = 0,['covet_enginemounts'] = 0,['covet_fendersignal_FR'] = 0,['covet_fendersignal_FL'] = 0,['covet_halfshaft_F'] = 0,['covet_door_L'] = 0,['covet_seat_FL'] = 0,['covet_brake_R'] = 0,['covet_flywheel'] = 0,['covet_doorglass_L'] = 0,['covet_engine_sohc_small'] = 0,['covet_windshield'] = 0,['covet_coilover_F'] = 0,['covet_tailgateglass'] = 0,['covet_skin_interior'] = 0,['covet_grille_F_alt'] = 0,['covet_wheeldata_F'] = 0,['covet_doordetent_L'] = 0,['covet_steering'] = 0,['covet_header'] = 0,['covet_bumper_R_alt'] = 0,['covet_sideskirts'] = 0,['covet_trim'] = 0,['covet_transmission_4M'] = 0,['covet_body'] = 0,['covet_seat_FR'] = 0,['covet_taillight_L_jdm'] = 0,['covet_mirror_R'] = 0,['covet_suspension_F'] = 0,['covet_engine_ecu'] = 0,['covet_lettering_fascia_R'] = 0,['covet_headlight_L_jdm'] = 0,['covet_door_R'] = 0,['covet_suspension_R'] = 0,['covet_shifter_M_rhd'] = 0,['covet_interior_rhd'] = 0,['covet_logo_F_grille'] = 0,['covet_tailgate'] = 0,['covet_hub_F_4'] = 0,['covet_steer'] = 0,['covet_innerfender_FR'] = 0,['covet_engine_internals'] = 0,['covet_taillight_R_jdm'] = 0,['covet_fascia_R'] = 0,['covet_doordetent_R'] = 0,['covet_hood'] = 0,['covet_radiator'] = 0,['covet_doorpanel_R'] = 0,['covet_finaldrive_F_389'] = 0,['covet_coilover_R'] = 0,['covet_fueltank'] = 0,['covet_quarterglass_R'] = 0,['covet_oilpan'] = 0,['covet_headlight_R_jdm'] = 0,['covet_quarterglass_L'] = 0,['covet_innerfender_FL'] = 0,['covet_pedalbox_M_rhd'] = 0,['covet_hub_R_4'] = 0,['covet_fender_L'] = 0,['covet_licenseplate_F'] = 0,['covet_fascia_F'] = 0,['covet_bumper_F_alt'] = 0,['covet_swaybar_F'] = 0,['covet_licenseplate_R'] = 0,['covet_intake_1.3_carb'] = 0,['covet_exhaust'] = 0,['covet_wheeldata_R'] = 0,['covet_doorglass_R'] = 0,['covet_differential_F'] = 0,['covet_doorpanel_L'] = 0,['ibishu_wheel_11a_13x5_R'] = 0,['tire_R_175_70_13_standard'] = 0,['tire_F_175_70_13_standard'] = 0,['brakepad_F'] = 0,['brakepad_R'] = 0,['ibishu_wheel_11a_13x5_F'] = 0}
starterParts["midsize"] = {['midsize_trunklight_L'] = 0,['midsize_seat_FL'] = 0,['midsize_muffler'] = 0,['midsize_bumper_R_trim'] = 0,['midsize_quarterglass_R'] = 0,['midsize_seat_R'] = 0,['midsize_doorpanel_FR'] = 0,['midsize_wheeldata_F'] = 0,['midsize_oilpan_i4'] = 0,['midsize_exhaust_i4'] = 0,['midsize_shifter_M'] = 0,['midsize_bumperbar_R'] = 0,['midsize_hood'] = 0,['midsize_quarterglass_L'] = 0,['midsize_backlight'] = 0,['midsize_bumper_R'] = 0,['midsize_fueltank'] = 0,['midsize_header_i4'] = 0,['midsize_ABS'] = 0,['midsize_wheeldata_R'] = 0,['midsize_taillight_R'] = 0,['midsize_seat_FR'] = 0,['midsize_gauges_imperial'] = 0,['midsize_hub_R_5'] = 0,['midsize_chmsl'] = 0,['midsize_engine_dohc'] = 0,['midsize_door_RL'] = 0,['midsize_fender_L'] = 0,['midsize_sunvisor'] = 0,['midsize_bumper_F'] = 0,['midsize_bumperbar_F'] = 0,['midsize_engine_i4_internals'] = 0,['midsize_windowtrim_chrome'] = 0,['midsize_doorpanel_FL'] = 0,['midsize_bumpersignal_FL'] = 0,['midsize_steer'] = 0,['midsize_engine_i4_ecu'] = 0,['midsize_mirror_R'] = 0,['midsize_headlight_L'] = 0,['midsize_trunk_trim_chrome'] = 0,['midsize_differential_F'] = 0,['midsize_swaybar_F'] = 0,['midsize_door_FR'] = 0,['midsize_radiator'] = 0,['midsize_strut_R'] = 0,['midsize_taillight_L'] = 0,['midsize_doorglass_RL'] = 0,['midsize_hub_F_5'] = 0,['midsize_trunklight_R'] = 0,['midsize_fender_R'] = 0,['midsize_enginemounts'] = 0,['midsize_grille_F'] = 0,['midsize_skin_interior_beige'] = 0,['midsize_headlight_R'] = 0,['midsize_flywheel'] = 0,['midsize_brake_F'] = 0,['midsize_windshield'] = 0,['midsize_doorglass_FR'] = 0,['midsize_dashboard'] = 0,['midsize_body'] = 0,['midsize_doorglass_FL'] = 0,['midsize_doorglass_RR'] = 0,['midsize_suspension_R'] = 0,['midsize_mirror_L'] = 0,['midsize_brake_R'] = 0,['midsize_swaybar_R'] = 0,['midsize_transmission_5M'] = 0,['midsize_trunk'] = 0,['midsize_doorpanel_RL'] = 0,['midsize_trim'] = 0,['midsize_door_RR'] = 0,['midsize_bumper_F_trim'] = 0,['midsize_tubs'] = 0,['midsize_suspension_F'] = 0,['midsize_weightreduction'] = 0,['midsize_strut_F'] = 0,['midsize_steering'] = 0,['midsize_doorpanel_RR'] = 0,['midsize_finaldrive_F_411'] = 0,['midsize_halfshafts_F'] = 0,['midsize_door_FL'] = 0,['midsize_lettering_LX'] = 0,['midsize_licenseplate_R'] = 0,['midsize_intake_i4'] = 0,['midsize_bumpersignal_FR'] = 0,['ibishu_hubcap_03a_15_F'] = 0,['ibishu_hubcap_03a_15_R'] = 0,['brakepad_F_premium'] = 0,['brakepad_R_premium'] = 0,['tire_F_205_60_15_standard'] = 0,['steelwheel_01a_15x7_R'] = 0,['steelwheel_01a_15x7_F'] = 0,['tire_R_205_60_15_standard'] = 0}
starterParts["bx"] = {['coupe_quarterglass_R'] = 0,['coupe_finaldrive_R_411'] = 0,['coupe_transmission_5M'] = 0,['coupe_headlight_R'] = 0,['coupe_fender_R'] = 0,['coupe_mirror_L'] = 0,['coupe_trunkpanel'] = 0,['coupe_oilpan_I4'] = 0,['coupe_bumper_F'] = 0,['coupe_suspension_R'] = 0,['coupe_wheeldata_F'] = 0,['coupe_engine_ecu'] = 0,['coupe_sideskirts'] = 0,['coupe_fueltank'] = 0,['coupe_intake'] = 0,['coupe_mirror_R'] = 0,['coupe_differential_R'] = 0,['coupe_seat_FR'] = 0,['coupe_trunk'] = 0,['coupe_doorpanel_R'] = 0,['coupe_door_R'] = 0,['coupe_swaybar_R'] = 0,['coupe_engine_I4'] = 0,['coupe_lettering_base'] = 0,['coupe_bumper_R'] = 0,['coupe_doorpanel_L'] = 0,['coupe_strut_F'] = 0,['coupe_flywheel'] = 0,['coupe_brake_R'] = 0,['coupe_skin_interior'] = 0,['coupe_radiator'] = 0,['coupe_bumperbar_F'] = 0,['coupe_licenseplate_R'] = 0,['coupe_tubs'] = 0,['coupe_wheeldata_R'] = 0,['coupe_windshield'] = 0,['coupe_doorglass_L'] = 0,['coupe_hub_F_5'] = 0,['coupe_driveshaft_R'] = 0,['coupe_taillight_L'] = 0,['coupe_swaybar_F'] = 0,['coupe_halfshaft_R'] = 0,['coupe_seat_FL'] = 0,['coupe_steer'] = 0,['coupe_suspension_F'] = 0,['coupe_hub_R_5'] = 0,['coupe_steering'] = 0,['coupe_engine_internals'] = 0,['coupe_brake_F'] = 0,['coupe_enginemounts'] = 0,['coupe_hood'] = 0,['coupe_taillight_R'] = 0,['coupe_headlight_L'] = 0,['coupe_seats_R'] = 0,['coupe_exhaust_I4'] = 0,['coupe_backlight'] = 0,['coupe_door_L'] = 0,['coupe_body'] = 0,['coupe_doorglass_R'] = 0,['coupe_coilover_R'] = 0,['coupe_quarterglass_L'] = 0,['coupe_fender_L'] = 0,['steelwheel_01a_15x7_F'] = 0,['ibishu_hubcap_03a_15_F'] = 0,['brakepad_F_premium'] = 0,['brakepad_R_premium'] = 0,['tire_F_195_60_15_standard'] = 0,['steelwheel_01a_15x7_R'] = 0,['tire_R_195_60_15_standard'] = 0,['ibishu_hubcap_03a_15_R'] = 0,['bx_doorpanel_R'] = 0,['bx_mirror_L_rhd'] = 0,['bx_doorglass_L'] = 0,['bx_wheeldata_R'] = 0,['bx_taillight_R_hatch'] = 0,['bx_trim_bumper_R_black'] = 0,['bx_sideskirt_R'] = 0,['bx_quarterglass_R_hatch'] = 0,['bx_seats_R'] = 0,['bx_doorpanel_L'] = 0,['bx_bumperbar_F'] = 0,['bx_gauges_rhd_metric'] = 0,['bx_tailgate_hatch'] = 0,['bx_lettering_tailgate_hatch_l'] = 0,['bx_skin_interior'] = 0,['bx_radio_rhd'] = 0,['bx_transmission_5M'] = 0,['bx_swaybar_R'] = 0,['bx_engine_ecu_i4'] = 0,['bx_bumper_F_popup'] = 0,['bx_swaybar_F'] = 0,['bx_finaldrive_R_408'] = 0,['bx_door_L'] = 0,['bx_exhaust_i4'] = 0,['bx_licenseplate_F_popup'] = 0,['bx_wheeldata_F'] = 0,['bx_signal_R_popup'] = 0,['bx_tubs_FR'] = 0,['bx_driveshaft_R'] = 0,['bx_windshield'] = 0,['bx_hub_F_4'] = 0,['bx_hood_popup'] = 0,['bx_licenseplate_R'] = 0,['bx_taillight_L_hatch'] = 0,['bx_signal_FL_popup'] = 0,['bx_brake_F'] = 0,['bx_trunklight_R_hatch'] = 0,['bx_fueltank'] = 0,['bx_trunklight_L_hatch'] = 0,['bx_trim_bumper_F_popup_black'] = 0,['bx_seat_FL'] = 0,['bx_quarterpanels_hatch'] = 0,['bx_tailgateglass_hatch'] = 0,['bx_brake_R'] = 0,['bx_tubs_FL'] = 0,['bx_suspension_F'] = 0,['bx_engine_i4_2.0'] = 0,['bx_doorglass_R'] = 0,['bx_intake_i4'] = 0,['bx_steering'] = 0,['bx_steer'] = 0,['bx_ABS'] = 0,['bx_halfshaft_R'] = 0,['bx_fender_R_popup'] = 0,['bx_lettering_rearpanel_hatch_200bx'] = 0,['bx_interior_hatch'] = 0,['bx_signal_L_popup'] = 0,['bx_headlight_L_popup_rhd'] = 0,['bx_coilover_R'] = 0,['bx_signal_FR_popup'] = 0,['bx_trunkpanel_hatch'] = 0,['bx_sideskirt_L'] = 0,['bx_fender_L_popup'] = 0,['bx_suspension_R'] = 0,['bx_bumper_R'] = 0,['bx_shifter_M_rhd'] = 0,['bx_shelf_hatch'] = 0,['bx_seat_FR'] = 0,['bx_trim_body_black'] = 0,['bx_headlight_R_popup_rhd'] = 0,['bx_radsupport_popup'] = 0,['bx_quarterglass_L_hatch'] = 0,['bx_enginemounts'] = 0,['bx_oilpan_i4'] = 0,['bx_mirror_R_rhd'] = 0,['bx_dashboard_rhd'] = 0,['bx_hub_R_4'] = 0,['bx_chmsl_hatch'] = 0,['bx_engine_internals_i4'] = 0,['bx_radiator_i4'] = 0,['bx_flywheel'] = 0,['bx_badge_F_popup'] = 0,['bx_door_R'] = 0,['bx_differential_R'] = 0,['bx_strut_F'] = 0,['bx_body_hatch'] = 0,['ibishu_wheel_07a_15x7_alt_R'] = 0,['ibishu_wheel_07a_15x7_alt_F'] = 0}
starterParts["moonhawk"] = {['moonhawk_seat_FL'] = 0,['moonhawk_driveshaft'] = 0,['moonhawk_steer'] = 0,['moonhawk_engine_i6_244'] = 0,['moonhawk_hood'] = 0,['moonhawk_bumper_R'] = 0,['moonhawk_suspension_F'] = 0,['moonhawk_fender_L'] = 0,['moonhawk_door_L'] = 0,['moonhawk_innerfender_FL'] = 0,['moonhawk_brake_R'] = 0,['moonhawk_tailcone'] = 0,['moonhawk_brake_F'] = 0,['moonhawk_finaldrive_R_308'] = 0,['moonhawk_door_R'] = 0,['moonhawk_fender_R'] = 0,['moonhawk_innerfender_FR'] = 0,['moonhawk_spring_R'] = 0,['moonhawk_transmission_3M'] = 0,['moonhawk_radiator'] = 0,['moonhawk_wheeldata_R'] = 0,['moonhawk_wheeldata_F'] = 0,['moonhawk_shock_R'] = 0,['moonhawk_swaybar_F'] = 0,['moonhawk_suspension_R'] = 0,['moonhawk_shifter_M_column'] = 0,['moonhawk_mirror_L'] = 0,['moonhawk_steering'] = 0,['moonhawk_spring_F'] = 0,['moonhawk_fueltank'] = 0,['moonhawk_mirror_R'] = 0,['moonhawk_nosecone'] = 0,['moonhawk_seats_R'] = 0,['moonhawk_bumper_F'] = 0,['moonhawk_seat_FR'] = 0,['moonhawk_radsupport'] = 0,['moonhawk_body'] = 0,['moonhawk_shock_F'] = 0,['moonhawk_steeringbox'] = 0,['moonhawk_exhaust_i6'] = 0,['moonhawk_trunk'] = 0,['moonhawk_differential_R'] = 0,['steelwheel_03a_15x7_R'] = 0,['steelwheel_03a_15x7_F'] = 0,['hubcap_05a_15_F_alt'] = 0,['tire_F_F78_15_alt'] = 0,['hubcap_05a_15_R_alt'] = 0,['tire_R_F78_15_alt'] = 0,['moonhawk_quarterglass_R'] = 0,['moonhawk_logo_trunk'] = 0,['moonhawk_frame'] = 0,['moonhawk_engine_i6_internals'] = 0,['moonhawk_header_i6'] = 0,['moonhawk_doorglass_L'] = 0,['moonhawk_doorglass_R'] = 0,['moonhawk_glass_F'] = 0,['moonhawk_doorpanel_R'] = 0,['moonhawk_flywheel'] = 0,['moonhawk_skin_interior'] = 0,['moonhawk_enginemounts'] = 0,['moonhawk_glass_R'] = 0,['moonhawk_licenseplate_R'] = 0,['moonhawk_quarterglass_L'] = 0,['moonhawk_intake_i6'] = 0,['moonhawk_doorpanel_L'] = 0,['moonhawk_lettering_tailcone'] = 0,['moonhawk_oilpan_i6'] = 0,['brakepad_F'] = 0,['brakepad_R'] = 0}
starterParts["fullsize"] = {['fullsize_exhmanifold'] = 0,['fullsize_enginemounts'] = 0,['fullsize_radiator'] = 0,['fullsize_backlight'] = 0,['fullsize_skin_interior'] = 0,['fullsize_shock_R'] = 0,['fullsize_quarterglass_RR'] = 0,['fullsize_steering'] = 0,['fullsize_radsupport'] = 0,['fullsize_doorglass_RR'] = 0,['fullsize_innerfender_L'] = 0,['fullsize_brake_R'] = 0,['fullsize_bumper_F'] = 0,['fullsize_doorglass_FR'] = 0,['fullsize_wheeldata_F'] = 0,['fullsize_headlight_L'] = 0,['fullsize_signal_FL'] = 0,['fullsize_trunk'] = 0,['fullsize_doorpanel_RR'] = 0,['fullsize_door_FR'] = 0,['fullsize_fender_R'] = 0,['fullsize_seats_R'] = 0,['fullsize_swaybar_F'] = 0,['fullsize_fender_L'] = 0,['fullsize_doorpanel_RL'] = 0,['fullsize_doorpanel_FR'] = 0,['fullsize_exhaust'] = 0,['fullsize_skin_bodycolorednochrome'] = 0,['fullsize_ABS'] = 0,['fullsize_engine_v8_4.5'] = 0,['fullsize_brake_F'] = 0,['fullsize_body'] = 0,['fullsize_armrest_FL'] = 0,['fullsize_doorglass_RL'] = 0,['fullsize_shock_F'] = 0,['fullsize_windshield'] = 0,['fullsize_licenseplate_R'] = 0,['fullsize_wheeldata_R'] = 0,['fullsize_shifter_A'] = 0,['fullsize_transmission_4A'] = 0,['fullsize_signal_FR'] = 0,['fullsize_swaybar_R'] = 0,['fullsize_taillight_R'] = 0,['fullsize_door_RL'] = 0,['fullsize_driveshaft'] = 0,['fullsize_suspension_R'] = 0,['fullsize_suspension_F'] = 0,['fullsize_innerfender_R'] = 0,['fullsize_finaldrive_R_327'] = 0,['fullsize_spring_R'] = 0,['fullsize_intake_stock'] = 0,['fullsize_spring_F'] = 0,['fullsize_armrest_FR'] = 0,['fullsize_frame'] = 0,['fullsize_seat_FR'] = 0,['fullsize_seat_FL'] = 0,['fullsize_converter'] = 0,['fullsize_bumper_R'] = 0,['fullsize_door_RR'] = 0,['fullsize_doorglass_FL'] = 0,['fullsize_differential_R'] = 0,['fullsize_lettering_grille'] = 0,['fullsize_quarterglass_RL'] = 0,['fullsize_hood'] = 0,['fullsize_doorpanel_FL'] = 0,['fullsize_fueltank'] = 0,['fullsize_grille'] = 0,['fullsize_mirror_R'] = 0,['fullsize_door_FL'] = 0,['fullsize_mirror_L'] = 0,['fullsize_headlight_R'] = 0,['fullsize_taillight_L'] = 0,['fullsize_steer'] = 0,['fullsize_dash'] = 0,['fullsize_bumperbar_F'] = 0,['pickup_engine_v8_ecu'] = 0,['pickup_oilpan_v8'] = 0,['brakepad_F_premium'] = 0,['steelwheel_01a_15x7_R_alt'] = 0,['steelwheel_01a_15x7_F_alt'] = 0,['tire_R_205_75_15_alt_standard'] = 0,['tire_F_205_75_15_alt_standard'] = 0,['pickup_engine_v8_internals'] = 0,['hubcap_08a_15_F_alt'] = 0,['brakepad_R_premium'] = 0,['hubcap_08a_15_R_alt'] = 0}

--------------------------------------------------------------------------------
--reorganize all Modules
M.dependencies = {"ui_imgui"}
M.markHeistLocation = markHeistLocation
M.setInfo = setInfo
M.setTime = setTime
M.initUI = initUI
M.setMoney = setMoney
M.requestQueue = requestQueue
M.clearGPS = clearGPS
M.refuelTry = refuelTry
M.restorePlayers = restorePlayers
M.respawnButton = respawnButton
M.findRepairTruck = findRepairTruck

M.findRefuelTruck = findRefuelTruck
M.robTry = robTry
M.repairTry = repairTry
M.receiveOwnedParts = receiveOwnedParts
M.raceInfoSync = raceInfoSync
M.markGPS = markGPS
M.onGPSTrigger = onGPSTrigger
M.onRobTrigger = onRobTrigger
M.onRepairTrigger = onRepairTrigger

------------------------------

M.spawnCooldownZone = spawnCooldownZone
M.spawnCooldownZoneMarker = spawnCooldownZoneMarker
M.ptw = ptw
M.setMostWanted = setMostWanted
M.sendFuel = sendFuel
M.setTankName = setTankName
M.setFuelLev = setFuelLev
M.r = r
M.c = c
M.b = b
M.a = a
M.lAF = lAF
M.onCooldownTrigger = onCooldownTrigger

M.onRaceTrigger = onRaceTrigger

M.heistSetupData = heistSetupData

M.syncHeistData = syncHeistData
M.onVReset = onVReset
M.resetHan =  resetHan
M.setTeam = setTeam
M.setPerfLevel = setPerfLevel
M.force = force
M.vehReset = vehReset
M.vehResetClient = vehResetClient
M.onVehicleResetted = onVehicleResetted
M.spawnOb = spawnOb
M.setDs = setDs
M.setD = setD
M.start = start
M.copRI = copRI
M.raceCheck = raceCheck
M.markerSet = markerSet
M.lightbar = lightbar
M.setSpeed = setSpeed
M.setTag = setTag
M.stealCar = stealCar
M.stealTry = stealTry
M.onVehicleDestroyed = onVehicleDestroyed
M.onVehicleSpawned = onVehicleSpawned
--M.onVehicleSwitched = onVehicleSwitched
M.idleChecker = idleChecker
M.roundIsOver = roundIsOver
M.beginRace = beginRace
--M.onBeamNGTrigger = onBeamNGTrigger
M.beginGame = beginGame
M.sendClientData = sendClientData
M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate
M.raceCheckpoint = raceCheckpoint

M.chatLog = chatLog
M.syncGroup = syncGroup
M.rob = rob
M.robFail = robFail
M.teleportedFromBigmap = teleportedFromBigmap
return M
