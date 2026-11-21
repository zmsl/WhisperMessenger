local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Theme = ns.Theme or require("WhisperMessenger.UI.Theme")
local Hud = ns.Hud or require("WhisperMessenger.UI.Theme.Hud")
local UIHelpers = ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local Badge = ns.Badge or require("WhisperMessenger.UI.Badge")

-- The clickable half disc on the screen edge (flat side on the edge): a fill
-- in the window background with a chat icon, under a half ring (Native HUD:
-- its own gold; custom: desaturated and tinted with the window border), with
-- the shared unread badge on the upper inner curve. The art (drawn by
-- scripts/compose_gold_ring.py) has its flat side on the left; the right edge
-- mirrors it.
local ScreenEdgeHandle = {}

ScreenEdgeHandle.FILL_TEXTURE = "Interface\\AddOns\\WhisperMessenger\\Media\\half_disc_mask.png"
ScreenEdgeHandle.RIM_TEXTURE = "Interface\\AddOns\\WhisperMessenger\\Media\\half_ring_gold.png"

local WHITE = { 1, 1, 1, 1 }

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
  fill:SetTexture(ScreenEdgeHandle.FILL_TEXTURE)
  local rim = frame:CreateTexture(nil, "BORDER")
  rim:SetAllPoints(frame)
  rim:SetTexture(ScreenEdgeHandle.RIM_TEXTURE)
  rim:SetDesaturated(not hud)
  local icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(theme.TEXTURES.nav_whispers_icon)
  icon:SetSize(layout.SCREEN_EDGE_HANDLE_ICON_SIZE, layout.SCREEN_EDGE_HANDLE_ICON_SIZE)
  local badge = Badge.Create(factory, frame, { size = layout.SCREEN_EDGE_HANDLE_BADGE_SIZE, outline = true })

  local function paint(activeTheme)
    local colors = (activeTheme or theme).COLORS
    UIHelpers.applyVertexColor(fill, colors.bg_primary)
    UIHelpers.applyVertexColor(rim, hud and WHITE or colors.window_border)
    UIHelpers.applyVertexColor(icon, colors.accent)
    badge.paint()
  end

  local function setSide(side)
    frame:ClearAllPoints()
    icon:ClearAllPoints()
    badge.frame:ClearAllPoints()
    local right = side == "right"
    for _, tex in ipairs({ fill, rim }) do
      tex:SetTexCoord(right and 1 or 0, right and 0 or 1, 0, 1)
    end
    if side == nil then
      return
    end
    local point = right and "RIGHT" or "LEFT"
    local inward = right and -1 or 1
    frame:SetPoint(point, parent, point)
    icon:SetPoint("CENTER", frame, point, inward * layout.SCREEN_EDGE_HANDLE_ICON_INSET, 0)
    -- On the curve, inward from the edge, so the badge never reaches past the screen.
    local offset = layout.SCREEN_EDGE_HANDLE_BADGE_OFFSET
    badge.frame:SetPoint("CENTER", frame, point, inward * offset, offset)
  end

  paint()

  return {
    frame = frame,
    fill = fill,
    rim = rim,
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
