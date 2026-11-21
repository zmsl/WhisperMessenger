local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local ScreenEdgeGlow = ns.ToggleIconScreenEdgeGlow or require("WhisperMessenger.UI.ToggleIcon.ScreenEdgeGlow")
local ScreenEdgeHandle = ns.ToggleIconScreenEdgeHandle or require("WhisperMessenger.UI.ToggleIcon.ScreenEdgeHandle")

-- The icon surface at the screen edge. IconSurfaces hands it the unread
-- counts; it lights the glow and shows the handle while the window is hidden.
local ScreenEdgeSurface = {}

-- options: theme, settings, getSide(), isWindowShown(), onClick().
function ScreenEdgeSurface.Create(factory, parent, options)
  local settings = options.settings
  local glow = ScreenEdgeGlow.Create(factory, parent, { theme = options.theme })
  local handle = ScreenEdgeHandle.Create(factory, parent, { theme = options.theme, onClick = options.onClick })
  local surface = { glow = glow, handle = handle }
  surface.total, surface.whispers = 0, 0

  function surface.refresh()
    local side = options.getSide()
    local closed = side ~= nil and not options.isWindowShown()
    glow.setSide(side, settings.edgeHandle == false)
    handle.setSide(side)
    glow.setLit(closed and settings.edgeGlow ~= false and surface.whispers > 0)
    handle.setShown(closed and settings.edgeHandle ~= false)
    handle.setCount(surface.whispers)
  end

  function surface.setUnreadCount(nextTotal, nextWhispers)
    surface.total, surface.whispers = nextTotal or 0, nextWhispers or 0
    surface.refresh()
  end

  function surface.refreshTheme(activeTheme)
    glow.refreshTheme(activeTheme)
    handle.refreshTheme(activeTheme)
  end

  surface.refresh()
  return surface
end

ns.ToggleIconScreenEdgeSurface = ScreenEdgeSurface

return ScreenEdgeSurface
