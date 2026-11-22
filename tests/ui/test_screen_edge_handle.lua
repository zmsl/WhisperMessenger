-- The edge handle: a 22 x 104 tab on the screen edge (flat side on the edge)
-- that opens the closed window. It wears the floating button's Icons settings
-- (shape, border, background, themed border, transparency) through the same
-- getters, and shows the unread whisper count as stacked digits.
local AnimatedFactory = require("tests.helpers.animated_factory")
local ScreenEdgeSurface = require("WhisperMessenger.UI.ToggleIcon.ScreenEdgeSurface")
local ScreenEdgeHandle = require("WhisperMessenger.UI.ToggleIcon.ScreenEdgeHandle")
local SquareLook = require("WhisperMessenger.UI.ToggleIcon.SquareLook")
local IconRuntime = require("WhisperMessenger.Core.Bootstrap.WindowRuntime.IconRuntime")
local Theme = require("WhisperMessenger.UI.Theme")
local FindUI = require("tests.helpers.find_ui")

local function build(settings)
  local factory = AnimatedFactory.newAnimatedFactory()
  local parent = factory.CreateFrame("Frame", "UIParent", nil)
  parent:SetSize(1920, 1080)
  local state = { side = "left", shown = false, clicks = 0 }
  settings = settings or {}
  local surface = ScreenEdgeSurface.Create(factory, parent, {
    theme = Theme,
    settings = settings,
    looks = IconRuntime.LookGetters(settings),
    getSide = function()
      return state.side
    end,
    isWindowShown = function()
      return state.shown
    end,
    onClick = function()
      state.clicks = state.clicks + 1
    end,
  })
  return surface, state, settings, parent
end

local function sameColor(got, want)
  return got ~= nil and got[1] == want[1] and got[2] == want[2] and got[3] == want[3]
end

return function()
  -- test_handle_shows_only_while_the_window_is_hidden_and_the_setting_is_on
  do
    local surface, state, settings = build()
    assert(surface.handle.frame:IsShown(), "a hidden window shows the handle")
    state.shown = true
    surface.refresh()
    assert(not surface.handle.frame:IsShown(), "a shown window hides the handle")
    state.shown = false
    settings.edgeHandle = false
    surface.refresh()
    assert(not surface.handle.frame:IsShown(), "edgeHandle = false hides the handle")
    settings.edgeHandle = nil
    state.side = nil
    surface.refresh()
    assert(not surface.handle.frame:IsShown(), "no side, no handle")
  end

  -- test_handle_is_22_by_104_on_the_screen_edge
  do
    local surface, state, _, parent = build()
    local frame = surface.handle.frame
    local p = frame.point
    assert(p[1] == "LEFT" and p[2] == parent and p[3] == "LEFT", "anchored LEFT to the parent's LEFT")
    assert(frame.width == 22 and frame.height == 104, "22 x 104, got " .. tostring(frame.width) .. " x " .. tostring(frame.height))
    assert(frame.frameStrata == "MEDIUM" and frame.mouseEnabled == true, "medium strata, takes the mouse")
    state.side = "right"
    surface.refresh()
    p = frame.point
    assert(p[1] == "RIGHT" and p[2] == parent and p[3] == "RIGHT", "anchored RIGHT to the parent's RIGHT")
  end

  -- test_circle_shape_wears_the_capsule_rim_over_its_mask
  do
    local surface = build()
    local handle = surface.handle
    assert(handle.rim.texturePath == ScreenEdgeHandle.CAPSULE_TEXTURE, "capsule rim, got " .. tostring(handle.rim.texturePath))
    assert(ScreenEdgeHandle.CAPSULE_TEXTURE == "Interface\\AddOns\\WhisperMessenger\\Media\\handle_capsule_gold.png", "rim path")
    assert(handle.fill.texturePath == ScreenEdgeHandle.CAPSULE_MASK_TEXTURE, "capsule fill")
    assert(ScreenEdgeHandle.CAPSULE_MASK_TEXTURE == "Interface\\AddOns\\WhisperMessenger\\Media\\handle_capsule_mask.png", "mask path")
    assert(sameColor(handle.fill.vertexColor, Theme.COLORS.toggle_icon_bg), "the button's background colour")
    assert(handle.rim:IsShown() and handle.fill:IsShown(), "border and background on by default")
  end

  -- test_square_shape_wears_the_tab_rim_the_button_would_use
  do
    local surface = build({ widgetShape = "square" })
    local handle = surface.handle
    local want = handle.frame.CreateMaskTexture and ScreenEdgeHandle.TAB_ROUNDED_TEXTURE or ScreenEdgeHandle.TAB_TEXTURE
    assert(handle.rim.texturePath == want, "tab rim, got " .. tostring(handle.rim.texturePath))
    assert(ScreenEdgeHandle.TAB_TEXTURE == "Interface\\AddOns\\WhisperMessenger\\Media\\handle_tab_gold.png", "tab path")
    assert(ScreenEdgeHandle.TAB_ROUNDED_TEXTURE == "Interface\\AddOns\\WhisperMessenger\\Media\\handle_tab_gold_rounded.png", "rounded tab path")
    assert(handle.fill.texturePath == SquareLook.SQUARE_TEXTURE, "a plain square fill")
    local p1, p2 = handle.fill.points[1], handle.fill.points[2]
    assert(p1[1] == "TOPRIGHT" and p1[4] == -2 and p1[5] == -2, "left: inset 2 on the inner side and top")
    assert(p2[1] == "BOTTOMLEFT" and p2[4] == 0 and p2[5] == 2, "left: flush on the screen side, inset 2 at the bottom")
  end

  -- test_border_and_background_settings_take_rim_and_fill_off
  do
    local surface = build({ iconBorder = false, iconBackground = false })
    assert(not surface.handle.rim:IsShown(), "border off: no rim")
    assert(not surface.handle.fill:IsShown(), "background off: no fill")
  end

  -- test_themed_border_tints_the_rim_like_the_button
  do
    local surface, _, settings = build()
    local rim = surface.handle.rim
    assert(rim.desaturated == true and sameColor(rim.vertexColor, Theme.COLORS.accent), "themed (default): desaturated, accent")
    settings.iconBorderThemed = false
    surface.refresh()
    assert(rim.desaturated == false and sameColor(rim.vertexColor, { 1, 1, 1 }), "gold: own colours")
  end

  -- test_a_setting_change_repaints_on_the_next_refresh
  do
    local surface, _, settings = build()
    settings.widgetShape = "square"
    settings.iconBorder = false
    surface.refresh()
    assert(surface.handle.fill.texturePath == SquareLook.SQUARE_TEXTURE, "square now")
    assert(not surface.handle.rim:IsShown(), "rim off now")
  end

  -- test_transparency_fades_unless_hovered_or_unread
  do
    local surface, _, settings = build({ widgetTransparency = 0.6 })
    local frame = surface.handle.frame
    assert(math.abs(frame.alpha - 0.4) < 1e-9, "faded to the chosen transparency, got " .. tostring(frame.alpha))
    surface.setUnreadCount(3, 2)
    assert(frame.alpha == 1, "unread whispers: opaque")
    surface.setUnreadCount(0, 0)
    assert(math.abs(frame.alpha - 0.4) < 1e-9, "read: faded again")
    frame.scripts.OnEnter(frame)
    assert(frame.alpha == 1, "hovered: opaque")
    frame.scripts.OnLeave(frame)
    settings.widgetTransparency = 0.2
    surface.refresh()
    assert(math.abs(frame.alpha - 0.8) < 1e-9, "a new transparency on the next refresh, got " .. tostring(frame.alpha))
  end

  -- test_count_is_stacked_vertical_text
  do
    local surface = build()
    local label = surface.handle.label
    assert(not label:IsShown(), "0: nothing shown")
    for _, case in ipairs({ { 7, "7" }, { 12, "1\n2" }, { 150, "9\n9\n+" } }) do
      surface.setUnreadCount(case[1] + 5, case[1])
      assert(label:IsShown() and label:GetText() == case[2], case[1] .. ": got " .. tostring(label:GetText()))
    end
    surface.setUnreadCount(4, 0)
    assert(not label:IsShown(), "back to 0: hidden")
    local p = label.point
    assert(p[1] == "CENTER" and p[2] == surface.handle.frame and p[3] == "CENTER", "centred")
    assert(sameColor(label.textColor, Theme.COLORS.accent), "accent text")
    assert(surface.handle.icon == nil and surface.handle.badge == nil, "no icon, no badge")
  end

  -- test_art_is_mirrored_on_the_right_edge
  do
    local surface, state = build()
    local handle = surface.handle
    local function coords(tex, want, label)
      local c = tex.texCoords
      assert(c[1] == want[1] and c[2] == want[2] and c[3] == 0 and c[4] == 1, label)
    end
    coords(handle.fill, { 0, 1 }, "left: fill as drawn")
    coords(handle.rim, { 0, 1 }, "left: rim as drawn")
    state.side = "right"
    surface.refresh()
    coords(handle.fill, { 1, 0 }, "right: fill mirrored")
    coords(handle.rim, { 1, 0 }, "right: rim mirrored")
  end

  -- test_no_blizzard_atlas
  do
    local surface = build()
    local found = FindUI.find(surface.handle.frame, function(node)
      return node.atlas ~= nil
    end)
    assert(found == nil, "no atlas on the handle")
  end

  -- test_click_runs_the_toggle
  do
    local surface, state = build()
    local frame = surface.handle.frame
    frame.scripts.OnClick(frame)
    assert(state.clicks == 1, "one click, one toggle")
  end
end
