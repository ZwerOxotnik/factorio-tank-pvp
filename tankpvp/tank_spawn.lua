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

local spawn_initial_vehicle = function(player)
  local playername = player.name
  local PDB = DB.players_data[playername]
  local character = player.character
  character = player.surface.create_entity{
    name = 'character',
    force = player.force,
    position = player.position
  }
  player.set_controller{
    type = defines.controllers.character,
    character = character
  }
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
  if player.character then
    player.character_inventory_slots_bonus = 30
    player.character_loot_pickup_distance_bonus = 2
  end
  tank.set_driver(player)
  Balance.starting_consumables(player)

  --탱크에 물건넣기 차단
  local trunk = tank.get_inventory(defines.inventory.car_trunk)
  for i = 1, #trunk do
    trunk.set_filter(i, 'cut-paste-tool')
  end

  --아머 만들어서 모듈넣어주기
  Balance.starting_armor(player)

  return tank
end

local spawn_from_vault = function(player)
  local playername = player.name
  local PDB = DB.players_data[playername]
  local vehicle = Tank_spawn.summon_vehicle_from_vault(player)
  if not vehicle then
    return spawn_initial_vehicle(player)
  else
    player.set_controller{
      type = defines.controllers.character,
      character = vehicle.get_driver()
    }
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
    if vehicle.position.y > 0 then
      vehicle.direction = defines.direction.north
    else
      vehicle.direction = defines.direction.south
    end
    if player.character then
      player.character_inventory_slots_bonus = 30
      player.character_loot_pickup_distance_bonus = 2
    end
    vehicle.color = player.color

    return vehicle
  end
end

Tank_spawn.spawn = function(player, initial_vehicle)
  local playername = player.name
  local PDB = DB.players_data[playername]
  local character = player.character
  if character then
    player.character = nil
    Util.ch_destroy(character)
  end
  if initial_vehicle then
    return spawn_initial_vehicle(player) --아직 tank이외에 안만듦
  else
    return spawn_from_vault(player)
  end
end

Tank_spawn.despawn = function(player)
  local PDB = DB.players_data[player.name]
  if player.vehicle then
    Util.save_quick_bar(player, player.vehicle.name)
    if player.surface.index == 1 then
      Tank_spawn.keep_vehicle_in_vault(player)
    end
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

  --탱크에 물건넣기 차단
  local trunk = vehicle.get_inventory(defines.inventory.car_trunk)
  for i = 1, #trunk do
    trunk.set_filter(i, 'cut-paste-tool')
  end
  if vehicle.type == 'spider-vehicle' then
    vehicle.vehicle_automatic_targeting_parameters = {
      auto_target_without_gunner = true,
      auto_target_with_gunner = false,
    }
  end
end

--저장고에서 차량 삭제하기
Tank_spawn.remove_vehicle_in_vault = function(player)
  local pos = {x = -999990 + player.index * 10, y = -999990}
  local area = {{pos.x-4.5,pos.y-4.5},{pos.x+4.5,pos.y+4.5}}
  local vault = game.surfaces.vault
  local entities = vault.find_entities_filtered{
    area = area,
    type = {'character', 'straight-rail', 'car', 'locomotive', 'spider-vehicle', 'artillery-wagon'}
  }
  for _, e in pairs(entities) do
    e.destroy()
  end
end

--저장고에 차량 보관하기
Tank_spawn.keep_vehicle_in_vault = function(player)
  local pos = {x = -999990 + player.index * 10, y = -999990}
  local vault = game.surfaces.vault
  if player.vehicle and player.character then
    Tank_spawn.remove_vehicle_in_vault(player)
    local vehicle = player.vehicle
    local character = player.character
    player.character = nil
    Util.set_control_spect(player)
    for x = -1, 1, 2 do
      for y = -1, 1, 2 do
        vault.create_entity{
          name = 'straight-rail',
          position = {pos.x+x,pos.y+y},
          force = 'player',
        }
      end
    end
    vehicle.orientation = 0
    player.surface.clone_entities{
      entities = {vehicle, character},
      destination_offset = {pos.x-vehicle.position.x, pos.y-vehicle.position.y},
      destination_surface = vault,
      destination_force = 'player',
    }
    vehicle.destroy()
    character.destroy()
  else
    Tank_spawn.remove_vehicle_in_vault(player)
  end
end

--저장고에서 차량 소환하기
Tank_spawn.summon_vehicle_from_vault = function(player)
  local pos = {x = -999990 + player.index * 10, y = -999990}
  local area = {{pos.x-4.5,pos.y-4.5},{pos.x+4.5,pos.y+4.5}}
  local vault = game.surfaces.vault
  local surface = player.surface
  if not player.character and not player.vehicle then
    local entities = vault.find_entities_filtered{
      area = area,
      type = {'character', 'straight-rail', 'car', 'locomotive', 'spider-vehicle', 'artillery-wagon'}
    }
    local deployed_character = nil
    local vehicle_name = nil
    local loc = player.position

    --자동차, 탱크, 거미, 기관차인 경우
    for _, e in pairs(entities) do
      --자동차, 탱크 또는 거미인 경우
      if e.type == 'car' or e.type == 'spider-vehicle' then
        loc = surface.find_non_colliding_position(
          e.name,
          player.position,
          15,
          0.1
        )
        if loc == nil then loc = player.position end
        vault.clone_entities{
          entities = {e},
          destination_offset = {loc.x-e.position.x, loc.y-e.position.y},
          destination_surface = surface,
          destination_force = 'player',
        }
        vehicle_name = e.name
        break

      --기관차인 경우
      elseif e.type == 'locomotive' then
        local chosen_rail = nil
        local rails = surface.find_entities_filtered{
          position = loc,
          radius = 500,
          type = {'straight-rail', 'curved-rail'},
        }
        local valid_rails = {}
        for _, r in pairs(rails) do
          if surface.can_place_entity{name = 'locomotive', position = r.position} then
            valid_rails[#valid_rails + 1] = r
          end
        end
        if #valid_rails > 0 then chosen_rail = surface.get_closest(loc, valid_rails) end
        if chosen_rail then
          loc = chosen_rail.position
          vault.clone_entities{
            entities = {e},
            destination_offset = {loc.x-e.position.x, loc.y-e.position.y},
            destination_surface = surface,
            destination_force = 'player',
          }
          vehicle_name = e.name
          break
        else
          local character = nil
          for __, ch in pairs(entities) do
            character = ch
            break
          end
          if character then
            Util.dispose_to_make_slot(character, 1)
            character.mine_entity(e, true)
            local temp = vault.create_entity{name = 'tank', position = pos, force = 'player'}
            temp.insert{'solid-fuel', 100}
            local trunk = vehicle.get_inventory(defines.inventory.car_trunk)
            for i = 1, #trunk do
              trunk.set_filter(i, 'cut-paste-tool')
            end
            loc = surface.find_non_colliding_position(
              'tank',
              player.position,
              15,
              0.1
            )
            if loc == nil then loc = player.position end
            vault.clone_entities{
              entities = {temp},
              destination_offset = {loc.x-temp.position.x, loc.y-temp.position.y},
              destination_surface = surface,
              destination_force = 'player',
            }
            vehicle_name = 'tank'
            break
          end
        end

      end
    end

    --대포 기관차인 경우
    for _, e in pairs(entities) do
      if e.type == 'artillery-wagon' then
        local character = nil
        for __, ch in pairs(entities) do
          if ch.type == 'character' then
            character = ch
            break
          end
        end
        if character then
          Util.dispose_to_make_slot(character, 1)
          character.mine_entity(e, true)
          break
        end
      end
    end

    --캐릭터인 경우
    for _, e in pairs(entities) do
      if e.type == 'character' then
        vault.clone_entities{
          entities = {e},
          destination_offset = {loc.x-e.position.x, loc.y-e.position.y},
          destination_surface = surface,
          destination_force = 'player',
        }
        deployed_character = true
      end
    end

    if deployed_character and vehicle_name then
      local character = surface.find_entities_filtered{
        position = loc,
        radius = 10,
        type = 'character',
        force = 'player',
        limit = 1,
      }
      if #character > 0 then character = character[1] else character = nil end
      local vehicle = surface.find_entities_filtered{
        position = loc,
        radius = 10,
        name = vehicle_name,
        force = 'player',
        limit = 1,
      }
      if #vehicle > 0 then vehicle = vehicle[1] else vehicle = nil end
      if character and vehicle then
        character.force = player.force
        vehicle.force = player.force
        player.associate_character(character)
        vehicle.set_driver(character)
        Tank_spawn.remove_vehicle_in_vault(player)
        return vehicle
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end

return Tank_spawn