-- The edge handle: a half disc on the screen edge (flat side on the edge) that
-- opens the closed window, rimmed like the window and badged with the unread
-- whisper count.
local ScreenEdgeHandle = require("WhisperMessenger.UI.ToggleIcon.ScreenEdgeHandle")
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
    assert(frame.width == 26 and frame.height == 52, "26 x 52 (radius x diameter), got " .. tostring(frame.width) .. " x " .. tostring(frame.height))
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

  local function test_badge_sits_on_the_upper_inner_curve()
    local surface, state = build()
    local handle = surface.handle
    local p = handle.badge.frame.point
    -- 45 degrees up the curve: radius 26 * 0.7 = 18 px in and up from the edge's midpoint.
    assert(p[1] == "CENTER" and p[2] == handle.frame and p[3] == "LEFT" and p[4] == 18 and p[5] == 18, "left edge: on the curve, inward")
    state.side = "right"
    surface.refresh()
    p = handle.badge.frame.point
    assert(p[1] == "CENTER" and p[2] == handle.frame and p[3] == "RIGHT" and p[4] == -18 and p[5] == 18, "right edge: on the curve, inward")
  end

  local function test_chat_icon_in_the_accent_colour()
    local surface = build()
    local icon = surface.handle.icon
    assert(icon.texturePath == Theme.TEXTURES.nav_whispers_icon, "the chat bubble icon")
    assert(icon.width == 16 and icon.height == 16, "16 px")
    local p = icon.point
    -- The half disc's centroid: 4r / 3pi = 11 px in from the flat edge.
    assert(p[1] == "CENTER" and p[2] == surface.handle.frame and p[3] == "LEFT" and p[4] == 11 and p[5] == 0, "centred in the half disc")
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

  local function test_half_disc_fill_in_the_background_colour()
    local surface = build()
    local fill = surface.handle.fill
    assert(fill.texturePath == ScreenEdgeHandle.FILL_TEXTURE, "the half-disc mask")
    assert(ScreenEdgeHandle.FILL_TEXTURE == "Interface\\AddOns\\WhisperMessenger\\Media\\half_disc_mask.png", "fill path")
    assert(fill.vertexColor[1] == Theme.COLORS.bg_primary[1] and fill.vertexColor[3] == Theme.COLORS.bg_primary[3], "background tint")
  end

  local function test_hud_rim_is_the_gold_half_ring()
    Hud.Configure("classic")
    local surface = build()
    local rim = surface.handle.rim
    assert(rim.texturePath == ScreenEdgeHandle.RIM_TEXTURE, "the half ring")
    assert(ScreenEdgeHandle.RIM_TEXTURE == "Interface\\AddOns\\WhisperMessenger\\Media\\half_ring_gold.png", "rim path")
    assert(rim.desaturated == false and rim.vertexColor[1] == 1 and rim.vertexColor[3] == 1, "its own gold")
    Hud.Configure("off")
  end

  local function test_custom_rim_is_the_half_ring_in_the_window_border_colour()
    Hud.Configure("off")
    local surface = build()
    local rim = surface.handle.rim
    assert(rim.texturePath == ScreenEdgeHandle.RIM_TEXTURE and rim.desaturated == true, "the half ring, desaturated")
    assert(rim.vertexColor[1] == Theme.COLORS.window_border[1] and rim.vertexColor[3] == Theme.COLORS.window_border[3], "window border tint")
  end

  local function test_art_is_mirrored_on_the_right_edge()
    local surface, state = build()
    local handle = surface.handle
    for _, tex in ipairs({ handle.fill, handle.rim }) do
      local c = tex.texCoords
      assert(c[1] == 0 and c[2] == 1 and c[3] == 0 and c[4] == 1, "left edge: art as drawn (flat side left)")
    end
    state.side = "right"
    surface.refresh()
    for _, tex in ipairs({ handle.fill, handle.rim }) do
      local c = tex.texCoords
      assert(c[1] == 1 and c[2] == 0 and c[3] == 0 and c[4] == 1, "right edge: mirrored")
    end
    local p = handle.icon.point
    assert(p[3] == "RIGHT" and p[4] == -11, "right edge: icon 11 px in from the flat side")
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
  test_half_disc_fill_in_the_background_colour()
  test_hud_rim_is_the_gold_half_ring()
  test_custom_rim_is_the_half_ring_in_the_window_border_colour()
  test_art_is_mirrored_on_the_right_edge()
  test_badge_sits_on_the_upper_inner_curve()
  test_chat_icon_in_the_accent_colour()
  test_no_blizzard_atlas()
  Hud.Configure("off")
end
