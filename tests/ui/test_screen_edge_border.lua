local FakeUI = require("tests.helpers.fake_ui")
local Theme = require("WhisperMessenger.UI.Theme")
local UIHelpers = require("WhisperMessenger.UI.Helpers")
local ScreenEdgeBorder = require("WhisperMessenger.UI.MessengerWindow.ChromeBuilder.ScreenEdgeBorder")

local function build()
  local factory = FakeUI.NewFactory()
  local frame = factory.CreateFrame("Frame", "Window", nil)
  return factory, frame
end

local function piece(frame, owner, key)
  local tex = frame:CreateTexture(nil, "BORDER")
  tex:Show()
  owner[key] = tex
  return tex
end

local function shown(...)
  for _, p in ipairs({ ... }) do
    if not p:IsShown() then
      return false
    end
  end
  return true
end

local function hidden(...)
  for _, p in ipairs({ ... }) do
    if p:IsShown() then
      return false
    end
  end
  return true
end

local CLASSIC = { "TopLeftCorner", "TopRightCorner", "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder", "TopBorder" }
local RETAIL = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "BottomEdge", "LeftEdge", "RightEdge", "TopEdge" }

local function withPieces(frame, owner, keys)
  local pieces = {}
  for _, key in ipairs(keys) do
    pieces[key] = piece(frame, owner, key)
  end
  return pieces
end

return function()
  -- test_modern_left_keeps_only_the_right_edge
  do
    local factory, frame = build()
    local edges = UIHelpers.createBorderBox(frame, { 1, 1, 1, 1 }, 1)
    for _, e in pairs(edges) do
      e:Show()
    end
    local border = ScreenEdgeBorder.Create(factory, frame, edges)
    border.apply("left")
    assert(shown(edges.right) and hidden(edges.left, edges.top, edges.bottom), "only the inner (right) edge stays")

    -- test_modern_off_shows_every_edge_again
    border.apply(nil)
    assert(shown(edges.top, edges.left, edges.right, edges.bottom), "every edge is back")

    border.apply("right")
    assert(shown(edges.left) and hidden(edges.right, edges.top, edges.bottom), "right edge keeps the left one")
  end

  -- test_classic_left_hides_corners_bottom_and_left_tile_keeps_top_and_right_tile
  do
    local factory, frame = build()
    local p = withPieces(frame, frame, CLASSIC)
    ScreenEdgeBorder.Create(factory, frame, nil).apply("left")
    assert(hidden(p.TopLeftCorner, p.TopRightCorner, p.BotLeftCorner, p.BotRightCorner, p.BottomBorder, p.LeftBorder), "screen-side pieces hidden")
    assert(shown(p.TopBorder, p.RightBorder), "top and right tile stay")
  end

  -- test_classic_right_hides_the_right_tile_not_the_left
  do
    local factory, frame = build()
    local p = withPieces(frame, frame, CLASSIC)
    ScreenEdgeBorder.Create(factory, frame, nil).apply("right")
    assert(hidden(p.RightBorder) and shown(p.LeftBorder, p.TopBorder), "right tile hidden, left stays")
  end

  -- test_retail_left_hides_nine_slice_corners_bottom_and_left_edge
  do
    local factory, frame = build()
    frame.NineSlice = factory.CreateFrame("Frame", nil, frame)
    local p = withPieces(frame.NineSlice, frame.NineSlice, RETAIL)
    local border = ScreenEdgeBorder.Create(factory, frame, nil)
    border.apply("left")
    assert(hidden(p.TopLeftCorner, p.TopRightCorner, p.BottomLeftCorner, p.BottomRightCorner, p.BottomEdge, p.LeftEdge), "hidden")
    assert(shown(p.RightEdge, p.TopEdge), "right and top edge stay")
    border.apply(nil)
    assert(shown(p.TopLeftCorner, p.LeftEdge, p.BottomEdge), "restored")
  end

  -- test_off_restores_only_what_it_hid
  do
    local factory, frame = build()
    local p = withPieces(frame, frame, CLASSIC)
    p.BottomBorder:Hide()
    local border = ScreenEdgeBorder.Create(factory, frame, nil)
    border.apply("left")
    border.apply(nil)
    assert(hidden(p.BottomBorder), "a piece hidden before stays hidden")
    assert(shown(p.TopLeftCorner, p.LeftBorder), "the others come back")
  end

  -- test_shade_sits_on_the_screen_side_above_the_panes
  do
    local factory, frame = build()
    frame:SetFrameLevel(5)
    local border = ScreenEdgeBorder.Create(factory, frame, nil)
    border.apply("left")
    local shade = frame.children[#frame.children]
    assert(shade:IsShown() and shade.mouseEnabled == false, "shown, no mouse")
    assert(shade.width == Theme.LAYOUT.SCREEN_EDGE_SHADE_WIDTH, "width")
    assert(shade.points[1][1] == "TOPLEFT" and shade.points[1][2] == frame, "left anchor")
    assert(shade:GetFrameLevel() == 30, "level is frame + 25")
    border.apply("right")
    assert(shade.points[1][1] == "TOPRIGHT" and shade.points[2][1] == "BOTTOMRIGHT", "right anchor")
    border.apply(nil)
    assert(not shade:IsShown(), "hidden when off")
  end

  -- test_shade_level_follows_a_raised_window
  do
    local factory, frame = build()
    frame:SetFrameLevel(5)
    local border = ScreenEdgeBorder.Create(factory, frame, nil)
    border.apply("left")
    local shade = frame.children[#frame.children]
    frame:SetFrameLevel(40)
    border.apply("left")
    assert(shade:GetFrameLevel() == 65, "level re-set to frame + 25, got " .. tostring(shade:GetFrameLevel()))
  end

  -- test_missing_pieces_are_skipped
  do
    local factory, frame = build()
    local border = ScreenEdgeBorder.Create(factory, frame, nil)
    border.apply("left")
    border.apply(nil)
  end
end
