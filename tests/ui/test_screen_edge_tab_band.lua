local FakeUI = require("tests.helpers.fake_ui")
local Theme = require("WhisperMessenger.UI.Theme")
local ScreenEdgeTabBand = require("WhisperMessenger.UI.MessengerWindow.ChromeBuilder.ScreenEdgeTabBand")

-- The darkened band the tab strip sits in at the bottom of a docked window.
local L = Theme.LAYOUT

local function build(hud)
  local factory = FakeUI.NewFactory()
  local frame = factory.CreateFrame("Frame", "Window", nil)
  return ScreenEdgeTabBand.Create(factory, frame, { hud = hud }), frame
end

return function()
  -- test_band_spans_the_window_bottom_with_room_around_the_tabs
  do
    local band, frame = build(true)
    local height = band.show(32)
    assert(height == L.SCREEN_EDGE_TAB_BAND_PAD_TOP + 32 + L.SCREEN_EDGE_TAB_BAND_PAD_BOTTOM, "band height, got " .. tostring(height))
    assert(band.frame:IsShown() and band.frame.height == height, "shown at its height")
    local p1, p2 = band.frame.points[1], band.frame.points[2]
    assert(p1[1] == "BOTTOMLEFT" and p1[2] == frame and p1[4] == 0 and p1[5] == 0, "bottom-left of the window")
    assert(p2[1] == "BOTTOMRIGHT" and p2[2] == frame and p2[4] == 0 and p2[5] == 0, "bottom-right of the window")
    assert(band.fill.color[1] == 0 and band.fill.alpha == 0.5, "darkened by a half-black fill")
  end

  -- test_hud_band_has_the_inset_bevel_on_top
  do
    local band = build(true)
    band.show(32)
    local d = band.divider
    assert(d:IsShown() and d.height == 3, "3 px")
    assert(d.atlas == "_UI-Frame-InnerBotTile", "the inset bottom bevel, got " .. tostring(d.atlas))
    assert(d.points[1][1] == "TOPLEFT" and d.points[1][2] == band.frame, "on the band's top")
  end

  -- test_custom_band_has_a_1px_window_border_divider
  do
    local band = build(false)
    band.show(24)
    assert(band.divider.height == 1 and band.divider.color[1] == Theme.COLORS.window_border[1], "1 px window border")
  end

  -- test_hide_hides_the_band
  do
    local band = build(true)
    band.show(32)
    band.hide()
    assert(not band.frame:IsShown(), "hidden")
  end
end
