local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Theme = ns.Theme or require("WhisperMessenger.UI.Theme")
local PulseGlow = ns.ToggleIconPulseGlow or require("WhisperMessenger.UI.ToggleIcon.PulseGlow")

-- A soft pulsing strip along the full height of a screen edge, for unread
-- whispers while the window is closed. PulseGlow drives the fade; the texture
-- is a half ellipse fading away from the edge.
local ScreenEdgeGlow = {}

ScreenEdgeGlow.TEXTURE = "Interface\\AddOns\\WhisperMessenger\\Media\\edge-glow.png"

-- options: theme.
function ScreenEdgeGlow.Create(factory, parent, options)
  options = options or {}
  local theme = options.theme or Theme
  local frame = factory.CreateFrame("Frame", nil, parent)
  frame:SetFrameStrata("BACKGROUND")
  frame:EnableMouse(false)
  frame:Hide()

  local pulse = PulseGlow.Create(factory, frame, {
    theme = theme,
    cycleSeconds = theme.LAYOUT.SCREEN_EDGE_GLOW_CYCLE_SECONDS,
  })
  pulse.glowTexture:SetTexture(ScreenEdgeGlow.TEXTURE)

  -- The height is read every time: a UI-scale change moves the parent's height.
  local function setSide(side)
    frame:ClearAllPoints()
    if side == nil then
      return
    end
    local point = side == "right" and "RIGHT" or "LEFT"
    frame:SetPoint(point, parent, point)
    frame:SetSize(theme.LAYOUT.SCREEN_EDGE_GLOW_DEPTH, parent:GetHeight())
    if side == "right" then
      pulse.glowTexture:SetTexCoord(1, 0, 0, 1)
    else
      pulse.glowTexture:SetTexCoord(0, 1, 0, 1)
    end
  end

  local function setLit(on)
    if on then
      frame:Show()
      pulse.start()
    else
      pulse.stop()
      frame:Hide()
    end
  end

  return {
    frame = frame,
    pulse = pulse,
    setSide = setSide,
    setLit = setLit,
    refreshTheme = pulse.applyTheme,
  }
end

ns.ToggleIconScreenEdgeGlow = ScreenEdgeGlow

return ScreenEdgeGlow
