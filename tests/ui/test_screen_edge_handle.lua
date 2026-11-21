-- The edge handle: a small icon tab on the screen edge that opens the closed
-- window, styled like the window and badged with the unread whisper count.
local AnimatedFactory = require("tests.helpers.animated_factory")
local Hud = require("WhisperMessenger.UI.Theme.Hud")
local ScreenEdgeSurface = require("WhisperMessenger.UI.ToggleIcon.ScreenEdgeSurface")
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

return function()
  local function test_handle_shows_while_the_window_is_hidden()
    local surface = build()
    assert(surface.handle.frame:IsShown(), "a hidden window shows the handle")
  end

  local function test_handle_hides_while_the_window_shows()
    local surface, state = build()
    state.shown = true
    surface.refresh()
    assert(not surface.handle.frame:IsShown(), "a shown window hides the handle")
  end

  local function test_edge_handle_off_hides_it()
    local surface, _, settings = build()
    settings.edgeHandle = false
    surface.refresh()
    assert(not surface.handle.frame:IsShown(), "edgeHandle = false hides the handle")
  end

  local function test_no_side_no_handle()
    local surface, state = build()
    state.side = nil
    surface.refresh()
    assert(not surface.handle.frame:IsShown(), "no side, no handle")
  end

  local function test_handle_sits_centred_on_the_left_edge()
    local surface, _, _, parent = build()
    local frame = surface.handle.frame
    local p = frame.point
    assert(p[1] == "LEFT" and p[2] == parent and p[3] == "LEFT", "anchored LEFT to the parent's LEFT")
    assert(frame.width == 30 and frame.height == 44, "30 x 44, got " .. tostring(frame.width) .. " x " .. tostring(frame.height))
    assert(frame.frameStrata == "MEDIUM", "medium strata")
    assert(frame.mouseEnabled == true, "the handle takes the mouse")
  end

  local function test_right_handle_sits_on_the_right_edge()
    local surface, state, _, parent = build()
    state.side = "right"
    surface.refresh()
    local p = surface.handle.frame.point
    assert(p[1] == "RIGHT" and p[2] == parent and p[3] == "RIGHT", "anchored RIGHT to the parent's RIGHT")
  end

  local function test_badge_shows_unread_whispers_and_hides_at_zero()
    local surface = build()
    local badge = surface.handle.badge
    assert(badge.outline ~= nil, "the shared badge, outlined")
    surface.setUnreadCount(4, 3)
    assert(badge.label:GetText() == "3", "badge shows whispers, got " .. tostring(badge.label:GetText()))
    assert(badge.frame:IsShown(), "badge shown")
    surface.setUnreadCount(200, 150)
    assert(badge.label:GetText() == "99+", "three digits cap at 99+, got " .. tostring(badge.label:GetText()))
    surface.setUnreadCount(2, 0)
    assert(not badge.frame:IsShown(), "badge hidden at zero whispers")
  end

  local function test_badge_sits_on_the_inner_top_corner()
    local surface, state = build()
    local handle = surface.handle
    local p = handle.badge.frame.point
    assert(p[1] == "CENTER" and p[2] == handle.frame and p[3] == "TOPRIGHT", "left edge: inner corner is top-right, got " .. tostring(p[3]))
    state.side = "right"
    surface.refresh()
    p = handle.badge.frame.point
    assert(p[1] == "CENTER" and p[2] == handle.frame and p[3] == "TOPLEFT", "right edge: inner corner is top-left, got " .. tostring(p[3]))
  end

  local function test_chat_icon_in_the_accent_colour()
    local surface = build()
    local icon = surface.handle.icon
    assert(icon.texturePath == Theme.TEXTURES.nav_whispers_icon, "the chat bubble icon")
    assert(icon.width == 18 and icon.height == 18, "18 px")
    assert(icon.vertexColor[1] == Theme.COLORS.accent[1] and icon.vertexColor[3] == Theme.COLORS.accent[3], "accent tint")
  end

  local function test_no_blizzard_atlas()
    for _, style in ipairs({ "off", "classic", "retail" }) do
      Hud.Configure(style)
      local surface = build()
      local found = FindUI.find(surface.handle.frame, function(node)
        return node.atlas ~= nil
      end)
      assert(found == nil, style .. ": no atlas on the handle")
    end
    Hud.Configure("off")
  end

  local function test_click_runs_the_toggle()
    local surface, state = build()
    local frame = surface.handle.frame
    frame.scripts.OnClick(frame)
    assert(state.clicks == 1, "one click, one toggle")
  end

  local function test_custom_style_hides_the_screen_side_edge()
    Hud.Configure("off")
    local surface, state = build()
    local border = surface.handle.border
    assert(border.left:IsShown() == false and border.right:IsShown() == true, "left handle hides its left edge")
    state.side = "right"
    surface.refresh()
    assert(border.left:IsShown() == true and border.right:IsShown() == false, "right handle hides its right edge")
  end

  local function test_hud_style_has_a_2px_accent_rim_on_three_sides()
    Hud.Configure("classic")
    local surface, state = build()
    local border = surface.handle.border
    assert(border.top.height == 2 and border.right.width == 2, "2 px rim")
    assert(border.top.color[1] == Theme.COLORS.accent[1] and border.top.color[3] == Theme.COLORS.accent[3], "accent rim")
    assert(border.left:IsShown() == false and border.right:IsShown() and border.top:IsShown() and border.bottom:IsShown(), "screen side open")
    state.side = "right"
    surface.refresh()
    assert(border.left:IsShown() and border.right:IsShown() == false, "right handle opens its right side")
    Hud.Configure("off")
  end

  Hud.Configure("off")
  test_handle_shows_while_the_window_is_hidden()
  test_handle_hides_while_the_window_shows()
  test_edge_handle_off_hides_it()
  test_no_side_no_handle()
  test_handle_sits_centred_on_the_left_edge()
  test_right_handle_sits_on_the_right_edge()
  test_badge_shows_unread_whispers_and_hides_at_zero()
  test_click_runs_the_toggle()
  test_custom_style_hides_the_screen_side_edge()
  test_hud_style_has_a_2px_accent_rim_on_three_sides()
  test_badge_sits_on_the_inner_top_corner()
  test_chat_icon_in_the_accent_colour()
  test_no_blizzard_atlas()
  Hud.Configure("off")
end
