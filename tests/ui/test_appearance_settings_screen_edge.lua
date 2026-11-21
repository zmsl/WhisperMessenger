local FakeUI = require("tests.helpers.fake_ui")
local FindUI = require("tests.helpers.find_ui")
local AppearanceSettings = require("WhisperMessenger.UI.MessengerWindow.AppearanceSettings")

local function create(config)
  local factory = FakeUI.NewFactory()
  local parent = factory.CreateFrame("Frame", "UIParent", nil)
  local changes = {}
  local result = AppearanceSettings.Create(factory, parent, config or {}, {
    onChange = function(key, value)
      changes[#changes + 1] = { key = key, value = value }
    end,
  })
  return result, changes
end

local function lastChange(changes, key)
  local found
  for _, change in ipairs(changes) do
    if change.key == key then
      found = change
    end
  end
  return found
end

return function()
  -- test_screen_edge_selector_lives_on_appearance
  do
    local result = create()
    assert(FindUI.byLabel(result.frame, "Screen edge") ~= nil, "on Appearance")
    local buttons = FindUI.selectorButtons(result.frame, "Screen edge")
    assert(
      #buttons == 3 and buttons[1].label.text == "Off" and buttons[2].label.text == "Left" and buttons[3].label.text == "Right",
      "Off, Left, Right"
    )
  end

  -- test_it_starts_off_when_nothing_is_saved
  do
    local result = create()
    local buttons = FindUI.selectorButtons(result.frame, "Screen edge")
    assert(buttons[1]._selected and not buttons[2]._selected, "Off is picked")
  end

  -- test_picking_left_saves_left
  do
    local result, changes = create()
    local buttons = FindUI.selectorButtons(result.frame, "Screen edge")
    buttons[2].scripts.OnClick(buttons[2])
    local saved = lastChange(changes, "screenEdge")
    assert(saved ~= nil and saved.value == "left", "asks for left")
  end

  -- test_it_sits_right_under_compact_window
  do
    local result = create()
    local compact = FindUI.byLabel(result.frame, "Compact window")
    local selector = FindUI.byLabel(result.frame, "Screen edge")
    assert(select(2, selector:GetPoint()) == compact, "anchored under the Compact window toggle")
  end

  -- test_edge_glow_sits_under_the_selector
  do
    local result = create()
    local selector = FindUI.byLabel(result.frame, "Screen edge")
    local glow = FindUI.byLabel(result.frame, "Edge glow")
    assert(select(2, glow:GetPoint()) == selector, "anchored under the selector")
    assert(select(2, FindUI.byLabel(result.frame, "Edge handle"):GetPoint()) == glow, "handle under glow")
  end

  -- test_edge_glow_and_handle_start_on
  do
    local result = create()
    assert(FindUI.isToggleOn(FindUI.toggle(result.frame, "Edge glow")), "glow on")
    assert(FindUI.isToggleOn(FindUI.toggle(result.frame, "Edge handle")), "handle on")
  end

  -- test_a_saved_off_shows_off
  do
    local result = create({ edgeGlow = false, edgeHandle = false })
    assert(not FindUI.isToggleOn(FindUI.toggle(result.frame, "Edge glow")), "glow off")
    assert(not FindUI.isToggleOn(FindUI.toggle(result.frame, "Edge handle")), "handle off")
  end

  -- test_clicking_saves_false
  do
    local result, changes = create()
    for _, key in ipairs({ "edgeGlow", "edgeHandle" }) do
      local label = key == "edgeGlow" and "Edge glow" or "Edge handle"
      local toggle = FindUI.toggle(result.frame, label)
      toggle.scripts.OnClick(toggle)
      assert(lastChange(changes, key).value == false, key .. " asks for off")
    end
  end

  -- test_reset_sends_off_and_both_switches_on
  do
    local result, changes = create({ screenEdge = "left", edgeGlow = false, edgeHandle = false })
    local reset = FindUI.byLabel(result.frame, "Reset to Defaults")
    reset.scripts.OnClick(reset)
    assert(lastChange(changes, "screenEdge").value == "off", "edge off")
    assert(lastChange(changes, "edgeGlow").value == true, "glow on")
    assert(lastChange(changes, "edgeHandle").value == true, "handle on")
  end

  -- test_labels_survive_a_language_refresh
  do
    local result = create()
    result.setLanguage()
    assert(FindUI.byLabel(result.frame, "Screen edge") ~= nil, "selector relabelled")
    assert(FindUI.byLabel(result.frame, "Edge glow") ~= nil and FindUI.byLabel(result.frame, "Edge handle") ~= nil, "toggles relabelled")
  end
end
