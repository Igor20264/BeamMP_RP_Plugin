local M = {}

local raceWaypoints = {}
local currentWaypoint = 0

-- race countdown stuff
local timeElapsed = 0
local countingDown = false
local highestCountedDown = 0
--

local raceColor = {1, 0.3, 0}

local IS_IN_RACE = false

local function startRace(payload)
  local waypointArray = jsonDecode(payload)
  raceWaypoints = waypointArray

  countingDown = true
  IS_IN_RACE = true

  core_input_actionFilter.setGroup(
    "carpRaceCountdownBlocks",
    {
      "reset_physics",
      "reset_all_physics",
      "recover_vehicle",
      "recover_vehicle_alt",
      "recover_to_last_road"
    }
  )
  core_input_actionFilter.addAction(0, "carpRaceCountdownBlocks", true)
end

local function cleanUpRace()
  -- delet all waypoints
  carp_poi.deleteMissionGroup("CarpraceTriggersGroup")

  playCarpSound("audio/racecomplete.ogg")

  IS_IN_RACE = false

  carp_groundmarkers.clearFocus()
end

-- this is so the server can cancel the race for the client
local function forceFinishRace()
  TriggerServerEvent("genericMessageSender", "Race Complete.")

  cleanUpRace()
end

local function finishRace(racePayload)
  dump(racePayload)
  print("---------------------------- FINISH RACE CALLED OH MY GOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOD")

  if MPVehicleGE.isOwn(racePayload.subjectID) and racePayload.event == "enter" then
    print("---------------------------- YEAH THIS IS US, CLEAN UP AND")

    cleanUpRace()

    -- trigger server event
    print("---------------------------- SEEEEEEEEEEEEND IT")
    TriggerServerEvent("receiveFinishRace", "nonempty")
  end
end

local function showNextWaypoint(racePayload)
  local triggerName = racePayload.triggerName

  if MPVehicleGE.isOwn(racePayload.subjectID) and racePayload.event == "enter" then
    if triggerName == "race-" .. currentWaypoint .. "_trigger" then
      if (racePayload.event == "enter") then
        Engine.Audio.playOnce("AudioGui", "event:UI_Checkpoint")

        -- clean up
        carp_poi.deleteMissionGroup("CarpraceTriggersGroup")

        -- increate currentWaypoint by 1
        currentWaypoint = currentWaypoint + 1
        local plusOne = currentWaypoint + 1

        local nextWaypoint = raceWaypoints[currentWaypoint]
        local secondNextWaypoint = raceWaypoints[plusOne]

        -- spawn next waypoint
        if nextWaypoint then
          local coords = stringToTable(raceWaypoints[currentWaypoint], "|")
          coords[1] = tonumber(coords[1])
          coords[2] = tonumber(coords[2])
          coords[3] = tonumber(coords[3])

          carp_groundmarkers.setDestination(vec3(coords), raceColor)

          if secondNextWaypoint then
            carp_poi.carpSpawnWaypoint("race-" .. currentWaypoint, currentWaypoint, raceWaypoints[currentWaypoint])
            carp_poi.carpSpawnWaypoint(
              "race-" .. plusOne,
              currentWaypoint,
              raceWaypoints[plusOne],
              {isNotActiveWaypoint = true}
            )
          else
            carp_poi.carpSpawnWaypoint(
              "race-" .. currentWaypoint,
              currentWaypoint,
              raceWaypoints[currentWaypoint],
              {isLastWaypoint = true}
            )
          end
        end
      end
    else
      TriggerServerEvent("genericMessageSender", "Wrong checkpoint! You're at " .. triggerName)
    end
  end
end

local function clearAllRaceWaypoints()
  carp_poi.deleteMissionGroup("CarpraceTriggersGroup")
end

local function onExtensionLoaded()
    AddEventHandler("startRace", startRace)
    AddEventHandler("forceFinishRace", forceFinishRace)
    AddEventHandler("clearAllRaceWaypoints", clearAllRaceWaypoints)
    print("[CaRP Race <><] Ready!")
    log("I", "onExtensionLoaded", "carp_race loaded.")
end

local function spawnFirstWaypoints()
  carp_poi.deleteMissionGroup("CarpraceTriggersGroup")
  carp_poi.deleteMissionGroup("CarpracestartTriggersGroup")

  -- set to 1, first item in the array
  currentWaypoint = 1

  -- only spawn the first two. i am a developer by trade btw
  carp_poi.carpSpawnWaypoint("race-1", "race-1", raceWaypoints[1])
  carp_poi.carpSpawnWaypoint("race-2", "race-2", raceWaypoints[2], {isNotActiveWaypoint = true})

  local coords = stringToTable(raceWaypoints[1], "|")
  for idx, value in pairs(coords) do
    coords[idx] = tonumber(value)
  end
  carp_groundmarkers.setDestination(vec3(coords), raceColor)

  Engine.Audio.playOnce("AudioGui", "event:UI_CountdownGo")
  carp.playCarpSound("audio/hello-14.ogg", 7)
end

local vehicleFreezeState = nil
local function freezeVehicle(disabled)
  if vehicleFreezeState == disabled then
    return
  end

  vehicleFreezeState = disabled

  local playerVehicle = be:getPlayerVehicle(0)
  if playerVehicle then
    playerVehicle:queueLuaCommand("controller.setFreeze(" .. tostring((disabled and 1) or 0) .. ")")
  else
    print("could not find player veh wew can't freeze it if we can't find it :joy:")
  end
end

local function setThrottleKeyDisabled(bool)
  freezeVehicle(bool)

  -- core_input_actionFilter.setGroup("carpBlockThrottle",
  --   {
  --     "accelerate",
  --     "accelerate_brake",
  --     "brake",
  --     "steering",
  --     "steer_left",
  --     "steer_right"
  --   }
  -- )

  -- core_input_actionFilter.addAction(0, "carpBlockThrottle", bool)
end

local function onUpdate(dtReal, dtSim, dtRaw)
  if not countingDown then
    return
  end

  setThrottleKeyDisabled(true)

  timeElapsed = timeElapsed + dtReal

  -- go!
  if timeElapsed >= 4 then
    timeElapsed = 0
    countingDown = false
    highestCountedDown = 0

    core_input_actionFilter.setGroup(
      "carpRaceCountdownBlocks",
      {
        "reset_physics",
        "reset_all_physics",
        "recover_vehicle",
        "recover_vehicle_alt",
        "recover_to_last_road"
      }
    )
    core_input_actionFilter.addAction(0, "carpRaceCountdownBlocks", false)

    setThrottleKeyDisabled(false)

    spawnFirstWaypoints()
  elseif timeElapsed > highestCountedDown + 1 then
    if highestCountedDown == 0 then
      carp.playCarpSound("audio/reverso.ogg", 7)
    end

    highestCountedDown = highestCountedDown + 1

    local msg = (4 - highestCountedDown) .. "..."
    local duration = 0.8
    guihooks.trigger("ScenarioFlashMessage", {{msg, duration}})

    Engine.Audio.playOnce("AudioGui", "event:UI_Countdown1")
  end
end

local function isInRace()
  return IS_IN_RACE
end

M.onExtensionLoaded = onExtensionLoaded
M.showNextWaypoint = showNextWaypoint
M.finishRace = finishRace
M.onUpdate = onUpdate
M.isInRace = isInRace

return M
