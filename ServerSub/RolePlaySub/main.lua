-- Переменные
local professionsFilePath = "/home/container/Resources/Server/RolePlaySub/db/profs.json"
local CheckPointsFilePath = "/home/container/Resources/Server/RolePlaySub/db/CheckPoints.json"


local playerStates = {}
local user_carId
JobsActivite = {}
DostavkaActive = {}


local function extract_json_part(data)
    local json_part = data:match(":%b{}")
    if json_part then
        return json_part:sub(2)
    else
        return nil
    end
end


function getCheckPointDostavka(profs_pos, use_pos, user_id)
    local profsUser = getProfs(UserData(MP.GetPlayerName(user_id)).profs_id)
    local json_content = readJSON(CheckPointsFilePath)
    local points = json_content[profs_pos]
    local count = 0
    for _ in pairs(points) do
        count = count + 1
    end


    if DostavkaActive[user_id] then
        pay_use = true
    else
        DostavkaActive[user_id] = "unload"
        pay_use = false
    end
    if DostavkaActive[user_id] == "load" then
        DostavkaActive[user_id] = "unload"
        randPos = Util.RandomIntRange(1, count)
        data = points[profs_pos..randPos]

        pos_name = profs_pos..randPos
        pos_cord = {x=data[1],y=data[2],z=data[3]}
    
        local data = {pos = pos_cord, logic = "jobs", user_id = getIdByNick(MP.GetPlayerName(user_id)), name = pos_name}
        local data_json = json.encode(data)
        MP.TriggerClientEvent(user_id, "PackettrigerPost" ,data_json)

        MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Езжяйте на выгрузку"}))

    elseif DostavkaActive[user_id] == "unload" then
        DostavkaActive[user_id] = "load"
        pos_cord = profs.dostavkapos
        pos_name = "pohta"

        local data = {pos = pos_cord, logic = "jobs", user_id = getIdByNick(MP.GetPlayerName(user_id)), name = pos_name}
        local data_json = json.encode(data)
        MP.TriggerClientEvent(user_id, "PackettrigerPost" ,data_json)

        if pay_use == true then
            randBal = Util.RandomIntRange(150, 800)
            MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Вы получили "..randBal.."$ за работу"}))
            local new_bal = UserData(MP.GetPlayerName(user_id)).bal + randBal
            editUserData(getIdByNick(MP.GetPlayerName(user_id)),"bal", new_bal)
        end
        MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Езжяйте на погрузку"}))
    end

end

function getCheckPointMarshrute(profs_pos, use_pos, user_id)
    local json_content = readJSON(CheckPointsFilePath)
    local points = json_content[profs_pos]
    
    local pos_cord
    local pos_name

    profsUser = getProfs(UserData(MP.GetPlayerName(user_id)).profs_id)
    if use_pos == profsUser.spawnposname then
        data = points[profs_pos.."1"]
        pos_name = profs_pos.."1"
        pos_cord = {x=data[1],y=data[2],z=data[3]}
        MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Начинайте работать"}))
    else
        local strNumber = string.gsub(use_pos, profs_pos,"")
        local Number = tostring(tonumber(strNumber)+1)
        data = points[profs_pos .. Number]
        if data == nil then
            data = points[profs_pos.."1"]
            pos_name = profs_pos.."1"
            pos_cord = {x=data[1],y=data[2],z=data[3]}
        else
            data = points[profs_pos..Number]
            pos_name = profs_pos..Number
            pos_cord = {x=data[1],y=data[2],z=data[3]}
        end
        if data[4] ~= 0 then
            local new_bal = UserData(MP.GetPlayerName(user_id)).bal + data[4]
            editUserData(getIdByNick(MP.GetPlayerName(user_id)),"bal", new_bal)
            MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Вы получили ".. data[4] .."$ за работу"}))
        end
        
    end
    local data = {pos = pos_cord, logic = "jobs", user_id = getIdByNick(MP.GetPlayerName(user_id)), name = pos_name}
    local data_json = json.encode(data)
    MP.TriggerClientEvent(user_id, "PackettrigerPost" ,data_json)
end

-- Евенты

function triggerEvent(user_id, data_json)
    local data = json.decode(data_json)
    local car_id, beam_id, type, name = string.match(data.triggerName, "(%d+)_(%d+)_(%w+)_(%w+)")
    if tonumber(car_id) == tonumber(data.vehId) then
        local user_beam_id = getIdByNick(MP.GetPlayerName(user_id))
        if tonumber(user_beam_id) == tonumber(beam_id) then
            MP.TriggerClientEvent(user_id, "PacketDeleteCheckpoint", "")
            profs = getProfs(UserData(MP.GetPlayerName(user_id)).profs_id)
            if type == "jobs" then
                if JobsActivite[user_id] == "spawncar" then
                    local data = getProfs(UserData(MP.GetPlayerName(user_id)).profs_id).car
                    local data_json = json.encode(data)
                    MP.TriggerClientEvent(user_id, "CarReplacePacket", data_json)
                    JobsActivite[user_id] = os.date("%Y-%m-%d %H:%M:%S", os.time())
                    MP.TriggerClientEvent(user_id, "PacketProfsButtonUpdate" ,"В работе")
                end

                local checkpointname = profs.checkpointname
                local joblogic = profs.joblogic

                if joblogic == "marshrute" then
                    getCheckPointMarshrute(checkpointname, name, user_id)
                elseif joblogic == "dostavka" then
                    getCheckPointDostavka(checkpointname, name, user_id)
                elseif joblogic == "none" then
                    MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Начинайте работать."}))
                end
            end
        end    
    end
end

function TriggerJobsLogic(user_id, data_json)
    local data = json.decode(data_json)
    local veh_id, pos_name, user_id_pos = data.triggerName:match("(%d+)_(%a+)_(%d+)")

    print(user_id .." приехал на триггер ".. data.triggerName)
    MP.SendChatMessage(user_id, "Вы проехали триггер "..  data.triggerName);
    if tonumber(user_id_pos) == tonumber(user_id) then
        if tonumber(veh_id) == tonumber(data.vehId) then
            print("Машина та же")
            print(pos_name)
            MP.TriggerClientEvent(user_id,"PacketDeleteCheckpoint", "")
        else
            print("Другая машина")
        end
    else
        print("Вы невладелец тригера")
    end
end

function onInit()
    MP.RegisterEvent("TriggerJobs", "TriggerJobsLogic")
    MP.RegisterEvent("onVehicleSpawn", "spawnVeh")
    MP.RegisterEvent("TriggerEventSener", "triggerEvent")
    MP.RegisterEvent("onChatMessage", "CommandInChat");
end


-- Таблица данных
local data = {
    bus = {
        bus1 = {10, 50, 0, 0},
        bus2 = {50, 50, 0, 0},
        bus3 = {50, 10, 0, 0},
        bus4 = {10, 10, 0, 100}
    },
    bus2 = {
        bus21 = {10, 50, 0, 0},
        bus22 = {50, 50, 0, 0},
        bus23 = {50, 10, 0, 0},
        bus24 = {10, 10, 0, 100}
    }
}


function findPos(busName)
    for category, poses in pairs(data) do
        if poses[busName] then
            local Data = poses[busName]
            return {
                name = busName,
                pos = {Data[1], Data[2], Data[3]},
                pay_day = Data[4]
            }
        end
    end
    return nil
end

function CheckPointInfo(name)
    local PosInfo = findPos(name)
    if PosInfo then
        trigger = string.format("name = \"%s\", pos = {%d, %d, %d}, pay_day = %d", PosInfo.name, PosInfo.pos[1], PosInfo.pos[2], PosInfo.pos[3], PosInfo.pay_day)
    end
    newPosName = getNextPos(name)
    newPos = findPos(newPosName)
    if newPos then
        print("")
    else
        newPosName = getEndPos(name)
        newPos = findPos(newPosName)
    end
    new_trigger = string.format("name = \"%s\", pos = {%d, %d, %d}, pay_day = %d", newPos.name, newPos.pos[1], newPos.pos[2], newPos.pos[3], newPos.pay_day)
    data = {
        [0] = trigger,
        [1] = new_trigger
    }
    return data
end
print(CheckPointInfo("bus1")[0])

