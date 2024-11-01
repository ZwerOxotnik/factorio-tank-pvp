local Tank_loots = {}
Tank_loots.event_filters = {}

local Const = require('tankpvp.const')
local Util = require('tankpvp.util')

local __DB = nil

Tank_loots.on_load = function()
  __DB = storage.tankpvp_
end


local __stack = {name = "", count = 1}
local __spill_item_stack_param = {
    position = nil, stack = __stack,
    enable_looted = true, allow_belts = false,
    force = "neutral"
}
local vehicle_types = {
  ['car'] = true,
  ['locomotive'] = true,
  ['spider-vehicle'] = true,
}
Tank_loots.on_entity_died = function(event)
  local vehicle = event.entity
  if not vehicle.valid then return end
  if not vehicle_types[vehicle.type] then return end
  if event.force.name == 'player' then return end
  if vehicle.get_driver() then
    local character = vehicle.get_driver()
    if character.player then
      local player = character.player
      local PDB = __DB.players_data[player.name]
      Util.save_quick_bar(player, vehicle.name)
      if event.cause then
        if vehicle_types[event.cause.type] or event.cause.last_user then

          --킬러가 플레이어
          local killer = nil
          if vehicle_types[event.cause.type] then
            killer = event.cause.get_driver()
            if killer then
              if killer.player then
                killer = killer.player
              elseif killer.is_player() then
                killer = killer
              else
                killer = event.cause.last_user
              end
            else
              killer = event.cause.last_user
            end
          elseif event.cause.type == 'character' then
            killer = event.cause.player
          else
            killer = event.cause.last_user
          end

          if killer then
            if killer.character then
              character.die(killer.force, killer.character)
            else
              character.die(event.cause.force, event.cause)
            end
            if killer.valid then
              local KDB = __DB.players_data[killer.name]
              if killer == player then
                if vehicle.surface.index == 1 then
                  PDB.ffa_deaths = PDB.ffa_deaths + 1
                end
              elseif vehicle.surface.index == 1 then
                KDB.ffa_kills = KDB.ffa_kills + 1
                PDB.ffa_deaths = PDB.ffa_deaths + 1
              elseif killer.force == player.force then
                if player.force.name == Const.team_defines[1].force or player.force.name == Const.team_defines[2].force then
                  KDB.tdm_kills = KDB.tdm_kills - 1
                end
              else
                if player.force.name == Const.team_defines[1].force or player.force.name == Const.team_defines[2].force then
                  KDB.tdm_kills = KDB.tdm_kills + 1
                end
              end
            end --킬 카운터
          else
            character.die(event.cause.force, event.cause)
            if vehicle.surface.index == 1 then
              PDB.ffa_deaths = PDB.ffa_deaths + 1
            end
          end

        else
          character.die(event.cause.force, event.cause)
          if vehicle.surface.index == 1 then
            PDB.ffa_deaths = PDB.ffa_deaths + 1
          end
        end
      else
        character.die()
        if vehicle.surface.index == 1 then
          PDB.ffa_deaths = PDB.ffa_deaths + 1
        end
      end
      local loots = vehicle.get_inventory(defines.inventory.car_ammo).get_contents()
      for _, item_data in pairs(loots) do
        local count = item_data.count
        if count > 10 then count = 10 end
        __spill_item_stack_param.position = vehicle.position
        __stack.count = math.random(1, count)
        __stack.name  = item_data.name
        vehicle.surface.spill_item_stack(__spill_item_stack_param)
      end
    end
  end
end

local loot_blacklist = {
  ['power-armor-mk2'] = true,
  ['artillery-targeting-remote'] = true,
  ['rts-tool'] = true,
}
--이벤트에 등록해서 쓰다가 버그가 있어서 결국 빼고 on_player_died에 섞어서 씀.
Tank_loots.on_post_entity_died = function(event)
  if not event.corpses then return end
  for _, corpse in pairs(event.corpses) do
    if corpse and corpse.valid then
      if corpse.name == 'character-corpse' then
        local inv = corpse.get_inventory(defines.inventory.character_corpse)
        if #inv > 0 then
          local loots = inv.get_contents()
          for _, item_data in pairs(loots) do
            local count = item_data.count
            if count > Const.loot_limit then count = Const.loot_limit end
            local item_name = item_data.name
            if not loot_blacklist[item_name] then
              __spill_item_stack_param.position = corpse.position
              __stack.count = math.random(1, count)
              __stack.name  = item_name
              corpse.surface.spill_item_stack(__spill_item_stack_param)
            end
          end
          --[[ --초기버전 테스트 용 - 미사용 - 죽은 자리에 빈 시체 남기기
          local new_corpse = corpse.surface.create_entity{
            name = corpse.name,
            position = corpse.position,
            direction = corpse.direction,
            inventory_size = 0,
            player_index = corpse.character_corpse_player_index,
          }
          new_corpse.character_corpse_death_cause = corpse.character_corpse_death_cause
          new_corpse.character_corpse_tick_of_death = corpse.character_corpse_tick_of_death
          --]]
          corpse.clear_items_inside()
        end
        corpse.destroy()
      end
    end
  end
end
--[[
Tank_loots.event_filters.on_post_entity_died = {defines.events.on_post_entity_died, {
  {
    filter = 'type',
    type = 'character',
    mode = 'or',
    invert = false
  },
}}
--]]

return Tank_loots