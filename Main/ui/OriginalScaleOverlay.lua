---
--- ~~copied~~ Based off Parker's Importer UI implementation.
---
local global = _G
---@diagnostic disable-next-line: undefined-field
local api = global.api ---@type Api
local require = global.require
local module = global.module
local tostring = global.tostring

local Object = require("Common.object")
local GamefaceUIWrapper = require("UI.GamefaceUIWrapper")
local table = require("Common.tableplus")
---@class OriginalScaleOverlay
local OriginalScaleOverlay = module(..., Object.subclass(GamefaceUIWrapper))
local ObjectNew = OriginalScaleOverlay.new

OriginalScaleOverlay.new = function(self, _fnOnReadyCallback)
    api.debug.Trace("OriginalScaleOverlay.new()")

    local oNewOriginalScaleOverlay = ObjectNew(OriginalScaleOverlay)
    local tInitSettings = {
        sViewName = "TMSUI",
        sViewAddress = "coui://UIGameface/OriginalScaleOverlay.html",
        bStartEnabled = true,
        fnOnReadyCallback = _fnOnReadyCallback,
        nViewDepth = 1,
        nViewWidth = 1920,
        nViewHeight = 1080,
        bRegisterWrapper = true,
    }
    api.debug.Trace("Attempting to init UI")
    oNewOriginalScaleOverlay:Init(tInitSettings)
    api.debug.Trace("Returning UI")


    return oNewOriginalScaleOverlay
end

function OriginalScaleOverlay:Show(minScale, maxScale)
    api.debug.Trace("OriginalScaleOverlay.Show()")
    local _tData = {
        minscale = minScale,
        maxscale = maxScale
    }
    api.debug.Trace(table.tostring(_tData))
    self:TriggerEventAtNextAdvance("Show", _tData)
end

OriginalScaleOverlay.Hide = function(self)
    api.debug.Trace("OriginalScaleOverlay.Hide()")
    self:TriggerEventAtNextAdvance("Hide")
end
