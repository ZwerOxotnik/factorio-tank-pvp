local Damaging = {}
Damaging.event_filters = {}

local Const = require('tankpvp.const')
local Balance = require('tankpvp.balance')

local DB = nil
--이하 local 변수는 연산시간을 최대한 줄여보려는...
local recover_capture_per_hit = Const.recover_capture_per_hit
local team_defines = Const.team_defines
local team_defines_key = Const.team_defines_key
local capture_radius = Const.capture_radius + 0.707 + 0.004

Damaging.on_load = function()
  DB = global.tankpvp_
end

local types = {
  ['car'] = true,
  ['locomotive'] = true,
  ['artillery-wagon'] = true,
  ['cargo-wagon'] = true,
  ['fluid-wagon'] = true,
  ['spider-vehicle'] = true,
}
Damaging.on_entity_damaged = function(event)
  if not event.entity.valid then return end
  if not event.cause then return end
  if not event.cause.valid then return end
  if not event.force then return end
  if not types[event.entity.type] then return end

  --팀전 승패 결정시 죽지않음
  if DB and event.entity.surface.index ~= 1 then
    if DB.team_game_win_state then
      event.entity.health = event.final_health + event.final_damage_amount
      return
    end
  end

  --데미지 보정
  event = Balance.modify_on_entity_damaged(event)

  local target = event.entity
  if target.force ~= event.cause.force then
    if types[event.cause.type] or event.cause.last_user then

      --딜러가 플레이어
      local dealer = nil
      if types[event.cause.type] then
        dealer = event.cause.get_driver()
        if dealer then
          if dealer.player then
            dealer = dealer.player
          elseif dealer.is_player() then
            dealer = dealer
          else
            dealer = event.cause.last_user
          end
        else
          dealer = event.cause.last_user
        end
      elseif event.cause.type == 'character' then
        dealer = event.cause.player
      else
        dealer = event.cause.last_user
      end

      --딜러 점수 계산
      if dealer and dealer.valid then
        if dealer.force ~= target.force then
          local PDB = DB.players_data[dealer.name]
          if dealer.surface.index == 1 then
            PDB.ffa_damage_dealt = PDB.ffa_damage_dealt + event.final_damage_amount
          else
            if dealer.force.name == team_defines[1].force or dealer.force.name == team_defines[2].force then
              if target.force.name == team_defines[1].force or target.force.name == team_defines[2].force then
                if DB.team_game_opened and DB.team_game_end_tick == nil then
                  PDB.tdm_damage_dealt = PDB.tdm_damage_dealt + event.final_damage_amount
                  if event.final_damage_amount > 0.3 then
                    local surface = game.surfaces[DB.team_game_opened]
                    if surface == target.surface then
                      local center = dealer.force.get_spawn_position(surface)
                      if math.sqrt((target.position.x - center.x)^2 + (target.position.y - center.y)^2) < capture_radius then
                        local index = team_defines_key[dealer.force.name].index
                        DB.team_game_capture_progress[index] = DB.team_game_capture_progress[index] - recover_capture_per_hit
                        PDB.tdm_recover = PDB.tdm_recover + recover_capture_per_hit * 100
                        if DB.team_game_capture_progress[index] < 0 then
                          DB.team_game_capture_progress[index] = 0
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      --박치기의 경우 : 모든 force가 friendly_fire=false이기 때문에 수동으로 반사피해 추가.
      if event.damage_type then
        if event.damage_type.name == 'impact' then
          --on_entity_damaged 이벤트가 무한 루프 도는 걸 방지
          if event.force.name ~= 'neutral' then
            if event.cause.prototype.max_health > 0
            and event.cause.can_be_destroyed()
            and event.cause.destructible then
              event.cause.damage(event.original_damage_amount, 'neutral', 'impact', event.entity)
              --damage force와 dealer force를 다르게 줄 수 있고 이걸로 루프 회피.
            end
          end
        end
      end
    end
  end
end
Damaging.event_filters.on_entity_damaged = {defines.events.on_entity_damaged, {
  {filter = 'type', type = 'car', mode = 'or', invert = false},
  {filter = 'type', type = 'locomotive', mode = 'or', invert = false},
  {filter = 'type', type = 'artillery-wagon', mode = 'or', invert = false},
  {filter = 'type', type = 'cargo-wagon', mode = 'or', invert = false},
  {filter = 'type', type = 'fluid-wagon', mode = 'or', invert = false},
  {filter = 'type', type = 'spider-leg', mode = 'or', invert = false},
  {filter = 'type', type = 'spider-vehicle', mode = 'or', invert = false}
}}

return Damaging


--[[
event.entity.name
event.damage_type.name
event.original_damage_amount
event.final_damage_amount
event.final_health
--]]