local M = {}

function M.generateRandomData(size)
  local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZабвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ0123456789'
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

return M