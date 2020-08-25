Util = {}

local Const = require('tankpvp.const')

--Error
--사용법 :
--  리턴값들... = Util.p({기본값들...}, 함수명, 인수들...)  --리턴값이 여러개
--  리턴값 = Util.p({기본값}, 함수명, 인수들...)  --리턴값이 한개
--  Util.p({}, 함수명, 인수들...)  --리턴값이 없으면
local error_wrapper = function(defaults_table, done, ...)
  if done == true then
    return ...
  else
    local arg = {...}
    for _, player in pairs(game.players) do
      if player.admin and player.connected then
        player.print{"",string.format("%.3f",game.tick/60),' ' ,arg[1]}
      end
    end
    localised_print{"",string.format("%.3f",game.tick/60),' ',arg[1]}
    return unpack(defaults_table)
  end
end
Util.p = function(defaults_table, f, ...)
  return error_wrapper(defaults_table, pcall(f, ...))
end

--String
Util.color2str = function(color)
  local r,g,b,a = 0,0,0,1
  if color.r then r = color.r
  elseif color[1] then r = color[1] end
  if color.g then g = color.g
  elseif color[2] then g = color[2] end
  if color.b then b = color.b
  elseif color[3] then b = color[3] end
  if color.a then a = color.a
  elseif color[4] then a = color[4] end
  return string.format("%.4f,%.4f,%.4f,%.4f",r,g,b,a)
end

--Gui --spectator로 전환시 닫히는 gui는 on_gui_closed를 발생시키지 않는 문제
--character.destroy()를 치환
Util.ch_destroy = function(character)
  local player = nil
  if character.player then
    player = character.player
  end
  character.destroy()
  if player then
    if global.tankpvp_.players_data[player.name].guis.tdmstat_frame.visible then
      global.tankpvp_.players_data[player.name].guis.tdmstat_frame.visible = false
      player.opened = nil
    end
  end
end

--Gui --spectator로 전환시 닫히는 gui는 on_gui_closed를 발생시키지 않는 문제
--player.set_controller{type = defines.controllers.spectator}를 치환
Util.set_control_spect = function(player)
  player.set_controller{type = defines.controllers.spectator}
  if global.tankpvp_.players_data[player.name].guis.tdmstat_frame.visible then
    global.tankpvp_.players_data[player.name].guis.tdmstat_frame.visible = false
    player.opened = nil
  end
end

--Database
Util.save_personal_color = function(player)
  global.tankpvp_.players_data[player.name].personal_color = {r=player.color.r,g=player.color.g,b=player.color.b,a=player.color.a}
end

--Database
Util.get_personal_color = function(player)
  local color = global.tankpvp_.players_data[player.name].personal_color
  return {r=color.r,g=color.g,b=color.b,a=color.a}
end

--Math
Util.np2radius = function(np)
  if np > Const.ffa_max_field_cnt then np = Const.ffa_max_field_cnt end
  return Const.ffa_min_fieldr + np / Const.ffa_max_field_cnt * (Const.ffa_max_fieldr - Const.ffa_min_fieldr)
end

--Gui
Util.add_div2stat_tab = function(tabname, tabpane, caption, data)
  -- 좌우 분할된 콘텐츠 공간을 리턴 함
  -- data = {ln, lc, rn, rc}
  local tab = tabpane.add{type = 'tab', name = tabname, caption = caption}
  local cwrap = tabpane.add{type = 'flow', direction = 'vertical'}
  tabpane.add_tab(tab,cwrap)
  local chead = cwrap.add{type = 'table', column_count = 2}
  chead.style.left_cell_padding=20
  chead.style.right_cell_padding=20
  local ltext = chead.add{type = 'label', caption = data[1]}
  local rtext = chead.add{type = 'label', caption = data[3]}
  ltext.style.horizontally_stretchable = true
  rtext.style.horizontally_stretchable = true
  ltext.style.font_color = data[2]
  rtext.style.font_color = data[4]
  ltext.style.font = 'default-bold'
  rtext.style.font = 'default-bold'
  local chead_al = chead.style.column_alignments
  chead_al[1]='left'
  chead_al[2]='right'
  local scrollspace = cwrap.add{type='scroll-pane', vertical_scroll_policy='auto',
    horizontal_scroll_policy = 'never', style='scroll_pane_under_subheader',
    direction = 'horizontal',
  }
  local cbody = scrollspace.add{type = 'table', column_count = 2, vertical_centering = false}
  local lspace = cbody.add{type = 'flow', direction = 'vertical'}
  local rspace = cbody.add{type = 'flow', direction = 'vertical'}
  lspace.style.horizontally_stretchable = true
  rspace.style.horizontally_stretchable = true
  lspace.style.horizontal_align = 'left'
  rspace.style.horizontal_align = 'right'
  
  local cbody_al = cbody.style.column_alignments
  cbody_al[1]='top-left'
  cbody_al[2]='top-right'
  return lspace, rspace
end

--Gui
Util.add_label_w_style = function(parent, caption, style, styles)
  local l = parent.add{type = 'label', caption = caption, style = style}
  for k, v in pairs(styles) do
    l.style[k] = v
  end
end

--Force
--플레이어가 팀명단에 있으면 팀세력이름을 출력
Util.get_player_team_force = function(playername)
  for i = 1, 2 do
    if global.tankpvp_.team_game_players[i][playername] then
      return Const.team_defines[i].force
    end
  end
  return 'player'
end


--Table
Util.sort_key_table = function(ktable, orderkey, ascending)
  local copy = {}
  for k, v in pairs(ktable) do
    copy[#copy + 1] = {key = k}
    for kk, vv in pairs(v) do
      copy[#copy][kk] = vv
    end
  end
  local sorter = nil
  if ascending then --true, 작은것이 앞으로
    sorter = function(a,b) return a[orderkey] < b[orderkey] end
  else --descending : false/nil, 큰것이 앞으로
    sorter = function(a,b) return a[orderkey] > b[orderkey] end
  end
  table.sort(copy, sorter)
  return copy
end

--Validity
Util.pcolor = function(playername)
  local PDB = global.tankpvp_.players_data[playername]
  if PDB then
    return PDB.personal_color
  else
    return {r=1,g=1,b=1,a=1}
  end
end

--Table
Util.tablecopy = function(source)
  local copy = {}
  for k, v in pairs(source) do
    copy[k] = v
  end
  return copy
end

--GuiCall
local end_reason = {
  ['eliminated'] = {"reason-eliminated"},
  ['captured'] = {"reason-captured"},
  ['timeup'] = {"reason-timeup"},
  ['forceclose'] = {"reason-forceclose"},
}
local survived_string = function(s)
  if s == 1 then return '[color=0,1,0,1]✓[/color]'
  elseif s == 0 then return '[color=1,0,0,1]☠[/color]'
  else return '[color=0.5,0.5,0.5,1]？[/color]'
  end
end
Util.opengui_last_team_stat = function(player)
  local DB = global.tankpvp_
  local PDB = DB.players_data[player.name]
  local tdmstat_frame = PDB.guis.tdmstat_frame
  local tdmstat_inner = PDB.guis.tdmstat_inner
  local align = nil
  tdmstat_frame.visible = true
  player.opened = tdmstat_frame
  tdmstat_frame.force_auto_center()
  
  local won_color = {0.7,0.7,0.7,1}
  local won_team = '-'
  if DB.stat_last_win ~= 'draw' then
    won_color = DB.stat_won_color
    won_team = DB.stat_last_win
  end
  tdmstat_inner.clear()
  local summary = tdmstat_inner.add{type='table', name='summary', column_count = 8, style = 'finished_game_table'}
  summary.style.margin = 8
  local lasttime = DB.stat_last_playtime/60
  lasttime = string.format("%d",(lasttime - lasttime%60)/60)..':'..string.format("%02d",math.floor(lasttime%60))
  Util.add_label_w_style(summary, {"summary-map-name"}, 'caption_label', {})
  Util.add_label_w_style(summary, DB.stat_last_map_name, nil, {})
  Util.add_label_w_style(summary, {"summary-winner-team"}, 'caption_label', {})
  Util.add_label_w_style(summary, won_team, nil, {font_color = won_color})
  Util.add_label_w_style(summary, {"summary-end-reason"}, 'caption_label', {})
  Util.add_label_w_style(summary, end_reason[DB.stat_last_win_reason], nil, {})
  Util.add_label_w_style(summary, {"summary-time-used"}, 'caption_label', {})
  Util.add_label_w_style(summary, lasttime, nil, {})

  local tabpane = tdmstat_inner.add{type = 'tabbed-pane'}
  tabpane.style.horizontally_stretchable = true
  local page1L, page1R = Util.add_div2stat_tab('tab1', tabpane, {"team-damage-dealt"}, {
    DB.stat_won_team_name, DB.stat_won_color, DB.stat_lost_team_name, DB.stat_lost_color
  })
  local page2L, page2R = Util.add_div2stat_tab('tab2', tabpane, {"team-capture-points"}, {
    DB.stat_won_team_name, DB.stat_won_color, DB.stat_lost_team_name, DB.stat_lost_color
  })

  local table1L = page1L.add{type = 'table', column_count = 4, style = 'finished_game_table'}
  align = table1L.style.column_alignments
  align[1] = 'bottom-left'
  align[2] = 'bottom-center'
  align[3] = 'bottom-right'
  align[4] = 'bottom-center'
  Util.add_label_w_style(table1L, {"table-cell-player"}, 'caption_label', {})
  Util.add_label_w_style(table1L, {"table-cell-kills"}, 'caption_label', {})
  Util.add_label_w_style(table1L, {"table-cell-damage-dealt"}, 'caption_label', {})
  Util.add_label_w_style(table1L, {"table-cell-survival"}, 'caption_label', {})
  local table1R = page1R.add{type = 'table', column_count = 4, style = 'finished_game_table'}
  align = table1R.style.column_alignments
  align[1] = 'bottom-center'
  align[2] = 'bottom-right'
  align[3] = 'bottom-center'
  align[4] = 'bottom-right'
  Util.add_label_w_style(table1R, {"table-cell-survival"}, 'caption_label', {})
  Util.add_label_w_style(table1R, {"table-cell-damage-dealt"}, 'caption_label', {})
  Util.add_label_w_style(table1R, {"table-cell-kills"}, 'caption_label', {})
  Util.add_label_w_style(table1R, {"table-cell-player"}, 'caption_label', {})

  local table2L = page2L.add{type = 'table', column_count = 4, style = 'finished_game_table'}
  align = table2L.style.column_alignments
  align[1] = 'bottom-left'
  align[2] = 'bottom-right'
  align[3] = 'bottom-right'
  align[4] = 'bottom-center'
  Util.add_label_w_style(table2L, {"table-cell-player"}, 'caption_label', {})
  Util.add_label_w_style(table2L, {"table-cell-recover"}, 'caption_label', {})
  Util.add_label_w_style(table2L, {"table-cell-capture"}, 'caption_label', {})
  Util.add_label_w_style(table2L, {"table-cell-survival"}, 'caption_label', {})
  local table2R = page2R.add{type = 'table', column_count = 4, style = 'finished_game_table'}
  align = table2R.style.column_alignments
  align[1] = 'bottom-center'
  align[2] = 'bottom-right'
  align[3] = 'bottom-right'
  align[4] = 'bottom-right'
  Util.add_label_w_style(table2R, {"table-cell-survival"}, 'caption_label', {})
  Util.add_label_w_style(table2R, {"table-cell-capture"}, 'caption_label', {})
  Util.add_label_w_style(table2R, {"table-cell-recover"}, 'caption_label', {})
  Util.add_label_w_style(table2R, {"table-cell-player"}, 'caption_label', {})

  for i, v in ipairs(DB.order_damage_stat_won_players) do
    Util.add_label_w_style(table1L, v.key, nil, {font_color = Util.pcolor(v.key), font = 'default-bold'})
    Util.add_label_w_style(table1L, v.kills, nil, {})
    Util.add_label_w_style(table1L, string.format("%d",v.damage_dealt), nil, {})
    Util.add_label_w_style(table1L, survived_string(v.survived), nil, {})
  end
  for i, v in ipairs(DB.order_damage_stat_lost_players) do
    Util.add_label_w_style(table1R, survived_string(v.survived), nil, {})
    Util.add_label_w_style(table1R, string.format("%d",v.damage_dealt), nil, {})
    Util.add_label_w_style(table1R, v.kills, nil, {})
    Util.add_label_w_style(table1R, v.key, nil, {font_color = Util.pcolor(v.key), font = 'default-bold'})
  end
  for i, v in ipairs(DB.order_capture_stat_won_players) do
    Util.add_label_w_style(table2L, v.key, nil, {font_color = Util.pcolor(v.key), font = 'default-bold'})
    Util.add_label_w_style(table2L, string.format("%.1f",v.recover):gsub("%.?0+$","")..'', nil, {})
    Util.add_label_w_style(table2L, string.format("%.1f",v.capture):gsub("%.?0+$","")..'', nil, {})
    Util.add_label_w_style(table2L, survived_string(v.survived), nil, {})
  end
  for i, v in ipairs(DB.order_capture_stat_lost_players) do
    Util.add_label_w_style(table2R, survived_string(v.survived), nil, {})
    Util.add_label_w_style(table2R, string.format("%.1f",v.capture):gsub("%.?0+$","")..'', nil, {})
    Util.add_label_w_style(table2R, string.format("%.1f",v.recover):gsub("%.?0+$","")..'', nil, {})
    Util.add_label_w_style(table2R, v.key, nil, {font_color = Util.pcolor(v.key), font = 'default-bold'})
  end
end

--Item
Util.insert_spider_remote = function(player, spider)
  if not player then return end
  local inv = game.create_inventory(1)
  inv.insert{name = 'spidertron-remote', count = 1}
  local remote = inv.find_item_stack('spidertron-remote')
  if spider and spider.valid then
    if spider.name == 'spidertron' then
      remote.connected_entity = spider
    end
  end
  local can_insert = player.can_insert(remote)
  if can_insert then player.insert(remote) end
  inv.destroy()
  return can_insert
end

--Force
Util.copypaste_weapon_modifiers = function(source, target)
  if type(source) == 'string' then source = game.forces[source] end
  if type(target) == 'string' then target = game.forces[target] end
  if not source then return end
  if not target then return end
  for i, ammo in pairs(Const.ammo_categories) do
    target.set_ammo_damage_modifier(ammo, source.get_ammo_damage_modifier(ammo))
    target.set_gun_speed_modifier(ammo, source.get_gun_speed_modifier(ammo))
  end
end

--Switch
Util.reenable_minimap = function(player)
  player.minimap_enabled = true
  player.game_view_settings.show_minimap = true
end
Util.disable_minimap = function(player)
  player.minimap_enabled = false
  player.game_view_settings.show_minimap = false
end

--Math
Util.pick_random_in_circle = function(radius)
  local x, y = -radius, -radius
  while x^2 + y^2 > radius^2 do
    x = math.random(-radius, radius)
    y = math.random(-radius, radius)
  end
  return {x = x, y = y}
end

--Inventory
Util.dispose_to_make_slot = function(player_or_character, nslot)
  local inv = player_or_character.get_main_inventory()
  local rand = nil
  for i = 1, nslot do
    if inv.count_empty_stacks(true) < nslot then
      rand = math.random(1,#inv)
      inv.set_filter(rand, nil)
      inv[rand].clear()
    else
      break
    end
  end
end

--QuickBar
Util.save_quick_bar = function(player, vehiclename)
  local slots = {}
  for i = 1, 20 do
    slots[i] = player.get_quick_bar_slot(i)
    if slots[i] then slots[i] = slots[i].name end
  end
  global.tankpvp_.players_data[player.name].quick_bars[vehiclename] = slots
end
Util.load_quick_bar = function(player, vehiclename)
  local slots = global.tankpvp_.players_data[player.name].quick_bars[vehiclename]
  if slots then
    for i = 1, 20 do
      player.set_quick_bar_slot(i, slots[i])
    end
    return true
  else
    return false
  end
end

--Damage --https://wiki.factorio.com/Damage#Resistance
-- on_entity_damaged이벤트에서 사용시
--  Util.recalculate_final_damage(event.entity.prototype, event.original_damage_amount, event.damage_type.name)
Util.recalculate_final_damage = function(entity_prototype, original_damage, damage_type_name)
  if entity_prototype.resistances then
    if entity_prototype.resistances[damage_type_name] then
      local rd = entity_prototype.resistances[damage_type_name].decrease
      local rp = entity_prototype.resistances[damage_type_name].percent
      if rd + 1 < original_damage then
        return (original_damage - rd) * (1 - rp)
      elseif original_damage > 1 then
        return 1 / (rd-original_damage + 2) * (1 - rp)
      else
        return 1 / (rd + 1) * (1 - rp)
      end
    end
  end
  return original_damage
end

return Util