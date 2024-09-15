-- Creates a 2D matrix
local function matrix(row,col)
  local m = {}
  for i = 1,row do m[i] = {}
    for j = 1,col do m[i][j] = 0 end
  end
  return m
end

-- Calculates the Levenshtein distance between two strings
local function lev_iter_based(strA,strB)
  local M = matrix(#strA+1,#strB+1)
  local i,j,cost
  local row,col = #M,#M[1]
  for i = 1,row do M[i][1] = i-1 end
  for j = 1,col do M[1][j] = j-1 end
  for i = 2,row do
    for j = 2,col do
      if (strA:sub(i-1,i-1) == strB:sub(j-1,j-1)) then cost = 0
      else cost = 1
      end
    M[i][j] = math.min(M[i-1][j]+1,M[i][j-1]+1,M[i-1][j-1]+cost)
    end
  end
  return M[row][col]
end

return lev_iter_based