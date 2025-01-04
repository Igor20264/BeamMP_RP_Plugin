local M = {}

local function is_integer(num)
    return num == math.floor(num)
end

local function round_color(value)
    if type(value) == "number" then
        if is_integer(value) then
            return value
        end
        return tonumber(string.format("%.4f", value))
    else
        return value
    end
end

local function TryReadDetail(etk, partName, jsonStr)
    -- Формируем шаблон для поиска ключа, который начинается с etk_ и содержит partName
    local pattern = '"' .. etk .. "_[^:]*" .. partName .. '[^:]*":"([^"]+)"'

    -- Ищем значение в JSON-строке
    local value = jsonStr:match(pattern)

    -- Если значение найдено, убираем префикс etk_
    if value then
        value = value:gsub("^" .. etk .. "_", "")
    end

    -- Возвращаем результат
    return value
end

local function parsParts(StrJson)
    local json_data = Util.JsonDecode(StrJson)
    local jbeam = json_data.jbm
    local pid = json_data.pid
    local ign = json_data.ign
    local rot = json_data.rot or {} -- 4 floats table
    local pro = json_data.pro
    local pos = json_data.pos or {} -- 3 floats table
    local vid = json_data.vid or {}
    local mainPartName = json_data.vcf.mainPartName or json_data.vcf.partConfigFilename:match("/(.-)/.*%.pc") or jbeam
    if json_data.vcf.mainPartName == nil then
        json_data.vcf.mainPartName = mainPartName
    end

    for i,item in pairs(json_data.vcf.paints) do
        for j,color in pairs(item.baseColor) do
            item.baseColor[j] = round_color(color)
        end
        if item.roughness ~= nil then
            item.roughness = round_color(item.roughness)
        end
        if item.clearcoat ~= nil then
            item.clearcoat = round_color(item.clearcoat)
        end
        if item.metallic ~= nil then
            item.metallic = round_color(item.metallic)
        end
        if item.clearcoatRoughness ~= nil then
            item.clearcoatRoughness = round_color(item.clearcoatRoughness)
        end
    end
    local vcf = json_data.vcf
    local vcfStr = Util.JsonEncode(vcf)
    local engine = TryReadDetail(mainPartName,"engine",vcfStr) or "nil"
    local transmission = TryReadDetail(mainPartName,"transmission",vcfStr) or TryReadDetail(mainPartName,"transaxle",vcfStr) or "nil"
    local transfer_case = TryReadDetail(mainPartName,"transfer_case",vcfStr) or "nil"
    local full = true
    if (engine == "nil" and transmission == "nil") then
        full = false
    end
    local base_parts = {
        partConfig = vcf.partConfigFilename,
        engine = engine,
        transmission = transmission,
        transfer_case = transfer_case,
        isFullConfig = full,
        mainPartName = mainPartName
    }

    local output = {
        vcf = {
            parts = table,
            model = str,
            partConfigFilename = str,
            paints = {
                N = {
                    baseColor = {
                        N0 = float, -- r
                        N1 = float, -- g
                        N2 = float, -- b
                        N3 = float -- a
                    },
                    roughness = float,
                    clearcoat = float,
                    metallic = float,
                    clearcoatRoughness = float
                }
            },
            vars = table,
            mainPartName = str,
        },
        base_parts = {
            partConfig = str,
            engine = str,
            transmission = str,
            transfer_case = str,
            isFullConfig = bool,
            mainPartName = str
        }
    }

    return {
        jbm = jbeam,
        pid = pid,
        ign = ign,
        rot = rot,
        pro = pro,
        pos = pos,
        vid = vid, -- vehicle id (in game)
        vcf = vcf,
        vcfStr = vcfStr,
        base = base_parts
    }
end

local function updateBaseData(vcf)
    local strVcf = Util.JsonEncode(vcf)
    local engine = TryReadDetail(vcf.mainPartName,"engine",strVcf) or "nil"
    local transmission = TryReadDetail(vcf.mainPartName,"transmission",strVcf) or TryReadDetail(vcf.mainPartName,"transaxle",strVcf) or "nil"
    local transfer_case = TryReadDetail(vcf.mainPartName,"transfer_case",strVcf) or "nil"
    local full = true
    if (engine == "nil" and transmission == "nil") then
        full = false
    end

    local base_parts = {
        partConfig = vcf.partConfigFilename,
        engine = engine,
        transmission = transmission,
        transfer_case = transfer_case,
        isFullConfig = full,
        mainPartName = vcf.mainPartName
    }
    return base_parts
end

local function basesplit(inputStr)
    local role, username, playerId, vehServerId, json_data = inputStr:match("^(.-):(.-):(.-)%-(.-):(.*)$")
    local parsedData = parsParts(json_data)
    parsedData.username = username
    parsedData.playerId = playerId
    parsedData.vehServerId = vehServerId
    return parsedData
end

local function updateParts(inputStr)
    local playerId, vehServerId, json_data = inputStr:match("^(.-)%-(.-):(.*)$")
    local parsedData = parsParts(json_data)
    parsedData.username = MP.GetPlayerName(tonumber(playerId))
    parsedData.playerId = playerId
    parsedData.vehServerId = vehServerId
    return parsedData
end

-- Экспорт функции
M.updateBaseData = updateBaseData
M.vehicleParser = basesplit
M.updateParts = updateParts
return M

--[[

local function AdditionalInfo(parsedData)
    parsedData.coast = CarCoast[parsedData.vcf.partConfigFilename]
    parsedData.carName = cars_name[parsedData.jbm] or parsedData.vcf.mainPartName
    parsedData.category = cars_category[parsedData.jbm]
    parsedData.licenss_plate = parsedData.vcf.licenseText or parsedData.vcf.licenss_plate
    return parsedData
end
self.database[owner][uuid] = {
        licenss_plate = Generator.numberPlate(),
        coast = car.coast,
		former_owners = {},
        name = car.carName,
        category = car.category,
        jbm = car.jbm,
        isFull = car.base.isFullConfig,
        data = car,
        nickname=(car.jbm):sub(0,math.min(#(car.jbm)-1,3))..""..Gen.generateRandomData(3)
    }


local output = {
        vcf = {
            parts = table,
            model = str,
            partConfigFilename = str,
            paints = table,
            vars = table,
            mainPartName = str,
        },
        base_parts = {
            partConfig = str,
            engine = str,
            transmission = str,
            transfer_case = str,
            isFullConfig = bool,
            mainPartName = str
        }
    }

    return {
        jbm = jbeam,
        pid = pid,
        ign = ign,
        rot = rot,
        pro = pro,
        pos = pos,
        vid = vid, -- vehicle id (in game)
        vcf = vcf,
        vcfStr = vcfStr,
        base = base_parts
    }


local parser = require("путь/к/вашему/модулю")

local full_data = 'USER:Igor20264:0-0:{"jbm":"autobello","pid":0,"ign":0,"rot":[0,0,0.99863147735596,0.052300725132227],"pro":"1","pos":[0,0,3],"vid":22239,"vcf":{"vars":{},"partConfigFilename":"vehicles/autobello/110a_m.pc","paints":[{"baseColor":[0.059999998658895,0.10000000149012,0.059999998658895,1.2000000476837],"roughness":1,"clearcoat":1,"metallic":0,"clearcoatRoughness":0.090000003576279},{"baseColor":[0.059999998658895,0.10000000149012,0.059999998658895,1.2000000476837],"roughness":1,"clearcoat":1,"metallic":0,"clearcoatRoughness":0.090000003576279},{"baseColor":[0.059999998658895,0.10000000149012,0.059999998658895,1.2000000476837],"roughness":1,"clearcoat":1,"metallic":0,"clearcoatRoughness":0.090000003576279}],"parts":{"tire_F_13x5":"tire_F_560_13_ww","tire_R_13x5":"tire_R_560_13_ww","wheel_R_4":"steelwheel_11b_13x5_R","skin_interior":"autobello_skin_interior_grey","licenseplate_design_2_1":"license_plate_italy_old_2_1","autobello_mirror_R":"none","autobello_door_R":"autobello_door_R_b","hubcap_R_13":"autobello_hubcap_01a_13_R","autobello_door_L":"autobello_door_L_b","wheel_F_4":"steelwheel_11b_13x5_F","autobello_sparewheel":"autobello_sparewheel_11b","autobello_hood":"autobello_hood_b","hubcap_F_13":"autobello_hubcap_01a_13_F","skin_seats":"autobello_skin_seats_grey"},"mainPartName":"autobello"}}'
local result = parser.vehicleParser(full_data)

if result then
  print(inspect(result))
else
    print("Ошибка, json не найден")
end
--]]


--[[

local function UDV(data)
    local data = string.gsub(data,'(%a+):(.-):(%d+)-(%d+)','{"config"',1)
	local data = string.gsub(data,'(%d+)-(%d+)','{"config"',1)
	local data =  data..'}'
    return data
end

local function finds(data,part_name)
	local y,x,part = string.find(data, part_name..'":"(.-)"')
	local status, part1 = pcall(string.gsub, part,part_name.."_","")
	if (status) then
		return part1
	else
		if part == nil then
			return nil
		end
	end
	return part
end

local function vehicle_parser(data)
    local jbm = finds(data, "jbm")
    local per_data = data
    print(data)
    data = string.gsub(data, jbm.."_", '')
    local engine = finds(data, "engine") or "Неизвестный двигатель"
    data = string.gsub(data, engine..'_', "")
    data = string.gsub(data, '_'..engine, "")
    local mainPartName = finds(data, "mainPartName")
    local transmission = finds(data, "transmission")
    local transfer_case = finds(data, "transfer_case")
    local body = finds(data, "body")
    return {engine = engine,
            transmission = transmission,
            mainPartName = mainPartName,
            transfer_case = transfer_case,body = body,
            per_data = per_data,color_name = "цвет",jbm = jbm}
end



--]]