local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Theme = ns.Theme or require("WhisperMessenger.UI.Theme")
local Localization = ns.Localization or require("WhisperMessenger.Locale.Localization")
local Options = ns.AppearanceSettingsOptions or require("WhisperMessenger.UI.MessengerWindow.AppearanceSettings.Options")
local ColorPicker = ns.AppearanceSettingsColorPicker or require("WhisperMessenger.UI.MessengerWindow.AppearanceSettings.ColorPicker")
local ScreenEdgeGlow = ns.ToggleIconScreenEdgeGlow or require("WhisperMessenger.UI.ToggleIcon.ScreenEdgeGlow")

-- The Screen edge rows on Appearance, slotted into the window style toggles:
-- "Screen edge" under Compact window, "Glow color" under Edge glow. Glow color
-- is a theme preset's accent or a custom colour from the game's picker;
-- nothing saved follows the active preset, which shows as picked.
local ScreenEdgeRows = {}

local SCREEN_EDGE_DEFAULT = "off"
local CUSTOM = "custom"
local SWATCH_SIZE = 10
local SWATCH_INSET = 6

local function createGlowColor(sel, panel, config, onChange)
  local saved = { edgeGlowColor = config.edgeGlowColor, edgeGlowCustom = config.edgeGlowCustom }
  local selector, swatch

  local function shownKey()
    return saved.edgeGlowColor or Theme.GetPreset()
  end

  local function paintSwatch()
    local c = saved.edgeGlowCustom
    if type(c) == "table" then
      swatch:SetColorTexture(c.r, c.g, c.b, 1)
      swatch:Show()
    else
      swatch:Hide()
    end
  end

  local function set(color, custom)
    saved.edgeGlowColor, saved.edgeGlowCustom = color, custom
    onChange("edgeGlowColor", color)
    onChange("edgeGlowCustom", custom)
    paintSwatch()
    selector.setSelected(shownKey())
  end

  local function openPicker()
    local before = { edgeGlowColor = saved.edgeGlowColor, edgeGlowCustom = saved.edgeGlowCustom }
    local c = ScreenEdgeGlow.ResolveColor(saved, Theme)
    local opened = ColorPicker.Open(c[1], c[2], c[3], function(r, g, b)
      set(CUSTOM, { r = r, g = g, b = b })
    end, function()
      set(before.edgeGlowColor, before.edgeGlowCustom)
    end)
    if not opened then
      selector.setSelected(shownKey())
    end
  end

  selector = sel(Localization.Text("Glow color"), Options.BuildGlowColorOptions(), shownKey(), shownKey(), function(key)
    if key == CUSTOM then
      openPicker()
      return
    end
    saved.edgeGlowColor = key
    onChange("edgeGlowColor", key)
  end)

  local customButton = selector.buttons[#selector.buttons]
  swatch = customButton:CreateTexture(nil, "OVERLAY")
  swatch:SetSize(SWATCH_SIZE, SWATCH_SIZE)
  swatch:SetPoint("RIGHT", customButton, "RIGHT", -SWATCH_INSET, 0)
  customButton.swatch = swatch
  paintSwatch()

  -- A theme preset change moves the pick while nothing is saved.
  local applyTheme = selector.applyTheme
  selector.applyTheme = function(...)
    applyTheme(...)
    selector.setSelected(shownKey())
  end

  function selector.setLanguage()
    selector.label:SetText(Localization.Text("Glow color"))
    selector.setOptionsList(Options.BuildGlowColorOptions())
  end

  return panel:bind(selector, {
    type = "selector",
    reset = function()
      set(nil, nil)
    end,
  })
end

-- Slots a row into the toggle list between two toggles.
local function slotRow(row, above, below, gap)
  row:SetPoint("TOPLEFT", above.row, "BOTTOMLEFT", 0, gap)
  below.row:ClearAllPoints()
  below.row:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, gap)
end

-- sel: AppearanceSettings' ButtonSelector builder; toggles: the window style
-- toggles (Compact window, Edge glow, Window animation, ...).
function ScreenEdgeRows.Create(sel, panel, config, onChange, toggles, gap)
  local screenEdge = panel:bind(
    sel(Localization.Text("Screen edge"), Options.BuildScreenEdgeOptions(), SCREEN_EDGE_DEFAULT, config.screenEdge or SCREEN_EDGE_DEFAULT, function(v)
      onChange("screenEdge", v)
    end),
    { type = "selector", key = "screenEdge", default = SCREEN_EDGE_DEFAULT }
  )
  slotRow(screenEdge.row, toggles[1], toggles[2], gap)
  local glowColor = createGlowColor(sel, panel, config, onChange)
  slotRow(glowColor.row, toggles[2], toggles[3], gap)

  return {
    setLanguage = function()
      screenEdge.label:SetText(Localization.Text("Screen edge"))
      screenEdge.setOptionsList(Options.BuildScreenEdgeOptions())
      glowColor.setLanguage()
    end,
  }
end

ns.AppearanceSettingsScreenEdgeRows = ScreenEdgeRows
return ScreenEdgeRows
