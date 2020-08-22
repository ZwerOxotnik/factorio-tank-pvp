Gui = {}

local Const = require('tankpvp.const')
local Game_var = require('tankpvp.game_var')
local Util = require('tankpvp.util')

local DB = nil

Gui.on_load = function()
  DB = global.tankpvp_
  Game_var.on_load()
end

--[[ guis
tdm_frame
tspec_ing_frame
ffa_frame
tcountdn_frame
tspec_frame
]]--
--최상위 GUI 생성
local ffa_gui = function(player)
  local PDB = DB.players_data[player.name]
  local top_flow = player.gui.top.add{type = 'flow', name = 'top_flow_tankpvp', direction = 'vertical'}

  --팀 데스매치 프레임
  local tdm_frame = top_flow.add{type = 'flow', name = 'tdm_frame', direction = 'vertical'}
  PDB.guis.tdm_frame = tdm_frame
  do
    tdm_frame.style.padding = 2
    tdm_frame.add{type = 'label', name = 'teamtimer', caption = '[font=default-game] 00:00[/font]'}
    local twrap = tdm_frame.add{type = 'flow', name = 'twrap', direction = 'vertical'}
    twrap.style.vertical_spacing = 0
    twrap.add{type = 'flow', name = 't1stat', direction = 'horizontal'}
    twrap.t1stat.style.vertical_align = 'center'
    twrap.t1stat.add{type = 'sprite', name = 'tankicon', sprite = 'item/tank'}
    twrap.t1stat.tankicon.style.width = 30
    twrap.t1stat.tankicon.style.height = 30
    twrap.t1stat.tankicon.style.stretch_image_to_widget_size = true
    twrap.t1stat.tankicon.resize_to_sprite = false
    twrap.t1stat.add{type = 'frame', name = 'rf', style = 'tooltip_frame'}
    twrap.t1stat.rf.style.padding = 0
    twrap.t1stat.rf.add{type = 'label', name = 'remains', caption = '[font=default-large-bold][color=1,0.15,0]10[/color][/font]'}
    twrap.t1stat.add{type = 'label', name = 'message', caption = '[font=default-game]Capturing : 3 [/font]'}
    twrap.add{type = 'flow', name = 't1capture', direction = 'horizontal'}
    twrap.t1capture.style.vertical_align = 'center'
    twrap.t1capture.add{type = 'progressbar', name = 'bar'}
    twrap.t1capture.bar.style.color = Const.team_defines[2].color
    twrap.t1capture.bar.style.width = 200
    twrap.t1capture.add{type = 'label', name = 'percent', caption = '[font=count-font]100%[/font]'}
    twrap.add{type = 'flow', name = 't2capture', direction = 'horizontal'}
    twrap.t2capture.style.vertical_align = 'center'
    twrap.t2capture.add{type = 'progressbar', name = 'bar'}
    twrap.t2capture.bar.style.color = Const.team_defines[1].color
    twrap.t2capture.bar.style.width = 200
    twrap.t2capture.add{type = 'label', name = 'percent', caption = '[font=count-font]100%[/font]'}
    twrap.add{type = 'flow', name = 't2stat', direction = 'horizontal'}
    twrap.t2stat.style.vertical_align = 'center'
    twrap.t2stat.add{type = 'sprite', name = 'tankicon', sprite = 'item/tank'}
    twrap.t2stat.tankicon.style.width = 30
    twrap.t2stat.tankicon.style.height = 30
    twrap.t2stat.tankicon.style.stretch_image_to_widget_size = true
    twrap.t2stat.tankicon.resize_to_sprite = false
    twrap.t2stat.add{type = 'frame', name = 'rf', style = 'tooltip_frame'}
    twrap.t2stat.rf.style.padding = 0
    twrap.t2stat.rf.add{type = 'label', name = 'remains', caption = '[font=default-large-bold][color=0.25,0.5,1]5[/color][/font]'}
    twrap.t2stat.add{type = 'label', name = 'message', caption = '[font=default-game]Being captured : 3 [/font]'}
    tdm_frame.visible = false
  end

  --팀 데스매치 관전중 프레임
  local tspec_ing_frame = top_flow.add{type = 'flow', name = 'tspec_ing_frame', direction = 'horizontal'}
  PDB.guis.tspec_ing_frame = tspec_ing_frame
  do
    tspec_ing_frame.style.padding = 2
    tspec_ing_frame.add{type = 'button', name = 'quitbtn', caption = {"return-to-ffa"}, mouse_button_filter = {'left'}}
    tspec_ing_frame.quitbtn.style.padding = 0
    tspec_ing_frame.add{type = 'label', name = 'ffaplay_count', caption = {"ffa-count", '-'}}
    tspec_ing_frame.visible = false
  end

  --FFA 프레임
  local ffa_frame = top_flow.add{type = 'flow', name = 'ffa_frame', direction = 'horizontal'}
  PDB.guis.ffa_frame = ffa_frame
  do
    ffa_frame.style.padding = 2
    ffa_frame.add{type = 'checkbox', name = 'tready', caption = {"queue-for-team"},
      state = PDB.queueing_for_team_game,
      tooltip = {"queue-for-team-tooltip", Const.min_people_tdm}
    }
    ffa_frame.add{type = 'label', name = 'tqueue_count', caption = {"queue-for-team-count", 0}}
    ffa_frame.add{type = 'label', name = 'lead', caption = '    [font=count-font]LEADERBOARD :[/font]',
      tooltip = {"leaderboard-tooltip"}
    }
    ffa_frame.add{type = 'flow', name = 'lead_content', direction = 'horizontal'}
    ffa_frame.visible = false
  end

  --팀 데스매치 인원이 모였을 때, 시작까지 카운트다운 표시하는 프레임
  local tcountdn_frame = top_flow.add{type = 'flow', name = 'tcountdn_frame', direction = 'horizontal'}
  PDB.guis.tcountdn_frame = tcountdn_frame
  do
    tcountdn_frame.style.padding = 2
    tcountdn_frame.add{type = 'label', caption = {"team-countdown-label"}}
    tcountdn_frame.add{type = 'label', name = 'timer', caption = '[font=default-game]00:00[/font]'}
    tcountdn_frame.visible = false
  end

  --관전 버튼 표시하는 프레임
  local tspec_frame = top_flow.add{type = 'flow', name = 'tspec_frame', direction = 'horizontal'}
  PDB.guis.tspec_frame = tspec_frame
  do
    tspec_frame.style.padding = 2
    tspec_frame.add{type = 'button', name = 'tspecbtn', caption = {"spectate-team"}, mouse_button_filter = {'left'}}
    tspec_frame.tspecbtn.style.padding = 0
    tspec_frame.add{type = 'label', name = 'tplay_count', caption = {"playing-team-count", '-'}}
    tspec_frame.add{type = 'label', name = 'tspec_count', caption = {"spectate-team-count", '-'}}
    tspec_frame.visible = false
  end

  --팀전 결과 통계 창
  local tdmstat_frame = player.gui.screen.add{type = 'frame', name = 'tdmstat_frame', direction = 'vertical'}
  PDB.guis.tdmstat_frame = tdmstat_frame
  do
    local align = nil
    tdmstat_frame.auto_center = true
    tdmstat_frame.add{type = 'flow', name = 'header', direction = 'horizontal'}
    tdmstat_frame.style.horizontally_stretchable = true
    tdmstat_frame.style.maximal_height = 600
    tdmstat_frame.header.add{type = 'label', caption = {"last-tdm-stat"}, style = 'frame_title'}
    local drag = tdmstat_frame.header.add{type = 'empty-widget', name = 'dragspace', style = 'draggable_space_header'}
    drag.drag_target = tdmstat_frame
    drag.style.right_margin = 8
    drag.style.horizontally_stretchable = true
    drag.style.vertically_stretchable = true
    local closebtn = tdmstat_frame.header.add{type = 'sprite-button', name = 'closebtn', sprite = 'utility/close_white', style = 'frame_action_button', mouse_button_filter = {'left'}}
    local innerframe = tdmstat_frame.add{type = 'frame', direction = 'vertical', style = 'inside_deep_frame'}
    tdmstat_frame.visible = false
    PDB.guis.tdmstat_inner = innerframe
  end

  local stat_view_btn = player.gui.top.add{type = 'sprite-button', name = 'stat_view_btn',
    sprite = 'utility/spawn_flag', style = 'transparent_slot', mouse_button_filter = {'left'},
    hovered_sprite = 'virtual-signal/signal-green', clicked_sprite = 'virtual-signal/signal-yellow',
    tooltip = {"stat-view-btn"}
  }
  stat_view_btn.style.width = 30
  stat_view_btn.style.height = 30
  stat_view_btn.visible = false
  PDB.guis.stat_view_btn = stat_view_btn

  return top_flow
end

--ffa 킬/데스 점수 순위 매기고 표시하기
local lead_sorter = function(a,b)
  --if a.kills == b.kills then
  --  return a.deaths < b.deaths
  --end
  return a.kills - a.deaths/2 > b.kills - b.deaths/2
end
Gui.update_lead_content = function()
  local list = {}
  local captions = {}
  local tooltips = {}
  local not_leader_caption = nil
  local place = 0
  local leaders = {}
  local playername = nil
  local color = nil
  for name, data in pairs(DB.players_data) do
    list[#list + 1] = {name = name, kills = data.ffa_kills, deaths = data.ffa_deaths, damage = data.ffa_damage_dealt}
  end
  table.sort(list, lead_sorter)
  for i = 1, 3 do --3위까지 누구에게나 표시
    if list[i] then
      color = game.players[list[i].name].color
      color = '[color='..tostring(color.r)..','..tostring(color.g)..','..tostring(color.b)..']'
      captions[#captions + 1] = '[font=count-font]   '..tostring(i)..'. '..color..list[i].name..'[/color] ('..list[i].kills..'/'..list[i].deaths..')[/font]'
      tooltips[#tooltips + 1] = {"ffa-damage-tooltip", list[i].name, string.format("%d",list[i].damage)}
      leaders[list[i].name] = true
    end
  end
  local PDB = nil
  for _, player in pairs(game.connected_players) do
    playername = player.name
    PDB = DB.players_data[playername]
    if player.surface.index == 1 then
      PDB.guis.ffa_frame.lead_content.clear()
      for i = 1, #captions do
        PDB.guis.ffa_frame.lead_content.add{
          type = 'label',
          caption = captions[i],
          tooltip = tooltips[i]
        }
      end
      if not leaders[playername] then --자신이 3위 내에 없는 경우
        place = 0
        for i = 1, #list do
          if list[i].name == playername then place = i end
        end
        color = player.color
        color = '[color='..tostring(color.r)..','..tostring(color.g)..','..tostring(color.b)..']'
        not_leader_caption = '[font=count-font]   '..tostring(place)..'. '..color
          ..playername..'[/color] ('
          ..PDB.ffa_kills..'/'
          ..PDB.ffa_deaths..')[/font]'
        PDB.guis.ffa_frame.lead_content.add{
          type = 'label',
          caption = not_leader_caption,
          tooltip = {"ffa-damage-tooltip", playername, string.format("%d",PDB.ffa_damage_dealt)}
        }
      end
      PDB.guis.ffa_frame.visible = true
    elseif player.surface.index == 2 then
    else
      PDB.guis.ffa_frame.visible = false
    end
  end
end

--대기인원 표시
Gui.update_tqueue_count = function()
  for _, player in pairs(game.connected_players) do
    if player.surface.index == 1 then
      DB.players_data[player.name].guis.ffa_frame.tqueue_count.caption = {"queue-for-team-count", DB.team_game_queue_count}
    elseif player.surface.index == 2 then
    else
      DB.players_data[player.name].guis.ffa_frame.visible = false
    end
  end
end

--체크박스 누를때
Gui.on_gui_checked_state_changed = function(event)
  if not event.element then return end
  if not event.element.valid then return end
  local player = game.players[event.player_index]
  local PDB = DB.players_data[player.name]

  if event.element == PDB.guis.ffa_frame.tready then
    PDB.queueing_for_team_game = event.element.state
  end
end

--버튼 누를 때
Gui.on_gui_click = function(event)
  if not event.element then return end
  if not event.element.valid then return end
  local player = game.players[event.player_index]
  local PDB = DB.players_data[player.name]
  if not PDB then return end
  if not PDB.guis then return end

  if event.element == PDB.guis.tspec_frame.tspecbtn then
    Game_var.go_spectate_teamgame(player)
  elseif event.element == PDB.guis.tspec_ing_frame.quitbtn then
    Game_var.go_return_ffagame(player)
  elseif event.element == PDB.guis.stat_view_btn then
    if player.opened == PDB.guis.tdmstat_frame or PDB.guis.tdmstat_frame.visible then
      player.opened = nil
      PDB.guis.tdmstat_frame.visible = false
    else
      Util.opengui_last_team_stat(player)
    end
  elseif event.element == PDB.guis.tdmstat_frame.header.closebtn then
    if player.opened == PDB.guis.tdmstat_frame then
      player.opened = nil
    end
    PDB.guis.tdmstat_frame.visible = false
  end
end

--닫을 때 (esc 등)
Gui.on_gui_closed = function(event)
  if event.gui_type ~= defines.gui_type.custom then return end
  if not event.element then return end
  if not event.element.valid then return end
  local player = game.players[event.player_index]
  local PDB = DB.players_data[player.name]
  if not PDB then return end
  if not PDB.guis then return end

  if event.element == PDB.guis.tdmstat_frame then
    PDB.guis.tdmstat_frame.visible = false
  end
end

--기본 맵 로딩시 로딩바 표시
Gui.loading_nauvis_chunks = function(player, percent)
  local loading_frame = player.gui.center.loading_frame
  if loading_frame and loading_frame.valid then
    loading_frame.destroy()
  end
  --if surface_name == 'nauvis' then
  --  surface_name = 'FreeForAll'
  --end
  loading_frame = player.gui.center.add{
    type = 'frame',
    name = 'loading_frame',
    caption = {"progress-bar", 'FreeForAll'},
  }
  local bar = loading_frame.add{type = 'progressbar', value = percent, style = 'research_progressbar'}
  bar.style.horizontally_stretchable = true
  bar.style.color = {1, 0.25, 0}
  if percent >= 1 then
    loading_frame.destroy()
  end
end

--팀데스매치 맵 로딩시 로딩바 표시
Gui.loading_team_chunks = function(player, percent, surface_name)
  local top_flow = player.gui.top.top_flow_tankpvp
  if not top_flow then
    top_flow = ffa_gui(player)
  end
  local flow = top_flow.loadingbar_flow
  if flow and flow.valid then
    flow.destroy()
  end
  flow = top_flow.add{
    type = 'frame',
    name = 'loadingbar_flow',
    direction = 'vertical',
  }
  top_flow.loadingbar_flow.add{
    type = 'label',
    caption = {"progress-bar-team", surface_name},
  }
  local bar = top_flow.loadingbar_flow.add{type = 'progressbar', value = percent,  style = 'research_progressbar'}
  bar.style.color = {1, 0.25, 1}
  if percent >= 1 then
    flow.destroy()
  end
end

-- 최초 접속시 GUI 생성
Gui.on_player_created = function(event)
  ffa_gui(game.players[event.player_index])
end

-- 플레이어가 재접속 했을 때 그동안 업데이트 되지 못한 GUI를 업데이트
Gui.on_player_joined_game = function(event)
  local player = game.players[event.player_index]
  local PDB = DB.players_data[player.name]
  local loading_frame = player.gui.center.loading_frame
  if loading_frame and loading_frame.valid then
    loading_frame.destroy()
  end
  local top_flow = player.gui.top.top_flow_tankpvp
  if not top_flow then
    top_flow = ffa_gui(player)
  end
  local flow = top_flow.loadingbar_flow
  if flow and flow.valid then
    flow.destroy()
  end
  if player.surface.index == 1 then
    PDB.guis.ffa_frame.visible = true
    PDB.guis.tdm_frame.visible = false
    PDB.guis.tspec_ing_frame.visible = false
    if DB.team_game_opened then
      PDB.guis.tspec_frame.visible = true
    else
      PDB.guis.tspec_frame.visible = false
    end
    if DB.team_game_countdown_time then
      if DB.team_game_remain_time then
        PDB.guis.tcountdn_frame.visible = false
      else
        PDB.guis.tcountdn_frame.visible = true
      end
    else
      PDB.guis.tcountdn_frame.visible = false
    end
  elseif player.surface.index == 2 then
  else
    PDB.guis.ffa_frame.visible = false
    PDB.guis.tdm_frame.visible = true
    PDB.guis.tspec_frame.visible = false
    PDB.guis.tcountdn_frame.visible = false
    if DB.team_game_end_tick or not player.vehicle then
      PDB.guis.tspec_ing_frame.visible = true
    else
      PDB.guis.tspec_ing_frame.visible = false
    end
  end
end

--카운트다운 표시용도
Gui.team_game_start_countdown = function()
  if DB.team_game_opening then
    for _, player in pairs(game.connected_players) do
      DB.players_data[player.name].guis.tcountdn_frame.visible = false
    end
    return
  end

  --팀맵 생성 후 시작전까지 카운트
  if DB.team_game_standby_time ~= nil then
    for _, player in pairs(game.connected_players) do
      local timer = DB.team_game_standby_time + DB.team_game_remain_time - DB.team_game_countup
      timer = timer/60
      local caption = '[font=default-game] '..string.format('%02d:%02d', math.floor((timer - timer%60)/60), math.floor(timer%60))..'[/font]'
      DB.players_data[player.name].guis.tdm_frame.teamtimer.caption = caption
      DB.players_data[player.name].guis.tcountdn_frame.visible = false
    end

  --팀맵 진행 중 카운트
  elseif DB.team_game_remain_time ~= nil then
    for _, player in pairs(game.connected_players) do
      local timer = DB.team_game_remain_time - DB.team_game_countup
      timer = timer/60
      if timer < 0 then timer = 0 end
      local caption = '[font=default-game] '..string.format('%02d:%02d', math.floor((timer - timer%60)/60), math.floor(timer%60))..'[/font]'
      DB.players_data[player.name].guis.tdm_frame.teamtimer.caption = caption
      DB.players_data[player.name].guis.tcountdn_frame.visible = false
    end

  --팀맵 생성 전까지 카운트
  elseif DB.team_game_countdown_time ~= nil then
    local countdown = DB.team_game_countdown_time - DB.team_game_countup
    local s = ''
    countdown = countdown/60
    if countdown%60 < 10 then s = '0' end
    local caption = '[font=default-game]'..string.format('%02d:%s%.1f', math.floor((countdown - countdown%60)/60), s, math.floor(countdown%60*10)/10)..'[/font]'

    for _, player in pairs(game.connected_players) do
      DB.players_data[player.name].guis.tcountdn_frame.visible = true
      DB.players_data[player.name].guis.tcountdn_frame.timer.caption = caption
    end
  else
    for _, player in pairs(game.connected_players) do
      DB.players_data[player.name].guis.tcountdn_frame.visible = false
    end
  end
end

--팀 상황 업데이트
Gui.update_team_stat = function()
  if DB.team_game_opened == nil then return end
  local t1cnt = DB.team_game_remained_tanks[1]
  local t2cnt = DB.team_game_remained_tanks[2]
  t1cnt = '[font=default-large-bold][color='..Util.color2str(Const.team_defines[1].color)..']'..tostring(t1cnt)..'[/color][/font]'
  t2cnt = '[font=default-large-bold][color='..Util.color2str(Const.team_defines[2].color)..']'..tostring(t2cnt)..'[/color][/font]'
  local capp = DB.team_game_capture_plus
  local capm = DB.team_game_capture_minus
  local capstr = {[1]={}, [2]={}}
  local capturing_string = {}
  local being_captured_string = {}
  local neutral_string = {}
  local cp = {[1]=capp[1],[2]=capp[2]}
  local cm = {[1]=capm[1],[2]=capm[2]}
  local CL = Const.capture_limit
  if cp[1] > CL then cp[1] = CL end
  if cp[2] > CL then cp[2] = CL end
  if cm[1] > CL then cm[1] = CL end
  if cm[2] > CL then cm[2] = CL end
  for i = 1, 2 do
    if capm[i] == 0 then
      capstr[i] = tostring(capp[i])
    else
      capstr[i] = '[color=yellow]'..tostring(cp[i] - cm[i])..'[/color] = '..tostring(capp[i])..string.format(' - %d',capm[i])
    end
    if capp[i] ~= 0 then
      capturing_string[i] = {"capturing-string", capstr[i]}
      being_captured_string[i] = {"being-captured-string", capstr[i]}
      neutral_string[i] = being_captured_string[i]
    elseif capp[i] == 0 and capm[i] ~= 0 and DB.team_game_capture_progress[i] ~= 0 then
      capturing_string[i] = {"being-recovered-string", '- '..tostring(capm[i])}
      being_captured_string[i] = {"recovering-string", '- '..tostring(capm[i])}
      neutral_string[i] = capturing_string[i]
    else
      capturing_string[i] = ''
      being_captured_string[i] = ''
      neutral_string[i] = ''
    end
  end

  local ffa_players_cnt, team_players_cnt, team_spectators_cnt = 0,0,0
  for _, player in pairs(game.connected_players) do
    if player.surface.index == 1 then
      ffa_players_cnt = ffa_players_cnt + 1
    elseif player.surface.index == 2 then
    elseif DB.players_data[player.name].player_mode == Const.defines.player_mode.team
      or DB.players_data[player.name].player_mode == Const.defines.player_mode.team_spectator
      then
      team_players_cnt = team_players_cnt + 1
    else
      team_spectators_cnt = team_spectators_cnt + 1
    end
  end

  local tdm_frame, tspec_frame, tspec_ing_frame = {},{},{}
  local twrap = nil
  local force_name = nil
  for _, player in pairs(game.connected_players) do
    local PDB = DB.players_data[player.name]
    tdm_frame = PDB.guis.tdm_frame
    tspec_frame = PDB.guis.tspec_frame
    tspec_ing_frame = PDB.guis.tspec_ing_frame
    twrap = tdm_frame.twrap

    if player.surface.index == 1 then
      tdm_frame.visible = false
      tspec_frame.visible = true
      tspec_ing_frame.visible = false
      tspec_frame.tplay_count.caption = {"playing-team-count", team_players_cnt}
      tspec_frame.tspec_count.caption = {"spectate-team-count", team_spectators_cnt}
    elseif player.surface.index == 2 then
    else
      tdm_frame = PDB.guis.tdm_frame
      tdm_frame.visible = true
      tspec_frame.visible = false
      if DB.team_game_end_tick or PDB.player_mode ~= Const.defines.player_mode.team then
        tspec_ing_frame.visible = true
      else
        tspec_ing_frame.visible = false
      end
      tspec_ing_frame.ffaplay_count.caption = {"ffa-count", ffa_players_cnt}
      twrap.t1stat.rf.remains.caption = t1cnt
      twrap.t2stat.rf.remains.caption = t2cnt
      force_name = Util.get_player_team_force(player.name)
      if force_name == Const.team_defines[1].force then
        twrap.t1stat.message.caption = being_captured_string[1]
        twrap.t2stat.message.caption = capturing_string[2]
      elseif force_name == Const.team_defines[2].force then
        twrap.t1stat.message.caption = capturing_string[1]
        twrap.t2stat.message.caption = being_captured_string[2]
      else
        twrap.t1stat.message.caption = neutral_string[1]
        twrap.t2stat.message.caption = neutral_string[2]
      end
    end
    twrap.t1capture.bar.value = DB.team_game_capture_progress[1]
    twrap.t1capture.percent.caption = string.format('[font=count-font]%.1f%%[/font]',DB.team_game_capture_progress[1]*100)
    twrap.t2capture.bar.value = DB.team_game_capture_progress[2]
    twrap.t2capture.percent.caption = string.format('[font=count-font]%.1f%%[/font]',DB.team_game_capture_progress[2]*100)
  end
end

--on_nth_tick 이벤트용
Gui.on_29_tick = function()
  Gui.update_team_stat()
end

Gui.on_31_tick = function()
  Gui.update_tqueue_count()
end

Gui.on_32_tick = function()
  Gui.update_lead_content()
end

Gui.on_6_tick = function()
  Gui.team_game_start_countdown()
end

return Gui