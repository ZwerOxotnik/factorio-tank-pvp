local Main = {}

local Event_filter = require('event_filter')
local event_filters = {}
local Terrain = require('tankpvp.terrain') --DB
local Game_var = require('tankpvp.game_var') --DB
local Tank_spawn = require('tankpvp.tank_spawn') --DB
local Prevent_action = require('tankpvp.prevent_action')
local Tank_loots = require('tankpvp.tank_loots') --DB
local Damaging = require('tankpvp.damaging') --DB
local Balance = require('tankpvp.balance')
local Chat = require('tankpvp.chat')
local Force = require('tankpvp.force')
local Gui = require('tankpvp.gui') --DB
local Const = require('tankpvp.const')
local Commands = require('tankpvp.commands') --DB
local Util = require('tankpvp.util')

local __DB = nil

--각 모듈의 on_load는 local DB 등록을 위한 것.
--순환참조하지 않도록 함수 배치에 주의.
--순환참조가 되면 게임 시작부터 안되므로 체크가 쉬움
Main.on_load = function()
  --이벤트 필터 정보 등록, 게임 저장 후 불러오기마다 실행
  for _, filter in pairs(event_filters) do
    Event_filter(filter[1], filter[2])
  end
  Game_var.on_load()
  __DB = storage.tankpvp_
  Terrain.on_load()
  Tank_spawn.on_load()
  Tank_loots.on_load()
  Damaging.on_load()
  Gui.on_load()
  Commands.on_load()
  --초기화. 게임 시작 시, 1회만 실행.
  if not __DB.initialized then
    Terrain.init()
    Prevent_action.permissions_init()
    Balance.init()
    __DB.initialized = true
  end
end

Main.on_init = function()
  Main.on_load()
end

--첫 player 세력은 모든 맵을 상시 차팅함
local on_nth_tick__f1_chart = function()
  local FR = Const.ffa_radius
  for k, surface in pairs(game.surfaces) do
    if k == 'nauvis' then
      game.forces[1].chart(surface, {{-FR, -FR}, {FR, FR}})
    else
      local w = surface.map_gen_settings.width
      local h = surface.map_gen_settings.height
      game.forces[1].chart(surface, {{-w/2-1, -h/2-1}, {w/2+1, h/2+1}})
    end
  end
end

local on_tick = function()
  local LCDB = __DB.loading_chunks
  Game_var.on_tick()
  if LCDB.is_loading then
    local t, f = 0, 0
    local w = false
    local surface = game.surfaces[LCDB.surface_name]
    for x = LCDB.lefttop.x, LCDB.rightbottom.x do
      for y = LCDB.lefttop.y, LCDB.rightbottom.y do
        w = surface.is_chunk_generated{x,y}
        if w then t = t + 1 else f = f + 1 end
      end
    end
    local percent = (t / (t + f))

    --nauvis가 아닌 경우(팀전 맵)
    if surface.index > 1 and surface.name ~= 'vault' then
      for _, player in pairs(game.connected_players) do
        Gui.loading_team_chunks(player, percent, LCDB.surface_name)
      end
      if percent >= 1 then

        local playername = nil
        local players = {}
        local teams = {[1]={}, [2]={}}
        local p = nil
        local force, spawn = nil, nil
        LCDB.is_loading = false
        __DB.team_game_opening = false

        --이 구문은 Game_var의 새 카운터를 시작시킨다.
        __DB.team_game_standby_time = Const.team_game_standby_time

        __DB.team_game_opened = LCDB.surface_name
        surface = game.surfaces[__DB.team_game_opened]
        local cliffs = surface.find_entities_filtered{type = 'cliff'}
        for _, cliff in pairs(cliffs) do cliff.destroy() end
        for _, player in pairs(game.connected_players) do
          playername = player.name
          if __DB.players_data[playername].queueing_for_team_game then
            __DB.players_data[playername].player_mode = Const.defines.player_mode.team
            Tank_spawn.despawn(player)
            Game_var.player_return_ffa_slot(playername)
            player.teleport({0,0}, surface)
            players[#players + 1] = playername
          end
        end
        if #players == 0 then
          game.delete_surface(surface)
          __DB.team_game_standby_time = nil
          __DB.team_game_opened = nil
          if __DB.reset_ffa_at_next_break then
            Game_var.store_online_vehicles_before_resetffa()
            Terrain.resetffa()
          end
          return
        end
        Force.set_team_spawn(surface)

        --무작위로 팀 채워넣기
        while #players > 0 do
          if math.random(0, 1) == 1 then
            p = math.random(1, #players)
            teams[1][#teams[1] + 1] = players[p]
            table.remove(players, p)
            if #players > 0 then
              p = math.random(1, #players)
              teams[2][#teams[2] + 1] = players[p]
              table.remove(players, p)
            end
          else
            p = math.random(1, #players)
            teams[2][#teams[2] + 1] = players[p]
            table.remove(players, p)
            if #players > 0 then
              p = math.random(1, #players)
              teams[1][#teams[1] + 1] = players[p]
              table.remove(players, p)
            end
          end
        end

        --팀 탱크 생성 및 차팅
        local width = surface.map_gen_settings.width
        local height = surface.map_gen_settings.height
        local area = {{-width/2-1,-height/2-1},{width/2+1,height/2+1}}
        local no_move = game.permissions.get_group('fc_standby')
        __DB.team_game_players = {[1]={},[2]={}}
        for i = 1, 2 do
          local player = nil
          local playername = nil
          local PDB = nil
          force = Const.team_defines[i].force
          --spawn = game.forces[force].get_spawn_position(surface)
          for ii = 1, #teams[i] do
            playername = teams[i][ii]
            PDB = __DB.players_data[playername]
            player = game.get_player(playername)
            player.force = force
            player.tag = '[[color='..Util.color2str(Const.team_defines_key[force].color)..']'..force..'[/color]]'
            player.print{"inform-team-chat-mode"}
            spawn = Terrain.get_team_spreaded_spawn(i, surface)
            player.teleport(spawn ,surface)
            Util.reenable_minimap(player)
            PDB.guis.tdm_frame.visible = true
            PDB.guis.tspec_ing_frame.visible = false
            PDB.guis.ffa_frame.visible = false
            PDB.guis.tcountdn_frame.visible = false
            PDB.guis.tspec_frame.visible = false
            Util.save_personal_color(player)
            PDB.tdm_kills = 0
            PDB.tdm_damage_dealt = 0
            PDB.tdm_capture = 0
            PDB.tdm_recover = 0
            player.color = Const.team_defines[i].color
            __DB.team_game_players[i][playername] = true
            Tank_spawn.spawn(player, 'tank')
            player.character.allow_dispatching_robots = false
            no_move.add_player(player) --이제 standby시간임. 시간동안 못움직이게 함.
          end
          game.forces[force].chart(surface, area)
        end
        game.forces[1].chart(surface, area)
        __DB.team_game_capture_progress = {[1]=0,[2]=0}
        Game_var.update_team_stat(1)

        --라운드 시간 계산
        local t1cnt, t2cnt = Tank_spawn.count_team_tanks()
        local roundtime = Const.team_roundtime_min + Const.team_roundtime_per*(t1cnt + t2cnt)
        if roundtime > Const.team_roundtime_max then roundtime = Const.team_roundtime_max end
        __DB.team_game_remain_time = roundtime
        __DB.team_game_remained_tanks[1] = t1cnt
        __DB.team_game_remained_tanks[2] = t2cnt
        __DB.team_game_capture_plus = {[1]=0,[2]=0}
        __DB.team_game_capture_minus = {[1]=0,[2]=0}
        __DB.team_game_capture_progress = {[1]=0,[2]=0}

        Gui.update_team_stat()

        --팀전하러 가고 남은 사람이 ffa대기중이면 ffa탱크생성
        while Force.find_no_one_connected() do
          local new_player_name = Game_var.pick_highest_prio_waiting_ffa()
          if new_player_name then
            Game_var.player_spawn_in_ffa(new_player_name)
          else
            break
          end
        end

        --맵 생성때문에 여기서 처리한게 많고 나머지 라운드 카운터 관련 game_var에서 처리
      
      end
    else --이하 nauvis인 경우.
      
      for _, player in pairs(game.connected_players) do
        Gui.loading_nauvis_chunks(player, percent)
      end
      if percent >= 1 then
        LCDB.is_loading = false
        __DB.last_ffa_reset = game.tick
        __DB.reset_ffa_at_next_break = false
        do
          local cliffs = surface.find_entities_filtered{type = 'cliff'}
          for _, cliff in pairs(cliffs) do cliff.destroy() end
          __DB.surface1_initialized = true
          Game_var.redraw_sizing_field()
          local mode = nil
          local playername = nil
          local player_index = nil
          for _, player in pairs(game.connected_players) do
            playername = player.name
            mode = __DB.players_data[playername].player_mode
            if mode == Const.defines.player_mode.normal then
              Game_var.player_return_ffa_slot(playername)
              if player.controller_type ~= defines.controllers.editor then
                Game_var.player_spawn_in_ffa(playername)
              end
            end
          end
          while Force.find_no_one_connected() do
            local new_player_name = Game_var.pick_highest_prio_waiting_ffa()
            if new_player_name then
              Game_var.player_spawn_in_ffa(new_player_name)
            else
              break
            end
          end
        end
      end
    end
  end
end

--플레이어 첫 입장시 초기화
local on_player_created = function(event)
  Game_var.on_player_created(event)
  Gui.on_player_created(event)
end

--플레이어 입장 시
local on_player_joined_game = function(event)
  local player = game.get_player(event.player_index)
  local playername = player.name
  local PDB = __DB.players_data[playername]
  local mode = PDB.player_mode
  player.clear_console()
  Prevent_action.disable_some_game_view_settings(player)
  __DB.zoom_world_queue[playername] = nil
  player.spectator = false
  if mode == Const.defines.player_mode.team and player.surface.index > 1 and player.surface.name ~= 'vault' then
    local force = Util.get_player_team_force(playername)
    if force == 'player' then
      Game_var.remove_character(player.index)
      PDB.player_mode = Const.defines.player_mode.ffa_spectator
      mode = Const.defines.player_mode.ffa_spectator
    else
      player.color = Const.team_defines_key[force].color
      player.tag = '[[color='..Util.color2str(Const.team_defines_key[force].color)..']'..force..'[/color]]'
      player.print{"inform-team-chat-mode"}
      if not player.vehicle then
        Game_var.remember_position_to_mapview(playername)
        PDB.player_mode = Const.defines.player_mode.team_spectator
        player.print{"lost_tank_offline_on_team"}
        Game_var.remove_character(playername)
        Game_var.move_to_outofring(playername)
        Util.disable_minimap(player)
      else
        Util.reenable_minimap(player)
      end
      player.force = force
    end
  end
  Game_var.remove_offline_player_from_ffa_queue()
  Game_var.redraw_sizing_field()
  if player.surface.index == 1
    or mode == Const.defines.player_mode.ffa_spectator
    or mode == Const.defines.player_mode.team_spectator
    or mode == Const.defines.player_mode.whole_team_spectator
    then
    Util.disable_minimap(player)
    player.teleport({0,0}, game.surfaces[1])
    player.force = 'player'
    player.tag = ''
    player.print{"inform-all-chat-mode"}
    Game_var.player_start_to_wait_ffa(playername)
    PDB.last_tick_start_queue_for_ffa = game.tick
    if __DB.surface1_initialized then
      Game_var.player_spawn_in_ffa(playername)
    end
    player.color = Util.get_personal_color(player)
  end
  Gui.on_player_joined_game(event)
  if __DB.stat_last_map_name then
    PDB.guis.stat_view_btn.visible = true
  else
    PDB.guis.stat_view_btn.visible = false
  end
end

--부활한 경우
local on_player_respawned = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local playername = player.name
  --mode는 부활 전에 어딘가에서 설정됨. 예) 죽었을 경우 등
  local mode = __DB.players_data[playername].player_mode
  if mode == Const.defines.player_mode.normal then
    Tank_spawn.spawn(player, 'tank') --리스폰은 player_spawn_in_ffa을 사용안함
    player.create_local_flying_text({
      position = player.position,
      text  = '[font=default-game]TANK IS READY[img=item/tank][/font]',
      color = {1, 1, 0, 1},
    })
    player.play_sound{path = 'utility/new_objective', volume_modifier = 1}
    --for _, other in pairs(game.connected_players) do
    --  if other.surface.index == 1 then
    --    if other.force ~= player.force and other.force.index ~= 1 and player.force ~= 1 then
    --      other.print{"multiplayer.player-respawn", playername}
    --    end
    --  end
    --end
  --관전자로 부활.
  elseif mode == Const.defines.player_mode.ffa_spectator
    or mode == Const.defines.player_mode.team_spectator
    or mode == Const.defines.player_mode.whole_team_spectator
    then
    game.permissions.get_group('ffa_spec').add_player(player)
    Game_var.remove_character(playername)
    if mode == Const.defines.player_mode.team_spectator then
      Util.disable_minimap(player)
      player.force = Util.get_player_team_force(playername)
      player.color = Util.get_personal_color(player)
    end
    Game_var.move_to_outofring(playername)
  end
end

--사망한 경우
local on_player_died = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end 
  local corpses = player.surface.find_entities_filtered{position = player.position, radius = 0.1,name = 'character-corpse'}
  Tank_loots.on_post_entity_died{corpses = corpses} --이벤트에 등록해서 쓰다가 버그가 있어서 빼고 그냥 여기다 씀
  local playername = player.name
  local PDB = __DB.players_data[playername]
  mode = PDB.player_mode
  --FFA에서 사망
  if mode == Const.defines.player_mode.normal then
    local return_slot = Game_var.player_dead_and_is_have_to_return_slot(playername)
    local spawn = {}
    if return_slot then
      local remains = player.surface.find_entities_filtered{force = player.force}
      for _, r in pairs(remains) do r.force = 'enemy' end
      Game_var.remember_position_to_mapview(playername)
      Game_var.player_return_ffa_slot(playername)
      local new_player_name = Game_var.pick_highest_prio_waiting_ffa()
      if new_player_name then
        Game_var.player_spawn_in_ffa(new_player_name)
      end
      player.print{"returning_ffa_slot"}
      player.ticks_to_respawn = Const.respawn_time
    else
      spawn = Terrain.get_ffa_spawn()
      player.force.set_spawn_position(spawn, game.surfaces[1])
      player.ticks_to_respawn = Const.respawn_time
    end
    if event.cause and event.cause.valid then
      local causename = nil
      if not event.cause.is_player() and event.cause.type == 'character' then
        if event.cause.player then
          causename = event.cause.player.name
        else
          causename = event.cause.localised_name
        end
      else
        causename = event.cause.localised_name
      end
      for _, other in pairs(game.connected_players) do
        if other.surface.index == 1 then
          if other.force ~= event.cause.force and event.cause.force ~= player.force and other.force ~= player.force and other.force.index ~= 1 and player.force ~= 1 then
            other.print({"multiplayer.player-died-by", playername, causename},{1,0.85,0.6,1})
          end
        end
      end
    else
      for _, other in pairs(game.connected_players) do
        if other.surface.index == 1 then
          if other.force ~= player.force and other.force.index ~= 1 and player.force ~= 1 then
            other.print({"multiplayer.player-died", playername},{1,0.85,0.6,1})
          end
        end
      end
    end
  --팀 전에서 사망
  elseif mode == Const.defines.player_mode.team then
    Game_var.remember_position_to_mapview(playername)
    PDB.player_mode = Const.defines.player_mode.team_spectator
    player.print{"die_on_team"}
    player.ticks_to_respawn = Const.respawn_time
  end
  --Gui 닫음 --spectator로 전환시 닫히는 gui는 on_gui_closed를 발생시키지 않는 문제
  if PDB.guis.tdmstat_frame.visible then
    PDB.guis.tdmstat_frame.visible = false
    player.opened = nil
  end
end

-- 운영자가 /editor 커맨드를 사용한 경우
local on_pre_player_toggled_map_editor = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local playername = player.name
  if player.controller_type ~= defines.controllers.editor then
    player.spectator = false
    if player.surface.index == 1 then
      Tank_spawn.despawn(player)
      Util.save_personal_color(player)
    elseif player.surface.name == 'vault' then
    elseif player.vehicle then
      Util.save_quick_bar(player, player.vehicle.name)
      player.vehicle.set_driver(nil)
      Util.disable_minimap(player)
    end
    player.clear_items_inside()
    player.force = 'player'
    Game_var.player_left(playername)
    game.permissions.get_group(0).add_player(playername)
    local mode = __DB.players_data[playername].player_mode
    if mode == Const.defines.player_mode.normal then
      if not __DB.loading_chunks.is_loading then
        local new_player_name = Game_var.pick_highest_prio_waiting_ffa()
        if new_player_name then
          Game_var.player_spawn_in_ffa(new_player_name)
        end
      end
    end
  end
end

local on_player_toggled_map_editor = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local playername = player.name
  if player.controller_type ~= defines.controllers.editor then
    if player.surface.index == 1 then
      Game_var.player_spawn_in_ffa(playername, true)
    elseif player.surface.name == 'vault' then
    else
      player.color = Util.get_personal_color(player)
      __DB.players_data[playername].player_mode = Const.defines.player_mode.whole_team_spectator
      Game_var.remove_character(playername)
      Game_var.remember_position_to_mapview(playername)
      Game_var.move_to_outofring(playername)
    end
  end
end

-- 플레이어를 삭제한 경우. (/admin 등을 이용해서)
local on_player_removed = function(event)
  local playername = __DB.players_index[event.player_index]
  Game_var.remove_player_from_ffa_queue(playername)
  Game_var.remove_player_from_DB(playername)
  log('\n'..string.format("%.3f",game.tick/60)..' [MANUAL-PLAYER-REMOVE] = '..playername)
end

-- 플레이어가 나간 경우
local on_pre_player_left_game = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local playername = player.name
  local mode = __DB.players_data[playername].player_mode
  Game_var.player_left(playername)
  if mode == Const.defines.player_mode.team_spectator or mode == Const.defines.player_mode.team then
    --nothing
  elseif mode == Const.defines.player_mode.normal then
    player.force = 'player'
    Tank_spawn.despawn(player)
    if not __DB.loading_chunks.is_loading then
      local new_player_name = Game_var.pick_highest_prio_waiting_ffa()
      if new_player_name then
        Game_var.player_spawn_in_ffa(new_player_name)
      end
    end
    Util.save_personal_color(player)
  else
    Util.save_personal_color(player)
  end
  Game_var.redraw_sizing_field()
end

local on_player_kicked = function(event)
  on_pre_player_left_game(event)
end

local on_player_banned = function(event)
  on_pre_player_left_game(event)
end

-- sub lua에서 받은걸 전달만 하는 이벤트
local on_surface_cleared = function(event)
  Terrain.on_surface_cleared(event)
end

local on_chunk_generated = function(event)
  Terrain.on_chunk_generated(event)
end

local on_player_cursor_stack_changed = function(event)
  Prevent_action.on_player_cursor_stack_changed(event)
end

local on_gui_opened = function(event)
  Prevent_action.on_gui_opened(event)
end

local on_player_driving_changed_state = function(event)
  Prevent_action.on_player_driving_changed_state(event)
end

local on_entity_died = function(event)
  if event.entity.name == 'sand-rock-big'
    or event.entity.name == 'rock-huge'
    or event.entity.name == 'rock-big'
    then
    event.entity.destroy()
    return
  end
  Tank_loots.on_entity_died(event)
end

--[[ 미사용
local on_post_entity_died = function(event)
  Tank_loots.on_post_entity_died(event)
end
event_filters[#event_filters + 1] = Tank_loots.event_filters.on_post_entity_died
--]]

local on_console_chat = function(event)
  Chat.on_console_chat(event)
end

local on_console_command = function(event)
  Prevent_action.on_console_command(event)
end

local on_built_entity = function(event)
  Prevent_action.on_built_entity(event)
  Tank_spawn.on_built_entity(event)
end

local on_entity_damaged = function(event)
  Damaging.on_entity_damaged(event)
  Balance.on_entity_damaged(event)
end
do
  local merged_filter = {defines.events.on_entity_damaged, {}}
  for _, v in pairs(Damaging.event_filters.on_entity_damaged[2]) do table.insert(merged_filter[2], v) end
  for _, v in pairs(Balance.event_filters.on_entity_damaged[2]) do table.insert(merged_filter[2], v) end
  event_filters[#event_filters + 1] = merged_filter
end

local on_gui_checked_state_changed = function(event)
  Gui.on_gui_checked_state_changed(event)
end

local on_gui_click = function(event)
  Gui.on_gui_click(event)
end

local on_gui_closed = function(event)
  Gui.on_gui_closed(event)
end

----------------

Main.on_nth_tick =
{
  [Const.fuel_refill_invertal] = Tank_spawn.periodic_fuel_refill_ffa,
  [Const.on_18000_tick_interval] = Game_var.on_18000_tick,
  [Const.supply_drop_interval] = Balance.on_1200_tick_drop_supply_ffa,
  [180] = on_nth_tick__f1_chart,
  [60] = Game_var.on_60_tick,
  [29] = Gui.on_29_tick,
  [31] = Gui.on_31_tick,
  [32] = function() Game_var.on_32_tick() Gui.on_32_tick() end,
  [10] = Game_var.on_10_tick,
  [6] = Gui.on_6_tick,
}
Main.events =
{
  [defines.events.on_tick] = on_tick,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_died]    = on_player_died,
  [defines.events.on_player_joined_game] = on_player_joined_game,
  [defines.events.on_player_respawned] = on_player_respawned,

  -- 운영자가 /editor 커맨드를 사용한 경우
  [defines.events.on_pre_player_toggled_map_editor] = on_pre_player_toggled_map_editor,
  [defines.events.on_player_toggled_map_editor] = on_player_toggled_map_editor,

  -- 플레이어를 삭제한 경우
  [defines.events.on_player_removed] = on_player_removed,

  -- 플레이어가 나간 경우
  [defines.events.on_pre_player_left_game] = on_pre_player_left_game,
  [defines.events.on_player_kicked] = on_player_kicked,
  [defines.events.on_player_banned] = on_player_banned,

  -- sub lua에서 받은걸 전달만 하는 이벤트
  [defines.events.on_surface_cleared] = on_surface_cleared,
  [defines.events.on_chunk_generated] = on_chunk_generated,
  [defines.events.on_player_cursor_stack_changed] = on_player_cursor_stack_changed,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_player_driving_changed_state] = on_player_driving_changed_state,
  [defines.events.on_entity_died] = on_entity_died,
  --[defines.events.on_post_entity_died] = on_post_entity_died,
  [defines.events.on_console_chat] = on_console_chat,
  [defines.events.on_console_command] = on_console_command,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_entity_damaged] = on_entity_damaged,
  [defines.events.on_gui_checked_state_changed] = on_gui_checked_state_changed,
  [defines.events.on_gui_click]  = on_gui_click,
  [defines.events.on_gui_closed] = on_gui_closed,
}

return Main