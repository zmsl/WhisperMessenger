local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Theme = ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers = ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local Badge = ns.Badge or require("WhisperMessenger.UI.Badge")
local IconArt = ns.ToggleIconIconArt or require("WhisperMessenger.UI.ToggleIcon.IconArt")
local IconBorder = ns.ToggleIconIconBorder or require("WhisperMessenger.UI.ToggleIcon.IconBorder")
local IconLooks = ns.ToggleIconIconLooks or require("WhisperMessenger.UI.ToggleIcon.IconLooks")
local SquareLook = ns.ToggleIconSquareLook or require("WhisperMessenger.UI.ToggleIcon.SquareLook")
local isOn = UIHelpers.isOn

-- The clickable tab on the screen edge (flat side on the edge). It wears the
-- floating button's Icons settings through the same getters: the circle
-- shape is a half capsule, the square a tab cut from the square frame; the
-- border and background settings take the rim and fill off; the rim is tinted
-- like the button's border; it fades like the button. The unread whisper
-- count runs down its middle as stacked characters. The art (drawn by
-- scripts/compose_gold_ring.py at this size) has its flat side on the left;
-- the right edge mirrors it.
local ScreenEdgeHandle = {}

local MEDIA = "Interface\\AddOns\\WhisperMessenger\\Media\\"
ScreenEdgeHandle.CAPSULE_TEXTURE = MEDIA .. "handle_capsule_gold.png"
ScreenEdgeHandle.CAPSULE_MASK_TEXTURE = MEDIA .. "handle_capsule_mask.png"
ScreenEdgeHandle.TAB_TEXTURE = MEDIA .. "handle_tab_gold.png"
-- Where the client rounds the button's square (mask textures), the tab's inner corners round too.
ScreenEdgeHandle.TAB_ROUNDED_TEXTURE = MEDIA .. "handle_tab_gold_rounded.png"

-- The square fill stops at the tab rim's mid-band, so it never shows past a rounded corner.
local TAB_FILL_INSET = 2

-- "12" -> "1\n2".
local function stacked(text)
  return (text:gsub(".", "%0\n"):sub(1, -2))
end

-- options: theme, onClick, looks (the Icons-page getters: getWidgetShape,
-- getIconBorder, getIconBackground, getIconBorderThemed, getWidgetTransparency).
function ScreenEdgeHandle.Create(factory, parent, options)
  local theme = options.theme or Theme
  local layout = theme.LAYOUT
  local looks = options.looks or {}
  local frame = factory.CreateFrame("Button", nil, parent)
  frame:SetFrameStrata("MEDIUM")
  frame:SetSize(layout.SCREEN_EDGE_HANDLE_WIDTH, layout.SCREEN_EDGE_HANDLE_HEIGHT)
  frame:EnableMouse(true)
  frame:Hide()

  local fill = frame:CreateTexture(nil, "BACKGROUND")
  local rim = frame:CreateTexture(nil, "BORDER")
  rim:SetAllPoints(frame)
  local label = frame:CreateFontString(nil, "OVERLAY", Theme.FONTS.unread_badge)
  label:SetPoint("CENTER", frame, "CENTER", 0, 0)
  label:SetJustifyH("CENTER")
  label:Hide()

  local hover = { active = false }
  local transparency = IconLooks.IconTransparency.Create(frame, {
    hover = hover,
    getWidgetTransparency = looks.getWidgetTransparency,
  })
  local side

  local function paint()
    local square = looks.getWidgetShape and looks.getWidgetShape() == "square"
    local right = side == "right"
    fill:ClearAllPoints()
    if square then
      fill:SetTexture(SquareLook.SQUARE_TEXTURE)
      -- Inset on the inner side, top and bottom; flush on the screen side.
      local inner, outer = right and "LEFT" or "RIGHT", right and "RIGHT" or "LEFT"
      fill:SetPoint("TOP" .. inner, frame, "TOP" .. inner, right and TAB_FILL_INSET or -TAB_FILL_INSET, -TAB_FILL_INSET)
      fill:SetPoint("BOTTOM" .. outer, frame, "BOTTOM" .. outer, 0, TAB_FILL_INSET)
      rim:SetTexture(frame.CreateMaskTexture and ScreenEdgeHandle.TAB_ROUNDED_TEXTURE or ScreenEdgeHandle.TAB_TEXTURE)
    else
      fill:SetAllPoints(frame)
      fill:SetTexture(ScreenEdgeHandle.CAPSULE_MASK_TEXTURE)
      rim:SetTexture(ScreenEdgeHandle.CAPSULE_TEXTURE)
    end
    for _, tex in ipairs({ fill, rim }) do
      tex:SetTexCoord(right and 1 or 0, right and 0 or 1, 0, 1)
    end
    UIHelpers.applyVertexColor(fill, hover.active and IconArt.ResolveHoverBgColor() or Theme.COLORS.toggle_icon_bg)
    fill:SetShown(isOn(looks.getIconBackground))
    IconBorder.Tint(rim, isOn(looks.getIconBorderThemed))
    rim:SetShown(isOn(looks.getIconBorder))
    UIHelpers.setTextColor(label, Theme.COLORS.accent)
    transparency.refresh()
  end

  frame:SetScript("OnClick", function()
    options.onClick()
  end)
  frame:SetScript("OnEnter", function()
    hover.active = true
    paint()
  end)
  frame:SetScript("OnLeave", function()
    hover.active = false
    paint()
  end)

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
    local text = Badge.Text(count)
    label:SetText(stacked(text))
    label:SetShown(text ~= "")
    transparency.setHasUnread(text ~= "")
  end

  paint()

  return {
    frame = frame,
    fill = fill,
    rim = rim,
    label = label,
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
