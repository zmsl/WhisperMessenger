local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Theme = ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers = ns.UIHelpers or require("WhisperMessenger.UI.Helpers")

-- The band at the bottom of a window held at a screen edge that the tab strip
-- sits in: the window background darkened, a divider along its top, and room
-- above and below the tabs so Blizzard's tab art is never cut by the screen.
local ScreenEdgeTabBand = {}

local DARKEN = { 0, 0, 0, 0.5 }
local HUD_DIVIDER = 2

-- look: hud (Native HUD divider: 2 px accent; else 1 px window border).
function ScreenEdgeTabBand.Create(factory, frame, look)
  local L = Theme.LAYOUT
  local band = factory.CreateFrame("Frame", nil, frame)
  band:EnableMouse(false)
  band:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  band:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
  band:Hide()
  local fill = band:CreateTexture(nil, "BACKGROUND")
  fill:SetAllPoints(band)
  local divider = band:CreateTexture(nil, "BORDER")
  divider:SetPoint("TOPLEFT", band, "TOPLEFT", 0, 0)
  divider:SetPoint("TOPRIGHT", band, "TOPRIGHT", 0, 0)
  divider:SetHeight(look.hud and HUD_DIVIDER or 1)
  divider:Show()

  return {
    frame = band,
    fill = fill,
    divider = divider,
    -- Shows the band around a strip this tall; returns the band's height.
    show = function(stripHeight)
      local height = L.SCREEN_EDGE_TAB_BAND_PAD_TOP + stripHeight + L.SCREEN_EDGE_TAB_BAND_PAD_BOTTOM
      band:SetHeight(height)
      UIHelpers.applyColorTexture(fill, DARKEN)
      UIHelpers.applyColorTexture(divider, look.hud and Theme.COLORS.accent or Theme.COLORS.window_border)
      band:Show()
      return height
    end,
    hide = function()
      band:Hide()
    end,
  }
end

ns.MessengerWindowChromeBuilderScreenEdgeTabBand = ScreenEdgeTabBand

return ScreenEdgeTabBand
