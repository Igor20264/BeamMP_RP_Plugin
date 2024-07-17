local M = {}
local DB = require "lib.database"
local GEO = require "lib.geo"
M.info = "Экономическая система"

M.ver = "1.0"

local function sort_by_distancse(not_sorted,sort_offset)
        sort_offset = sort_offset or false
        local sort_by_distancse_list = {}
        for uuid,data in pairs(not_sorted) do
            local len = #sort_by_distancse_list+1
            sort_by_distancse_list[len] = data
            sort_by_distancse_list[len].uuid = uuid
        end
        if sort_offset == true then
            table.sort(sort_by_distancse_list,function(a,b) return a.distancse > b.distancse end)
        else
            table.sort(sort_by_distancse_list,function(a,b) return a.distancse < b.distancse end)
        end

        return sort_by_distancse_list
    end

-- Система координат
local geo = {}

function geo:new_point(nickname,work,x1,y1,z1,x2,y2,z2)-- str,bool,float,float,float,float
    local uuid = Gen.uuid()
    if self.database[uuid] ~= nil then
        uuid = Gen.uuid()
    end
    local database = self.database or gps.database
    database[uuid] = {nickname = nickname,type={work=work,public=false},geo = {{x=x1,y=y1,z=z1},{x=x2,y=y2,z=z2}}}
    self:save()
end

function geo:get_uuid_by_nickname(nickname)
    local database = self.database or gps.database
    for uuid,data in pairs(database) do
        if data.nickname == nickname then
            return uuid
        end
    end
end

function geo:get_len()
    local l = 0
    local database = self.database or gps.database
    for uuid, name in pairs(database) do
        l = l + 1
    end
    return l
end

function geo:get_table_by_distancse(px,py,min_dist)
    min_dist = min_dist or 10
    local temp = {}
    for uuid,data in pairs((self.database or gps.database)) do
        l1 = data.geo[1]
        l2 = data.geo[2]
        if data.type.work == true and GEO.Rectangle(l1.x,l1.y,l2.x,l2.y,px,py) == false then
            local distancse = GEO.minDistancePointRect(l1.x,l1.y,l2.x,l2.y,px,py)
            --local distancse1 = math.min(GEO.Distance(l1.x,l1.y,px,py),GEO.Distance(l2.x,l2.y,px,py))
            if distancse >= min_dist then
                temp[uuid] = data
                temp[uuid].distancse = distancse
            end
        end
    end
    -- sort by distancse

    temp = sort_by_distancse(temp)
    return temp
end

function geo:get_random(px,py,min_dist)
    min_dist = min_dist or 10
    local temp = geo:get_table_by_distancse(px,py,min_dist)
    local s = Util.RandomIntRange(#temp//2,#temp)
    return temp[s].uuid
end

function geo:set_random_path(player)
    local x,y,z = GEO.getPos(MP.GetId(player))
    local uuid = geo:get_random(x,y,300)
    geo:set_active_path(player,uuid)
    local database = self.database or gps.database
    return GEO.Distance(x,y,database[uuid].geo[1].x,database[uuid].geo[1].y)*1.5,uuid
end

function geo:update_active_path(player,uuid)
    local database = self.database or gps.database
    print(database[uuid])
    local x,y,z = midPoint(database[uuid].geo[1].x,database[uuid].geo[1].y,database[uuid].geo[1].z or 0,database[uuid].geo[2].x,database[uuid].geo[2].y,database[uuid].geo[2].z or 0)
    RemoutRun(player,"core_groundMarkers.setFocus(vec3("..x..","..y..","..z.."))")
end

function geo:set_active_path(player,uuid)
    local database = self.database or gps.database
    local x,y,z = GEO.midPoint(database[uuid].geo[1].x,database[uuid].geo[1].y,database[uuid].geo[1].z,database[uuid].geo[2].x,database[uuid].geo[2].y,database[uuid].geo[2].z)
    RemoutRun(player,"core_groundMarkers.setFocus(vec3("..x..","..y..","..z.."))")
end

function geo:remove_active_path(player)
    RemoutRun(player,"core_groundMarkers.resetAll()")
end

function geo:get_user_in_point()
    local ret = {}
    for id,name in pairs(MP.GetPlayers()) do
        local x,y,z = GEO.getPos(id,GEO.getActiveVehicle(id))
        print(x,y,z)
        for uuid,data in pairs((self.database or gps.database)) do
            if GEO.Rectangle(data.geo[1].x,data.geo[1].y,data.geo[2].x,data.geo[2].y,x,y) then
                ret[name] = uuid
            end
        end
    end
    return ret
end

function geo:get_public_points()
    local temp = {}
    local database = self.database or gps.database
    for uuid,data in pairs(database) do
        if data.type.public == true then
            temp[#temp+1] = data
        end
    end
    temp = sort_by_distancse(temp)
    return temp
end
extended(geo,DB)
--[[
type_gep = круг, квадрад
uuid = {nickname= str, type = {work = bool, cam = bool}, geo = {0={x=float,y=float,z=float},2={x=float,y=float,z=float}}}

--]]

gps = geo:init("points.ixt")
M.gps = gps

-- System

--detect veh in point by pos

-- USER COMMAND [[

function GPS_GET_POS(sender_id,sender_name, message)
    local x,y,z = 0,0,0
    if sender_id ~= -2 then
        local player,vehicle = GEO.getActiveVehicle(sender_id)
        x,y,z = GEO.getPos(player,vehicle)
    end
    SendMessage(sender_id, "Текущая позиция: x = "..round(x,2).." | y = "..round(y,2).." | z = "..round(z,2))
end

function GEO_GET_ALL(sender_id, sender_name, message)
    local list_sep = 10
    if tonumber(message) == nil then
        message = 1
    end
    local skip = (tonumber(message)-1)*10
    local ret = "Точки отсортированы по дистанции: \n"
    local x,y,z = 0,0,0
    if sender_id ~= -2 then
        local player,vehicle = GEO.getActiveVehicle(sender_id)
        x,y,z = GEO.getPos(player,vehicle)
    end
    local list = gps:get_table_by_distancse(x,y,0,true)
    for i,data in pairs(list) do
        if i > skip then
            if list_sep == 0 then
                ret = ret.."\n"
                string.sub(ret,#ret-1,#ret)
                SendMessage(sender_id, ret)
                return
            end
        list_sep = list_sep-1
        local public = "Нет"
        if list[i].type.public then
            public = "Да"
        end
        ret = ret..list[i].nickname..": "..round(list[i].distancse,2).."м. | public = "..public.."\n"
        end
    end
    if ret == "Точки отсортированы по дистанции: \n" then
        SendMessage(sender_id, "Нет точек")
    else
        string.sub(ret,#ret-1,#ret)
        SendMessage(sender_id, ret)
    end
end

function GEO_ADD_WORK(sender_id, sender_name, message) -- name x1 y1 z1 x2 y2 z2
    local case = split(message," ")
    local name = case[1]
    local x1 = tonumber(case[2])
    local y1 = tonumber(case[3])
    local z1 = tonumber(case[4])
    local x2 = tonumber(case[5])
    local y2 = tonumber(case[6])
    local z2 = tonumber(case[7])
    if x1 == nil or y1 == nil or z1 == nil or x2 == nil or y2 == nil or z2 == nil then
        SendMessage(sender_id, "Неверные данные")
        return
    end
    gps:new_point(name,true,x1,y1,z1,x2,y2,z2)
    SendMessage(sender_id, "Точка "..name.." добавлена")
end

function GEO_GET_INFO(sender_id, sender_name, message) -- name
    local name = message
    local uuid = gps:get_uuid_by_nickname(name)
    if data == nil then
        SendMessage(sender_id, "Точка не найдена")
        return
    end
    local data = gps.database[uuid]
    local ret = "Точка "..name..": \n"
    ret = ret.."point 1:".."x = "..data.geo[1].x.." | y = "..data.geo[1].y.." | z = "..data.geo[1].z.."\n"
    ret = ret.."point 2:".."x = "..data.geo[2].x.." | y = "..data.geo[2].y.." | z = "..data.geo[2].z.."\n"
    ret = ret.."public = "..tostring(data.type.public).."\n"
    ret = ret.."work = "..tostring(data.type.work).."\n"
    ret = ret.."uuid = ".. uuid
    SendMessage(sender_id, ret)
end

function GEO_DELETE_POINT(sender_id, sender_name, message) -- name
    local name = message
    local uuid = gps:get_uuid_by_nickname(name)
    if data == nil then
        SendMessage(sender_id, "Точка не найдена")
        return
    end
    gps:delete(uuid)
    SendMessage(sender_id, "Точка "..name.." удалена")
end

function GEO_SET_POINT(sender_id, sender_name, message) -- point_name type true/false
    local case = split(message," ")
    local name = case[1]
    local uuid = gps:get_uuid_by_nickname(name)
    if data == nil then
        SendMessage(sender_id, "Точка не найдена")
        return
    end
    case[1] = nil
    local type = case[2]
    if case[3] == "true" or case[3] == "1" then
        case[3] = true
    elseif case[3] == "false" or case[3] == "0" then
        case[3] = false
    end
    local edit = gps:set(uuid,"type",table.unpack(case))
    SendMessage(sender_id, "Точка "..name.." изменена "..edit)
end

function fitCube(name,corner1, corner2)
    local x,y,z = (corner1.x + corner2.x) / 2, (corner1.y + corner2.y) / 2, (corner1.z + corner2.z) / 2
    local distanceX = math.abs(corner1.x - corner2.x)
    local distanceY = math.abs(corner1.y - corner2.y)
    local distanceZ = math.abs(corner1.z - corner2.z)
    ret = 'local nm = createObject("TSStatic"); nm:setPosition(vec3('..x..','..y..','..z..'));nm:setField("shapeName",0,"/art/shapes/interface/checkpoint_marker.dae");nm:registerObject("'..name..'");nm.scale = vec3('..distanceX..','..distanceY..','..distanceZ..');nm:setField("canSave",0,"0");nm:setField("collisionType",0,"None");scenetree.MissionGroup:addObject(nm)'
    return ret
end

function Otk(user_id)
    HeventTimer.Createtask(5,SPAWN_ALL_OBJECT,user_id.."SpawnObject",user_id)
end

function SPAWN_ALL_OBJECT(user_id)
    print("IM RUN")
    for id,data in pairs(gps:get_table_by_distancse(0,0,0)) do
        if data.type.work == true or data.type.public == true then
            local s = fitCube(data.nickname,data.geo[1],data.geo[2])
            print(s)
            RemoutRun(user_id,s)
        end
    end
end

--HeventTimer.Createtask(5,SPAWN_ALL_OBJECT,(0).."SpawnObject",0)

-- LOAD PEREMENNI

M.command = {
    {category = "gps", command = "get", help = "Получить текущую позицию",args = "",roles = {"admin"},func = "GPS_GET_POS"},
    {category = "gps", command = "list", help = "Получить список точке для построения маршрута",args = "",roles = {"tester"},func = "GPS_GET_ALL"},

    {category = "geo", command = "list",help = "Получить список всех точек | дальность от пользователя", args = "[list 1/2/3/4/...]",roles = {"admin"},func = "GEO_GET_ALL"},
    {category = "geo", command = "info",help = "Получить информаци о точке", args = "[geo_nick]",roles = {"admin"},func = "GEO_GET_INFO"},
    {category = "geo", command = "add_work", help = "Создать область работы !! Предпологаемый цент области должен быть пуст !!", args = "[named] [x1] [y1] [z1] [x2] [y2] [z2]",roles = {"admin"},func = "GEO_ADD_WORK"},
    {category = "geo", command = "del", help = "Удалить точку", args = "[geo_nick]",roles = {"admin"},func = "GEO_DELETE_POINT"},
    {category = "geo", command = "set", help = "Изменить данные о точке", args = "[geo_nick_type] [data]",roles = {"admin"},func = "GEO_SET_POINT"},
}

function M.load()
    MP.RegisterEvent("onPlayerJoin","Otk")
	--M.command = RegEvent(M.command)
end

function M.unload()
end

return M