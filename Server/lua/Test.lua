local M = {}
M.curcle = 0
M.data = {}
function foriin()
    if not FS.Exists(M.pluginPath.."/database/test.test") then
        forced_save_database("test.test",eco.database)
    end
    local start = os.time()
    for i = 1, 200 do
        M.curcle = M.curcle+1
        start = os.time()
        M.data[M.curcle] = load_database("test.test")
        files.verify("test.test",M.data)
        log({"На 1 проверку",os.time() - start,"сек. | ",M.curcle,"цикл"},4)
    end
end

function M.load()
    MP.RegisterEvent("FASTER_TEST", "foriin")
    MP.CreateEventTimer("FASTER_TEST", 200) -- ms
    --HeventTimer.addFunc(foriin,1) -- раз в 10 минут
end

function M.unload()
end

return M