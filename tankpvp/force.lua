local Force = {}

local Block_recipes = require('tankpvp.block_recipes')
local Const = require('tankpvp.const')
local T1 = Const.team_defines[1].force
local T2 = Const.team_defines[2].force

Force.create_team_init = function()
  if not game.forces[4] then
    game.create_force(T1)
    Block_recipes.disable_tech_of_force(T1)
    Util.copypaste_weapon_modifiers('player', T1)
  end
  if not game.forces[5] then
    game.create_force(T2)
    Block_recipes.disable_tech_of_force(T2)
    Util.copypaste_weapon_modifiers('player', T2)
  end
  game.forces['player'].set_friend(T1, true)
  game.forces['player'].set_friend(T2, true)
  game.forces['player'].friendly_fire = false
  game.forces[T1].set_friend('player', true)
  game.forces[T1].friendly_fire = false
  game.forces[T2].set_friend('player', true)
  game.forces[T2].friendly_fire = false
  game.forces['enemy'].friendly_fire = false
end

Force.find_no_one_connected = function()
  if not game.forces[5] then
    Force.create_team_init()
  end
  local i = 6 --1:player, 2:enemy, 3:neutral, 4,5:팀전 예약
  for ii = 6, (#game.forces + 1) do
    if not game.forces[ii] then
      i = ii
      break
    end
    if #game.forces[ii].connected_players == 0 then
      i = ii
      break
    end
    ii = ii + 1
  end
  if i > Const.force_limit then
    return nil
  else
    return i
  end
end

Force.pick_no_one_connected = function()
  local i = Force.find_no_one_connected()
  if i == nil then
    return 'player', 1
  end
  local f = string.format('%d', i)

  if not game.forces[f] then
    game.create_force(f)
    Block_recipes.disable_tech_of_force(f)
    Util.copypaste_weapon_modifiers('player', f)
  elseif #game.forces[f].connected_players == 0 then
    for _, player in pairs(game.forces[f].players) do
      --해당 개인 세력의 미접속 플레이어는 기본 세력으로 변경
      player.force = game.forces[1]
    end
  end
  game.forces['player'].set_friend(f, true)
  game.forces['player'].friendly_fire = false
  game.forces[f].set_friend('player', true)
  game.forces[f].friendly_fire = false
  return f, game.forces[f].index
end

Force.set_team_spawn = function(surface)
  local width = surface.map_gen_settings.width
  local height = surface.map_gen_settings.height
  local center = {0, 0}
  for i = 1, #Const.team_defines do
    center = Const.team_defines[i].direction * (height/2 - Const.capture_margin - Const.capture_radius)
    game.forces[Const.team_defines[i].force].set_spawn_position({0, center}, surface)
  end
end

return Force