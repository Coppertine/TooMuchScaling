local global = _G
local api = global.api
local pairs = global.pairs
local require = global.require
local table = require("Common.tableplus")

local Mod_SceneryTooMuchScalingLuaDatabase = module(...)

Mod_SceneryTooMuchScalingLuaDatabase.AddContentToCall = function(_tContentToCall)    
    if not global.api.acse or global.api.acse.versionNumber < 0.7 then
        return
    end

    table.insert(_tContentToCall, Mod_SceneryTooMuchScalingLuaDatabase)
    table.insert(_tContentToCall, require("Database.Mod_SceneryTooMuchScaling.ScalingDBManager"))
end

Mod_SceneryTooMuchScalingLuaDatabase.Init = function()
    api.debug.Trace("Mod_SceneryTooMuchScalingLuaDatabase.Init()")
end

Mod_SceneryTooMuchScalingLuaDatabase.Activate = function()
    api.debug.Trace("Mod_SceneryTooMuchScalingLuaDatabase.Activate()")
end