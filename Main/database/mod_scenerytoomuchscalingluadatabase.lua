local global = _G
local api = global.api ---@type Api
local pairs = global.pairs
local require = global.require
local tryrequire = global.tryrequire
local table = require("Common.tableplus")
---@class Mod_SceneryTooMuchScalingLuaDatabase
local Mod_SceneryTooMuchScalingLuaDatabase = module(...)
Mod_SceneryTooMuchScalingLuaDatabase.CurrentSaveParkID = nil

local MOD_INFO = {
	name = "TooMuchScaling",
	author = "Coppertine",
	mod_version = 2.0,
	min_modmenu_version = 1.0,
	description = "Expands the range of scalable objects to an extreme degree.",
	optional_mods = {
		"Mod_ModMenu"
	},
	incompatable_mods = {
		"ACSEDebug"
	},
	mod_folder = "Mod_SceneryTooMuchScaling"
}


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

	local modmenu = tryrequire("modmenu.ModDatabase")
	if modmenu ~= nil then
		modmenu:RegisterMod(MOD_INFO)
	end
end


Mod_SceneryTooMuchScalingLuaDatabase.tManagers = {
	["Environments.CPTEnvironment"] = {
		["Managers.ScalingParkManager"] = {},
	},
}

Mod_SceneryTooMuchScalingLuaDatabase.AddLuaManagers = function(_fnAdd)
	for sManagerName, tParams in pairs(Mod_SceneryTooMuchScalingLuaDatabase.tManagers) do
		_fnAdd(sManagerName, tParams)
	end
end

Mod_SceneryTooMuchScalingLuaDatabase._HookParkLoadSaveManager = function(tModule)
	tModule._Hook_LoadParkFromSaveToken = tModule.LoadParkFromSaveToken
	tModule.LoadParkFromSaveToken = function(self, cSaveToken)
		api.debug.Trace("TooMuchScaling.LoadParkFromsaveToken")
		return self:_Hook_LoadParkFromSaveToken(cSaveToken)
	end
end

Mod_SceneryTooMuchScalingLuaDatabase._HookStartScreenHUD = function(tModule)
	tModule._Hook_RequestParkLoadFromSaveToken = tModule._RequestParkLoadFromSaveToken
	tModule._RequestParkLoadFromSaveToken = function(self, _sParkID, _sGameModeOverride)
		api.debug.Trace("TooMuchScaling.RequestParkFromsaveToken")
		api.debug.Trace(_sParkID)
		Mod_SceneryTooMuchScalingLuaDatabase.CurrentSaveParkID = _sParkID
		self:_Hook_RequestParkLoadFromSaveToken(_sParkID, _sGameModeOverride)
	end
end

Mod_SceneryTooMuchScalingLuaDatabase.tLuaHooks = {
	["StartScreen.Shared.StartScreenHUD"] = Mod_SceneryTooMuchScalingLuaDatabase._HookStartScreenHUD
}

Mod_SceneryTooMuchScalingLuaDatabase.AddLuaHooks = function(_fnAdd)
	for key, value in pairs(Mod_SceneryTooMuchScalingLuaDatabase.tLuaHooks) do
		_fnAdd(key, value)
	end
end
