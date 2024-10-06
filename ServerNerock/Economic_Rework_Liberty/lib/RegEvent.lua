local M = {}

local function genReg(size)
  local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local charTable = {}
  for c in chars:gmatch"." do
	  table.insert(charTable, c)
  end
  local res = ''
  for i = 1, size do
	res = res .. charTable[math.random(1, #charTable)]
  end
  return res
end

local RegCaches = {}
function GenReg() 
	local repeats = true
	while repeats do
		local dts = genReg(6)
		if RegCaches[dts] then
			log("Generated replay: "..dts,4)
		else
			RegCaches[dts] = dts
		return dts
		end
	end
end

function RegEvent(KRF)
	local cmd = {}
	for i,case in ipairs(KRF) do
		local rego = GenReg()
		MP.RegisterEvent(rego,case.func)
		log(rego.." "..case.func.." Зареган ивент",2)
		cmd[i] = {reg = rego,command = case.command,help = case.help,func=case.func,admin=case.admin,hide = case.hide}
	end
	return cmd
end

return M