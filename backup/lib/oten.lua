local Module = {}
database_player = {}
local Player = require "lib.player"
local shablon = {
money = 1000, work = {name = "Безработынй",money = 1000,on_works = false}, perm = 1
}

function Module:import()
    old_database_player = load_database("economica.ixt")
    for i,case in ipairs(old_database_player) do
        pl = Player:init(-1,shablon,eco.database,true)
        pl:create(case[1],{money = case[2]+case[4],work = {name = case[3],money = case[4],on_works = false},perm = 1}) --name,$,payday,bank$,WorkName,taxIP
    end
    pl = Player:init(-1,shablon,eco.database)
    eco:save()
end

return Module