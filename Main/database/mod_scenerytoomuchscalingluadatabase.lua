local global = _G
local api = global.api ---@type Api
local pairs = global.pairs
local require = global.require
local tryrequire = global.tryrequire
local table = require("Common.tableplus")
local ScalingDBManager = require("Database.Mod_SceneryToomuchScaling.ScalingDBManager")
local ScalingParkManager = require("Managers.ScalingParkManager")
local forgeUtils = tryrequire("forgeutils.moddb")
---@class Mod_SceneryTooMuchScalingLuaDatabase
local Mod_SceneryTooMuchScalingLuaDatabase = {}
Mod_SceneryTooMuchScalingLuaDatabase.CurrentSaveParkID = nil

--- Mod information for ModMenu
Mod_SceneryTooMuchScalingLuaDatabase.MOD_INFO = {
    mod_name = "TooMuchScaling",
    author = "Coppertine",
    mod_version = 2.0,
    description = "Expands the range of scalable objects to an extreme degree.",
    required_mods = {
        { mod = "ACSE", min_version = 0.7 }
    },
    optional_mods = {
        { mod = "Mod_ModMenu", min_version = 1.0 },
        --       { mod = "ForgeUtils",  min_version = 1.0 }
    },
    incompatable_mods = {
        "ACSEDebug"
    },
    mod_folder = "Mod_SceneryTooMuchScaling",
}

Mod_SceneryTooMuchScalingLuaDatabase.ForgeUtilsEnabled = false

Mod_SceneryTooMuchScalingLuaDatabase.AddContentToCall = function(_tContentToCall)
    table.insert(_tContentToCall, Mod_SceneryTooMuchScalingLuaDatabase)
    table.insert(_tContentToCall, require("Database.Mod_SceneryTooMuchScaling.ScalingDBManager"))
end

Mod_SceneryTooMuchScalingLuaDatabase.Init = function()
    api.debug.Trace("Mod_SceneryTooMuchScalingLuaDatabase.Init()")
    api.ui2.MapResources("TMSUI")

    -- ACSE hooks are a pain.. this way from Distantz is way better..
    Mod_SceneryTooMuchScalingLuaDatabase._HookParkLoadSaveManager(require("Managers.ParkLoadSaveManager"))

    Mod_SceneryTooMuchScalingLuaDatabase._HookStartScreenHUD(require("StartScreen.Shared.StartScreenHUD"))
    Mod_SceneryTooMuchScalingLuaDatabase._Hook_StartScreenPopupHelper(require(
        "StartScreen.Shared.StartScreenPopupHelper"))
    Mod_SceneryTooMuchScalingLuaDatabase._HookHUDGamefaceHelper(require("Windows.HUDGamefaceHelper"))
    Mod_SceneryTooMuchScalingLuaDatabase._HookSubmodePlacement(require("Editors.Scenery.SubmodePlacement"))
end

Mod_SceneryTooMuchScalingLuaDatabase.Shutdown = function()
    api.ui2.UnmapResources("TMSUI")
end

Mod_SceneryTooMuchScalingLuaDatabase.Setup = function()
    --local modmenu = tryrequire("modmenu.moddatabase")
    --api.debug.Trace("checking if modmenu exists")
    ----api.debug.Trace(table.tostring(modmenu))
    --if modmenu ~= nil then
    --    api.debug.Trace("Found ModMenu")
    --    api.debug.Trace(table.tostring(MOD_INFO))
    --    modmenu.RegisterMod(MOD_INFO)
    --end
    --  api.debug.Trace("checking if forgeUtils exists")
    --  --api.debug.Trace(table.tostring(forgeUtils))
    --  if forgeUtils ~= nil then
    --      api.debug.Trace("Found ForgeUtils")
    --      Mod_SceneryTooMuchScalingLuaDatabase.ForgeUtilsEnabled = true
    --      forgeUtils.RegisterMod(MOD_INFO.mod_name, MOD_INFO.optional_mods[2].min_version)
    --  end
end

Mod_SceneryTooMuchScalingLuaDatabase.Activate = function()
    api.debug.Trace("Mod_SceneryTooMuchScalingLuaDatabase.Activate()")
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

Mod_SceneryTooMuchScalingLuaDatabase._bLoadingBlueprint = false

Mod_SceneryTooMuchScalingLuaDatabase._HookParkLoadSaveManager = function(tModule)
    ---- Saving to local blueprint, inject the config values in.
    tModule._TMSHook_SaveBlueprintToSaveToken = tModule.SaveBlueprintToSaveToken
    tModule.SaveBlueprintToSaveToken = function(self, cSaveTokenOrPlayer, tSaveInfo, cBlueprintSaveSelection, tMetadata,
                                                tScreenshotInfo)
        api.debug.Trace("TooMuchScaling.SaveBlueprintToSaveToken")
        if Mod_SceneryTooMuchScalingLuaDatabase._bLoadingBlueprint then
            api.debug.Trace("Attempting to save blueprint??? HUH??? Ignoring that..")
            return self:_TMSHook_SaveBlueprintToSaveToken(cSaveTokenOrPlayer, tSaveInfo, cBlueprintSaveSelection,
                tMetadata,
                tScreenshotInfo)
        end
        api.debug.Trace("Metadata:")
        api.debug.Trace(table.tostring(tMetadata))
        api.debug.Trace(table.tostring(ScalingDBManager.Global))
        tMetadata.tBlueprint.tTMSScaleValues = ScalingDBManager.Global
        return self:_TMSHook_SaveBlueprintToSaveToken(cSaveTokenOrPlayer, tSaveInfo, cBlueprintSaveSelection, tMetadata,
            tScreenshotInfo)
    end

    ---- Loading from a local blueprint
    tModule._TMSHook_LoadBlueprintFromSaveToken = tModule.LoadBlueprintFromSaveToken
    tModule.LoadBlueprintFromSaveToken = function(self, cSaveToken)
        api.debug.Trace("TooMuchScaling.SaveBlueprintToSaveToken")
        local _successLoad = tModule._TMSHook_LoadBlueprintFromSaveToken(self, cSaveToken)
        if _successLoad then
            local tMetadata = api.save.GetSaveMetadata(cSaveToken)
            api.debug.Trace("Metadata")
            api.debug.Trace(table.tostring(tMetadata))
            if tMetadata.tBlueprint.tTMSScaleValues ~= nil then
                api.debug.Trace(table.tostring(tMetadata.tBlueprint.tTMSScaleValues))
                _successLoad = Mod_SceneryTooMuchScalingLuaDatabase:CheckBlueprintScaleValues(tMetadata.tBlueprint
                    .tTMSScaleValues)
            end
        end
        Mod_SceneryTooMuchScalingLuaDatabase._bLoadingBlueprint = true
        return _successLoad
    end

    ---- Loading from a workshop blueprint
    tModule._TMSHook_LoadBlueprintFromItemToken = tModule.LoadBlueprintFromItemToken
    tModule.LoadBlueprintFromItemToken = function(self, _cItemToken)
        local _bSuccess = tModule._TMSHook_LoadBlueprintFromItemToken(self, _cItemToken)
        if _bSuccess then
            local tMetadata = api.usercontent.GetItemMetadata(_cItemToken)
            api.debug.Trace("Metadata")
            api.debug.Trace(table.tostring(tMetadata))
            if tMetadata.tBlueprint.tTMSScaleValues ~= nil then
                api.debug.Trace(table.tostring(tMetadata.tBlueprint.tTMSScaleValues))
                _bSuccess = Mod_SceneryTooMuchScalingLuaDatabase:CheckBlueprintScaleValues(tMetadata.tBlueprint
                    .tTMSScaleValues)
            end
        end

        Mod_SceneryTooMuchScalingLuaDatabase._bLoadingBlueprint = true
        return _bSuccess
    end
end

--- Used to grab the currently loaded park id for reloading purposes
Mod_SceneryTooMuchScalingLuaDatabase._HookStartScreenHUD = function(tModule)
    tModule._Hook_RequestParkLoadFromSaveToken = tModule._RequestParkLoadFromSaveToken
    tModule._RequestParkLoadFromSaveToken = function(self, _sParkID, _sGameModeOverride)
        api.debug.Trace("TooMuchScaling.RequestParkFromsaveToken")
        api.debug.Trace(_sParkID)
        Mod_SceneryTooMuchScalingLuaDatabase.CurrentSaveParkID = _sParkID
        self:_Hook_RequestParkLoadFromSaveToken(_sParkID, _sGameModeOverride)
    end
end

Mod_SceneryTooMuchScalingLuaDatabase._TMSForgeUtilsShownPopup = false

Mod_SceneryTooMuchScalingLuaDatabase._Hook_StartScreenPopupHelper = function(tModule)
    tModule.RunCheckLocalModification_TMS = tModule._RunCheckLocalModification
    tModule._RunCheckLocalModification = function(self)
        --if Mod_SceneryTooMuchScalingLuaDatabase._TMSForgeUtilsShownPopup then
        --    tModule.RunCheckLocalModification_TMS(self)
        --    return
        --end
        --
        --api.debug.Trace("attempting to check if config is set")
        --Mod_SceneryTooMuchScalingLuaDatabase._TMSForgeUtilsShownPopup = true
        -----Now to check if forgeUtils is installed or not
        --if ScalingDBManager.Global.bGridsAreNotGrids then
        --    api.debug.Trace("grids are grids is enabled")
        --    if not Mod_SceneryTooMuchScalingLuaDatabase.ForgeUtilsEnabled then
        --        api.debug.Trace("ForgeUtils not enabled")
        --        ScalingDBManager.Global.bGridsAreNotGrids = false
        --        local popup = require("Helpers.PopUpDialogUtils")
        --        popup.RunOKDialog(
        --            "[STRING_LITERAL:Value=|TooMuchScaling|]",
        --            "[TMSForgeUtilsNotFound]"
        --        )
        --    end
        --end
        tModule.RunCheckLocalModification_TMS(self) -- run base
    end
end

function Mod_SceneryTooMuchScalingLuaDatabase._HookHUDGamefaceHelper(tModule)
    tModule._TMSHook_OnBrowserItemSelected = tModule.OnBrowserItemSelected
    tModule.OnBrowserItemSelected = function(_self, _sSelectedProp, _sType)
        api.debug.Trace("TooMuchScaling.OnBrowserItemSelected")
        if _sType == "modularScenery" then
            ScalingParkManager:HandleNewSelectedItem(_sSelectedProp)
        end

        tModule._TMSHook_OnBrowserItemSelected(_self, _sSelectedProp, _sType)
    end
end

function Mod_SceneryTooMuchScalingLuaDatabase._HookSubmodePlacement(tModule)
    tModule._TMSHook_ExitSubMode = tModule.ExitSubMode
    tModule.ExitSubMode = function(self)
        tModule._TMSHook_ExitSubMode(self)
        api.debug.Trace("TooMuchScaling.TransitionOut")
        ScalingParkManager.CloseOriginalScaleUI()
    end

    -- Thanks Kaiodenic for the implimentation used for JWE3
    --tModule._TMSHook_CreateMoveObject = tModule._CreateMoveObject
    --tModule._CreateMoveObject = function(self, _clh)
    --    local moveObject = tModule._TMSHook_CreateMoveObject(self, _clh)
    --    local objMetatable = getmetatable(moveObject)
    --    if objMetatable._TMSGetMinScale == nil then
    --        objMetatable._TMSGetMinScale = objMetatable.GetMinScale

    --        objMetatable.GetMinScale = function(self)
    --            if ScalingDBManager.Global.tScale.min ~= nil then
    --                return ScalingDBManager.Global.tScale.min
    --            end
    --            return objMetatable:_TMSGetMinScale()
    --        end
    --    end

    --    if objMetatable._TMSGetMaxScale == nil then
    --        objMetatable._TMSGetMaxScale = objMetatable.GetMaxScale

    --        objMetatable.GetMaxScale = function(self)
    --            if ScalingDBManager.Global.tScale.max ~= nil then
    --                return ScalingDBManager.Global.tScale.max
    --            end
    --            return objMetatable:_TMSGetMaxScale()
    --        end
    --    end
    --    return moveObject
    --end
end

function Mod_SceneryTooMuchScalingLuaDatabase:CheckBlueprintScaleValues(_tConfigValues)
    local _bCanLoad = true
    api.debug.Trace("Current Scale: " ..
        ScalingDBManager.Global.tScale.min .. " - " .. ScalingDBManager.Global.tScale.max)
    api.debug.Trace("Blueprint Scale: " .. _tConfigValues.tScale.min .. " - " .. _tConfigValues.tScale.max)

    local _bScaleDifferent = ScalingDBManager.Global.tScale.min > _tConfigValues.tScale.min or
        ScalingDBManager.Global.tScale.max < _tConfigValues.tScale.max

    if _bScaleDifferent then
        _bCanLoad = false
        local dialogStackManager = api.game.GetEnvironment():RequireInterface("Interfaces.IDialogStack")
        local _sLocalScale = ""
        local _sBlueprintScale = ""
        local _sTriggerEnabled = ""
        if _bScaleDifferent then
            _sLocalScale = "Local Scale: " ..
                tostring(ScalingDBManager.Global.tScale.min * 100) ..
                "% - " .. tostring(ScalingDBManager.Global.tScale.max * 100) .. "%"
            _sBlueprintScale = "Blueprint Scale:" ..
                tostring(_tConfigValues.tScale.min * 100) ..
                "% - " .. tostring(_tConfigValues.tScale.max * 100) .. "%"
        end

        local tData = {
            title = "[STRING_LITERAL:Value=|TooMuchScaling|]",
            content = "[TMSBlueprintScaleDialog:LocalScale=|" ..
                _sLocalScale .. "|:BlueprintScale=|" ..
                _sBlueprintScale .. "|]",
            buttons = {
                {
                    id = "ignore",
                    label = "[Ignore]",
                    inputName = "UI_Cancel"
                },
                {
                    id = "use",
                    label = "[TMSUseValues]",
                    inputName = "UI_Select"
                }
            }
        }


        local OnDialogSelect = function(_inSelf, _sID)
            api.debug.Trace("Dialog button clicked!")
            self.bWaitForInput = nil
            if _sID == "use" then
                ScalingDBManager.Global = _tConfigValues
                _bCanLoad = true
            end
            if _sID == "ignore" then
                _bCanLoad = true
            end
        end

        local nFakeSelf = 2
        api.debug.Trace("Attempting to show dialog")

        self.nDialogID = dialogStackManager:ShowDialog(4, tData, nFakeSelf, OnDialogSelect)
        self.bWaitForInput = true
        while self.bWaitForInput do
            coroutine.yield()
        end
        dialogStackManager:HideDialog(self.nDialogID)
        self.nDialogID = nil
        return _bCanLoad
    end
    return _bCanLoad
end

return Mod_SceneryTooMuchScalingLuaDatabase
