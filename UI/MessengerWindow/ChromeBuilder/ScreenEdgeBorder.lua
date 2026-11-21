local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Theme = ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers = ns.UIHelpers or require("WhisperMessenger.UI.Helpers")

-- Hides the border pieces on the screen side of a window held against a screen
-- edge, and paints a dark shade there. One piece list per chrome; a key a
-- flavour lacks is skipped. Only pieces that were shown are hidden and restored.
local ScreenEdgeBorder = {}

local SHADE_LEVEL_ABOVE_PANES = 25
local SHADE_COLOR = { 0, 0, 0, 0.75 }

local CLASSIC_KEYS = { "TopLeftCorner", "TopRightCorner", "BotLeftCorner", "BotRightCorner", "BottomBorder" }
local RETAIL_KEYS = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "BottomEdge" }

local function collect(pieces, owner, keys, sideKey)
  if type(owner) ~= "table" then
    return
  end
  for _, key in ipairs(keys) do
    pieces[#pieces + 1] = owner[key]
  end
  pieces[#pieces + 1] = owner[sideKey]
end

local function screenSidePieces(frame, windowEdges, side)
  local pieces = {}
  if type(windowEdges) == "table" then
    pieces[1], pieces[2], pieces[3] = windowEdges.top, windowEdges.bottom, windowEdges[side]
  end
  collect(pieces, frame, CLASSIC_KEYS, side == "left" and "LeftBorder" or "RightBorder")
  collect(pieces, frame.NineSlice, RETAIL_KEYS, side == "left" and "LeftEdge" or "RightEdge")
  return pieces
end

function ScreenEdgeBorder.Create(factory, frame, windowEdges)
  local hiddenByUs = {}
  local shade, shadeTexture

  local function restore()
    for _, piece in ipairs(hiddenByUs) do
      piece:Show()
    end
    hiddenByUs = {}
  end

  local function paintShade(side)
    if not shade then
      shade = factory.CreateFrame("Frame", nil, frame)
      shade:EnableMouse(false)
      shade:SetFrameLevel(frame:GetFrameLevel() + SHADE_LEVEL_ABOVE_PANES)
      shade:SetWidth(Theme.LAYOUT.SCREEN_EDGE_SHADE_WIDTH)
      shadeTexture = shade:CreateTexture(nil, "OVERLAY")
      shadeTexture:SetAllPoints(shade)
    end
    local edge = side == "right" and "RIGHT" or "LEFT"
    shade:ClearAllPoints()
    shade:SetPoint("TOP" .. edge, frame, "TOP" .. edge, 0, 0)
    shade:SetPoint("BOTTOM" .. edge, frame, "BOTTOM" .. edge, 0, 0)
    if side == "right" then
      UIHelpers.applyHorizontalFadeLeft(shadeTexture, SHADE_COLOR)
    else
      UIHelpers.applyHorizontalFade(shadeTexture, SHADE_COLOR)
    end
    shade:Show()
  end

  return {
    apply = function(side)
      restore()
      if side ~= "left" and side ~= "right" then
        if shade then
          shade:Hide()
        end
        return
      end
      for _, piece in ipairs(screenSidePieces(frame, windowEdges, side)) do
        if piece.IsShown and piece:IsShown() then
          piece:Hide()
          hiddenByUs[#hiddenByUs + 1] = piece
        end
      end
      paintShade(side)
    end,
  }
end

ns.MessengerWindowChromeBuilderScreenEdgeBorder = ScreenEdgeBorder

return ScreenEdgeBorder
