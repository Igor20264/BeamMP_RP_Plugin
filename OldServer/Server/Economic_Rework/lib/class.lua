M = {}

function extended (child, parent)
    setmetatable(child,{__index = parent}) 
end

function M:init(name)
    local private = {}

    local public = {}	

    setmetatable(public,self)
    self.__index = self;
    return public
end

return M