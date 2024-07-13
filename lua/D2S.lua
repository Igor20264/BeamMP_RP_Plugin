local M = {}
M.info = "Система Связи Discord"
M.ver = "BETA 0.4"

function GetFile()
    local fileList = FS.ListFiles("Resources/Server/transf_data/")
    for _, file in pairs(fileList) do
        local data = read_td(file)
        MyCmdHandler("!"..data)
    end
end

M.command = {}
function M.load()
    HeventTimer.addFunc(GetFile, 10)
end

function M.unload()
end

return M

