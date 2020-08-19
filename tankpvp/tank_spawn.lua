local Tank_spawn = {}

local Const = require('tankpvp.const')

local DB = nil

Tank_spawn.on_load = function()
  DB = global.tankpvp_
end

Tank_spawn.count_team_tanks = function()
  if DB.team_game_opened then
    local surface = game.surfaces[DB.team_game_opened]
    if surface and surface.valid then
      local t1 = surface.count_entities_filtered{
        name = 'tank',
        force = Const.team_defines[1].force
      }
      local t2 = surface.count_entities_filtered{
        name = 'tank',
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
      character.destroy()
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
  tank.set_driver(player)
  tank.insert{name = 'solid-fuel', count = 100}
  tank.insert{name = 'cannon-shell', count = 200}
  player.insert{name = 'explosive-cannon-shell', count = 100}
  tank.insert{name = 'piercing-rounds-magazine', count = 200}
  player.insert{name = 'uranium-rounds-magazine', count = 10}
  tank.insert{name = 'flamethrower-ammo', count = 100}

  --탱크에 물건넣기 차단
  local trunk = tank.get_inventory(defines.inventory.car_trunk)
  for i = 1, #trunk do
    trunk.set_filter(i, 'cut-paste-tool')
  end

  --mk2 아머 만들어서 모듈넣어주기
  player.insert{name = 'power-armor-mk2', count = 1}
  local armor = player.get_inventory(defines.inventory.character_main).find_item_stack('power-armor-mk2')
    or player.get_inventory(defines.inventory.character_armor).find_item_stack('power-armor-mk2')
  if armor then
    local inv = armor.grid
    local batt = nil
    if inv then
      inv.put{name = 'fusion-reactor-equipment'}
      inv.put{name = 'fusion-reactor-equipment'}
      batt = inv.put{name = 'personal-roboport-equipment'}
      batt.energy = batt.max_energy
      batt = inv.put{name = 'battery-mk2-equipment'}
      batt.energy = batt.max_energy
      batt = inv.put{name = 'battery-mk2-equipment'}
      batt.energy = batt.max_energy
      batt = inv.put{name = 'discharge-defense-equipment'}
      batt.energy = batt.max_energy
      batt = inv.put{name = 'discharge-defense-equipment'}
      batt.energy = batt.max_energy
      batt = inv.put{name = 'discharge-defense-equipment'}
      batt.energy = batt.max_energy
    end
  end

  --퀵바 초기화
  player.set_quick_bar_slot(1, 'cannon-shell')
  player.set_quick_bar_slot(2, 'explosive-cannon-shell')
  player.set_quick_bar_slot(3, 'uranium-rounds-magazine')
  player.set_quick_bar_slot(4, 'piercing-rounds-magazine')
  player.set_quick_bar_slot(5, 'firearm-magazine')
  player.set_quick_bar_slot(6, 'destroyer-capsule')
  player.set_quick_bar_slot(7, 'distractor-capsule')
  player.set_quick_bar_slot(8, 'defender-capsule')
  player.set_quick_bar_slot(10, 'repair-pack')
  player.set_quick_bar_slot(20, 'construction-robot')
  player.set_quick_bar_slot(11, 'uranium-cannon-shell')
  player.set_quick_bar_slot(12, 'explosive-uranium-cannon-shell')
  player.set_quick_bar_slot(13, 'slowdown-capsule')
  player.set_quick_bar_slot(14, 'discharge-defense-remote')
  player.set_quick_bar_slot(15, 'poison-capsule')
  player.set_quick_bar_slot(16, 'cluster-grenade')
  player.set_quick_bar_slot(17, 'grenade')
end

Tank_spawn.despawn = function(player)
  local PDB = DB.players_data[player.name]
  if player.vehicle then
    if player.vehicle.get_health_ratio() < 1 then
      if player.surface.index == 1 then
        if PDB then
          PDB.ffa_deaths = PDB.ffa_deaths + 1
        end
      end
    end
    player.vehicle.destroy()
  end
end

--[[
Tank_spawn.eject_driver = function(player)
  if player.vehicle then
    player.vehicle.set_driver(nil)
    player.vehicle.set_passenger(nil)
    player.vehicle.force = 'enemy'
  end
end--]]

return Tank_spawn