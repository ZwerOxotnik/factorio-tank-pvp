local Terrain = {}

local Const = require('tankpvp.const')
local Util = require('tankpvp.util')

local DB = nil

Terrain.on_load = function()
  DB = global.tankpvp_
end

local ffa_map_gen_settings = function(radius, last_seed)
  local seed = math.random(0, 4294967295) + last_seed
  if seed > 4294967295 then seed = seed - 4294967295 end
  local map_gen_settings = {
    ['seed'] = seed,
    ['width'] = radius*2,
    ['height'] = radius*2,
    ['terrain_segmentation'] = 13,
    ['water'] = 0.4,
    ['starting_area'] = 1,
    ['cliff_settings'] = {cliff_elevation_interval = 30, cliff_elevation_0 = 2, richness = 0.3},
    ['default_enable_all_autoplace_controls'] = true,
    ['autoplace_controls'] = {
      ['enemy-base'] = {frequency = 0, size = 0, richness = 0},
      ['stone'] = {frequency = 0, size = 0, richness = 0},
      ['iron-ore'] = {frequency = 0, size = 0, richness = 0},
      ['copper-ore'] = {frequency = 0, size = 0, richness = 0},
      ['uranium-ore'] = {frequency = 0, size = 0, richness = 0},
      ['crude-oil'] = {frequency = 0, size = 0, richness = 0},
      ['coal'] = {frequency = 0, size = 0, richness = 0},
      ['trees'] = {frequency = 2, size = 2, richness = 2},
    },
    ['autoplace_settings'] = {
      ['entity'] = {treat_missing_as_default = true},
      ['tile'] = {treat_missing_as_default = true},
      ['decorative'] = {treat_missing_as_default = true}
    },
    ['property_expression_names'] = {
    }
  }
  return map_gen_settings
end

local team_map_gen_settings = function(width, height)
  local map_gen_settings = {
    ['seed'] = math.random(0, 4294967295),
    ['width'] = width,
    ['height'] = height,
    ['terrain_segmentation'] = 13,
    ['water'] = 0.4,
    ['starting_area'] = 1,
    ['cliff_settings'] = {cliff_elevation_interval = 30, cliff_elevation_0 = 2, richness = 0.3},
    ['default_enable_all_autoplace_controls'] = true,
    ['autoplace_controls'] = {
      ['enemy-base'] = {frequency = 0, size = 0, richness = 0},
      ['stone'] = {frequency = 0, size = 0, richness = 0},
      ['iron-ore'] = {frequency = 0, size = 0, richness = 0},
      ['copper-ore'] = {frequency = 0, size = 0, richness = 0},
      ['uranium-ore'] = {frequency = 0, size = 0, richness = 0},
      ['crude-oil'] = {frequency = 0, size = 0, richness = 0},
      ['coal'] = {frequency = 0, size = 0, richness = 0},
      ['trees'] = {frequency = 2, size = 2, richness = 2},
    },
    ['autoplace_settings'] = {
      ['entity'] = {treat_missing_as_default = true},
      ['tile'] = {treat_missing_as_default = true},
      ['decorative'] = {treat_missing_as_default = true}
    },
    ['property_expression_names'] = {
    }
  }
  return map_gen_settings
end

Terrain.resetffa = function()
  local surface = game.surfaces[1]
  surface.map_gen_settings = ffa_map_gen_settings(Const.ffa_radius, surface.map_gen_settings.seed)
  surface.clear(false)
  surface.always_day = true
  DB.reset_ffa_at_next_break = false
  DB.surface1_initialized = false
  if game.tick > 2000 then
    game.print{"inform_resetffa_reason_period", Const.ffa_reset_interval}
    log{"",string.format("%.3f",game.tick/60),' [AUTO-RESET] Auto resetffa reason = ', Const.ffa_reset_interval, 'h interval'}
  end
end

Terrain.on_surface_cleared = function(event)
  local LCDB = DB.loading_chunks
  --첫 맵이 초기화 된 경우.
  if event.surface_index == 1 then
    local FR = Const.ffa_radius
    for _, player in pairs(game.connected_players) do
      if player.surface.index == 1 and player.controller_type ~= defines.controllers.editor then
        player.force = 'player'
        Util.set_control_spect(player)
      end
    end
    for i = #game.forces, 6, -1 do
      if i > 5 then
        game.merge_forces(game.forces[i], game.forces[1])
      end
    end
    game.surfaces[1].request_to_generate_chunks({0,0}, FR/32 + 1)
    game.forces[1].chart(game.surfaces[1], {{-FR, -FR}, {FR, FR}})
    LCDB.surface_name = game.surfaces[1].name
    LCDB.lefttop = {x=((-FR) - (-FR%32))/32, y=((-FR) - (-FR%32))/32}
    LCDB.rightbottom = {x=(FR - (FR%32))/32, y=(FR - (FR%32))/32}
    LCDB.is_loading = true
  end
end

local write_capture_wall_pos = function(width, height)
  local center = {0, 0}
  local wall_line, wall_pos = {}, {}
  local CR = Const.capture_radius
  for i = 1, #Const.team_defines do
    center = Const.team_defines[i].direction * (height/2 - Const.capture_margin - CR)
    wall_line = {
      {-CR / 4 * 1.4142, center - CR/2}, {CR / 4 * 1.4142, center - CR/2},
      {-CR / 4 * 1.4142, center + CR/2}, {CR / 4 * 1.4142, center + CR/2},
    }
    for i, v in ipairs(wall_line) do
      wall_line[i][1] = math.floor(v[1])
      wall_line[i][2] = math.floor(v[2])
    end
    wall_pos = {}
    for xline = wall_line[1][1], wall_line[2][1] do
      wall_pos[#wall_pos + 1] = {x = xline + 0.5, y = wall_line[1][2] + 0.5}
    end
    for xline = wall_line[3][1], wall_line[4][1] do
      wall_pos[#wall_pos + 1] = {x = xline + 0.5, y = wall_line[3][2] + 0.5}
    end
    DB.team_game_wall_pos[i] = wall_pos
  end
end

Terrain.generate_team_map = function(player_count)
  local LCDB = DB.loading_chunks
  if LCDB.is_loading then return end
  DB.team_game_history_count = DB.team_game_history_count + 1
  local width = math.floor(Const.team_map_width_min + player_count*Const.team_map_width_per)
  local height = math.floor(Const.team_map_height_min + player_count*Const.team_map_height_per)
  local surface = game.create_surface(
    'TeamDeathMatch'..tostring(DB.team_game_history_count),
    team_map_gen_settings(width, height)
  )
  surface.always_day = true
  write_capture_wall_pos(width, height)
  width = width/2 - 1
  height = height/2 - 1
  local xa = (width - (width%32))/32
  local ya = (height - (height%32))/32
  for x = -xa, xa do
    for y = -ya, ya do
      surface.request_to_generate_chunks({x*32, y*32}, 1)
    end
  end
  game.forces[1].chart(surface, {{-width, -height}, {width, height}})
  LCDB.surface_name = surface.name
  LCDB.lefttop = {x=-xa, y=-ya}
  LCDB.rightbottom = {x=xa, y=ya}
  LCDB.is_loading = true
end

Terrain.init = function()
  game.create_surface('vault',{seed=0,width=1,height=1}).generate_with_lab_tiles = true
  Terrain.resetffa()
end

Terrain.get_ffa_spawn = function()
  local p = {x = 0, y = 0}
  local valid = false
  local surface = game.surfaces[1]
  local tiles = nil
  local try = 0
  local radius = DB.field_radius - 1 --Const.ffa_radius
  while not valid do
    p = Util.pick_random_in_circle(radius)
    tiles = surface.find_tiles_filtered{
      position = p,
      radius = 5,
      limit = 70,
      collision_mask = 'ground-tile'
    }
    if #tiles > 60 then
      if surface.count_entities_filtered{position = p, radius = 5, type = 'cliff' } == 0
        and surface.count_entities_filtered{position = p, radius = 5, type = 'wall' } == 0
        and surface.count_entities_filtered{position = p, radius = 5, type = 'car' } == 0
        then
        valid = true
      end
    end
    try = try + 1
    
    if try > 20 and not valid then
      valid = true
    end
  end
  return p
end

Terrain.get_team_spreaded_spawn = function(team_index, surface)
  local p = {x = 0, y = 0}
  local valid = false
  local tiles = nil
  local try = 0
  local w = surface.map_gen_settings.width
  local h = surface.map_gen_settings.height
  local CR = Const.capture_radius
  local CM = Const.capture_margin
  local SL = Const.team_spawn_line
  local lefttop = {x = -w/2, y = nil}
  local rightbottom = {x = w/2, y = nil}
  if CR*2+CM > h*SL then
    SL = CR*2+CM
  else
    SL = h*SL
  end --여기부터 SL은 스폰구역 높이
  if team_index == 1 then
    lefttop.y = -h/2
    rightbottom.y = -h/2 + SL
  else
    lefttop.y = h/2 - SL
    rightbottom.y = h/2
  end
  while not valid do
    p.x = lefttop.x+math.random()*(rightbottom.x-lefttop.x)
    p.y = lefttop.y+math.random()*(rightbottom.y-lefttop.y)
    tiles = surface.find_tiles_filtered{
      position = p,
      radius = 5,
      limit = 70,
      collision_mask = 'ground-tile'
    }
    if #tiles > 60 then
      if surface.count_entities_filtered{position = p, radius = 5, type = 'cliff' } == 0
        and surface.count_entities_filtered{position = p, radius = 5, type = 'wall' } == 0
        and surface.count_entities_filtered{position = p, radius = 1.5, type = 'car' } == 0
        then
        valid = true
      end
    end
    try = try + 1
    if try > 20 and not valid then
      valid = true
    end
  end
  return p
end

Terrain.on_chunk_generated = function(event)
  local surface = event.surface
  local tiles = surface.find_tiles_filtered{
    area = event.area,
    limit = 1024
  }
  if surface.index == 1 then
    local filtered_tiles = {}
    for _, tile in pairs(tiles) do
      if tile.position.x^2 + tile.position.y^2 > Const.ffa_radius^2 then
        filtered_tiles[#filtered_tiles + 1] = {
          name = 'out-of-map',
          position = {tile.position.x, tile.position.y}
        }
      end
    end
    surface.set_tiles(filtered_tiles, true, true, true)
  elseif surface.name == 'vault' then
    return
  else
    local width = surface.map_gen_settings.width
    local height = surface.map_gen_settings.height
    local tilesa, tilesb = {}, {}
    local center = {0, 0}
    local entities = {}
    local entity = nil
    for i = 1, #Const.team_defines do
      center = Const.team_defines[i].direction * (height/2 - Const.capture_margin - Const.capture_radius)
      tilesa = surface.find_tiles_filtered{
        area = event.area,
        position = {0, center},
        radius = Const.capture_radius
      }
      tilesb = {}
      for _, tile in pairs(tilesa) do
        tilesb[#tilesb + 1] = {
          name = Const.team_defines[i].capture_tile,
          position = tile.position
        }
      end
      surface.set_tiles(tilesb, true, true, true)
      entities = surface.find_entities_filtered{
        area = event.area,
        position = {0, center},
        radius = Const.capture_radius,
        type = {'tree', 'cliff', 'simple-entity'}
      }
      for _, e in pairs(entities) do
        e.destroy()
      end
      for _, p in pairs(DB.team_game_wall_pos[i]) do
        if p.x < event.area.right_bottom.x
          and p.x >= event.area.left_top.x
          and p.y < event.area.right_bottom.y
          and p.y >= event.area.left_top.y
          then
          entity = surface.create_entity{
            name = 'stone-wall',
            position = p,
            force = 'player'
          }
          entity.destructible = false
          entity.minable = false -- 퍼미션에 방지되서 굳이 없어도 됨
        end
      end
    end
  end
  local cliff = nil
  local wall = nil
  for _, tile in pairs(tiles) do
    cliff = surface.find_entity('cliff', {tile.position.x + 0.5, tile.position.y + 0.5})
    if cliff ~= nil then
      wall = surface.create_entity{
        name = 'stone-wall',
        position = {tile.position.x + 0.5, tile.position.y + 0.5},
        force = 'player'
      }
      wall.destructible = false
      wall.minable = false
    end
  end
end

return Terrain