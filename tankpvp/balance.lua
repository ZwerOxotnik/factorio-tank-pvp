local Balance = {}
Balance.event_filters = {}

local Const = require('tankpvp.const')
local Util = require('tankpvp.util')
local damageable_spider_leg = require('tankpvp.damageable_spider_leg')

--데미지 배율은 /gdm 커맨드를 통해서 확인 가능하고, /sdm 으로 추후 변경가능
--속도 배율은 /grm 커맨드를 통해서 확인 가능하고, /srm 으로 추후 변경가능
Balance.init = function()
  local force = game.forces['player']
  force.set_ammo_damage_modifier('bullet', 1.035)
  force.set_ammo_damage_modifier('cannon-shell', 0.45)
  force.set_ammo_damage_modifier('flamethrower', 1.85)
  force.set_ammo_damage_modifier('landmine', -0.35)
  force.set_ammo_damage_modifier('grenade', 1.9)
  force.set_ammo_damage_modifier('rocket', -0.35)
  force.set_gun_speed_modifier('cannon-shell', -0.1)
  force.set_gun_speed_modifier('rocket', 0.25)
  Util.copypaste_weapon_modifiers('player','enemy')
  Util.copypaste_weapon_modifiers('player','neutral')
end

--탈것을 생성할 때 넣어주는 기본 아이템
Balance.starting_consumables = function(player)
  if not player.vehicle then return end
  local vehicle = player.vehicle

  if vehicle.name == 'tank' then
    Util.dispose_to_make_slot(player, 2)
    vehicle.insert{name = 'solid-fuel', count = 100}
    vehicle.insert{name = 'cannon-shell', count = 200}
    player.insert{name = 'explosive-cannon-shell', count = 10}
    vehicle.insert{name = 'piercing-rounds-magazine', count = 200}
    player.insert{name = 'uranium-rounds-magazine', count = 3}
    vehicle.insert{name = 'flamethrower-ammo', count = 100}
    if not Util.load_quick_bar(player, vehicle.name) then
      player.set_quick_bar_slot(1, 'cannon-shell')
      player.set_quick_bar_slot(2, 'explosive-cannon-shell')
      player.set_quick_bar_slot(3, 'uranium-rounds-magazine')
      player.set_quick_bar_slot(4, 'piercing-rounds-magazine')
      player.set_quick_bar_slot(5, 'discharge-defense-remote')
      player.set_quick_bar_slot(6, 'destroyer-capsule')
      player.set_quick_bar_slot(7, 'distractor-capsule')
      player.set_quick_bar_slot(8, 'defender-capsule')
      player.set_quick_bar_slot(9, 'spidertron')
      player.set_quick_bar_slot(10, 'repair-pack')
      player.set_quick_bar_slot(20, 'construction-robot')
      player.set_quick_bar_slot(11, 'uranium-cannon-shell')
      player.set_quick_bar_slot(12, 'explosive-uranium-cannon-shell')
      player.set_quick_bar_slot(13, 'slowdown-capsule')
      player.set_quick_bar_slot(14, nil)
      player.set_quick_bar_slot(15, nil)
      player.set_quick_bar_slot(16, 'cluster-grenade')
      player.set_quick_bar_slot(17, 'grenade')
      player.set_quick_bar_slot(18, 'car')
      player.set_quick_bar_slot(19, 'tank')
    end

  elseif vehicle.name == 'car' then
    Util.dispose_to_make_slot(player, 6)
    vehicle.insert{name = 'solid-fuel', count = 50}
    vehicle.insert{name = 'uranium-rounds-magazine', count = 200}
    player.insert{name = 'uranium-rounds-magazine', count = 200}
    player.insert{name = 'construction-robot', count = 20}
    player.insert{name = 'repair-pack', count = 20}
    player.insert{name = 'defender-capsule', count = 100}
    player.insert{name = 'distractor-capsule', count = 10}
    player.insert{name = 'destroyer-capsule', count = 2}
    if not Util.load_quick_bar(player, vehicle.name) then
      player.set_quick_bar_slot(1, 'uranium-rounds-magazine')
      player.set_quick_bar_slot(2, 'cluster-grenade')
      player.set_quick_bar_slot(3, 'grenade')
      player.set_quick_bar_slot(4, 'slowdown-capsule')
      player.set_quick_bar_slot(5, 'discharge-defense-remote')
      player.set_quick_bar_slot(6, 'destroyer-capsule')
      player.set_quick_bar_slot(7, 'distractor-capsule')
      player.set_quick_bar_slot(8, 'defender-capsule')
      player.set_quick_bar_slot(9, 'spidertron')
      player.set_quick_bar_slot(10, 'repair-pack')
      player.set_quick_bar_slot(20, 'construction-robot')
      player.set_quick_bar_slot(11, 'piercing-rounds-magazine')
      player.set_quick_bar_slot(12, 'cluster-grenade')
      player.set_quick_bar_slot(13, 'grenade')
      player.set_quick_bar_slot(14, 'slowdown-capsule')
      player.set_quick_bar_slot(15, nil)
      player.set_quick_bar_slot(16, nil)
      player.set_quick_bar_slot(17, nil)
      player.set_quick_bar_slot(18, 'car')
      player.set_quick_bar_slot(19, 'tank')
    end

  elseif vehicle.name == 'spidertron' then
    vehicle.enable_logistics_while_moving = false
    vehicle.color = player.color
    local grid = vehicle.grid
    local batt = nil
    if grid then
      --batt = grid.put{name = 'exoskeleton-equipment'}
      --batt.energy = batt.max_energy
      for i = 1, 2 do
        batt = grid.put{name = 'battery-mk2-equipment'}
        batt.energy = batt.max_energy
      end
      for i = 1, 10 do
        batt = grid.put{name = 'energy-shield-equipment'}
        batt.energy = batt.max_energy
        batt.shield = batt.max_shield
      end
      batt = grid.put{name = 'personal-laser-defense-equipment'}
      batt.energy = batt.max_energy
      for i = 1, 3 do
        grid.put{name = 'solar-panel-equipment'}
      end
    end
    vehicle.insert{name = 'rocket', count = 200}
    vehicle.insert{name = 'explosive-rocket', count = 200}
    vehicle.insert{name = 'rocket', count = 200}
    vehicle.insert{name = 'explosive-rocket', count = 200}
    Util.insert_spider_remote(player, vehicle)
    local remote = player.get_main_inventory().find_item_stack('spidertron-remote')
    Util.dispose_to_make_slot(player, 1)
    player.insert{name = 'grenade', count = 25}
    if not Util.load_quick_bar(player, vehicle.name) then
      player.set_quick_bar_slot(1, 'rocket')
      player.set_quick_bar_slot(2, 'explosive-rocket')
      player.set_quick_bar_slot(3, 'slowdown-capsule')
      player.set_quick_bar_slot(4, remote)
      player.set_quick_bar_slot(5, 'discharge-defense-remote')
      player.set_quick_bar_slot(6, 'destroyer-capsule')
      player.set_quick_bar_slot(7, 'distractor-capsule')
      player.set_quick_bar_slot(8, 'defender-capsule')
      player.set_quick_bar_slot(9, 'spidertron')
      player.set_quick_bar_slot(10, 'repair-pack')
      player.set_quick_bar_slot(20, 'construction-robot')
      player.set_quick_bar_slot(11, 'cluster-grenade')
      player.set_quick_bar_slot(12, 'grenade')
      player.set_quick_bar_slot(13, 'slowdown-capsule')
      player.set_quick_bar_slot(14, nil)
      player.set_quick_bar_slot(15, nil)
      player.set_quick_bar_slot(16, nil)
      player.set_quick_bar_slot(17, nil)
      player.set_quick_bar_slot(18, 'car')
      player.set_quick_bar_slot(19, 'tank')
    else
      for i = 1, 20 do
        if player.get_quick_bar_slot(i).name == 'spidertron-remote' then
          player.set_quick_bar_slot(i, remote)
          break
        end
      end
    end

  elseif vehicle.name == 'locomotive' then
    Util.dispose_to_make_slot(player, 5)
    vehicle.insert{name = 'solid-fuel', count = 150}
    player.insert{name = 'artillery-wagon', count = 1}
    player.insert{name = 'artillery-targeting-remote', count = 1}
    player.insert{name = 'artillery-shell', count = 20}
    player.insert{name = 'grenade', count = 100}
    player.insert{name = 'cluster-grenade', count = 10}
    if not Util.load_quick_bar(player, vehicle.name) then
      player.set_quick_bar_slot(1, 'artillery-targeting-remote')
      player.set_quick_bar_slot(2, 'grenade')
      player.set_quick_bar_slot(3, 'cluster-grenade')
      player.set_quick_bar_slot(4, 'slowdown-capsule')
      player.set_quick_bar_slot(5, 'discharge-defense-remote')
      player.set_quick_bar_slot(6, 'destroyer-capsule')
      player.set_quick_bar_slot(7, 'distractor-capsule')
      player.set_quick_bar_slot(8, 'defender-capsule')
      player.set_quick_bar_slot(9, 'spidertron')
      player.set_quick_bar_slot(10, 'repair-pack')
      player.set_quick_bar_slot(20, 'construction-robot')
      player.set_quick_bar_slot(11, 'artillery-shell')
      player.set_quick_bar_slot(12, nil)
      player.set_quick_bar_slot(13, nil)
      player.set_quick_bar_slot(14, nil)
      player.set_quick_bar_slot(15, nil)
      player.set_quick_bar_slot(16, nil)
      player.set_quick_bar_slot(17, 'artillery-wagon')
      player.set_quick_bar_slot(18, 'car')
      player.set_quick_bar_slot(19, 'tank')
    end

  end
end

--캐릭터가 생성될 때(탈것이 생김과 동시에) 캐릭터에 (거의 무의미한)아머를 입혀줌.
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
end

--ffa 랜덤 상자 내용물
local random_containers = {
  {
    name = 'wooden-chest',
    weight = 60,
    stuff = {
      ['cannon-shell'] = {chance = 1, count = 3},
      ['piercing-rounds-magazine'] = {chance = 0.8, count = 10},
      ['cannon-shell'] = {chance = 0.8, count = 20},
      ['flamethrower-ammo'] = {chance = 0.4, count = 20},
      ['explosive-cannon-shell'] = {chance = 0.4, count = 10},
      ['rocket'] = {chance = 0.5, count = 5},
      ['grenade'] = {chance = 0.6, count = 3},
      ['repair-pack'] = {chance = 0.2, count = 1},
      ['construction-robot'] = {chance = 0.2, count = 1},
    },
    mob_tier = 1
  },
  {
    name = 'iron-chest',
    weight = 30,
    stuff = {
      ['explosive-cannon-shell'] = {chance = 1, count = 2},
      ['piercing-rounds-magazine'] = {chance = 0.3, count = 20},
      ['uranium-rounds-magazine'] = {chance = 0.3, count = 10},
      ['cannon-shell'] = {chance = 0.6, count = 50},
      ['explosive-cannon-shell'] = {chance = 0.6, count = 20},
      ['flamethrower-ammo'] = {chance = 0.5, count = 50},
      ['rocket'] = {chance = 0.6, count = 20},
      ['explosive-rocket'] = {chance = 0.3, count = 20},
      ['grenade'] = {chance = 0.5, count = 15},
      ['cluster-grenade'] = {chance = 0.3, count = 5},
      ['uranium-cannon-shell'] = {chance = 0.2, count = 20},
      ['explosive-uranium-cannon-shell'] = {chance = 0.15, count = 5},
      ['slowdown-capsule'] = {chance = 0.5, count = 5},
      ['defender-capsule'] = {chance = 0.4, count = 10},
      ['repair-pack'] = {chance = 0.3, count = 2},
      ['construction-robot'] = {chance = 0.3, count = 2},
    },
    mob_tier = 2
  },
  {
    name = 'steel-chest',
    weight = 10,
    stuff = {
      ['explosive-cannon-shell'] = {chance = 1, count = 10},
      ['uranium-rounds-magazine'] = {chance = 0.5, count = 80},
      ['explosive-cannon-shell'] = {chance = 0.5, count = 80},
      ['rocket'] = {chance = 0.6, count = 80},
      ['explosive-rocket'] = {chance = 0.4, count = 80},
      ['grenade'] = {chance = 0.6, count = 50},
      ['cluster-grenade'] = {chance = 0.4, count = 20},
      ['uranium-cannon-shell'] = {chance = 0.3, count = 70},
      ['explosive-uranium-cannon-shell'] = {chance = 0.25, count = 40},
      ['slowdown-capsule'] = {chance = 0.6, count = 20},
      ['defender-capsule'] = {chance = 0.3, count = 40},
      ['distractor-capsule'] = {chance = 0.3, count = 10},
      ['destroyer-capsule'] = {chance = 0.2, count = 5},
      ['discharge-defense-remote'] = {chance = 0.1, count = 1},
      ['repair-pack'] = {chance = 0.4, count = 3},
      ['construction-robot'] = {chance = 0.4, count = 3},
    },
    mob_tier = 3
  },
  {
    name = 'logistic-chest-active-provider',
    weight = 5,
    stuff = {
      ['grenade'] = {chance = 1, count = 30},
      ['cluster-grenade'] = {chance = 1, count = 60},
      ['slowdown-capsule'] = {chance = 1, count = 20},
    },
    mob_tier = 3
  },
  {
    name = 'logistic-chest-passive-provider',
    weight = 5,
    stuff = {
      ['explosive-cannon-shell'] = {chance = 1, count = 100},
      ['defender-capsule'] = {chance = 1, count = 80},
      ['distractor-capsule'] = {chance = 1, count = 15},
      ['destroyer-capsule'] = {chance = 1, count = 8},
    },
    mob_tier = 4
  },
  {
    name = 'logistic-chest-requester',
    weight = 7,
    stuff = {
      ['repair-pack'] = {chance = 1, count = 10},
      ['construction-robot'] = {chance = 1, count = 10},
    },
    mob_tier = 2
  },
  {
    name = 'logistic-chest-storage',
    weight = 4,
    stuff = {
      ['rocket'] = {chance = 1, count = 200},
      ['explosive-rocket'] = {chance = 1, count = 150},
    },
    mob_tier = 4
  },
  {
    name = 'logistic-chest-buffer',
    weight = 3,
    stuff = {
      ['uranium-rounds-magazine'] = {chance = 1, count = 200},
      ['uranium-cannon-shell'] = {chance = 1, count = 200},
      ['explosive-uranium-cannon-shell'] = {chance = 1, count = 150},
      ['atomic-bomb'] = {chance = 0.33, count = 2},
    },
    mob_tier = 5
  },
  {
    name = 'car',
    weight = 2,
    stuff = {
      ['car'] = {chance = 1, count = 1},
    },
    mob_tier = 2
  },
  {
    name = 'tank',
    weight = 2,
    stuff = {
      ['tank'] = {chance = 1, count = 1},
    },
    mob_tier = 2
  },
  {
    name = 'spidertron',
    weight = 1,
    stuff = {
      ['spidertron'] = {chance = 1, count = 1},
    },
    mob_tier = 6
  },
}
local weight_sum = 0
for _, box in ipairs(random_containers) do
  weight_sum = weight_sum + box.weight
  box.weight = weight_sum
end
--무작위 보급품 만들기
Balance.create_random_supply = function(surface, position)
  local rng = math.random()*weight_sum
  local chosen = nil
  for i, box in ipairs(random_containers) do
    if rng <= box.weight then
      chosen = box
      break
    end
  end
  if not chosen then return end
  local entity = surface.create_entity{
    name = chosen.name,
    force = 'neutral',
    position = position,
  }
  if entity.color then entity.color = {0.5,0.5,0.5,0.5} end
  if entity.type == 'spider-vehicle' then
    damageable_spider_leg.register_spider(entity)
  end
  surface.create_entity{
    name = 'flying-text',
    position = position,
    text = {"pop-supply"},
    color = {1, 1, 0, 1}
  }
  surface.play_sound{path = 'utility/rotated_big', position = position, volume_modifier = 1}
  entity.operable = false
  entity.orientation = math.random()
  local inv = entity.get_inventory(defines.inventory.car_trunk)
  if inv then
    for name, stuff in pairs(chosen.stuff) do
      if stuff.chance >= math.random() then
        inv.insert{name = name, count = math.random(1,stuff.count)}
      end
    end
  else
    inv = entity.get_inventory(defines.inventory.chest)
    for name, stuff in pairs(chosen.stuff) do
      if stuff.chance >= math.random() then
        inv.insert{name = name, count = math.random(1,stuff.count)}
      end
    end
  end
  return entity
end

local supply_names_at_k = {}
local supply_names_at_v = {}
for _, box in pairs(random_containers) do
  supply_names_at_k[box.name] = box.mob_tier
  table.insert(supply_names_at_v, box.name)
end
local breaker_types = {
  ['car'] = true,
  ['locomotive'] = true,
  ['artillery-wagon'] = true,
  ['cargo-wagon'] = true,
  ['fluid-wagon'] = true,
  ['spider-vehicle'] = true,
}
local mob_pop = {
  --인덱스는 mob_tier
  [1] = {
    ['small-biter'] = {chance = 0.15, count = 40},
    ['medium-biter'] = {chance = 0.3, count = 10},
    ['small-spitter'] = {chance = 0.2, count = 20},
    ['medium-spitter'] = {chance = 0.3, count = 10},
  },
  [2] = {
    ['small-biter'] = {chance = 0.15, count = 80},
    ['medium-biter'] = {chance = 0.3, count = 20},
    ['big-biter'] = {chance = 0.25, count = 4},
    ['behemoth-biter'] = {chance = 0.05, count = 1},
    ['small-spitter'] = {chance = 0.15, count = 40},
    ['medium-spitter'] = {chance = 0.3, count = 20},
    ['big-spitter'] = {chance = 0.15, count = 4},
    ['behemoth-spitter'] = {chance = 0.05, count = 1},
  },
  [3] = {
    ['small-biter'] = {chance = 0.1, count = 100},
    ['medium-biter'] = {chance = 0.2, count = 50},
    ['big-biter'] = {chance = 0.3, count = 8},
    ['behemoth-biter'] = {chance = 0.15, count = 2},
    ['small-spitter'] = {chance = 0.1, count = 50},
    ['medium-spitter'] = {chance = 0.2, count = 40},
    ['big-spitter'] = {chance = 0.2, count = 8},
    ['behemoth-spitter'] = {chance = 0.1, count = 2},
  },
  [4] = {
    ['medium-biter'] = {chance = 0.1, count = 80},
    ['big-biter'] = {chance = 0.35, count = 15},
    ['behemoth-biter'] = {chance = 0.3, count = 4},
    ['medium-spitter'] = {chance = 0.1, count = 60},
    ['big-spitter'] = {chance = 0.25, count = 10},
    ['behemoth-spitter'] = {chance = 0.2, count = 3},
  },
  [5] = {
    ['medium-biter'] = {chance = 0.1, count = 100},
    ['big-biter'] = {chance = 0.4, count = 25},
    ['behemoth-biter'] = {chance = 0.35, count = 8},
    ['medium-spitter'] = {chance = 0.1, count = 70},
    ['big-spitter'] = {chance = 0.3, count = 15},
    ['behemoth-spitter'] = {chance = 0.25, count = 8},
  },
  [6] = {
    ['big-biter'] = {chance = 0.9, count = 50},
    ['behemoth-biter'] = {chance = 0.9, count = 16},
    ['big-spitter'] = {chance = 0.9, count = 35},
    ['behemoth-spitter'] = {chance = 0.9, count = 16},
  },
}
--보급상자를 부수면 내용물이 떨어진다.
Balance.on_entity_damaged = function(event)
  if event.final_health > 0 then return end
  if not event.entity.valid then return end
  local box = event.entity
  if not box.force then return end
  if box.force.name ~= 'neutral' then return end
  if not supply_names_at_k[event.entity.name] then return end

  local breaker = nil
  if event.cause and event.cause.valid then
    if breaker_types[event.cause.type] or event.cause.last_user then
      breaker = event.cause.get_driver()
      if breaker then
        if breaker.player then
          breaker = breaker.player
        elseif breaker.is_player() then
          breaker = breaker
        else
          breaker = event.cause.last_user
        end
      else
        breaker = event.cause.last_user
      end
    elseif event.cause.type == 'character' then
      breaker = event.cause.player
    else
      breaker = event.cause.last_user
    end
  end

  local distance = nil
  if breaker and breaker.connected and breaker.surface == box.surface then
    distance = math.sqrt((box.position.x-breaker.position.x)^2 + (box.position.y-breaker.position.y)^2)
  end

  local inv = box.get_inventory(defines.inventory.car_trunk)
  if not inv then inv = box.get_inventory(defines.inventory.chest) end
  local loots = inv.get_contents()
  local stack = nil
  local taken = false
  if distance and distance < 15 then
    for item, count in pairs(loots) do
      stack = {name = item, count = count}
      if breaker.can_insert(stack) then
        taken = true
        breaker.insert(stack)
      else
        box.surface.spill_item_stack(box.position, stack, true, 'neutral', false)
      end
    end
  else
    for item, count in pairs(loots) do
      box.surface.spill_item_stack(
        box.position,
        {name = item, count = count},
        true,
        'neutral',
        false
      )
    end
  end
  if taken then
    box.surface.create_entity{
      name = 'flying-text',
      position = box.position,
      text = {"supply-took-by", breaker.name},
      color = {1, 0.8, 0, 1}
    }
  end
  local fpos = nil
  for name, v in pairs(mob_pop[supply_names_at_k[event.entity.name]]) do
    if v.chance >= math.random() then
      fpos = box.surface.find_non_colliding_position(name, box.position, 30, 0.2)
      if not fpos then fpos = box.position end
      for i = 1, math.random(1, v.count) do
        box.surface.create_entity{name = name, force = 'enemy', position = fpos}
      end
    end
  end
end
local damage_filters = {}
for _, box in pairs(random_containers) do
  table.insert(damage_filters, {filter = 'name', name = box.name, mode = 'or', invert = false})
end
Balance.event_filters.on_entity_damaged = {defines.events.on_entity_damaged, damage_filters}

--보급품 투하!
Balance.on_1200_tick_drop_supply_ffa = function()
  local ffa_cnt = 0
  local surface = game.surfaces[1]
  local radius = global.tankpvp_.field_radius
  local p = nil
  local giveup = false
  local try = 0
  local supply = nil
  for _, player in pairs(game.connected_players) do
    if player.surface == surface then ffa_cnt = ffa_cnt + 1 end
  end
  if Const.force_limit < ffa_cnt then ffa_cnt = Const.force_limit end
  for i = 1, ffa_cnt do
    try = 0
    while not giveup do
      p = Util.pick_random_in_circle(radius)
      --if surface.get_tile(p.x, p.y).collides_with('ground-tile') then
        if surface.count_entities_filtered{
            position = p,
            radius = 20,
            name = supply_names_at_v,
            force = 'neutral'
          } == 0 then
          break
        end
      --end
      try = try + 1
      if try > 100 then giveup = true end
    end
    if giveup then break end
    supply = Balance.create_random_supply(surface, p)
  end
end

--데미지 보정 --Damaging.on_entity_damaged 에서 호출됨.
Balance.modify_on_entity_damaged = function(event)
  local DB = global.tankpvp_
  local entity = event.entity
  if entity.name == 'car' then
    if event.final_health > 0 then
      event.final_health = event.final_health + event.final_damage_amount
      event.final_damage_amount = Util.recalculate_final_damage(DB.prototypes['tank'], event.original_damage_amount, event.damage_type.name)
      event.final_health = event.final_health - (event.final_damage_amount * 0.6)
      if event.final_health < 0 then event.final_health = 0 end
      entity.health = event.final_health
    end
  elseif entity.name == 'tank' then
    --nothing
  elseif entity.type == 'spider-vehicle' then
    event.final_health = event.final_health - event.final_damage_amount * 0.5
    if event.final_health < 0 then event.final_health = 0 end
    entity.health = event.final_health
  elseif entity.type == 'locomotive' or entity.type == 'artillery-wagon' then
    if event.final_health > 0 then
      event.final_health = event.final_health + event.final_damage_amount * 0.5
    end
  end
  return event
end

return Balance
