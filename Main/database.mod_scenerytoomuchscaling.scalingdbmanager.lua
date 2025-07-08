local global = _G
local api = global.api ---@type Api
local pairs = pairs
local ipairs = ipairs
local type = type
local table = global.table
local tostring = global.tostring
local tonumber = global.tonumber
local loadfile = global.loadfile
local tableplus = require("Common.tableplus")
local GameDatabase = require("Database.GameDatabase")
local StartScreenHUD = require("StartScreen.Shared.StartScreenHUD")
local database = api.database
local coroutine = global.coroutine
---@class ScalingDBManager
local ScalingDBManager = module(...)

ScalingDBManager._tConfigDefaults = {
	tScale = {
		min = 0.1,
		max = 6
	}
}

local dbgTrace = function(_line)
	-- if api.acse.acsedebug then
	api.debug.Trace("TooMuchScaling: " .. _line)
	-- end
end

-- Shamelessly taken partly from PZPlus
local LoadConfig = function(sContext, tEnv)
	local bOK, sMsg = false, ""
	local env = tEnv or {}
	local chunk, err = loadfile("Win64\\ovldata\\Mod_SceneryTooMuchScaling\\Config.TooMuchScaling.ini", "bt", env)
	if not err then
		dbgTrace("Loading " .. "Config.TooMuchScaling")
		bOK, sMsg = global.pcall(chunk, nil)
		if bOK == false then
			dbgTrace("Config.TooMuchScaling - error")
			dbgTrace(sMsg)
		end
	else
		dbgTrace(tostring(err))
	end
	return bOK, env, { err, sMsg }
end
local MergeConfig = function(_input)
	local _global = ScalingDBManager.Global
	for i, v in pairs(_input) do
		_global[i] = (_input[i] ~= nil and _input[i] == true)
		_global[i] = v
		dbgTrace("Merging: " .. i)
	end
end

local tPreparedStatements = {
	ModularScenery = "Mod_SceneryTooMuchScaling_ModularScenery"
}

ScalingDBManager._BindPreparedStatements = function()
	dbgTrace("ScalingDBManager._BindPreparedStatements()")
	local bSuccess = 0

	for k, ps in pairs(tPreparedStatements) do
		dbgTrace(k)
		dbgTrace(ps)
		database.SetReadOnly(k, false)

		bSuccess = database.BindPreparedStatementCollection(k, ps)
		if bSuccess == 0 then
			dbgTrace("Warning: Prepared Statement " .. ps .. " can not be bound to table " .. k)
			return nil
		end
		dbgTrace("bsuccess" .. tostring(bSuccess))
		database.SetReadOnly(k, true)
	end
end


ScalingDBManager.Init = function(self)
	dbgTrace("TooMuchScaling.ScalingDBManager:Init()")
	ScalingDBManager.Global = {}
	ScalingDBManager._tScalableObjects = {}
end

ScalingDBManager.Setup = function()
	api.debug.Trace("TooMuchScaling.ScalingDBManager:Setup()")

	ScalingDBManager.Global = ScalingDBManager._tConfigDefaults

	-- Config read here
	local bOK_Main, tNTL, tErrorMain = LoadConfig()
	dbgTrace("config grabbed")
	-- Now, PZPlus basically "merges" the tables together.. ok
	dbgTrace(tostring(bOK_Main))
	MergeConfig(tNTL)
	ScalingDBManager._BindPreparedStatements()
end


---Executes a Prepared Statement to a selected database with provided arguments.
---@param _sDatabase string Database name.
---@param _sPSCollection string Prepared Statement Collection name.
---@param _sInstance string Prepared Statement name.
---@param ...? any Prepared Statement paramaters.
---@return table|nil
ScalingDBManager._ExecuteQuery = function(_sDatabase, _sPSCollection, _sInstance, ...)
	local result = nil
	database.SetReadOnly(_sDatabase, false)
	local tArgs = table.pack(...)

	local cPSInstance = database.GetPreparedStatementInstance(_sDatabase, _sInstance)
	if cPSInstance ~= nil then
		dbgTrace("binding to: " .. _sInstance)
		if #tArgs > 0 then
			for i, j in ipairs(tArgs) do
				dbgTrace("binding parameter: " .. j)
				database.BindParameter(cPSInstance, i, j)
			end
		end
		database.BindComplete(cPSInstance)
		database.Step(cPSInstance)

		local tRows = database.GetAllResults(cPSInstance, false)
		result = tRows or nil
	else
		dbgTrace("WARNING: COULD NOT GET INSTANCE: " .. _sInstance .. " IN: " .. _sPSCollection)
	end
	database.SetReadOnly(_sDatabase, true)
	return result
end



ScalingDBManager.tDatabaseFunctions = {
	TMSSetSceneryPiecesScale = function(_min, _max)
		dbgTrace("ScalingDBManager.TMSSetSceneryPiecesScale()")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSSetSceneryPiecesScale", _min, _max)
	end,
	TMSSetSceneryPiecesMinScale = function(_min)
		dbgTrace("ScalingDBManager.TMSSetSceneryPiecesMinScale()")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSSetSceneryPiecesMinScale", _min)
	end,
	TMSSetSceneryPiecesMaxScale = function(_max)
		dbgTrace("ScalingDBManager.TMSSetSceneryPiecesMaxScale()")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSSetSceneryPiecesMaxScale", _max)
	end,
	TMSSetSceneryPieceScale = function(_sPiece, _min, _max)
		dbgTrace("ScalingDBManager.TMSSetSceneryPieceScale()")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSSetSceneryPieceMinScale", _sPiece, _min, _max)
	end,
	TMSSetSceneryPieceMinScale = function(_sPiece, _min)
		dbgTrace("ScalingDBManager.TMSSetSceneryPieceMinScale()")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSSetSceneryPieceMinScale", _sPiece, _min)
	end,
	TMSSetSceneryPieceMaxScale = function(_sPiece, _max)
		dbgTrace("ScalingDBManager.TMSSetSceneryPieceMaxScale()")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSSetSceneryPieceMaxScale", _sPiece, _max)
	end,
	--TMSGetAllSceneryScalingPieces = function()
	--	dbgTrace("ScalingDBManager.TMSGetAllSceneryScalingPieces")
	--	return {}

	--end

}

ScalingDBManager.AddDatabaseFunctions = function(_tDatabaseFunctions)
	for sMethod, fnMethod in pairs(ScalingDBManager.tDatabaseFunctions) do
		_tDatabaseFunctions[sMethod] = fnMethod
	end
end

ScalingDBManager.ShutdownForReInit = function()

end

ScalingDBManager.Shutdown = function()

end
ScalingDBManager.PreBuildPrefabs = function(_fnAdd, _tLuaPrefabNames, _tLuaPrefabs)
	dbgTrace("ScalingDBManager.PreBuildPrefabs()")

	ScalingDBManager._BindPreparedStatements()
	ScalingDBManager.Global = ScalingDBManager._tConfigDefaults

	-- Config read here
	local bOK_Main, tNTL, tErrorMain = LoadConfig()
	-- yes, we are doing this again to allow the player to "reload config" without having to close game.
	MergeConfig(tNTL)
	-- Processing config here.. it's an easy one
	if ScalingDBManager.Global.tScale then
		if (ScalingDBManager.Global.tScale.min and ScalingDBManager.Global.tScale.min ~= nil) and (ScalingDBManager.Global.tScale.min and ScalingDBManager.Global.tScale.min ~= nil) then
			GameDatabase.TMSSetSceneryPiecesScale(ScalingDBManager.Global.tScale.min,
				ScalingDBManager.Global.tScale.max)
		else
			if (ScalingDBManager.Global.tScale.min and ScalingDBManager.Global.tScale.min ~= nil) then
				GameDatabase.TMSSetSceneryPiecesMinScale(ScalingDBManager.Global.tScale.min)
			end
			if (ScalingDBManager.Global.tScale.max and ScalingDBManager.Global.tScale.max ~= nil) then
				GameDatabase.TMSSetSceneryPiecesMaxScale(ScalingDBManager.Global.tScale.max)
			end
		end
	end
end
