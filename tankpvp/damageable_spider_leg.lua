--[[
이 파일은 모드가 설정되어 있지 않은 바닐라 시나리오 혹은 세이브파일에서 사용하기 위한 lua module입니다.
This file is lua module for non-modded vanilla scenarios or savefiles.

Usage example (event_handler format) :

[control.lua in scenario]
local handler = require("event_handler")
..blah blah..
handler.add_lib(require("damageable_spider_leg")) --if this module is at root path.

--]]

local damageable_spider_leg = {}

-- damageable-spider-leg lua module

local debugging = false
local damage_modifier = 1/4

local register_spider = function(entity)
  if not entity then return end
  if not entity.valid then return end
  if entity.type ~= 'spider-vehicle' then return end
  if not global.damageable_spider_leg then
    global.damageable_spider_leg = {}
  end
  local data = {}
  local spider = entity
  local surface = spider.surface
  local legs = surface.find_entities_filtered{
    position = spider.position,
    radius = 10,
    type = 'spider-leg'
  }
  for _, leg in pairs(legs) do
    if not leg.destructible then
      leg.destructible = true
      data[#data + 1] = leg
    end
  end
  global.damageable_spider_leg[tostring(spider.unit_number)] = data
  script.register_on_entity_destroyed(spider)
  if debugging then
    game.print{"",'legs=',#data,' ',spider.name,spider.unit_number}
  end
end

damageable_spider_leg.register_spider = function(entity)
  register_spider(entity)
end

local on_entity_damaged = function(event)
  if not event.entity then return end
  if not event.entity.valid then return end
  if event.entity.type ~= 'spider-leg' then return end
  local leg = event.entity
  local torsos = event.entity.surface.find_entities_filtered{
    position = leg.position,
    radius = 10,
    type = 'spider-vehicle'
  }
  local unit_number = nil
  for _, torso in pairs(torsos) do
    unit_number = tostring(torso.unit_number)
    if global.damageable_spider_leg[unit_number] then
      for _, entity in pairs(global.damageable_spider_leg[unit_number]) do
        if entity == leg then
          leg.health = leg.prototype.max_health
          local damage = event.original_damage_amount * damage_modifier
          --저항 감산수치가 있으면 modify한 다음에 다시 데미지에 추가한다.
          if torso.prototype.resistances then
            if torso.prototype.resistances[event.damage_type.name] then
              damage = damage + torso.prototype.resistances[event.damage_type.name].decrease * (1 - damage_modifier)
              if damage > event.original_damage_amount then
                damage = event.original_damage_amount
              end
            end
          end
          if event.cause and event.cause.valid then
            torso.damage(
              damage,
              event.force,
              event.damage_type.name,
              event.cause
            )
          else
            torso.damage(
              damage,
              event.force,
              event.damage_type.name
            )
          end
          return
        end
      end
    end
  end
end

local on_entity_destroyed = function(event)
  if debugging then
    local check = nil
    if global.damageable_spider_leg[tostring(event.unit_number)] then check = event.unit_number end
    game.print{"",'removed ',check}
  end
  global.damageable_spider_leg[tostring(event.unit_number)] = nil
end

local on_robot_built_entity = function(event)
  register_spider(event.created_entity)
end

local on_built_entity = function(event)
  register_spider(event.created_entity)
end

local on_entity_cloned = function(event)
  register_spider(event.destination)
end

damageable_spider_leg.events = { --core\lualib\event_handler.lua를 위한 포맷
  [defines.events.on_entity_damaged] = on_entity_damaged,
  [defines.events.on_entity_destroyed] = on_entity_destroyed,
  [defines.events.on_robot_built_entity] = on_robot_built_entity,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_entity_cloned] = on_entity_cloned,
}

damageable_spider_leg.on_load = function()
  if global.damageable_spider_leg then
    for _, data in pairs(global.damageable_spider_leg) do
      for _, entity in pairs(data) do
        entity.destructible = true
      end
    end
  end
end

return damageable_spider_leg