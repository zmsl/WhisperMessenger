-- The edge handle: a thin tab on the screen edge that opens the closed window,
-- styled like the window and badged with the unread whisper count.
local AnimatedFactory = require("tests.helpers.animated_factory")
local Hud = require("WhisperMessenger.UI.Theme.Hud")
local ScreenEdgeSurface = require("WhisperMessenger.UI.ToggleIcon.ScreenEdgeSurface")
local Theme = require("WhisperMessenger.UI.Theme")

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
    assert(frame.width == 12 and frame.height == 96, "12 x 96, got " .. tostring(frame.width) .. " x " .. tostring(frame.height))
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
    surface.setUnreadCount(4, 3)
    assert(surface.handle.badge:GetText() == "3", "badge shows whispers, got " .. tostring(surface.handle.badge:GetText()))
    assert(surface.handle.badge:IsShown(), "badge shown")
    surface.setUnreadCount(2, 0)
    assert(not surface.handle.badge:IsShown(), "badge hidden at zero whispers")
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

  local function test_hud_style_uses_the_window_side_tile()
    Hud.Configure("classic")
    local surface, state = build()
    local tile = surface.handle.tile
    assert(tile.atlas == "!UI-Frame-RightTile", "left handle uses the right tile, got " .. tostring(tile.atlas))
    assert(tile:IsShown(), "tile shown in HUD style")
    assert(surface.handle.border.top:IsShown() == false, "no custom border in HUD style")
    state.side = "right"
    surface.refresh()
    assert(tile.atlas == "!UI-Frame-LeftTile", "right handle uses the left tile, got " .. tostring(tile.atlas))
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
  test_hud_style_uses_the_window_side_tile()
  Hud.Configure("off")
end
