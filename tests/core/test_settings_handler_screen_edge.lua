local SettingsHandler = require("WhisperMessenger.Core.Bootstrap.WindowRuntime.SettingsHandler")

local function build()
  local case = { settings = {}, seen = {} }
  case.onChange = SettingsHandler.Create({
    runtime = { store = { config = {} } },
    accountSettings = case.settings,
    onScreenEdgeSetting = function(key, value)
      case.seen[#case.seen + 1] = { key = key, value = value }
    end,
  })
  return case
end

return function()
  -- test_screen_edge_is_saved_and_reported
  do
    local case = build()
    case.onChange("screenEdge", "left")
    assert(case.settings.screenEdge == "left", "saved")
    assert(#case.seen == 1 and case.seen[1].key == "screenEdge" and case.seen[1].value == "left", "reported")
  end

  -- test_glow_is_saved_and_reported
  for _, key in ipairs({ "edgeGlow" }) do
    local case = build()
    case.onChange(key, false)
    assert(case.settings[key] == false, key .. " saved")
    assert(#case.seen == 1 and case.seen[1].key == key and case.seen[1].value == false, key .. " reported")
  end
end
