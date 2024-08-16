local M = {}
M.info = "Система Связи Discord"
M.ver = "BETA 0.4"
long_tasks = {}

function GetFile()
    if FS.Exists("Resources/Server/transf_data/") == false then
        log("Автоматическое создание папки",4)
        FS.CreateDirectory("Resources/Server/transf_data/")
    end
    local fileList = FS.ListFiles("Resources/Server/transf_data/")
    for _, file in pairs(fileList) do
        local data = read_td(file)
        MyCmdHandler("!"..data)
    end
end

function GetLongTask()
    if FS.Exists("Resources/Server/long_task/") == false then
        log("Автоматическое создание папки",4)
        FS.CreateDirectory("Resources/Server/long_task/")
    end
    local fileList = FS.ListFiles("Resources/Server/long_task/")
    for _, file in pairs(fileList) do
        if long_tasks[file] == nil then
            local data = read_td(file)
            if data:sub(0,1) ~= "!" then
                data = "!"..data
            end
            long_tasks[file] = {command = data, time = split(file,".")[1]}
        end
    end

    for file, data in pairs(long_tasks) do
        if os.time() >= data.time then
            MyCmdHandler(data.command)
            FS.Delete("Resources/Server/long_task/"..file)
            long_tasks[file] = nil
        end
    end
end

M.command = {}
function M.load()
    HeventTimer.addFunc(GetLongTask, 10)
    HeventTimer.addFunc(GetFile, 10)
end

function M.unload()
end

return M

