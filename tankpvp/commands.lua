local Commands = {}

local Terrain = require('tankpvp.terrain')
local Game_var = require('tankpvp.game_var')
local Const = require('tankpvp.const')

local DB = nil

Commands.on_load = function()
  DB = global.tankpvp_
  Terrain.on_load()
  Game_var.on_load()
  commands.add_command('resetffa', {"help_resetffa"}, Commands.reset_ffa)
  commands.add_command('kill', {"help_kill"}, Commands.kill)
  commands.add_command('ㄴ', {"help_n"}, Commands.shout_korean)
  commands.add_command('sdm', {"help_sdm"}, Commands.set_damage_mod)
  commands.add_command('gdm', {"help_gdm"}, Commands.get_damage_mod)
  commands.add_command('srm', {"help_srm"}, Commands.set_fire_rate_mod)
  commands.add_command('grm', {"help_grm"}, Commands.get_fire_rate_mod)
  commands.add_command('close-team-game', {"help_close-team-game"}, Commands.force_close_team_game)
  --commands.add_command('test', 'test', test)
end

--[[
local test = function(data)
  --data.parameters
end
--]]

--대상 죽이기(탱크 터트리면 주금)
Commands.kill = function(data)
  local player = nil
  if data.player_index then player = game.players[data.player_index] end
  if player then
    if not player.admin then player.print{"not_admin"} return end
  end
  if not data.parameter then
    if not player then log('\n[WARNING] /kill failed. Input parameter.')
    else player.print{"input_parameter"} end
    return
  end
  local name = data.parameter:match( "^%s*(.-)%s*$" )
  local target = game.players[name]
  local online = nil
  if target then online = target.connected end
  if not target and not online then
    if not player then log{"",'\n[WARNING] /kill failed. Can not find "',name,'".'}
    else player.print{"cannot_find", name} end
    return
  end
  if target.vehicle then
    target.vehicle.die()
    log{"",'\n[COMMAND] /kill ',name,' used.'}
    return
  else
    if not player then log{"",'\n[WARNING] /kill failed. "',name,'" is not riding vehicle.'}
    else player.print{"not_riding", name} end
    return
  end
end

--FFA 맵 초기화
Commands.reset_ffa = function(data)
  local player = game.players[data.player_index]
  if data.player_index then player = game.players[data.player_index] end
  if player then
    if not player.admin then player.print{"not_admin"} return end
  end
  if DB.loading_chunks.is_loading then
    if player then player.print{"during_map_gen"} end
    log('\n[WARNING] /resetffa failed. During map generation. Can not start another.')
    return
  end
  Game_var.store_online_vehicles_before_resetffa()
  Terrain.resetffa()
  log('\n[COMMAND] /resetffa used.')
end

--외치기 한글 자판
--"/s "를 한글상태에서 입력하면 "/ㄴ "로 나오는데 그냥 쓸 수 있게 해줌.
Commands.shout_korean = function(data)
  local player = game.players[data.player_index]
  if data.player_index then player = game.players[data.player_index] end
  if not player then return end
  local force = player.force
  local color = player.chat_color
  local tag = player.tag
  if tag then tag = ' ' .. tag end

  game.print({"",player.name,tag," (",{"command-output.shout"},"): ",data.parameter}, color)
  localised_print{"",string.format("%.3f",game.tick/60)," [SHOUT] ",player.name,tag," (",{"command-output.shout"},"): ",data.parameter}
end

--데미지 배수 설정
Commands.set_damage_mod = function(data)
  local player = nil
  if data.player_index then player = game.players[data.player_index] end
  local pname = '<server>'
  if player then
    if not player.admin then player.print{"not_admin"} return end
    pname = player.name
  end
  if not data.parameter then
    if not player then log('\n[WARNING] /sdm failed. Input parameter.')
    else player.print{"input_parameter"} end
    return
  end
  local params = {}
  for substr in data.parameter:gmatch("%S+") do
    params[#params + 1] = substr
  end
  if #params > 1 and tonumber(params[1]) > 0 and tonumber(params[2]) and tonumber(params[1]) <= #Const.ammo_categories then
    local ammo = Const.ammo_categories[tonumber(params[1])]
    local mod = tonumber(params[2])
    for _, force in pairs(game.forces) do
      force.set_ammo_damage_modifier(ammo, mod)
    end
    mod = string.format("%+.1f",mod*100):gsub("%.?0+$","")
    game.print{"notice_sdm",ammo,mod,pname}
    localised_print{"",string.format("%.3f",game.tick/60),' [COMMAND] /sdm used. "',ammo,'" damage set to ',mod,'% by ',pname}
  else
    if not player then log{"",'\n[WARNING] /sdm failed. Wrong parameter.'}
    else player.print{"wrong_parameter"} end
  end
end

--데미지 배수 덤핑
Commands.get_damage_mod = function(data)
  local player = nil
  if data.player_index then player = game.players[data.player_index] end
  if player then
    local report = 'damage modifiers = '
    local force = game.forces['player']
    for i, ammo in ipairs(Const.ammo_categories) do
      report = report..i..'.[color=1,0.5,1,1]'..ammo..'[/color]=[color=yellow]'..string.format("%.4f",force.get_ammo_damage_modifier(ammo)):gsub("%.?0+$","")..'[/color] , '
    end
    game.players[data.player_index].print(report)
  else
    local report = string.format("%.3f",game.tick/60)..' [PRINT] damage modifiers = '
    local force = game.forces['player']
    for i, ammo in ipairs(Const.ammo_categories) do
      report = report..i..'.'..ammo..'='..string.format("%.4f",force.get_ammo_damage_modifier(ammo)):gsub("%.?0+$","")..' , '
    end
    localised_print(report)
  end
end

--공격속도 배수 설정
Commands.set_fire_rate_mod = function(data)
  local player = nil
  if data.player_index then player = game.players[data.player_index] end
  local pname = '<server>'
  if player then
    if not player.admin then player.print{"not_admin"} return end
    pname = player.name
  end
  if not data.parameter then
    if not player then log('\n[WARNING] /srm failed. Input parameter.')
    else player.print{"input_parameter"} end
    return
  end
  local params = {}
  for substr in data.parameter:gmatch("%S+") do
    params[#params + 1] = substr
  end
  if #params > 1 and tonumber(params[1]) > 0 and tonumber(params[2]) and tonumber(params[1]) <= #Const.ammo_categories then
    local ammo = Const.ammo_categories[tonumber(params[1])]
    local mod = tonumber(params[2])
    for _, force in pairs(game.forces) do
      force.set_gun_speed_modifier(ammo, mod)
    end
    mod = string.format("%+.1f",mod*100):gsub("%.?0+$","")
    game.print{"notice_srm",ammo,mod,pname}
    localised_print{"",string.format("%.3f",game.tick/60),' [COMMAND] /srm used. "',ammo,'" fire rate set to ',mod,'% by ',pname}
  else
    if not player then log{"",'\n[WARNING] /srm failed. Wrong parameter.'}
    else player.print{"wrong_parameter"} end
  end
end

--공격속도 배수 덤핑
Commands.get_fire_rate_mod = function(data)
  local player = nil
  if data.player_index then player = game.players[data.player_index] end
  if player then
    local report = 'fire rate modifiers = '
    local force = game.forces['player']
    for i, ammo in ipairs(Const.ammo_categories) do
      report = report..i..'.[color=1,0.5,1,1]'..ammo..'[/color]=[color=0.25,0.75,1,1]'..string.format("%.4f",force.get_gun_speed_modifier(ammo)):gsub("%.?0+$","")..'[/color] , '
    end
    game.players[data.player_index].print(report)
  else
    local report = string.format("%.3f",game.tick/60)..' [PRINT] fire rate modifiers = '
    local force = game.forces['player']
    for i, ammo in ipairs(Const.ammo_categories) do
      report = report..i..'.'..ammo..'='..string.format("%.4f",force.get_gun_speed_modifier(ammo)):gsub("%.?0+$","")..' , '
    end
    localised_print(report)
  end
end

Commands.force_close_team_game = function(data)
  local player = nil
  if data.player_index then player = game.players[data.player_index] end
  local pname = '<server>'
  if player then
    if not player.admin then player.print{"not_admin"} return end
    pname = player.name
  end
  if DB.team_game_opened and not DB.team_game_win_state then
    game.print{"notice_force-close-team-game",pname}
    localised_print{"",string.format("%.3f",game.tick/60),' [COMMAND] /close-team-game used by ',pname}
    DB.team_game_queue_force_to_close_game = true
  elseif DB.team_game_opened and DB.team_game_win_state then
    if player then player.print('current team game is already closing.') end
    localised_print{"",string.format("%.3f",game.tick/60),' [WARNING] /close-team-game tried by ',pname,', but it is already closing.'}
    DB.team_game_queue_force_to_close_game = false
  else
    if player then player.print('no team game opened.') end
    localised_print{"",string.format("%.3f",game.tick/60),' [WARNING] /close-team-game tried by ',pname,', but no team game opened.'}
    DB.team_game_queue_force_to_close_game = false
  end
end

return Commands