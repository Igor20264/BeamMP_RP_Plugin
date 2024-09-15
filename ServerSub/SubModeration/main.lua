-- Импорты
local json = require("plugins.json")

local bannedjson = "/home/container/Resources/Server/SubModeration/banned.json"

-- Функции
local function readJSON(filePath)
    local file = io.open(filePath, "r")
    if not file then return {} end
    local content = file:read("*a")
    file:close()
    return json.decode(content)
end

local function writeJSON(filePath, data)
    local file = io.open(filePath, "w")
    file:write(json.encode(data))
    file:close()
end

-- 3.6 секунд
function Connecting_users(player_id)
    local data = readJSON(bannedjson)

    if MP.IsPlayerGuest(player_id) then
        MP.DropPlayer(player_id, "Вход возможен только с аккаунта")
        return
    end

    local player_data = MP.GetPlayerIdentifiers(player_id)
    local beammp_id = player_data.beammp

    if beammp_id and data[beammp_id] then
        MP.DropPlayer(player_id, "Вы забанены на этом сервере.")
        return
    end
end

function handleConsoleInput(cmd)
    local delim = cmd:find(' ')
    if delim then
        local command = cmd:sub(1, delim-1)
        local message = cmd:sub(delim+1)

        if command == "ban" then
            local player_id = tonumber(message)
            if player_id then
                local player_data = MP.GetPlayerIdentifiers(player_id)
                local beammp_id = player_data.beammp

                if beammp_id then
                    local data = readJSON(bannedjson)
                    data[beammp_id] = true
                    writeJSON(bannedjson, data)
                    MP.TriggerClientEvent(player_id, "PacketBannedSub" ,"")
                    MP.Sleep(3600)
                    MP.DropPlayer(player_id, "Вы были забанены на этом сервере.")
                    print(beammp_id .. " забанен.")
                else
                    print("Player ID " .. player_id .. " does not have a valid BeamMP ID.")
                end
            else
                print("Invalid player ID.")
            end
        end
    end
end

function onInit()
    MP.RegisterEvent("onConsoleInput", "handleConsoleInput")
    MP.RegisterEvent("onPlayerConnecting", "Connecting_users")
    
    print("----------------------")
    print("SubModeration | System Started")
    print("Version | v0.0.1")
    print("Power by | Subterrania Team")
    print("Coder | Jastickon")
    print("----------------------")
end
