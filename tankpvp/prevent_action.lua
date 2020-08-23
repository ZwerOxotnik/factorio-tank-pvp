local Prevent_action = {}

local Const = require('tankpvp.const')
local Util = require('tankpvp.util')

--퍼미션 초기화, 게임 시작 시 1회만 실행
Prevent_action.permissions_init = require('tankpvp.default_permissions')

--우측상단 미니맵 및 기타UI 감추기
Prevent_action.disable_some_game_view_settings = function(player)
  player.minimap_enabled = false
  player.game_view_settings.show_minimap = false
  player.game_view_settings.show_research_info = false
  player.game_view_settings.show_shortcut_bar = false
  player.game_view_settings.show_side_menu = false
  player.game_view_settings.show_alert_gui = false
end

local ammo_types = {
  ['cannon-shell'] = 'tank-shell',
  ['explosive-cannon-shell'] = 'tank-shell',
  ['uranium-cannon-shell'] = 'tank-shell',
  ['explosive-uranium-cannon-shell'] = 'tank-shell',
  ['firearm-magazine'] = 'magazine',
  ['piercing-rounds-magazine'] = 'magazine',
  ['uranium-rounds-magazine'] = 'magazine',
  ['flamethrower-ammo'] = 'flame-ammo',
}
Prevent_action.on_player_cursor_stack_changed = function(event)
  local player = game.players[event.player_index]
  if not player.cursor_stack then return end
  if not player.cursor_stack.valid_for_read then return end
  local cursor_stack = player.cursor_stack
  if not cursor_stack then return end
  local cursor_item_name = nil
  local cursor_item_type = nil

  for k, v in pairs(ammo_types) do
    if cursor_stack.name == k then
      cursor_item_name = k
      cursor_item_type = v
      break
    end
  end

  if cursor_item_name and player.vehicle then
    if player.vehicle.name == 'tank' then
      local tank = player.vehicle
      local inv = tank.get_inventory(defines.inventory.car_ammo)
      local tank_stack = nil
      local tank_item_name = nil
      local cursor_stack_to_be_moved = {name = cursor_item_name, count = cursor_stack.count}
      for k, v in pairs(ammo_types) do
        if cursor_item_type == v then
          tank_stack = inv.find_item_stack(k)
          if tank_stack then
            tank_item_name = k
            break
          end
        end
      end

      if not tank_item_name then
        tank.insert(cursor_stack_to_be_moved)
        player.remove_item(cursor_stack)
        player.clean_cursor()
      elseif tank_item_name == cursor_item_name then
        local remove_count = tank_stack.prototype.stack_size - tank_stack.count
        if cursor_stack.count >= remove_count then
          cursor_stack_to_be_moved.count = remove_count
        end
        if remove_count > 0 then
          tank.insert(cursor_stack_to_be_moved)
          player.remove_item(cursor_stack_to_be_moved)
        end
        player.clean_cursor()
      else
        local tank_stack_to_be_moved = {name = tank_item_name, count = tank_stack.count}
        inv.remove(tank_stack)
        tank.insert(cursor_stack_to_be_moved)
        player.remove_item(cursor_stack)
        player.clean_cursor()
        player.insert(tank_stack_to_be_moved)
      end

    end
  elseif cursor_stack.name == 'deconstruction-planner'
    or cursor_stack.name == 'copy-paste-tool'
    or cursor_stack.name == 'cut-paste-tool'
    or cursor_stack.name == 'upgrade-planner'
    or cursor_stack.name == 'blueprint'
    or cursor_stack.name == 'blueprint-book'
    then
    --alt+d 같은 단축키 방지
    player.clean_cursor()
  end
end

Prevent_action.on_console_command = function(event)
  if not global.tankpvp_ then return end
  local DB = global.tankpvp_
  if event.player_index then
    local player = game.players[event.player_index]
    if not player then return end
    if event.command == 'color' then
      Util.save_personal_color(player)
      if player.surface.index > 1 and player.surface.name ~= 'vault' and DB.team_game_opened and player.controller_type == defines.controllers.character then
        local force = Util.get_player_team_force(player.name)
        if force ~= 'player' then
          player.color = Const.team_defines_key[force].color
        end
      end
      if player.vehicle then
        if player.vehicle.type == 'spider-vehicle' then
          player.vehicle.color = player.color
        end
      end
    end
  end
end

Prevent_action.on_gui_opened = function(event)
  local player = game.players[event.player_index]
  if event.gui_type ~= defines.gui_type.entity then return end
  if event.entity.type == 'car' then
    player.opened = nil
  elseif event.entity.type == 'spider-vehicle' then
    player.opened = nil
    event.entity.vehicle_automatic_targeting_parameters = {
      auto_target_without_gunner = true,
      auto_target_with_gunner = false,
    }
  elseif event.entity.type == 'locomotive' then
    player.opened = nil
    local train = event.entity.train
    if train then
      if not train.manual_mode then
        train.manual_mode = true
      end
    end
  end
end

Prevent_action.on_player_driving_changed_state = function(event)
  local player = game.players[event.player_index]
  local vehicle = event.entity
  if not vehicle then return end
  if not vehicle.valid then return end
  if player.vehicle ~= vehicle then
    vehicle.set_driver(player)
  end
end

Prevent_action.on_built_entity = function(event)
  if not event.created_entity then return end
  local entity = event.created_entity
  if entity.name == 'entity-ghost' or entity.name == 'tile-ghost' then
    entity.destroy()
  end
end

return Prevent_action