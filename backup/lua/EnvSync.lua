local M = {}
M.info = "Env Sync"
M.ver = "0.2"
M.author = "Hlebushek"

local function tableMerge(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                tableMerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

BeamMPEnvSync = {
    _state = {
        tickCounter = 0,
        previousClockTime = nil,
        init = false,
        timeOfDay = nil
    },
    _defaultOptions = {
        timeOfDay = {
            dayLengthRealTimeSeconds = 1800,
            serverWorldStartTime = "10:00",
            daytimeScale = 1,
            nighttimeScale = 2,
            azimuth = 0,
            fixed = false
        },

        syncRate = 2,
    },
    options = {},
    MINUTES_PER_DAY = 1440,
    MINUTES_PER_HOUR = 60,
    SECONDS_PER_MINUTE = 60,
    SECONDS_PER_HOUR = 3600,
    SECONDS_PER_DAY = 3600 * 24,
    GAME_NIGHTTIME_START_VALUE = 0.275, -- approx. 18:36
    GAME_DAYTIME_START_VALUE = 0.7425, -- approx. 05:23
    GAME_TIME_MAX_REF = 1.0,
    GAME_TIME_SCALE_MIN = 0.5,
    GAME_TIME_SCALE_MAX = 10,
    SYNC_RATE_MIN = 1,
    SYNC_RATE_MAX = 30,
}
    function BeamMPEnvSync:init()
        if (self._state.init) then
            return
        end
        self:loadOptions()
        self._state.init = true
        self:recalcServerTimeOfDay()
    end

    function BeamMPEnvSync:loadOptions()
        local options = dofile(M.pluginPath .."/settings/envsync.lua") or {}
        -- load default options
        tableMerge(self.options, self._defaultOptions)
        -- merge user options
        tableMerge(self.options, options)
        -- convert start time to game time
        self._state.timeOfDay = self:convertClockTimeToGameTime(self.options.timeOfDay.serverWorldStartTime) or self._defaultOptions.timeOfDay.serverWorldStartTime
        -- normalize/sanitize other options
        self.options.syncRate = math.min(self.SYNC_RATE_MAX, math.max(self.SYNC_RATE_MIN, self.options.syncRate or self._defaultOptions.syncRate))
        self.options.timeOfDay.daytimeScale = math.min(self.GAME_TIME_SCALE_MAX, math.max(self.GAME_TIME_SCALE_MIN, self.options.timeOfDay.daytimeScale or self._defaultOptions.timeOfDay.daytimeScale))
        self.options.timeOfDay.nighttimeScale = math.min(self.GAME_TIME_SCALE_MAX, math.max(self.GAME_TIME_SCALE_MIN, self.options.timeOfDay.nighttimeScale or self._defaultOptions.timeOfDay.nighttimeScale))
        self.options.timeOfDay.dayLengthRealTimeSeconds = math.max(0, self.options.timeOfDay.dayLengthRealTimeSeconds or self._defaultOptions.timeOfDay.dayLengthRealTimeSeconds)
        -- other calculations
        self.options.timeOfDay.__dayLengthRealTimeSecondsPart = 1.0 / self.options.timeOfDay.dayLengthRealTimeSeconds
        self:updateDerivedOptions()
    end

    function BeamMPEnvSync:updateDerivedOptions()
        if self.options.timeOfDay.fixed then
            self.options.timeOfDay.__play = 0
        else
            self.options.timeOfDay.__play = 1
        end
    end

    function BeamMPEnvSync:recalcServerTimeOfDay()
        if not self._state.previousClockTime then
            self._state.previousClockTime = os.time()
            return
        end
        local elapsedSeconds = os.time() - self._state.previousClockTime
        self._state.previousClockTime = os.time()
        if self.options.timeOfDay.fixed then
            return
        end
        local newTimeOfDay = self._state.timeOfDay
        local inc = self.options.timeOfDay.__dayLengthRealTimeSecondsPart
        for i = 1, elapsedSeconds do
            local isNighttime = newTimeOfDay >= self.GAME_NIGHTTIME_START_VALUE and newTimeOfDay < self.GAME_DAYTIME_START_VALUE
            if isNighttime then
                newTimeOfDay = newTimeOfDay + (inc * self.options.timeOfDay.nighttimeScale)
            else
                newTimeOfDay = newTimeOfDay + (inc * self.options.timeOfDay.daytimeScale)
            end
            if newTimeOfDay >= 1 then newTimeOfDay = newTimeOfDay - 1 end
        end
        self._state.timeOfDay = newTimeOfDay
    end

    function BeamMPEnvSync:setTimeOfDay(value, fixed)
        self.options.timeOfDay.fixed = fixed
        self:updateDerivedOptions()
        self._state.timeOfDay = value
        self._state.previousClockTime = os.time()
        self:syncTimeOfDay()
    end

    function BeamMPEnvSync:convertClockTimeToGameTime(value)
        local h_s, m_s = string.match(value, "^(%d%d):(%d%d)$")
        if not h_s or not m_s then return nil end
        return self:convertSecondsToGameTime(((tonumber(h_s) * self.SECONDS_PER_HOUR) + (tonumber(m_s) * self.SECONDS_PER_MINUTE)) % self.SECONDS_PER_DAY)
    end

    function BeamMPEnvSync:convertSecondsToGameTime(seconds)
        -- sanitize
        local s = math.min(self.SECONDS_PER_DAY, math.max(0, seconds or 0))
        -- need to convert range [0,86400) (12am-11:59pm) to [0,1) (12pm-11:59am)
        local a = s + (self.SECONDS_PER_DAY / 2)
        if a >= self.SECONDS_PER_DAY then
            a = a - self.SECONDS_PER_DAY
        end
        return a / self.SECONDS_PER_DAY
    end

    function BeamMPEnvSync:syncTimeOfDay()
        local t = self._state.timeOfDay
        -- [1] = time
        -- [2] = dayLength
        -- [3] = dayScale
        -- [4] = nightScale
        -- [5] = play
        -- [6] = azimuthOverride
        local data = t .. "|" .. self.options.timeOfDay.dayLengthRealTimeSeconds .. "|" .. self.options.timeOfDay.daytimeScale .. "|" .. self.options.timeOfDay.nighttimeScale .. "|" .. self.options.timeOfDay.__play .. "|" .. self.options.timeOfDay.azimuth
        --log("Syncing time of day (" .. t .. ")",2)
        MP.TriggerClientEvent(-1, "BeamMPEnvSyncSetTimeOfDay", data)
    end

    function BeamMPEnvSync:tick()
        local c = self._state.tickCounter
        if c > 60 / self.options.syncRate then
            c = 0
            self:recalcServerTimeOfDay()
            self:syncTimeOfDay()
        end
        c = c + 1
        self._state.tickCounter = c
    end
-- end class BeamMPEnvSync

function ENVSETIME(sender_id,sender_name,message)
    local time = split(message, " ")[1] or nil -- 08:00
    local modifier = split(message, " ")[2] or nil-- --fixed
    if time then
        time = BeamMPEnvSync:convertClockTimeToGameTime(time) or nil
        if time then
            BeamMPEnvSync:setTimeOfDay(time, modifier)
        end
    end
    SendMessage(sender_id, "Установлено время суток: " .. BeamMPEnvSync._state.timeOfDay)
end

function onPlayerJoinENV()
    BeamMPEnvSync:recalcServerTimeOfDay()
    BeamMPEnvSync:syncTimeOfDay()
end

function envSyncTick()
    BeamMPEnvSync:tick()
end

M.command = {
    {category = "env",command = "set", help ="Установить время суток.",args="[08:00]",func ="ENVSETIME",roles = {"moderator","admin"}}
}

function M.load()
    BeamMPEnvSync:init()
    MP.RegisterEvent("onPlayerJoin", "onPlayerJoinENV")
    HeventTimer.addFunc(envSyncTick, 1)
end

function M.unload()
end

return M

