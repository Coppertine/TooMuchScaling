local global = _G
local api = global.api --- @type Api
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


--- Fallback values
ScalingDBManager._tConfigDefaults = {
	tScale = {
		min = 0.1,
		max = 6
	},
	bAlwaysScaleTriggeredProps = false,
	bGridsAreNotGrids = false
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
				if j ~= nil then
					database.BindParameter(cPSInstance, i, j)
				end
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
	TMSAddSceneryPieceToSceneryScaling = function(_sPiece, _min, _max)
		dbgTrace("ScalingDBManager.TMSAddSceneryPieceToSceneryScaling")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSAddSceneryPieceToSceneryScaling", _sPiece, _min, _max)
	end,
	TMSUpdateSceneryPiecePrefabType = function(_sOldType, _sNewType)
		dbgTrace("ScalingDBManager.TMSUpdateSceneryPiecePrefabType")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSUpdateSceneryPiecePrefabType", _sOldType, _sNewType)
	end,
	TMSGetAllSceneryPiecesByPrefabType = function(_sPrefabType)
		dbgTrace("TMSGetAllSceneryPiecesByPrefabType")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSGetAllSceneryPiecesByPrefabType", _sPrefabType)
	end,
	-- Totally didn't steal this from ForgeUtils...
	TMSAddModularSceneryPart = function(SceneryPartName, PrefabName, DataPrefabName, ContentPack, UGCID, BoxXSize,
					    BoxYSize, BoxZSize)
		dbgTrace("TMSAddModularSceneryPart")
		return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSAddModularSceneryPart", SceneryPartName, PrefabName, DataPrefabName, ContentPack, UGCID,
			BoxXSize, BoxYSize, BoxZSize)
	end


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
--- Bypasses the current config loading
ScalingDBManager._IgnoreConfigLoad = false

ScalingDBManager.PreBuildPrefabs = function(_fnAdd, _tLuaPrefabNames, _tLuaPrefabs)
	dbgTrace("ScalingDBManager.PreBuildPrefabs()")

	ScalingDBManager._BindPreparedStatements()
	if not ScalingDBManager._IgnoreConfigLoad then
		ScalingDBManager.Global = ScalingDBManager._tConfigDefaults

		-- Config read here
		local bOK_Main, tNTL, tErrorMain = LoadConfig()
		-- yes, we are doing this again to allow the player to "reload config" without having to close game.
		MergeConfig(tNTL)
	else
		ScalingDBManager._IgnoreConfigLoad = false
	end

	dbgTrace("checking if scalable objects is empty..")
	--	dbgTrace(tableplus.tostring(ScalingDBManager._tScalableObjects))
	if #ScalingDBManager._tScalableObjects <= 0 then
		dbgTrace("attempting to grab original scale pieces");
		local _scalableProps = ScalingDBManager._ExecuteQuery("ModularScenery",
			"Mod_SceneryTooMuchScaling_ModularScenery",
			"TMSGetAllSceneryScalingPieces")
		dbgTrace("got props!")
		for _, x in ipairs(_scalableProps) do
			if #x == 1 then -- doesn't include frontier provided scale values, TMS can't handle this..
				x[2] = 0.1
				x[3] = 50 -- even though interally, it's 100, the game treats it as 500%
				GameDatabase.TMSAddSceneryPieceToSceneryScaling(x[1], x[2], x[3])
			end
		end
		ScalingDBManager._tScalableObjects = _scalableProps
	end

	if ScalingDBManager.Global.bAlwaysScaleTriggeredProps ~= nil and ScalingDBManager.Global.bAlwaysScaleTriggeredProps then
		GameDatabase.TMSUpdateSceneryPiecePrefabType("TriggerableScenery", "TriggerableScalableScenery")
	end

	--- TODO: Add button / gui thing to switch between grid and non-grid.

	if ScalingDBManager.Global.bGridsAreNotGrids ~= nil and ScalingDBManager.Global.bGridsAreNotGrids then
		--GameDatabase.TMSUpdateSceneryPiecePrefabType("OnGrid", "SurfaceScaling")
		local _onGridItems = GameDatabase.TMSGetAllSceneryPiecesByPrefabType("OnGrid")
		--dbgTrace(tableplus.tostring(_onGridItems))
		local SCENERY_PREFAB_TYPE_COLUMN = 3
		local SCENERY_PREFAB_NAME_COLUMN = 1
		for _, _tGridProp in ipairs(_onGridItems) do
			dbgTrace(tableplus.tostring(_tGridProp))
			_tGridProp[SCENERY_PREFAB_TYPE_COLUMN] = "SurfaceScaling"
			--	_tGridProp[SCENERY_PREFAB_NAME_COLUMN] = _tGridProp[SCENERY_PREFAB_NAME_COLUMN] +
			--	    "_SurfaceScaling"
			dbgTrace("Saving modified 'grid' prop")
			dbgTrace(tableplus.tostring(_tGridProp))
			GameDatabase.TMSAddModularSceneryPart(_tGridProp[1], _tGridProp[2], _tGridProp[3], _tGridProp[4],
				_tGridProp[5], _tGridProp[6], _tGridProp[7], _tGridProp[8])
		end
	end

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

ScalingDBManager._tTmpConfig = nil -- only really used to check if the current config isn't the same as the park's config
ScalingDBManager.OnWorldSave = function(_tSaver)
	dbgTrace("ScalingDBManager.OnWorldSave()")
	_tSaver.tTooMuchScalingConfig = ScalingDBManager.Global
end

ScalingDBManager.OnWorldLoad = function(_tSaver)
	dbgTrace("ScalingDBManager.OnWorldLoad()")
	dbgTrace(tableplus.tostring(_tSaver))
	if _tSaver.tTooMuchScalingConfig ~= nil then
		dbgTrace(tableplus.tostring(_tSaver.tTooMuchScalingConfig))
		ScalingDBManager._tTmpConfig = _tSaver.tTooMuchScalingConfig
	end
end
