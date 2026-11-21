local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Theme = ns.Theme or require("WhisperMessenger.UI.Theme")
local Hud = ns.Hud or require("WhisperMessenger.UI.Theme.Hud")
local UIHelpers = ns.UIHelpers or require("WhisperMessenger.UI.Helpers")

-- The clickable tab on the screen edge, styled like the window: the Native HUD
-- window's own side tile, or a bordered fill with the screen side left open.
local ScreenEdgeHandle = {}

-- options: theme, onClick.
function ScreenEdgeHandle.Create(factory, parent, options)
  local theme = options.theme or Theme
  local layout = theme.LAYOUT
  local frame = factory.CreateFrame("Button", nil, parent)
  frame:SetFrameStrata("MEDIUM")
  frame:SetSize(layout.SCREEN_EDGE_HANDLE_WIDTH, layout.SCREEN_EDGE_HANDLE_HEIGHT)
  frame:EnableMouse(true)
  frame:SetScript("OnClick", function()
    options.onClick()
  end)
  frame:Hide()

  local fill = frame:CreateTexture(nil, "BACKGROUND")
  fill:SetAllPoints(frame)
  local border = UIHelpers.createBorderBox(frame, theme.COLORS.window_border, 1)
  local tile = frame:CreateTexture(nil, "ARTWORK")
  local badge = frame:CreateFontString(nil, "OVERLAY")
  UIHelpers.setFontObject(badge, theme.FONTS.unread_badge)
  badge:SetPoint("BOTTOM", frame, "TOP", 0, 2)
  badge:Hide()

  local side
  local function paint(activeTheme)
    local colors = (activeTheme or theme).COLORS
    UIHelpers.applyColorTexture(fill, colors.bg_primary)
    UIHelpers.applyBorderBoxColor(border, colors.window_border)
    UIHelpers.setTextColor(badge, colors.unread_badge)
    local hud = Hud.IsOn()
    if hud then
      tile:ClearAllPoints()
      local inner = side == "right" and "LEFT" or "RIGHT"
      tile:SetPoint("TOP" .. inner, frame, "TOP" .. inner, 0, 0)
      tile:SetPoint("BOTTOM" .. inner, frame, "BOTTOM" .. inner, 0, 0)
      tile:SetWidth(layout.SCREEN_EDGE_HANDLE_WIDTH)
      if tile.SetAtlas then
        tile:SetAtlas(side == "right" and "!UI-Frame-LeftTile" or "!UI-Frame-RightTile")
      end
    end
    tile:SetShown(hud)
    UIHelpers.setBorderEdgesShown(border, not hud and { top = true, bottom = true, left = side == "right", right = side ~= "right" } or {})
  end

  local function setSide(nextSide)
    side = nextSide
    frame:ClearAllPoints()
    if side ~= nil then
      local point = side == "right" and "RIGHT" or "LEFT"
      frame:SetPoint(point, parent, point)
    end
    paint()
  end

  local function setCount(count)
    count = count or 0
    badge:SetText(tostring(count))
    badge:SetShown(count > 0)
  end

  return {
    frame = frame,
    border = border,
    tile = tile,
    badge = badge,
    setSide = setSide,
    setShown = function(shown)
      frame:SetShown(shown)
    end,
    setCount = setCount,
    refreshTheme = paint,
  }
end

ns.ToggleIconScreenEdgeHandle = ScreenEdgeHandle

return ScreenEdgeHandle
