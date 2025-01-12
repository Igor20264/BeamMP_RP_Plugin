local M = {}
M.efunc = {}
M.times = 1 -- seconds
M.info = "Система Продвинутых таймеров"
M.ver = "0.3 Beta"
local tasker = M.tasker or {}
local endtask = M.endtask or {}

local function task(time,func,hextag,...) -- sec, func, tag
    log("Добавлена задача: "..tostring(func).." "..hextag,2)
    table.insert(tasker,{end_time = timer.get()+time,func = func,tag=hextag,data = {...}})
end

local function canceltask(hextag)
    for i,tasks in ipairs(tasker) do
        if tasks.tag == hextag then
            tasker[i] = nil
            log("Задача отменена: "..tasks.func.." "..tasks.tag,2)
        end
    end
end

local function getendtask(hextag)
    for i,tasks in ipairs(endtask) do
        if tasks.tag == hextag then
            return tasks
        end
    end
end

local function getallendtask()
    return endtask
end

local function addFunc(func, interval)
    interval = interval or 1
    table.insert(M.efunc,{func,interval})
end

local function remFunc(func)
    for i,f in ipairs(M.efunc) do
        if f[1] == func then
            table.remove(M.efunc,i)
        end
    end
end

local function runFunc()
    for i,f in ipairs(M.efunc) do
        if M.times % f[2] == 0 then
            try_exept(f[1])
        end
    end
end

local function CreateTimer(func,interval,event_name,callstrategy)
    interval = interval or 1000
    event_name = event_name or Gen.uuid()
    callstrategy = callstrategy or MP.CallStrategy.BestEffort -- MP.CallStrategy.Precise
    MP.CancelEventTimer(event_name)
    MP.RegisterEvent(event_name, func)
    MP.CreateEventTimer(event_name, 1000)
end

CreateTimer("eventtimerAll",1000,'TimerEventAllinOne')

function eventtimerAll()
    M.times = M.times + 1
    if #M.efunc ~= 0 then
        runFunc()
    end
    if M.times % 3600 == 0 then --каждый час обнуляем
        M.times = 0
    end
end

function kernel_thread()
    if #tasker == 0 then return end
    for i,tasks in ipairs(tasker) do
        if tasks.end_time <= timer.get() then
            tasker[i] = nil
            local data = try_exept(tasks.func,table.unpack(tasks.data))
            endtask[i] = {end_time = tasks.end_time, hextag = tasks.tag,curret_time_end = timer.get(),returnd = data,func = tasks.func,data = tasks.data}
            log("Задача завершена: "..tostring(tasks.func).." "..tasks.tag,2)
        end
    end
    for i,tasks in ipairs(endtask) do
        if tasks.curret_time_end+(60*10) <= timer.get() then
            endtask[i] = nil
        end
    end
end

addFunc(kernel_thread,1)

M.addFunc = addFunc
M.remFunc = remFunc
M.CreateTimer = CreateTimer

M.Createtask = task
M.Canceltask = canceltask
M.getendtask = getendtask
M.getallendtask = getallendtask
return M
