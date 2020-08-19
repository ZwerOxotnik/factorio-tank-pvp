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
  --commands.add_command('test', 'test', test)
end

--[[
local test = function(data)
  --data.parameters
  Terrain.generate_team_map(3)
end
--]]

--대상 죽이기(탱크 터트리면 주금)
Commands.kill = function(data)
  local player = nil
  if data.player_index then player = game.players[data.player_index] end
  if player then
    if not player.admin then
      player.print{"not_admin"}
      return
    end
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
  if not target or not online then
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
    if not player.admin then
      player.print{"not_admin"}
      return
    end
  end
  if DB.loading_chunks.is_loading then
    if player then player.print{"during_map_gen"} end
    log('\n[WARNING] /resetffa failed. During map generation. Can not start another.')
    return
  end
  Terrain.resetffa()
  log('\n[COMMAND] /resetffa used.')
end

--외치기 한글 자판
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

return Commands