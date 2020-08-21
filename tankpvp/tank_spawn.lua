local Tank_spawn = {}

local Const = require('tankpvp.const')
local Util = require('tankpvp.util')
local Balance = require('tankpvp.balance')

local DB = nil

Tank_spawn.on_load = function()
  DB = global.tankpvp_
end

Tank_spawn.count_team_tanks = function()
  if DB.team_game_opened then
    local surface = game.surfaces[DB.team_game_opened]
    if surface and surface.valid then
      local t1 = surface.count_entities_filtered{
        type = {'car', 'locomotive', 'spider-vehicle'},
        force = Const.team_defines[1].force
      }
      local t2 = surface.count_entities_filtered{
        type = {'car', 'locomotive', 'spider-vehicle'},
        force = Const.team_defines[2].force
      }
      return t1, t2
    end
  end
  return 0, 0
end

Tank_spawn.spawn = function(player)
  local playername = player.name
  local PDB = DB.players_data[playername]
  if not player.controller_type ~= defines.controllers.character then
    local character = player.character
    if character then
      player.character = nil
      Util.ch_destroy(character)
    end
    character = player.surface.create_entity{
      name = 'character',
      force = player.force,
      position = player.position
    }
    player.set_controller{
      type = defines.controllers.character,
      character = character
    }
  end
  player.spectator = false
  PDB.outofring_reserved = false
  if player.render_mode ~= defines.render_mode.game then
    player.close_map()
    player.zoom = 0.45
  end
  DB.zoom_world_queue[playername] = nil
  local mode = PDB.player_mode
  if mode == Const.defines.player_mode.normal then
    game.permissions.get_group(0).add_player(playername)
  elseif mode == Const.defines.player_mode.team then
    game.permissions.get_group('fix_color').add_player(playername)
  end
  local surface = player.surface
  local position = surface.find_non_colliding_position(
    'tank',
    player.position,
    15,
    0.1
  )
  if position == nil then position = player.position end
  local direction = nil
  if position.y > 0 then
    direction = defines.direction.north
  else
    direction = defines.direction.south
  end
  local tank = surface.create_entity{
    name = 'tank',
    position = position,
    force = player.force,
    direction = direction
  }
  if Const.tank_health then
    tank.health = Const.tank_health --빠른 킬 테스트용
  end
  if player.character then player.character_inventory_slots_bonus = 30 end
  tank.set_driver(player)
  Balance.starting_consumables(player)

  --탱크에 물건넣기 차단
  local trunk = tank.get_inventory(defines.inventory.car_trunk)
  for i = 1, #trunk do
    trunk.set_filter(i, 'cut-paste-tool')
  end

  --아머 만들어서 모듈넣어주기
  Balance.starting_armor(player)
end

Tank_spawn.despawn = function(player)
  local PDB = DB.players_data[player.name]
  if player.vehicle then
    Util.save_quick_bar(player, player.vehicle.name)
    if player.vehicle.get_health_ratio() < 0.9 then
      if player.surface.index == 1 then
        if PDB then
          PDB.ffa_deaths = PDB.ffa_deaths + 1
        end
      end
    end
    player.vehicle.destroy()
  end
end

Tank_spawn.periodic_fuel_refill_ffa = function()
  local cars = game.surfaces[1].find_entities_filtered{type = {'car', 'locomotive'}}
  local inv, insertable = nil, 0
  for _, car in pairs(cars) do
    inv = car.get_fuel_inventory()
    insertable = inv.get_insertable_count('solid-fuel')
    if insertable > 0 then inv.insert{name = 'solid-fuel', count = insertable} end
  end
end

local buildable = {
  ['locomotive'] = false,
  ['artillery-wagon'] = false,
  ['car'] = true,
  ['tank'] = true,
  ['spidertron'] = true,
}
Tank_spawn.on_built_entity = function(event)
  local player = game.players[event.player_index]
  local old = player.vehicle
  if not old then return end
  local vehicle = event.created_entity
  if not buildable[vehicle.name] then return end
  Util.save_quick_bar(player, old.name)
  old.die('player')
  vehicle.set_driver(player)
  Balance.starting_consumables(player)
end

return Tank_spawn