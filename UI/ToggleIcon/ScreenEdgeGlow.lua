local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Theme = ns.Theme or require("WhisperMessenger.UI.Theme")
local Presets = ns.ThemePresets or require("WhisperMessenger.UI.Theme.Presets")
local UIHelpers = ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local PulseGlow = ns.ToggleIconPulseGlow or require("WhisperMessenger.UI.ToggleIcon.PulseGlow")

-- A soft pulsing strip along the full height of a screen edge, for unread
-- whispers while the window is closed. PulseGlow drives the fade; the texture
-- is a half ellipse fading away from the edge.
local ScreenEdgeGlow = {}

ScreenEdgeGlow.TEXTURE = "Interface\\AddOns\\WhisperMessenger\\Media\\edge-glow.png"

-- settings.edgeGlowColor: "custom" (edgeGlowCustom = { r, g, b }, 0-1), a theme
-- preset key (that preset's accent), or nil / unknown: the active accent.
function ScreenEdgeGlow.ResolveColor(settings, activeTheme)
  local choice = settings.edgeGlowColor
  local custom = settings.edgeGlowCustom
  if choice == "custom" and type(custom) == "table" then
    return { custom[1], custom[2], custom[3], 1 }
  end
  local preset = choice ~= nil and choice ~= "custom" and Presets.Get(choice)
  return preset and preset.accent or activeTheme.COLORS.accent
end

-- options: theme, settings (edgeGlowColor, edgeGlowCustom).
function ScreenEdgeGlow.Create(factory, parent, options)
  options = options or {}
  local theme = options.theme or Theme
  local settings = options.settings or {}
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

  -- Repainted on every refresh, so a colour setting applies at once.
  local lastTheme = theme
  local function paint(activeTheme)
    lastTheme = activeTheme or lastTheme
    UIHelpers.applyVertexColor(pulse.glowTexture, ScreenEdgeGlow.ResolveColor(settings, lastTheme))
  end
  paint()

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
    paint = paint,
    refreshTheme = paint,
  }
end

ns.ToggleIconScreenEdgeGlow = ScreenEdgeGlow

return ScreenEdgeGlow
