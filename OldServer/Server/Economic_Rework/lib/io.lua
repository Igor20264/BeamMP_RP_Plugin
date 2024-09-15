M = {}
M.pluginPath = "Resources/Server/Economic_Rework"

function load_database(namefile)
	log(namefile,3)
	local file, err = io.open (M.pluginPath.."/database/"..namefile,"r")
	if file==nil then
		log("Couldn't open file: "..err,5)
	else
		local result = assert(Util.JsonDecode(file:read("*all")))
		file:close() 
		return result
	end
end

function save_database(namefile,data)
	log(namefile,3)
	local file = io.open (M.pluginPath .."/database/"..namefile,"w")
	file:write(Util.JsonEncode(data))
	file:close()  
	end
 
function load_config(namefile)
	log(namefile,3)
	local file, err = io.open(M.pluginPath..'/'..namefile..'.json',"r")
	if file==nil then log("Couldn't open file: "..err,5) 
	else	
		local result = Util.JsonDecode(file:read("*all"))
		file:close()
		return result
	end
end

return M