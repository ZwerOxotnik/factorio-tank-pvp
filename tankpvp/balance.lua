local Balance = {}

local Const = require('tankpvp.const')
local Util = require('tankpvp.util')

--데미지 배율은 /gdm 커맨드를 통해서 확인 가능하고, /sdm 으로 추후 변경가능
--속도 배율은 /grm 커맨드를 통해서 확인 가능하고, /srm 으로 추후 변경가능
Balance.init = function()
  local force = game.forces['player']
  force.set_ammo_damage_modifier('bullet', 1.035)
  force.set_ammo_damage_modifier('cannon-shell', 0.45)
  force.set_ammo_damage_modifier('flamethrower', 2)
  force.set_ammo_damage_modifier('landmine', -0.35)
  force.set_ammo_damage_modifier('grenade', 1.9)
  force.set_ammo_damage_modifier('rocket', -0.40)
  force.set_gun_speed_modifier('cannon-shell', -0.1)
  force.set_gun_speed_modifier('rocket', 1.75)
  Util.copypaste_weapon_modifiers('player','enemy')
  Util.copypaste_weapon_modifiers('player','neutral')
end

Balance.starting_consumables = function(player)
  if not player.vehicle then return end
  local vehicle = player.vehicle

  if vehicle.name == 'tank' then
    vehicle.insert{name = 'solid-fuel', count = 100}
    vehicle.insert{name = 'cannon-shell', count = 200}
    player.insert{name = 'explosive-cannon-shell', count = 10}
    vehicle.insert{name = 'piercing-rounds-magazine', count = 200}
    player.insert{name = 'uranium-rounds-magazine', count = 3}
    vehicle.insert{name = 'flamethrower-ammo', count = 100}

  elseif vehicle.name == 'car' then
    vehicle.insert{name = 'solid-fuel', count = 50}
    vehicle.insert{name = 'uranium-rounds-magazine', count = 200}
    player.insert{name = 'construction-robot', count = 20}
    player.insert{name = 'repair-pack', count = 20}
    player.insert{name = 'defender-capsule', count = 100}
    player.insert{name = 'distractor-capsule', count = 10}
    player.insert{name = 'destroyer-capsule', count = 2}

  elseif vehicle.name == 'spidertron' then
    vehicle.enable_logistics_while_moving = false
    local grid = vehicle.grid
    local batt = nil
    if grid then
      batt = grid.put{name = 'exoskeleton-equipment'}
      batt.energy = batt.max_energy
      for i = 1, 4 do
        batt = grid.put{name = 'battery-mk2-equipment'}
        batt.energy = batt.max_energy
      end
      for i = 1, 10 do
        batt = grid.put{name = 'energy-shield-mk2-equipment'}
        batt.energy = batt.max_energy
        batt.shield = batt.max_shield
      end
      batt = grid.put{name = 'personal-laser-defense-equipment'}
      batt.energy = batt.max_energy
    end
    vehicle.insert{name = 'rocket', count = 200}
    vehicle.insert{name = 'explosive-rocket', count = 200}
    vehicle.insert{name = 'rocket', count = 200}
    vehicle.insert{name = 'explosive-rocket', count = 200}
    Util.insert_spider_remote(player, vehicle)
    player.insert{name = 'grenade', count = 25}

  elseif vehicle.name == 'locomotive' then
    vehicle.insert{name = 'solid-fuel', count = 150}
    player.insert{name = 'artillery-shell', count = 20}
    player.insert{name = 'artillery-targeting-remote', count = 1}
    player.insert{name = 'artillery-wagon', count = 1}
    player.insert{name = 'grenade', count = 100}
    player.insert{name = 'cluster-grenade', count = 10}

  end
end

Balance.starting_armor = function(player)
  if not player then return end
  local inv = game.create_inventory(1)
  inv.insert{name = 'power-armor-mk2', count = 1}
  local armor = inv.find_item_stack('power-armor-mk2')
  if armor then
    local grid = armor.grid
    local batt = nil
    if grid then
      grid.put{name = 'fusion-reactor-equipment'}
      grid.put{name = 'fusion-reactor-equipment'}
      batt = grid.put{name = 'personal-roboport-equipment'}
      batt.energy = batt.max_energy
      batt = grid.put{name = 'battery-mk2-equipment'}
      batt.energy = batt.max_energy
      batt = grid.put{name = 'battery-mk2-equipment'}
      batt.energy = batt.max_energy
      batt = grid.put{name = 'discharge-defense-equipment'}
      batt.energy = batt.max_energy
    end
  end
  player.insert(armor)
  inv.destroy()
  player.character.allow_dispatching_robots = false
end

return Balance