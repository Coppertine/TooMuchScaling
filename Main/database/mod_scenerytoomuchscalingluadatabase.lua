local global = _G
local api = global.api ---@type Api
local pairs = global.pairs
local require = global.require
local tryrequire = global.tryrequire
local table = require("Common.tableplus")
local SceneryDBManager = require("Database.Mod_SceneryToomuchScaling.ScalingDBManager")
local ScalingParkManager = require("Managers.ScalingParkManager")
local forgeUtils = tryrequire("forgeutils.moddb")
---@class Mod_SceneryTooMuchScalingLuaDatabase
local Mod_SceneryTooMuchScalingLuaDatabase = module(...)
Mod_SceneryTooMuchScalingLuaDatabase.CurrentSaveParkID = nil

--- Mod information for ModMenu
local MOD_INFO = {
    mod_name = "TooMuchScaling",
    author = "Coppertine",
    mod_version = 2.0,
    description = "Expands the range of scalable objects to an extreme degree.",
    optional_mods = {
        { mod = "Mod_ModMenu", min_version = 1.0 },
        { mod = "ForgeUtils",  min_version = 1.0 }
    },
    incompatable_mods = {
        "ACSEDebug"
    },
    mod_folder = "Mod_SceneryTooMuchScaling"
}

Mod_SceneryTooMuchScalingLuaDatabase.ForgeUtilsEnabled = false

Mod_SceneryTooMuchScalingLuaDatabase.AddContentToCall = function(_tContentToCall)
    if not global.api.acse or global.api.acse.versionNumber < 0.7 then
        return
    end

    table.insert(_tContentToCall, Mod_SceneryTooMuchScalingLuaDatabase)
    table.insert(_tContentToCall, require("Database.Mod_SceneryTooMuchScaling.ScalingDBManager"))
end

Mod_SceneryTooMuchScalingLuaDatabase.Init = function()
    api.debug.Trace("Mod_SceneryTooMuchScalingLuaDatabase.Init()")
    api.ui2.MapResources("TMSUI")

    Mod_SceneryTooMuchScalingLuaDatabase._HookParkLoadSaveManager(require("Managers.ParkLoadSaveManager"))
end

Mod_SceneryTooMuchScalingLuaDatabase.Shutdown = function()
    api.ui2.UnmapResources("TMSUI")
end

Mod_SceneryTooMuchScalingLuaDatabase.Setup = function()
    local modmenu = tryrequire("modmenu.moddatabase")
    api.debug.Trace("checking if modmenu exists")
    --api.debug.Trace(table.tostring(modmenu))
    if modmenu ~= nil then
        api.debug.Trace("Found ModMenu")
        api.debug.Trace(table.tostring(MOD_INFO))
        modmenu.RegisterMod(MOD_INFO)
    end
    api.debug.Trace("checking if forgeUtils exists")
    --api.debug.Trace(table.tostring(forgeUtils))
    if forgeUtils ~= nil then
        api.debug.Trace("Found ForgeUtils")
        Mod_SceneryTooMuchScalingLuaDatabase.ForgeUtilsEnabled = true
        forgeUtils.RegisterMod(MOD_INFO.mod_name, MOD_INFO.optional_mods[2].min_version)
    end
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

Mod_SceneryTooMuchScalingLuaDatabase._HookParkLoadSaveManager = function(tModule)
    ---- Saving to local blueprint, inject the config values in.
    tModule._TMSHook_SaveBlueprintToSaveToken = tModule.SaveBlueprintToSaveToken
    tModule.SaveBlueprintToSaveToken = function(self, cSaveTokenOrPlayer, tSaveInfo, cBlueprintSaveSelection, tMetadata,
                                                tScreenshotInfo)
        api.debug.Trace("TooMuchScaling.SaveBlueprintToSaveToken")
        api.debug.Trace("Metadata:")
        api.debug.Trace(table.tostring(tMetadata))
        api.debug.Trace(table.tostring(ScalingDBManager.Global))
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
            api.debug.Trace(table.tostring(tMetadata.tBlueprint.tTMSScaleValues))
            Mod_SceneryTooMuchScalingLuaDatabase.CheckBlueprintScaleValues(tMetadata.tBlueprint.tTMSScaleValues)
        end
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
            api.debug.Trace(table.tostring(tMetadata.tBlueprint.tTMSScaleValues))
            Mod_SceneryTooMuchScalingLuaDatabase.CheckBlueprintScaleValues(tMetadata.tBlueprint.tTMSScaleValues)
        end
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
        if Mod_SceneryTooMuchScalingLuaDatabase._TMSForgeUtilsShownPopup then
            tModule.RunCheckLocalModification_TMS(self)
            return
        end

        api.debug.Trace("attempting to check if config is set")
        Mod_SceneryTooMuchScalingLuaDatabase._TMSForgeUtilsShownPopup = true
        ---Now to check if forgeUtils is installed or not
        if SceneryDBManager.Global.bGridsAreNotGrids then
            api.debug.Trace("grids are grids is enabled")
            if not Mod_SceneryTooMuchScalingLuaDatabase.ForgeUtilsEnabled then
                api.debug.Trace("ForgeUtils not enabled")
                SceneryDBManager.Global.bGridsAreNotGrids = false
                local popup = require("Helpers.PopUpDialogUtils")
                popup.RunOKDialog(
                    "[STRING_LITERAL:Value=|TooMuchScaling|]",
                    "[TMSForgeUtilsNotFound]"
                )
            end
        end
        tModule.RunCheckLocalModification_TMS(self) -- run base
    end
end

Mod_SceneryTooMuchScalingLuaDatabase._HookHUDGamefaceHelper = function(tModule)
    tModule.OnBrowserItemSelected_TMS = tModule.OnBrowserItemSelected
    tModule.OnBrowserItemSelected = function(_self, _sSelectedProp, _sType)
        api.debug.Trace("TooMuchScaling.OnBrowserItemSelected")
        if _sType == "modularScenery" then
            ScalingParkManager:HandleNewSelectedItem(_sSelectedProp)
        end

        tModule.OnBrowserItemSelected_TMS(_self, _sSelectedProp, _sType)
    end
end

Mod_SceneryTooMuchScalingLuaDatabase.tLuaHooks = {
    ["StartScreen.Shared.StartScreenHUD"] = Mod_SceneryTooMuchScalingLuaDatabase._HookStartScreenHUD,
    ["StartScreen.Shared.StartScreenPopupHelper"] = Mod_SceneryTooMuchScalingLuaDatabase
        ._Hook_StartScreenPopupHelper,
    ["Windows.HUDGamefaceHelper"] = Mod_SceneryTooMuchScalingLuaDatabase._HookHUDGamefaceHelper
}


Mod_SceneryTooMuchScalingLuaDatabase.AddLuaHooks = function(_fnAdd)
    for key, value in pairs(Mod_SceneryTooMuchScalingLuaDatabase.tLuaHooks) do
        _fnAdd(key, value)
    end
end


function Mod_SceneryTooMuchScalingLuaDatabase.CheckBlueprintScaleValues(_tConfigValues)

end
