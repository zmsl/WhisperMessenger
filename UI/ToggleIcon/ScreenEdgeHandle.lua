local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Theme = ns.Theme or require("WhisperMessenger.UI.Theme")
local Hud = ns.Hud or require("WhisperMessenger.UI.Theme.Hud")
local UIHelpers = ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local Badge = ns.Badge or require("WhisperMessenger.UI.Badge")

-- The clickable icon tab on the screen edge: a dark fill with a chat icon,
-- rimmed on its three inner sides (Native HUD: a 2 px accent rim; custom: the
-- window's 1 px border), with the shared unread badge on its inner top corner.
local ScreenEdgeHandle = {}

local HUD_RIM = 2

-- options: theme, onClick.
function ScreenEdgeHandle.Create(factory, parent, options)
  local theme = options.theme or Theme
  local layout = theme.LAYOUT
  local hud = Hud.IsOn()
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
  local border = UIHelpers.createBorderBox(frame, nil, hud and HUD_RIM or 1)
  local icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(theme.TEXTURES.nav_whispers_icon)
  icon:SetSize(layout.SCREEN_EDGE_HANDLE_ICON_SIZE, layout.SCREEN_EDGE_HANDLE_ICON_SIZE)
  icon:SetPoint("CENTER", frame, "CENTER", 0, 0)
  local badge = Badge.Create(factory, frame, { size = layout.SCREEN_EDGE_HANDLE_BADGE_SIZE, outline = true })

  local side
  local function paint(activeTheme)
    local colors = (activeTheme or theme).COLORS
    UIHelpers.applyColorTexture(fill, colors.bg_primary)
    UIHelpers.applyBorderBoxColor(border, hud and colors.accent or colors.window_border)
    UIHelpers.applyVertexColor(icon, colors.accent)
    badge.paint()
  end

  local function setSide(nextSide)
    side = nextSide
    frame:ClearAllPoints()
    badge.frame:ClearAllPoints()
    if side ~= nil then
      local point = side == "right" and "RIGHT" or "LEFT"
      frame:SetPoint(point, parent, point)
      -- The inner top corner, so the badge never reaches past the screen edge.
      badge.frame:SetPoint("CENTER", frame, side == "right" and "TOPLEFT" or "TOPRIGHT", 0, 0)
    end
    UIHelpers.setBorderEdgesShown(border, { top = true, bottom = true, left = side == "right", right = side ~= "right" })
  end

  paint()

  return {
    frame = frame,
    border = border,
    icon = icon,
    badge = badge,
    setSide = setSide,
    setShown = function(shown)
      frame:SetShown(shown)
    end,
    setCount = badge.setCount,
    refreshTheme = paint,
  }
end

ns.ToggleIconScreenEdgeHandle = ScreenEdgeHandle

return ScreenEdgeHandle
