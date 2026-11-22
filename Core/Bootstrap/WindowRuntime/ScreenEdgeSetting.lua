local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- The live reaction to the screen edge settings. ctx: runtime,
-- ensureSurface(), updateIconSurfaces(), readCompactSlot().
local ScreenEdgeSetting = {}

-- The Icons-page look keys repaint the handle, which wears the button's look.
local KEYS = {
  screenEdge = true,
  edgeGlow = true,
  edgeHandle = true,
  widgetShape = true,
  iconBorder = true,
  iconBackground = true,
  iconBorderThemed = true,
  widgetTransparency = true,
}

function ScreenEdgeSetting.Apply(ctx, key, _value)
  if not KEYS[key] then
    return
  end
  local window = ctx.runtime.window
  -- A window that was never at the edge stays put (Reset to Defaults re-sends "off").
  if key == "screenEdge" and window and window.applyScreenEdge then
    window.applyScreenEdge(ctx.readCompactSlot())
  end
  ctx.ensureSurface()
  ctx.updateIconSurfaces()
end

ns.BootstrapWindowRuntimeScreenEdgeSetting = ScreenEdgeSetting
return ScreenEdgeSetting
