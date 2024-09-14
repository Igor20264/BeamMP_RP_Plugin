local M = {}
M.info = "CheckCheater"
M.ver = "1.0"
send_ansfer ={}

function whileCheckCheater()
    for id,name in pairs(online_player) do
        if send_ansfer[name] == nil then
            send_ansfer[name] = os.time()
        end
        RemoutRun(id,"TriggerServerEvent('IMMOD','okey')")
    end
    if send_ansfer == nil then
        return
    end
    for name,times in pairs(send_ansfer) do
        if math.abs(os.time() - times) > 60 then
            if MP.check_in_online(name) then
                MP.DropPlayer(MP.GetId(name),"Ошибка: L0 x48")
                send_ansfer[name] = nil
            else
                send_ansfer[name] = nil
            end
        end
    end
end

function IMMODhor(id,data)
    local name = MP.GetPlayerName(id)
    if data == "okey" then
        print(name,id,"okey")
    end
    send_ansfer[name] = os.time()
end

M.command = {
    {client = true, reg = "IMMOD", func = "IMMODhor"},
}

function M.load()
    HeventTimer.addFunc(whileCheckCheater, 5)
end

function M.unload()
end

return M