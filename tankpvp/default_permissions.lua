--기본 퍼미션
local default_group = function(id)
  local pgroup = game.permissions.get_group(id)
  pgroup.set_allows_action(defines.input_action.begin_mining, false)
  pgroup.set_allows_action(defines.input_action.begin_mining_terrain, false)
  pgroup.set_allows_action(defines.input_action.drop_item, false)
  pgroup.set_allows_action(defines.input_action.take_equipment, false)
  pgroup.set_allows_action(defines.input_action.pipette, false) -- TODO: recheck
  pgroup.set_allows_action(defines.input_action.toggle_driving, false)
  pgroup.set_allows_action(defines.input_action.open_production_gui, false)
  -- pgroup.set_allows_action(defines.input_action.open_technology_gui, false) -- TODO: recheck
  --pgroup.set_allows_action(defines.input_action.open_tutorials_gui, false) --TODO: recheck
  -- pgroup.set_allows_action(defines.input_action.open_logistic_gui, false) --TODO: recheck
  pgroup.set_allows_action(defines.input_action.open_bonus_gui, false)
  pgroup.set_allows_action(defines.input_action.open_achievements_gui, false)
  pgroup.set_allows_action(defines.input_action.paste_entity_settings, false)
  pgroup.set_allows_action(defines.input_action.fast_entity_transfer, false)

  --청사진 관련
  pgroup.set_allows_action(defines.input_action.reassign_blueprint, false)
  pgroup.set_allows_action(defines.input_action.open_blueprint_record, false)
  pgroup.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
  pgroup.set_allows_action(defines.input_action.import_blueprint, false)
  pgroup.set_allows_action(defines.input_action.import_blueprint_string, false)
  pgroup.set_allows_action(defines.input_action.import_blueprints_filtered, false)
  pgroup.set_allows_action(defines.input_action.drop_blueprint_record, false)
  pgroup.set_allows_action(defines.input_action.delete_blueprint_library, false)
  pgroup.set_allows_action(defines.input_action.delete_blueprint_record, false)
  pgroup.set_allows_action(defines.input_action.edit_blueprint_tool_preview, false)
  --pgroup.set_allows_action(defines.input_action.create_blueprint_like, false) --TODO: FIX
  pgroup.set_allows_action(defines.input_action.copy_opened_blueprint, false)
  --pgroup.set_allows_action(defines.input_action.change_blueprint_library_tab, false) --TODO: FIX
  pgroup.set_allows_action(defines.input_action.setup_blueprint, false)
  pgroup.set_allows_action(defines.input_action.setup_single_blueprint_record, false)
  pgroup.set_allows_action(defines.input_action.delete_blueprint_library, false)
  pgroup.set_allows_action(defines.input_action.undo, false)
  pgroup.set_allows_action(defines.input_action.upgrade, false)
  pgroup.set_allows_action(defines.input_action.upgrade_opened_blueprint_by_item, false)
  pgroup.set_allows_action(defines.input_action.upgrade_opened_blueprint_by_record, false)
  pgroup.set_allows_action(defines.input_action.deconstruct, false)

  --철도 관련
  pgroup.set_allows_action(defines.input_action.add_train_station, false)
  pgroup.set_allows_action(defines.input_action.change_train_stop_station, false)
  pgroup.set_allows_action(defines.input_action.change_train_wait_condition, false)
  pgroup.set_allows_action(defines.input_action.change_train_wait_condition_data, false)
  pgroup.set_allows_action(defines.input_action.drag_train_schedule, false)
  pgroup.set_allows_action(defines.input_action.drag_train_wait_condition, false)
  pgroup.set_allows_action(defines.input_action.go_to_train_station, false)
  pgroup.set_allows_action(defines.input_action.open_train_gui, false)
  pgroup.set_allows_action(defines.input_action.open_train_station_gui, false)
  pgroup.set_allows_action(defines.input_action.open_trains_gui, false)
  pgroup.set_allows_action(defines.input_action.remove_train_station, false)
  pgroup.set_allows_action(defines.input_action.set_train_stopped, false)
  pgroup.set_allows_action(defines.input_action.connect_rolling_stock, false)
  pgroup.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
end

local default = function()
  default_group(0) --Default 그룹
  --개인으로 관전하는 그룹
  game.permissions.create_group('ffa_spec')
  default_group('ffa_spec')
  game.permissions.get_group('ffa_spec').set_allows_action(defines.input_action.start_walking, false)
  game.permissions.get_group('ffa_spec').set_allows_action(defines.input_action.change_riding_state, false)
  game.permissions.get_group('ffa_spec').set_allows_action(defines.input_action.change_shooting_state, false)
  game.permissions.get_group('ffa_spec').set_allows_action(defines.input_action.set_entity_color, false)

  --팀전 진행중 그룹
  game.permissions.create_group('fix_color')
  default_group('fix_color')
  game.permissions.get_group('fix_color').set_allows_action(defines.input_action.set_player_color, false)
  game.permissions.get_group('fix_color').set_allows_action(defines.input_action.set_entity_color, false)

  --팀전에서 사망 후 관전하는 그룹
  game.permissions.create_group('fc_standby')
  default_group('fc_standby')
  game.permissions.get_group('fc_standby').set_allows_action(defines.input_action.set_player_color, false)
  game.permissions.get_group('fc_standby').set_allows_action(defines.input_action.start_walking, false)
  game.permissions.get_group('fc_standby').set_allows_action(defines.input_action.change_riding_state, false)
  game.permissions.get_group('fc_standby').set_allows_action(defines.input_action.change_shooting_state, false)
  game.permissions.get_group('fc_standby').set_allows_action(defines.input_action.set_entity_color, false)
end

local frozen_group = function(id)
  local pgroup = game.permissions.get_group(id)
  for k, _ in pairs(defines.input_action) do
    pgroup.set_allows_action(defines.input_action[k], false)
  end
end

return default