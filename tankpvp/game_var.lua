local Game_var = {}

local Force = require('tankpvp.force')
local Terrain = require('tankpvp.terrain')
local Const = require('tankpvp.const')
local Tank_spawn = require('tankpvp.tank_spawn')
local Util = require('tankpvp.util')

local __DB = nil

Game_var.on_load = function()
  if not storage.tankpvp_ then
    Game_var.init()
  end
  __DB = storage.tankpvp_
  Terrain.on_load()
  Tank_spawn.on_load()
end

Game_var.init = function()
  storage.tankpvp_ = {
    initialized = false,
    --job_to_start_next_tick = nil, --아래 next_tick이 왔을 때 실행할 작업
    team_game_history_count = 0, --열렸던 팀 게임 횟수
    team_game_opened = nil, --열린 팀 게임 이름
    team_game_opening = false, --팀 게임 열리는 중?
    team_game_win_state = nil, --팀 게임 승패
    team_game_end_tick = nil, --팀 게임 종료 틱
    team_game_queue_count = 0, --대기중인 사람 수
    team_game_playing_count = 0, --팀 게임 플레이중인 사람 수
    team_game_countup = 0, --팀 게임용 카운터
    team_game_countdown_time = nil, --팀 게임 시작하려고 카운트 세는 중이면 숫자, 아니면 nil
    team_game_remain_time = nil, --팀 게임 남은 시간 세는 중이면 숫자, 아니면 nil
    team_game_standby_time = nil, --팀 게임 시작 대기시간 있으면 숫자, 아니면 nil
    team_game_players = {[1]={},[2]={}}, --팀 게임 참가자 명단
    team_game_wall_pos = {[1]={},[2]={}}, --점령지역 기본 벽 위치
    team_game_remained_tanks = {[1]=0,[2]=0}, --남은 팀 탱크
    team_game_capture_plus = {[1]=0,[2]=0}, --점령증가속도 /초
    team_game_capture_minus = {[1]=0,[2]=0}, --점령감소속도 /초
    team_game_capture_progress = {[1]=0,[2]=0}, --점령상태 0~1
    team_game_queue_force_to_close_game = false, --팀 게임 강제종료
    ffa_queue = {}, --ffa 사람많을 때 큐
    players_data = {}, --플레이어 데이터베이스
    players_index = {}, --플레이어 데이터베이스_인덱스로 이름을 찾기(on_player_removed 용)
    loading_chunks = { --청크 로딩중?
      surface_name = nil,
      lefttop = {x=nil,y=nil},
      rightbottom = {x=nil,y=nil},
      is_loading = false,
    },
    zoom_world_queue = {},
    stat_last_map_name = nil,
    stat_last_win = 'draw',
    stat_last_win_reason = {},
    stat_last_playtime = 0,
    stat_won_players = {},
    stat_lost_players = {},
    stat_won_color = {},
    stat_lost_color = {},
    stat_won_team_name = nil,
    stat_lost_team_name = nil,
    order_damage_stat_won_players = {},
    order_damage_stat_lost_players = {},
    order_capture_stat_won_players = {},
    order_capture_stat_lost_players = {},
    last_connected_players = 0, --Game_var.damage_out_of_field 에서 갱신함
    field_radius = Const.ffa_max_fieldr, --Game_var.redraw_sizing_field 에서 갱신함
    last_ffa_reset = 0,
    reset_ffa_at_next_break = false,
    prototypes = {},
  }
  local register_prototype = function(name)
    storage.tankpvp_.prototypes[name] = prototypes.entity[name]
  end
  register_prototype('car')
  register_prototype('tank')
  register_prototype('spidertron')
end

Game_var.on_player_created = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  local playername = player.name
  __DB.players_index[event.player_index] = playername
  __DB.players_data[playername] = {
    current_team_game = nil, --참가한 팀 게임 번호
    personal_color = {0,0,0,0}, --ffa 색상
    queueing_for_team_game = true, --team게임 참가희망여부
    player_mode = Const.defines.player_mode.ffa_spectator, --플레이어 모드
    last_tick_start_queue_for_ffa = game.tick, --ffa에 참가하려고 기다리기 시작한 틱
    mapview_position = {0, 0}, --지도보기 예약위치(관전으로 부활시 사용)
    mapview_surface_name = nil, --지도보기 예약지면(관전으로 부활시 사용)
    outofring_reserved = false, --텔레포트 예약됨?(관전으로 부활시 사용)
    guis = {}, --GUI elements 목록
    ffa_kills = 0, --개인전 킬 수
    ffa_deaths = 0, --개인전 사망 수
    ffa_damage_dealt = 0, --개인전 딜량
    tdm_kills = 0, --팀데스매치 킬 수
    tdm_damage_dealt = 0, --팀데스매치 데미지 딜량
    tdm_capture = 0, --팀데스매치 점령점수
    tdm_recover = 0, --팀데스매치 수비점수
    quick_bars = {}, --엔티티 네임 별 퀵바. ['tank'] 등
  }
  Util.save_personal_color(player)
end

--플레이어의 캐릭터 삭제하고 관전상태로 변경
Game_var.remove_character = function(pname_or_index)
  local player = game.get_player(pname_or_index)
  player.force = 'player'
  local character = player.character
  if character then
    player.character = nil
    Util.ch_destroy(character)
  end
  Util.set_control_spect(player)
end

--플레이어 스폰
Game_var.player_spawn_in_ffa = function(playername, fixed_spawn) --리스폰이 아님
  local player = game.get_player(playername)
  local force, forcei = Force.pick_no_one_connected()
  local spawn = {}
  player.force = force
  if forcei > 5 then
    local FR = Const.ffa_radius
    Game_var.remove_player_from_ffa_queue(playername)
    __DB.players_data[playername].player_mode = Const.defines.player_mode.normal
    if not fixed_spawn then
      spawn = Terrain.get_ffa_spawn()
      player.force.set_spawn_position(spawn, game.surfaces[1])
      player.teleport(spawn, game.surfaces[1])
    end
    local vehicle = Tank_spawn.spawn(player, nil)
    local vehicleimg = ''
    local vehiclename = '?'
    if vehicle then
      vehiclename = vehicle.localised_name
      vehicleimg = '[img=item/'..vehicle.name..']'
    end
    player.create_local_flying_text({
      position = player.position,
      text  = {"",'[font=default-game]',vehiclename,' READY',vehicleimg,'[/font]'},
      color = {1, 1, 0, 1},
    })
    player.play_sound{path = 'utility/new_objective', volume_modifier = 1}
    player.force.chart(game.surfaces[1], {{-FR, -FR}, {FR, FR}})
  elseif forcei == 1 then
    Game_var.player_start_to_wait_ffa(playername)
    player.print{"returning_ffa_slot"}
  end
end

--FFA 대기 시작하기
Game_var.player_start_to_wait_ffa = function(playername)
  local found_in_queue = false
  for i = 1, #__DB.ffa_queue do
    if __DB.ffa_queue[i] == playername then
      found_in_queue = true
      break
    end
  end
  __DB.players_data[playername].player_mode = Const.defines.player_mode.ffa_spectator
  if not found_in_queue then
    __DB.players_data[playername].last_tick_start_queue_for_ffa = game.tick
    __DB.ffa_queue[#__DB.ffa_queue + 1] = playername
  end
  Game_var.remove_character(playername)
  if not game.get_player(playername).spectator
    and not __DB.players_data[playername].outofring_reserved
    then --spectator는 이미 맵뷰 상태인지 체크하는 용도.
    Game_var.remember_position_to_mapview(playername)
    Game_var.move_to_outofring(playername)
  end
end

--ffa큐에서 플레이어 삭제
Game_var.remove_player_from_ffa_queue = function(playername)
  for i, name in ipairs(__DB.ffa_queue) do
    if name == playername then
      table.remove(__DB.ffa_queue, i)
      break
    end
  end
end

--ffa큐에서 오프라인 플레이어 삭제
Game_var.remove_offline_player_from_ffa_queue = function()
  local removed = true
  local count = 0
  while removed do
    removed = false
    for i, name in ipairs(__DB.ffa_queue) do
      local player = game.get_player(name)
      if player and player.valid then
        if not player.connected then
          table.remove(__DB.ffa_queue, i)
          removed = true
          count = count + 1
          break
        end
      else
        table.remove(__DB.ffa_queue, i)
        removed = true
        count = count + 1
        break
      end
    end
  end
end

--ffa큐에서 가장 오래 기다린 플레이어 추출
Game_var.pick_highest_prio_waiting_ffa = function()
  if #__DB.ffa_queue > 0 then
    local oldest_tick, oldest_name, chosen_i = -1, 0, 0
    local dupl_name = {}
    local dupl_i = {}
    local rand = nil
    for i, name in ipairs(__DB.ffa_queue) do
      local player = game.get_player(name)
      if not player.connected or player.controller_type == defines.controllers.editor then
        --nothing
      elseif oldest_tick < 0 then
        oldest_tick = __DB.players_data[name].last_tick_start_queue_for_ffa
        oldest_name = name
        chosen_i = i
      elseif oldest_tick > __DB.players_data[name].last_tick_start_queue_for_ffa then
        oldest_tick = __DB.players_data[name].last_tick_start_queue_for_ffa
        oldest_name = name
        chosen_i = i
      end
    end
    for i, name in ipairs(__DB.ffa_queue) do
      local player = game.get_player(name)
      if not player.connected or player.controller_type == defines.controllers.editor then
        --nothing
      elseif oldest_tick == __DB.players_data[name].last_tick_start_queue_for_ffa then
        dupl_name[#dupl_name + 1] = name
        dupl_i[#dupl_i + 1] = i
      end
    end
    rand = math.random(1, #dupl_i)
    oldest_name = dupl_name[rand]
    chosen_i = dupl_i[rand]
    table.remove(__DB.ffa_queue, chosen_i)
    return oldest_name --playername
  else
    return nil
  end
end

--Main의 on_player_left_game에서 호출하고, 여기저기서 초기화할 때 씀
Game_var.player_left = function(playername)
  local PDB = __DB.players_data[playername]
  if PDB.player_mode == Const.defines.player_mode.ffa_spectator then
    Game_var.remove_player_from_ffa_queue(playername)
  end
  PDB.outofring_reserved = false
end

--플레이어가 죽었을 때 ffa슬롯을 반납해야하는가?
Game_var.player_dead_and_is_have_to_return_slot = function(playername)
  local PDB = __DB.players_data[playername]
  if PDB.player_mode == Const.defines.player_mode.normal then
    if #__DB.ffa_queue > 0 then
      return true
    else
      return false
    end
  else
    return false
  end
end

--플레이어는 ffa슬롯을 반납한다
Game_var.player_return_ffa_slot = function(playername)
  local PM = Const.defines.player_mode
  local mode = __DB.players_data[playername].player_mode
  if mode == PM.normal or mode == PM.ffa_spectator then
    Game_var.player_start_to_wait_ffa(playername)
  elseif mode == PM.team then
    Game_var.remove_player_from_ffa_queue(playername)
    Game_var.remove_character(playername)
  elseif mode == PM.team_spectator then
    Game_var.remove_player_from_ffa_queue(playername)
    Game_var.remove_character(playername)
  elseif mode == PM.whole_team_spectator then
    Game_var.remove_player_from_ffa_queue(playername)
    Game_var.remove_character(playername)
  end
end

--장외로 보낼 때 사용.
Game_var.remember_position_to_mapview = function(playername)
  local PDB = __DB.players_data[playername]
  local player = game.get_player(playername)
  PDB.mapview_position = player.position
  PDB.mapview_surface_name = player.surface.name
  PDB.outofring_reserved = true
end

--장외로 보내기 취소
Game_var.cancel_move_to_outofring = function(playername)
  local PDB = __DB.players_data[playername]
  PDB.outofring_reserved = false
end

--zoom_to_world queue bug fix(함수 그냥 쓰면 큐를 안잡고 안되면 걍 안함)
Game_var.queue_zoom_to_world = function(playername, position, zoom)
  __DB.zoom_world_queue[playername] = {position = position, zoom = zoom}
end

--장외 위치 얻기
local get_outofring_position = function(top_pos)
  local lefttop = {x=top_pos.x-top_pos.x%32,y=top_pos.y-top_pos.y%32}
  return {x=lefttop.x + math.random()*32, y=lefttop.y -2*lefttop.y*math.random()}
end

--장외로 보낼 때 사용. 이전에 관전자로 만드는 기능 : Game_var.remember_position_to_mapview 설정 필요.
Game_var.move_to_outofring = function(playername)
  local PDB = __DB.players_data[playername]
  if PDB.outofring_reserved then
    local player = game.get_player(playername)
    local surface_name = PDB.mapview_surface_name
    local surface = game.surfaces[surface_name]
    if surface then
      local position = get_outofring_position{x=surface.map_gen_settings.width/2 + 96, y=-surface.map_gen_settings.height/2}
      player.teleport(position, surface)
      player.spectator = true
      Game_var.queue_zoom_to_world(playername, PDB.mapview_position, 0.2)
    end
    
    PDB.outofring_reserved = false
    local mode = PDB.player_mode
    if mode == Const.defines.player_mode.ffa_spectator
      or mode == Const.defines.player_mode.whole_team_spectator
      then
      game.permissions.get_group('ffa_spec').add_player(player)
    elseif mode == Const.defines.player_mode.team_spectator then
      --game.permissions.get_group('fc_standby').add_player(player) --색못바꾸는거 취소
      game.permissions.get_group('ffa_spec').add_player(player) --색바꿀수있게함
    end
  end
end

--팀데스매치 인원모집 대기열 카운트
Game_var.update_tqueue_count = function()
  local sum = 0
  for _, player in pairs(game.connected_players) do
    if __DB.players_data[player.name].queueing_for_team_game and player.surface.index == 1 then
      sum = sum + 1
    end
  end
  __DB.team_game_queue_count = sum
  if sum >= Const.min_people_tdm
    and __DB.team_game_standby_time == nil
    and __DB.team_game_remain_time == nil
    and __DB.team_game_end_tick == nil
    then
    __DB.team_game_countdown_time = Const.team_start_cntdn_max - (sum - Const.min_people_tdm) * Const.team_start_cntdn_per
    if __DB.team_game_countdown_time < Const.team_start_cntdn_min then
      __DB.team_game_countdown_time = Const.team_start_cntdn_min
    end
  else
    __DB.team_game_countdown_time = nil
  end
end

local __set_controller_param = {
  type = defines.controllers.remote,
  start_zoom = 1,
  position = nil,
  surface = nil
}
--주로 카운트다운 용도
Game_var.on_tick = function()
  for name, data in pairs(__DB.zoom_world_queue) do
    local player = game.get_player(name)
    __set_controller_param.start_zoom = data.zoom
    __set_controller_param.position   = data.position
    __set_controller_param.surface    = player.surface
    player.set_controller(__set_controller_param)
    if player.render_mode ~= defines.render_mode.game then
      __DB.zoom_world_queue[name] = nil
    end
  end

  if __DB.team_game_opening or __DB.loading_chunks.is_loading then return end

  --팀맵 생성 후 시작전까지 카운트
  if __DB.team_game_standby_time ~= nil then
    if __DB.team_game_countup >= __DB.team_game_standby_time then
      local surface = game.surfaces[__DB.team_game_opened]
      __DB.team_game_countup = __DB.team_game_countup - __DB.team_game_standby_time
      __DB.team_game_standby_time = nil
      local fc = game.permissions.get_group('fix_color')
      for i = 1, 2 do
        for player, _ in pairs(__DB.team_game_players[i]) do
          fc.add_player(player)
          player = game.get_player(player)
          if player.connected then
            player.create_local_flying_text({
              position = player.position,
              text  = '[font=default-game]GO![img=item/tank][/font]',
              color = {1, 1, 0, 1},
            })
          end
        end
      end
      surface.play_sound{path = 'utility/new_objective', volume_modifier = 1}
    elseif __DB.team_game_countup%60 == 0 then
      local surface = game.surfaces[__DB.team_game_opened]
      local timer = tostring(math.floor((__DB.team_game_standby_time - __DB.team_game_countup) / 60))
      timer = '[font=default-game]'..timer..'[/font]'
      for i = 1, 2 do
        for player, _ in pairs(__DB.team_game_players[i]) do
          player = game.get_player(player)
          if player.connected then
            player.create_local_flying_text({
              position = player.position,
              text  = timer,
              color = {0.5, 1, 1, 1},
            })
          end
        end
      end
      surface.play_sound{path = 'utility/inventory_move', volume_modifier = 1}
    end
    __DB.team_game_countup = __DB.team_game_countup + 1

  --팀맵 진행 중 카운트
  elseif __DB.team_game_remain_time ~= nil then
    __DB.team_game_countup = __DB.team_game_countup + 1

  --팀맵 생성 전까지 카운트
  elseif __DB.team_game_countdown_time ~= nil then
    __DB.team_game_countup = __DB.team_game_countup + 1
    if __DB.team_game_countup > __DB.team_game_countdown_time then
      __DB.team_game_opening = true
      __DB.team_game_countup = 0
      Terrain.generate_team_map(__DB.team_game_queue_count)
    end

  else
    __DB.team_game_countup = 0
  end
end

--팀 상황 업데이트
Game_var.update_team_stat = function(refresh_interval_tick)
  if __DB.team_game_opened == nil then return end

  --팀전 종료 시
  if __DB.team_game_win_state ~= nil then
    if game.tick > __DB.team_game_end_tick then
      __DB.team_game_queue_force_to_close_game = false
      __DB.team_game_countdown_time = nil
      __DB.team_game_remain_time = nil
      __DB.team_game_standby_time = nil
      local surface = game.surfaces[__DB.team_game_opened]
      local playername = nil
      local returning_players = {}
      local gametick = game.tick
      for _, player in pairs(game.connected_players) do
        playername = player.name
        if player.surface.name == __DB.team_game_opened then
          __DB.zoom_world_queue[playername] = nil
          Util.disable_minimap(player)
          player.teleport({0,0}, game.surfaces[1])
          player.spectator = false
          __DB.players_data[playername].player_mode = Const.defines.player_mode.ffa_spectator
          Game_var.player_left(playername)
          player.force = 'player'
          player.tag = ''
          player.print{"inform-all-chat-mode"}
          game.permissions.get_group(0).add_player(player)
          player.color = Util.get_personal_color(player)
          if player.controller_type ~= defines.controllers.editor then
            Game_var.player_start_to_wait_ffa(playername)
            __DB.players_data[playername].last_tick_start_queue_for_ffa = gametick
            returning_players[playername] = player
          end
          __DB.players_data[playername].guis.tdm_frame.visible = false
          __DB.players_data[playername].guis.tspec_ing_frame.visible = false
          __DB.players_data[playername].guis.ffa_frame.visible = true
          __DB.players_data[playername].guis.tcountdn_frame.visible = false
        end
        __DB.players_data[playername].guis.tspec_frame.visible = false
      end
      game.delete_surface(__DB.team_game_opened)
      __DB.team_game_opened = nil
      __DB.team_game_win_state = nil
      __DB.team_game_end_tick = nil
      while Force.find_no_one_connected() do
        local new_player_name = Game_var.pick_highest_prio_waiting_ffa()
        if new_player_name then
          Game_var.player_spawn_in_ffa(new_player_name)
        else
          break
        end
      end
      if __DB.reset_ffa_at_next_break then
        Game_var.store_online_vehicles_before_resetffa()
        Terrain.resetffa()
      end
    end
    return
  end

  --남은 탱크 수 업데이트
  __DB.team_game_remained_tanks[1], __DB.team_game_remained_tanks[2] = Tank_spawn.count_team_tanks()

  --점령 상태 업데이트
  local surface = game.surfaces[__DB.team_game_opened]
  if surface then
    local win_state = nil
    local force = {game.forces[Const.team_defines[1].force], game.forces[Const.team_defines[2].force]}
    local CR = Const.capture_radius + 0.707
    local capture_speed = {[1]=0,[2]=0}
    --점령증가속도 인원
    local capture_plus = {
      [1] = surface.find_entities_filtered{
        position = force[1].get_spawn_position(surface),
        radius = CR,
        type = {'car', 'spider-vehicle', 'locomotive'},
        force = force[2]
      },
      [2] = surface.find_entities_filtered{
        position = force[2].get_spawn_position(surface),
        radius = CR,
        type = {'car', 'spider-vehicle', 'locomotive'},
        force = force[1]
      },
    }
    --점령감소속도 인원
    local capture_minus = {
      [1] = surface.find_entities_filtered{
        position = force[1].get_spawn_position(surface),
        radius = CR,
        type = {'car', 'spider-vehicle', 'locomotive'},
        force = force[1]
      },
      [2] = surface.find_entities_filtered{
        position = force[2].get_spawn_position(surface),
        radius = CR,
        type = {'car', 'spider-vehicle', 'locomotive'},
        force = force[2]
      },
    }
    local cp = {[1]=0,[2]=0}
    local cm = {[1]=0,[2]=0}
    for i = 1, 2 do for _ in pairs(capture_plus[i]) do cp[i] = cp[i] + 1 end end
    for i = 1, 2 do for _ in pairs(capture_minus[i]) do cm[i] = cm[i] + 1 end end
    __DB.team_game_capture_plus = {[1]=cp[1],[2]=cp[2]}
    __DB.team_game_capture_minus = {[1]=cm[1],[2]=cm[2]}
    local CL = Const.capture_limit
    if cp[1] > CL then cp[1] = CL end
    if cp[2] > CL then cp[2] = CL end
    if cm[1] > CL then cm[1] = CL end
    if cm[2] > CL then cm[2] = CL end

    --점령상태 value = 0~1
    local vers = 0
    for i = 1, 2 do
      capture_speed[i] = Const.capture_speed / 6000 * refresh_interval_tick * (cp[i] - cm[i])
    end
    for i = 1, 2 do
      if __DB.team_game_capture_progress[i] + capture_speed[i] > 1 then
        --capture_speed[i] = 1 - DB.team_game_capture_progress[i]
        __DB.team_game_capture_progress[i] = 1
      elseif __DB.team_game_capture_progress[i] + capture_speed[i] < 0 then
        --capture_speed[i] = 0 - DB.team_game_capture_progress[i]
        __DB.team_game_capture_progress[i] = 0
      else
        __DB.team_game_capture_progress[i] = __DB.team_game_capture_progress[i] + capture_speed[i]
      end
    end
    local speaker = {}
    for i = 1, 2 do
      speaker = surface.find_entities_filtered{position = {1000000, -1000000}, radius = 2, force = force[i]}
      if capture_speed[i] > 0 and #speaker == 0 then
        local e = {}
        e[1] = surface.create_entity{name = 'programmable-speaker', position = {1000000, -1000000}, force = force[i]}
        e[2] = surface.create_entity{name = 'hidden-electric-energy-interface', position = e[1].position, force = force[i]}
        e[3] = surface.create_entity{name = 'crash-site-electric-pole', position = e[1].position, force = force[i]}
        for i = 1, 3 do e[i].operable = false e[i].minable = false e[i].destructible = false end
        e[3].connect_neighbour{ wire = defines.wire_type.red, target_entity = e[1]}
        e[2].power_production = 34
        e[2].electric_buffer_size = 34
        e[1].parameters = {playback_volume = 0.75, playback_globally = true, allow_polyphony = false}
        e[1].get_control_behavior().circuit_parameters = {signal_value_is_pitch = false, instrument_id = 0, note_id = 6}
        e[1].get_control_behavior().circuit_condition = {condition = {comparator = '=', first_signal = {type = 'virtual', name = 'signal-everything'}, second_signal = nil, constant = 0}, fulfilled = true}
      elseif capture_speed[i] <= 0 and #speaker > 0 then
        for _, e in pairs(speaker) do e.destroy() end
      end
    end

    --개인별 점령 점수 반영
    for i = 1, 2 do
      cp[i] = Const.capture_speed / 6000 * refresh_interval_tick * cp[i]
      cm[i] = Const.capture_speed / 6000 * refresh_interval_tick * cm[i]
      if cm[i] > cp[i] and __DB.team_game_capture_progress[i] == 0 then cm[i] = 0 end
    end
    local driver = nil
    for i = 1, 2 do
      for _, vehicle in pairs(capture_plus[i]) do
        driver = vehicle.get_driver()
        if driver then
          if driver.name == 'character' then
            if driver.player then
              __DB.players_data[driver.player.name].tdm_capture = __DB.players_data[driver.player.name].tdm_capture
                + cp[i] / __DB.team_game_capture_plus[i] * 100
            end
          elseif driver.is_player() then
            __DB.players_data[driver.name].tdm_capture = __DB.players_data[driver.name].tdm_capture
              + cp[i] / __DB.team_game_capture_plus[i] * 100
          end
        end
      end
      for _, vehicle in pairs(capture_minus[i]) do
        driver = vehicle.get_driver()
        if driver then
          if driver.name == 'character' then
            if driver.player then
              __DB.players_data[driver.player.name].tdm_recover = __DB.players_data[driver.player.name].tdm_recover
                + cm[i] / __DB.team_game_capture_minus[i] * 100
            end
          elseif driver.is_player() then
            __DB.players_data[driver.name].tdm_recover = __DB.players_data[driver.name].tdm_recover
              + cm[i] / __DB.team_game_capture_minus[i] * 100
          end
        end
      end
    end

    --승패 결정
    if __DB.team_game_remain_time == nil then return end
    if __DB.team_game_queue_force_to_close_game then
      win_state = 'draw'
      __DB.stat_last_win_reason = 'forceclose'
      __DB.team_game_queue_force_to_close_game = false
    elseif __DB.team_game_remained_tanks[1] == 0 and __DB.team_game_remained_tanks[2] == 0 and not Const.no_eliminate_lose then
      win_state = 'draw'
      __DB.stat_last_win_reason = 'eliminated'
    elseif __DB.team_game_capture_progress[1] >= 1 and __DB.team_game_capture_progress[2] >= 1 then
      win_state = 'draw'
      __DB.stat_last_win_reason = 'captured'
    elseif __DB.team_game_remained_tanks[1] == 0 and not Const.no_eliminate_lose then
      win_state = Const.team_defines[2]
      __DB.stat_last_win_reason = 'eliminated'
    elseif __DB.team_game_remained_tanks[2] == 0 and not Const.no_eliminate_lose then
      win_state = Const.team_defines[1]
      __DB.stat_last_win_reason = 'eliminated'
    elseif __DB.team_game_capture_progress[1] >= 1 then
      win_state = Const.team_defines[2]
      __DB.stat_last_win_reason = 'captured'
    elseif __DB.team_game_capture_progress[2] >= 1 then
      win_state = Const.team_defines[1]
      __DB.stat_last_win_reason = 'captured'
    elseif __DB.team_game_remain_time - __DB.team_game_countup < 0 then
      win_state = 'draw'
      __DB.stat_last_win_reason = 'timeup'
    end
    --승패가 결정난 경우
    if win_state then
      local speaker = surface.find_entities_filtered{position = {1000000, -1000000}, radius = 2}
      for _, e in pairs(speaker) do e.destroy() end
      if win_state == 'draw' then
        game.print{"team-draw"}
        log('\n[TEAM-RESULT] draw')
        for _, v in pairs(Const.team_defines) do
          game.forces[v.force].play_sound{path = 'utility/game_lost', volume_modifier = 1}
        end
        if math.random(0,1) == 1 then
          __DB.stat_won_players  = Util.tablecopy(__DB.team_game_players[1])
          __DB.stat_lost_players = Util.tablecopy(__DB.team_game_players[2])
          __DB.stat_won_color      = Const.team_defines[1].color
          __DB.stat_lost_color     = Const.team_defines[2].color
          __DB.stat_won_team_name  = Const.team_defines[1].force
          __DB.stat_lost_team_name = Const.team_defines[2].force
        else
          __DB.stat_won_players  = Util.tablecopy(__DB.team_game_players[2])
          __DB.stat_lost_players = Util.tablecopy(__DB.team_game_players[1])
          __DB.stat_won_color      = Const.team_defines[2].color
          __DB.stat_lost_color     = Const.team_defines[1].color
          __DB.stat_won_team_name  = Const.team_defines[2].force
          __DB.stat_lost_team_name = Const.team_defines[1].force
        end
      else
        game.print{"team-winner", Util.color2str(win_state.color), win_state.force}
        win_state = win_state.force
        log{"",'\n[TEAM-RESULT] winner = ', win_state}
        for k, v in pairs(Const.team_defines) do
          if v.force ~= win_state then
            game.forces[v.force].play_sound{path = 'utility/game_lost', volume_modifier = 1}
            __DB.stat_lost_players = Util.tablecopy(__DB.team_game_players[k])
            __DB.stat_lost_color = Const.team_defines[k].color
            __DB.stat_lost_team_name = Const.team_defines[k].force
          else
            game.forces[v.force].play_sound{path = 'utility/game_won', volume_modifier = 1}
            __DB.stat_won_players = Util.tablecopy(__DB.team_game_players[k])
            __DB.stat_won_color = Const.team_defines[k].color
            __DB.stat_won_team_name = Const.team_defines[k].force
          end
        end
      end
      __DB.team_game_win_state = win_state
      __DB.team_game_end_tick = game.tick + Const.team_end_time
      surface.print{"quit-after-time", math.ceil(Const.team_end_time/60)}
      __DB.stat_last_win = win_state
      __DB.stat_last_map_name = __DB.team_game_opened
      __DB.stat_last_playtime = __DB.team_game_countup

      local survived = nil
      local PDB = nil
      for name in pairs(__DB.stat_won_players) do
        PDB = __DB.players_data[name]
        local player = game.get_player(name)
        if player.connected then
          if player.surface == surface and player.controller_type == defines.controllers.character then
            survived = 1
          else
            survived = 0
          end
        else
          survived = nil
        end
        __DB.stat_won_players[name] = {
          kills = PDB.tdm_kills,
          damage_dealt = PDB.tdm_damage_dealt,
          capture = PDB.tdm_capture,
          recover = PDB.tdm_recover,
          survived = survived,
        }
        PDB.tdm_kills = 0
        PDB.tdm_damage_dealt = 0
        PDB.tdm_capture = 0
        PDB.tdm_recover = 0
      end
      for name in pairs(__DB.stat_lost_players) do
        PDB = __DB.players_data[name]
        local player = game.get_player(name)
        if player.connected then
          if player.surface == surface and player.controller_type == defines.controllers.character then
            survived = 1
          else
            survived = 0
          end
        else
          survived = nil
        end
        __DB.stat_lost_players[name] = {
          kills = PDB.tdm_kills,
          damage_dealt = PDB.tdm_damage_dealt,
          capture = PDB.tdm_capture,
          recover = PDB.tdm_recover,
          survived = survived,
        }
        PDB.tdm_kills = 0
        PDB.tdm_damage_dealt = 0
        PDB.tdm_capture = 0
        PDB.tdm_recover = 0
      end

      __DB.order_damage_stat_won_players   = Util.sort_key_table(__DB.stat_won_players,  'damage_dealt')
      __DB.order_damage_stat_lost_players  = Util.sort_key_table(__DB.stat_lost_players, 'damage_dealt')
      __DB.order_capture_stat_won_players  = Util.sort_key_table(__DB.stat_won_players,  'capture')
      __DB.order_capture_stat_lost_players = Util.sort_key_table(__DB.stat_lost_players, 'capture')

      local tspec_ing_frame = {}
      local PDB2
      for _, player in pairs(game.connected_players) do
        PDB2 = __DB.players_data[player.name]
        PDB2.guis.stat_view_btn.visible = true
        if player.surface.name == __DB.team_game_opened then
          tspec_ing_frame = PDB2.guis.tspec_ing_frame
          tspec_ing_frame.visible = true
          Util.opengui_last_team_stat(player)
        end
        PDB2.guis.stat_view_btn.visible = true
      end
    end
  end
end

--관전하러가기 버튼을 누를 때
Game_var.go_spectate_teamgame = function(player)
  if not __DB.team_game_opened then return end
  local playername = player.name
  local PDB = __DB.players_data[playername]
  local force = Util.get_player_team_force(playername)
  if player.surface.name == __DB.team_game_opened then return end
  local surface = game.surfaces[__DB.team_game_opened]

  if force == 'player' then
    PDB.player_mode = Const.defines.player_mode.whole_team_spectator
    Util.save_personal_color(player)
  else
    PDB.player_mode = Const.defines.player_mode.team_spectator
    Util.save_personal_color(player)
    player.tag = '[[color='..Util.color2str(Const.team_defines_key[force].color)..']'..force..'[/color]]'
    player.print{"inform-team-chat-mode"}
  end
  game.permissions.get_group('ffa_spec').add_player(player)
  Util.disable_minimap(player)
  Tank_spawn.despawn(player)
  Game_var.remove_character(playername)
  player.teleport({surface.map_gen_settings.width/2,0}, surface)
  player.force = force
  player.color = Util.get_personal_color(player)
  Game_var.remember_position_to_mapview(playername)
  Game_var.move_to_outofring(playername)
  PDB.guis.tdm_frame.visible = true
  PDB.guis.ffa_frame.visible = false
  PDB.guis.tspec_ing_frame.visible = true
  PDB.guis.tspec_frame.visible = false
end

--FFA로 돌아가기 버튼을 누를 때
Game_var.go_return_ffagame = function(player)
  if player.surface.index == 1 then return end
  local playername = player.name
  local PDB = __DB.players_data[playername]
  local force = nil

  if player.vehicle then
    if __DB.team_game_end_tick then
      Util.save_quick_bar(player, player.vehicle.name)
      player.vehicle.set_driver(nil)
    else
      return
    end
  end
  player.teleport({0,0}, game.surfaces[1])
  if player.force.name ~= 'player' then
    player.color = Util.get_personal_color(player)
    player.tag = ''
    Util.disable_minimap(player)
    player.print{"inform-all-chat-mode"}
  end
  Game_var.remove_character(playername)
  player.spectator = false
  PDB.player_mode = Const.defines.player_mode.ffa_spectator
  Game_var.player_left(playername)
  game.permissions.get_group(0).add_player(playername)
  PDB.last_tick_start_queue_for_ffa = game.tick
  Game_var.player_spawn_in_ffa(playername)
  PDB.guis.tdm_frame.visible = false
  PDB.guis.ffa_frame.visible = true
  PDB.guis.tspec_ing_frame.visible = false
  if __DB.team_game_opened then
    PDB.guis.tspec_frame.visible = true
  else
    PDB.guis.tspec_frame.visible = false
  end
end

--전기장 그리기
Game_var.redraw_sizing_field = function(np)
  if not np then np = #game.connected_players end
  local surface = game.surfaces[1]
  local n_vertex, vertexes = 0, {}
  local radius = Util.np2radius(np)
  __DB.field_radius = radius
  if not __DB.surface1_initialized then return end
  local last = surface.find_entities_filtered{name = 'electric-beam-no-sound', force = 'neutral'}
  for _, beam in pairs(last) do beam.destroy() end
  n_vertex = math.ceil((2 * math.pi * radius) / 10)
  for i = 1, n_vertex do
    vertexes[i] = {
      x = radius * math.cos(2 * math.pi * (i-1)/n_vertex),
      y = radius * math.sin(2 * math.pi * (i-1)/n_vertex)
    }
  end
  for i = 1, n_vertex do
    if i ~= n_vertex then
      surface.create_entity{
        name = 'electric-beam-no-sound',
        force = 'neutral',
        position = {0,0},
        source_position = vertexes[i],
        target_position = vertexes[i+1],
      }
    else
      surface.create_entity{
        name = 'electric-beam-no-sound',
        force = 'neutral',
        position = {0,0},
        source_position = vertexes[i],
        target_position = vertexes[1],
      }
    end
  end
end

--전기장 밖에서 데미지 입게 하기
Game_var.damage_out_of_field = function(refresh_interval_tick)
  local np = #game.connected_players
  if __DB.last_connected_players ~= np then
    __DB.last_connected_players = np
    Game_var.redraw_sizing_field(np)
  end
  local surface = game.surfaces[1]
  local vehicles = surface.find_entities_filtered{type = {'car', 'spider-vehicle', 'locomotive', 'artillery-wagon', 'cargo-wagon', 'fluid-wagon'}}
  for _, vehicle in pairs(vehicles) do
    if vehicle.force.index > 5 then
      if math.sqrt(vehicle.position.x^2 + vehicle.position.y^2) > __DB.field_radius then
        if vehicle.destructible then
          vehicle.health = vehicle.health - vehicle.max_health * 0.02
          if vehicle.health <= 0 then vehicle.die() end
        end
        --vehicle.damage(10, 'neutral', 'poison')
      end
    end
  end
end

--DB에서 플레이어 삭제하기
Game_var.remove_player_from_DB = function(playername)
  __DB.team_game_players[1][playername] = nil
  __DB.team_game_players[2][playername] = nil
  __DB.players_data[playername] = nil
  for k, name in pairs(__DB.players_index) do
    if name == playername then
      Tank_spawn.remove_vehicle_in_vault{index = k}
      __DB.players_index[k] = nil
      break
    end
  end
end

--오래된 오프라인 플레이어 이력 삭제하기
Game_var.remove_old_offline_player = function()
  local now = game.tick
  local lim = math.floor(Const.offline_limit*216000)
  local report = ''
  local to_remove = {}
  for _, player in pairs(game.players) do
    if not player.connected then
      if player.last_online + lim < now then
        to_remove[#to_remove + 1] = player.name
      end
    end
  end
  for _, playername in pairs(to_remove) do
    report = report..playername..', '
    Game_var.remove_player_from_ffa_queue(playername)
    Game_var.remove_player_from_DB(playername)
  end
  if #to_remove > 0 then
    game.remove_offline_players(to_remove)
    log('\n'..string.format("%.3f",game.tick/60)..' [AUTO-PLAYER-REMOVE] = '..report)
  end
end

--resetffa 직전에 모든 플레이어 차량 저장하기
Game_var.store_online_vehicles_before_resetffa = function()
  for _, player in pairs(game.connected_players) do
    if player.surface.index == 1 then
      Tank_spawn.despawn(player)
    end
  end
end

--on_nth_tick 이벤트용
Game_var.on_18000_tick = function()
  Game_var.remove_old_offline_player()
  if __DB.last_ffa_reset + math.floor(Const.ffa_reset_interval*216000) < game.tick then
    if __DB.loading_chunks.is_loading or __DB.team_game_opening or __DB.team_game_opened or __DB.team_game_end_tick or not __DB.surface1_initialized then
      __DB.reset_ffa_at_next_break = true
    else
      Game_var.store_online_vehicles_before_resetffa()
      Terrain.resetffa()
    end
  end
end

Game_var.on_10_tick = function()
  Game_var.update_team_stat(10)
end

Game_var.on_32_tick = Game_var.update_tqueue_count

Game_var.on_60_tick = function()
  Game_var.damage_out_of_field(60)
end

return Game_var