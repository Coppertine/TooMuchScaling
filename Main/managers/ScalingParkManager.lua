local global = _G
local api = global.api --- @type Api
local require = global.require
local ScalingDBManager = require("Database.Mod_SceneryTooMuchScaling.ScalingDBManager")
local VersionControlHUD = require("StartScreen.Shared.VersionControlHUD")
local Mutators = require("Environment.ModuleMutators")
local tostring = global.tostring
local table = require("Common.tableplus")
local OriginalScaleOverlay = require("UI.OriginalScaleOverlay")
local TMSLuaDatabase = require("Database.Mod_SceneryTooMuchScalingLuaDatabase")
---@class ScalingParkManager
local ScalingParkManager = module(..., Mutators.Manager())


local dbgTrace = function(_line)
	api.debug.Trace("TooMuchScaling: " .. _line)
end

function ScalingParkManager.Init(self, _tProperties, _tEnvironment)
	dbgTrace("ScalingParkManager.Init()")
	--self.parkLoadSaveManager = _tEnvironment:RequireInterface("Interfaces.IParkLoadSaveManager")
end

function ScalingParkManager.ReloadParkWithNewScales(self, _tScale)
	dbgTrace(TMSLuaDatabase.CurrentSaveParkID)
	dbgTrace("Setting new scale")
	ScalingDBManager._IgnoreConfigLoad = true
	ScalingDBManager.Global = _tScale
	dbgTrace("Reloading park")
	local tEnvironment = api.game.GetEnvironment()
	local parkLoadSaveManager = tEnvironment:RequireInterface("Interfaces.IParkLoadSaveManager")
	if not parkLoadSaveManager then
		dbgTrace("parkloadsavemanager does not exist")
	end
	local tParkData = parkLoadSaveManager:GetParkDataFromID(TMSLuaDatabase.CurrentSaveParkID)

	dbgTrace('got park data')
	dbgTrace(table.tostring(tParkData))
	parkLoadSaveManager:LoadParkFromSaveToken(tParkData.token)
end

function ScalingParkManager.Activate(self)
	dbgTrace("ScalingParkManager.Activate()")
	dbgTrace("Attempting to show overlay")
	---- Here for UI overlay intialisation
	self.ui = OriginalScaleOverlay:new(function()
		api.debug.Trace("Mod_SceneryTooMuchScaling.ScalingPakManager:OriginalScaleOverlay is ready")
		if self.ui then
			--self.ui:Show()
			--if self.InEditor then
			--	self.ui:Show()
			--else
			--	self.ui:Hide()
			--end
		end
	end)

	local _tTmpConfig = ScalingDBManager._tTmpConfig
	if _tTmpConfig == nil then
		return
	end
	dbgTrace("Current Scale: " .. ScalingDBManager.Global.tScale.min .. " - " .. ScalingDBManager.Global.tScale.max)
	dbgTrace("Park Scale: " .. _tTmpConfig.tScale.min .. " - " .. _tTmpConfig.tScale.max)

	local _bScaleDifferent = ScalingDBManager.Global.tScale.min > _tTmpConfig.tScale.min or
	    ScalingDBManager.Global.tScale.max < _tTmpConfig.tScale.max

	local _bTriggerDiffernet = _tTmpConfig.bAlwaysScaleTriggeredProps == true and
	    ScalingDBManager.Global.bAlwaysScaleTriggeredProps == false

	local _bGridDifferent = _tTmpConfig.bGridsAreNotGrids == true and
	    ScalingDBManager.Global.bGridsAreNotGrids == false


	if _bScaleDifferent or _bGridDifferent or _bTriggerDiffernet then
		dbgTrace("Scaling values are differnet, displaying popup to player.")
		local dialogStackManager = api.game.GetEnvironment():RequireInterface("Interfaces.IDialogStack")
		dbgTrace("Grabbed stack manager")
		local _sLocalScale = ""
		local _sParkScale = ""
		local _sGridEnabled = ""
		local _sTriggerEnabled = ""
		if _bScaleDifferent then
			_sLocalScale = "Local Scale: " ..
			    tostring(ScalingDBManager.Global.tScale.min * 100) ..
			    "% -> " .. tostring(ScalingDBManager.Global.tScale.max * 100) .. "%"
			_sParkScale = "Park Scale:" ..
			    tostring(_tTmpConfig.tScale.min * 100) ..
			    "% -> " .. tostring(_tTmpConfig.tScale.max * 100) .. "%"
		end
		if _bGridDifferent then
			_sGridEnabled = api.loc.GetLocalisedText("TMSGridNotEnabled")
		end
		if _bTriggerDiffernet then
			_sTriggerEnabled = api.loc.GetLocalisedText("TMSTriggerNotEnabled")
		end
		local tData = {
			title = "[STRING_LITERAL:Value=|TooMuchScaling|]",
			content = "[TMSParkScaleDialog:LocalScale=|" ..
			    _sLocalScale .. "|:ParkScale=|" ..
			    _sParkScale .. "|:Trigger=|" .. _sTriggerEnabled .. "|:Grid=|" .. _sGridEnabled .. "|]",
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

		local bDialogInProgress = true

		local OnDialogSelect = function(_inSelf, _sID)
			dbgTrace("Dialog button clicked!")
			--	bDialogInProgress = false
			if _sID == "use" then
				dbgTrace("Reloading park with new values")
				--- call a "reload park thing here.."
				ScalingParkManager:ReloadParkWithNewScales(_tTmpConfig)
			end
			dbgTrace("dialog closing")
			dialogStackManager:HideDialog(nDialogID)
			nDialogID = nil
		end

		local nFakeSelf = 2
		dbgTrace("Attempting to show dialog")
		nDialogID = dialogStackManager:ShowDialog(1, tData, nFakeSelf, OnDialogSelect)
	end
end

Mutators.VerifyManagerModule(ScalingParkManager)
