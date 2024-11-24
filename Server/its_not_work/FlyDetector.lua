-- Enter the speeds where the player will be warned and kicked in MPH
WarnSpeed = 180
KickSpeed = 200

MP.CancelEventTimer("FlyDetector", 1000)
MP.RegisterEvent("FlyDetector", "Main")
MP.CreateEventTimer("FlyDetector", 1000)

Players, PlayerCars, PlayerVelocities, PlayerSpeeds = {}, {}, {}, {}

function Judge(speed, playerID)
    if speed > KickSpeed then
        return MP.DropPlayer(playerID, "You were kicked for going too fast!")
    end
    if speed > WarnSpeed then
        return MP.SendChatMessage(playerID, "You're going too fast! Slow down!")
    end
end

function Main()
    Players = MP.GetPlayers()

    for i, v in pairs(Players) do
        PlayerCars[i] = MP.GetPlayerVehicles(i)
        if not PlayerCars[i] then goto skipPlayer end

        for j, _ in pairs(PlayerCars) do
            if not PlayerVelocities[i] then PlayerVelocities[i] = {} end

            if not MP.GetPositionRaw(i, j) then goto skipCar end

            PlayerVelocities[i][j] = MP.GetPositionRaw(i, j).vel

            if not PlayerSpeeds[i] then PlayerSpeeds[i] = {} end

            PlayerSpeeds[i][j] = math.floor(math.sqrt(PlayerVelocities[i][j][1]^2 + PlayerVelocities[i][j][2]^2 + PlayerVelocities[i][j][3]^2) * 2.2369362912)

            Judge(PlayerSpeeds[i][j], i)

            ::skipCar::
        end
        ::skipPlayer::
    end
end
