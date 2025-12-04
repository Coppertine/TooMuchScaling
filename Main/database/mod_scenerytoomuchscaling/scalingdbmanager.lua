local global = _G
local api = global.api --- @type Api
local pairs = pairs
local ipairs = ipairs
local type = type
local table = global.table
local tostring = global.tostring
local loadfile = global.loadfile
local tryrequire = global.tryrequire
local tableplus = require("Common.tableplus")
local GameDatabase = require("Database.GameDatabase")
local StartScreenHUD = require("StartScreen.Shared.StartScreenHUD")
local database = api.database
--- Only used to check if mod is installed.
local ForgeUtils = tryrequire("forgeutils.builders.scenerypartbuilder")

---@class ScalingDBManager
local ScalingDBManager = {}

--- Fallback values
ScalingDBManager._tConfigDefaults = {
    tScale = {
        min = 0.01,
        max = 6
    },
}

local dbgTrace = function(_line)
    -- if api.acse.acsedebug then
    local trace = api.debug.TraceNoFlush or api.debug.Trace
    --    trace("TooMuchScaling: " .. _line)
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

ScalingDBManager.bGridsDisabled = false
ScalingDBManager.ForgeUtilsPopupShown = false
ScalingDBManager.Init = function(self)
    dbgTrace("TooMuchScaling.ScalingDBManager:Init()")
    ScalingDBManager.Global = {}
    ScalingDBManager._tScalableObjects = {}
    ScalingDBManager._BindPreparedStatements()
end

ScalingDBManager.Setup = function()
    api.debug.Trace("TooMuchScaling.ScalingDBManager:Setup()")

    ScalingDBManager.Global = ScalingDBManager._tConfigDefaults

    ScalingDBManager._BindPreparedStatements()
    -- Config read here
    local bOK_Main, tNTL, tErrorMain = LoadConfig()
    dbgTrace("config grabbed")
    -- Now, PZPlus basically "merges" the tables together.. ok
    dbgTrace(tostring(bOK_Main))
    MergeConfig(tNTL)
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
        --       dbgTrace("binding to: " .. _sInstance)
        if #tArgs > 0 then
            for i, j in ipairs(tArgs) do
                --dbgTrace("binding parameter: " .. j)
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
    end,
    TMSAddSceneryUIData = function(SceneryPartName, LabelTextSymbol, DescriptionTextSymbol, Icon, ReleaseGroup)
        dbgTrace("TMSAddSceneryUIData")
        return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
            "TMSAddSceneryUIData", SceneryPartName, LabelTextSymbol, DescriptionTextSymbol, Icon, ReleaseGroup)
    end,
    TMSAddScenerySimulationData = function(SceneryPartName, BuildCost, HourlyRunningCost, ResearchPack,
                                           RequiresUnlockInSandbox)
        dbgTrace("TMSAddScenerySimulationData")
        return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
            "TMSAddScenerySimulationData", SceneryPartName, LabelTextSymbol, DescriptionTextSymbol, Icon, ReleaseGroup)
    end,
    TMSAddSceneryThemingData = function(SceneryPartName, Weight, Radius, FalloffRadius)
        dbgTrace("TMSAddSceneryThemingData")
        return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
            "TMSAddSceneryThemingData", SceneryPartName, Weight, Radius, FalloffRadius)
    end,
    TMSAddSceneryTag = function(SceneryPart, Tag)
        dbgTrace("TMSAddSceneryTag")
        return ScalingDBManager._ExecuteQuery("ModularScenery", "Mod_SceneryTooMuchScaling_ModularScenery",
            "TMSAddSceneryTag", SceneryPart, Tag)
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

    --    if ScalingDBManager.Global.bAlwaysScaleTriggeredProps ~= nil and ScalingDBManager.Global.bAlwaysScaleTriggeredProps then
    --        GameDatabase.TMSUpdateSceneryPiecePrefabType("TriggerableScenery", "TriggerableScalableScenery")
    --    end


    dbgTrace("checking if scalable objects is empty..")
    if #ScalingDBManager._tScalableObjects <= 0 then
        dbgTrace("attempting to grab original scale pieces");
        local _scalableProps = ScalingDBManager._ExecuteQuery("ModularScenery",
            "Mod_SceneryTooMuchScaling_ModularScenery",
            "TMSGetAllSceneryScalingPieces")
        dbgTrace("got props!")
        for _, x in ipairs(_scalableProps) do
            if #x == 1 then -- doesn't include frontier provided scale values, TMS can't handle this..
                x[2] = 0.1
                x[3] = 5    -- even though interally, it's 1000, the game treats it as 500%
                GameDatabase.TMSAddSceneryPieceToSceneryScaling(x[1], x[2], x[3])
            end
        end
        ScalingDBManager._tScalableObjects = _scalableProps
    end

    dbgTrace(tableplus.tostring(ScalingDBManager._tScalableObjects))



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


--- Requires ForgeUtils
--- Impliments the "new" grid-less items
function ScalingDBManager.InsertToDBs()
    ScalingDBManager._BindPreparedStatements()
    --- TODO: Add button / gui thing to switch between grid and non-grid.
    --- This currently would make a duplicate prop as a non-grid
    ----- WARNING: This has been commented out due to Update 1.7 featuring rotatable and "scalable" buildings.
    ---- If you want to use this, please uncomment the entire section below
    --
    --  if ScalingDBManager.Global.bGridsAreNotGrids ~= nil and ScalingDBManager.Global.bGridsAreNotGrids then
    --      --GameDatabase.TMSUpdateSceneryPiecePrefabType("OnGrid", "SurfaceScaling")
    --      local _onGridItems = GameDatabase.TMSGetAllSceneryPiecesByPrefabType("OnGrid")
    --      --dbgTrace(tableplus.tostring(_onGridItems))
    --      local SURFACESCALING_SUFFIX = "_SurfaceScaling"
    --      local SCENERY_PREFAB_TYPE_COLUMN = 3
    --      local PROPUI_ICON_COLUMN = 4
    --      local SCENERY_PREFAB_COLUMN = 2
    --      local SCENERY_PREFAB_NAME_COLUMN = 1
    --      local SIMULATION_PREFAB_NAME_COLUMN = 1
    --      local PROPUI_PREFAB_NAME_COLUMN = 1
    --      local THEMING_PREFAB_NAME_COLUMN = 1
    --      for _, _tGridProp in ipairs(_onGridItems) do
    --          local _tPropUIData = ScalingDBManager._ExecuteQuery("ModularScenery",
    --              "Mod_SceneryTooMuchScaling_ModularScenery",
    --              "TMSGetSceneryUIDataOfPart", _tGridProp[SCENERY_PREFAB_NAME_COLUMN])[1]
    --          local _tPropSimulationData = ScalingDBManager._ExecuteQuery("ModularScenery",
    --              "Mod_SceneryTooMuchScaling_ModularScenery", "TMSGetScenerySimulationData",
    --              _tGridProp[SCENERY_PREFAB_NAME_COLUMN])[1]
    --          local _tPropTheming = ScalingDBManager._ExecuteQuery("ModularScenery",
    --              "Mod_SceneryTooMuchScaling_ModularScenery", "TMSGetSceneryThemingData",
    --              _tGridProp[SCENERY_PREFAB_NAME_COLUMN])
    --          local _tMetadataTags = ScalingDBManager._ExecuteQuery("ModularScenery",
    --              "Mod_SceneryTooMuchScaling_ModularScenery", "TMSGetSceneryMetadataTags",
    --              _tGridProp[SCENERY_PREFAB_NAME_COLUMN])
    --          dbgTrace(_tGridProp[SCENERY_PREFAB_NAME_COLUMN])
    --
    --          ---- Modular Scenery Part
    --          _tGridProp[SCENERY_PREFAB_TYPE_COLUMN] = "SurfaceScaling"
    --          -- here to ensure the
    --          _tGridProp[SCENERY_PREFAB_COLUMN] = _tGridProp[SCENERY_PREFAB_NAME_COLUMN]
    --
    --          _tGridProp[SCENERY_PREFAB_NAME_COLUMN] = _tGridProp[SCENERY_PREFAB_NAME_COLUMN] ..
    --              SURFACESCALING_SUFFIX
    --          GameDatabase.TMSAddModularSceneryPart(_tGridProp[1], _tGridProp[2], _tGridProp[3], _tGridProp[4],
    --              _tGridProp[5], _tGridProp[6], _tGridProp[7], _tGridProp[8])
    --
    --          dbgTrace("Adding simulation stuff..")
    --          ---- Simulation
    --          _tPropSimulationData[SIMULATION_PREFAB_NAME_COLUMN] = _tGridProp[SCENERY_PREFAB_NAME_COLUMN]
    --          GameDatabase.TMSAddScenerySimulationData(_tPropSimulationData[1], _tPropSimulationData[2],
    --              _tPropSimulationData[3], _tPropSimulationData[4], _tPropSimulationData[5])
    --
    --          ---- Theming
    --          if _tPropTheming ~= nil and #_tPropTheming > 0 then
    --              -- dbgTrace(tableplus.tostring(_tPropTheming))
    --              _tPropTheming = _tPropTheming[1]
    --              _tPropTheming[THEMING_PREFAB_NAME_COLUMN] = _tGridProp[SCENERY_PREFAB_NAME_COLUMN]
    --              --dbgTrace(tableplus.tostring(_tPropTheming))
    --              GameDatabase.TMSAddSceneryThemingData(_tPropTheming[1], _tPropTheming[2], _tPropTheming[3],
    --                  _tPropTheming[4])
    --          end
    --          ---- UI Data
    --
    --          ---- TODO: Change this out for swappable ui
    --          dbgTrace("Adding ui item")
    --          if _tPropUIData ~= nil then
    --              _tPropUIData[PROPUI_ICON_COLUMN] = _tPropUIData[PROPUI_PREFAB_NAME_COLUMN]
    --              _tPropUIData[PROPUI_PREFAB_NAME_COLUMN] = _tGridProp[SCENERY_PREFAB_NAME_COLUMN]
    --              --  dbgTrace(tableplus.tostring(_tPropUIData))
    --              GameDatabase.TMSAddSceneryUIData(_tPropUIData[1], _tPropUIData[2], _tPropUIData[3], _tPropUIData[4],
    --                  _tPropUIData[5])
    --          end
    --          --           dbgTrace(tableplus.tostring(_tMetadataTags))
    --          for _, _tTag in ipairs(_tMetadataTags) do
    --              if _tTag[2] == "Filter_GridProperty_Grid" then
    --                  _tTag[2] = "Filter_GridProperty_OffGrid"
    --              end
    --
    --              _tTag[1] = _tTag[1] .. SURFACESCALING_SUFFIX
    --              GameDatabase.TMSAddSceneryTag(_tTag[1], _tTag[2])
    --          end
    --      end
    --  end
end

ScalingDBManager._tTmpConfig = nil -- only really used to check if the current config isn't the same as the park's config
-- For SOME REASON, this is called FOUR TIMES!! WHY FRONTIER??
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

return ScalingDBManager
