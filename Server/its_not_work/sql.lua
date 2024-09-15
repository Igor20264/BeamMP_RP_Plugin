local mysql = require "luasql.mysql"

-- Define the CacheManager class
CacheManager = {}
CacheManager.__index = CacheManager

function CacheManager.new(mysql, fullRefreshInterval)
    local self = setmetatable({}, CacheManager)
    self.mysql = mysql
    self.cache = {}
    self.lastFullRefresh = 0
    self.fullRefreshInterval = fullRefreshInterval or 3600  -- Default to 1 hour
    return self
end

function CacheManager:getCacheForTable(tableName)
    if not self.cache[tableName] then
        self.cache[tableName] = {}
    end
    return self.cache[tableName]
end

function CacheManager:updateCache(tableName, query, params)
    local results = self.mysql:query(query, table.unpack(params)):fetchall()
    local tableCache = self:getCacheForTable(tableName)

    for _, row in ipairs(results) do
        local key = self:generateCacheKey(row)
        tableCache[key] = row
    end
end

function CacheManager:generateCacheKey(row)
    -- This function should generate a unique key for each row
    -- The implementation depends on your table structure
    -- For example, if you have an 'id' column:
    return tostring(row.id)
end

function CacheManager:get(tableName, key)
    local tableCache = self:getCacheForTable(tableName)
    return tableCache[key]
end

function CacheManager:fullRefresh()
    if os.time() - self.lastFullRefresh < self.fullRefreshInterval then
        print("Performing full cache refresh")
        -- Implement full refresh logic here
        -- For example, you could have a list of tables and their corresponding queries
        local tables = {
            {name = "users", query = "SELECT * FROM users"},
            {name = "cars", query = "SELECT * FROM cars"},
            -- Add more tables as needed
        }

        for _, table in ipairs(tables) do
            self:updateCache(table.name, table.query, {})
        end

        self.lastFullRefresh = os.time()
    end
end

-- Define the MySQL class
MySQL = {}
MySQL.__index = MySQL

function MySQL.new(database, username, password, host, port)
    local self = setmetatable({}, MySQL)
    self.env = assert(mysql.mysql())
    self.con = assert(self.env:connect(database, username, password, host, port))
    self.cacheManager = CacheManager.new(self)
    return self
end



function MySQL:close()
    self.con:close()
    self.env:close()
end

function MySQL:query(query, ...)
    --self.cacheManager:fullRefresh()  -- Check if full refresh is needed
    print("test")
    -- Escape and format parameters
    local params = {...}
    for i, v in ipairs(params) do
        if type(v) == "string" then
            params[i] = self.con:escape(v)
        end
    end
    print("test1")
    -- Format the query
    local formattedQuery = string.format(query, table.unpack(params))
    print(formattedQuery)
    -- Execute the query
    local cur, err = self.con:execute(formattedQuery)
    if not cur then
        error("SQL Error: " .. (err or "Unknown error"))
    end

    return MySQLQuery.new(self, cur, formattedQuery, params)
end

-- Define the MySQLQuery class
MySQLQuery = {}
MySQLQuery.__index = MySQLQuery

function MySQLQuery.new(mysql, cursor, query, params)
    local self = setmetatable({}, MySQLQuery)
    self.mysql = mysql
    self.cursor = cursor
    self.query = query
    self.params = params
    self.cache = {}
    self.position = 0
    return self
end

function MySQLQuery:fetchone()
    if #self.cache > self.position then
        self.position = self.position + 1
        return self.cache[self.position]
    end

    local row = self.cursor:fetch({}, "a")
    if row then
        table.insert(self.cache, row)
        self.position = self.position + 1
    end
    return row
end

function MySQLQuery:fetchall()
    while self:fetchone() do end
    return self.cache
end

function MySQLQuery:close()
    self.cursor:close()
end

function MySQLQuery:extractTableName(query)
    -- This is a simple implementation and might need to be more robust
    local tableName = string.match(query:lower(), "from%s+(%w+)")
    return tableName
end

-- Define the Cars class
Cars = {}
Cars.__index = Cars

function Cars.new(mysql)
    local self = setmetatable({}, Cars)
    self.mysql = mysql
    return self
end

function Cars:getCarsByOwner(owner)
    local query = self.mysql:query("SELECT * FROM users WHERE username = '%s'", owner)
    return query:fetchall()
end

function Cars:updateCar(carId, newData)
    local query = self.mysql:query("UPDATE users SET name = '%s' WHERE username = '%s'", newData, carId)
    query:close()
    -- The cache will be updated automatically on the next query
end

-- Usage example
local mysql = MySQL.new("database", "username", "password", "host", 3306)
local cars = Cars.new(mysql)

-- This will use and update the cache
local playerCars = cars:getCarsByOwner("tedddy")
print(playerCars)
-- This will update the database and invalidate the cache
cars:updateCar(1, "new car data")

-- This will refresh the cache with the new data
playerCars = cars:getCarsByOwner("tedddy","new car data")

mysql:close()
