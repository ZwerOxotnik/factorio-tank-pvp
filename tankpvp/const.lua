--상수
local Const = {}

--testmode를 0, false, nil을 하면 꺼지고, 1, true를 하면 가동
local testmode = 0
local test_redefine = function()
--test--------------------------
--Const.tank_health = 200 --빠른 킬 테스트용, --기본은 코멘트처리
Const.no_eliminate_lose = true
Const.ffa_radius = 50
Const.ffa_min_fieldr = 25
Const.ffa_max_fieldr = 55
Const.min_people_tdm = 1
Const.team_start_cntdn_max = 600
Const.team_start_cntdn_min = 600
Const.team_game_standby_time = 300
--test-end----------------------
end

Const.no_eliminate_lose = false --테스트용. 전멸로 패배하지 않음.
Const.force_limit = 64 --5는 ffa없음, 6으로 하면 혼자 테스트. 최대64(최대59명의 FFA플레이어)
Const.respawn_time = 300 --틱 단위 300
Const.ffa_radius = 300 --타일 단위 300
Const.ffa_min_fieldr = 100 --타일 전기장최소반지름 100
Const.ffa_max_fieldr = 305 --타일 전기장최대반지름 305
Const.ffa_max_field_cnt = 30 --전기장 최대반지름이기 위한 사람 수 30
Const.loot_limit = 10 --사망시 템 종류별로 떨구는 최대 갯수 10
Const.min_people_tdm = 4 --팀 데스매치 카운트 개시 최소인원. 4명
Const.team_start_cntdn_max = 7200 --틱 단위. 최대 대기시간 7200
Const.team_start_cntdn_per = 480 --틱 단위. 추가 인원당 시간 감소 480
Const.team_start_cntdn_min = 900 --틱 단위. 최소 대기시간 900
Const.team_game_standby_time = 900 --틱 단위. 팀 데스매치 시작 직전 카운트다운 900
Const.team_roundtime_min = 25260 --최소 라운드 시간 25260
Const.team_roundtime_per = 600 --추가1인당 추가 라운드 시간 600
Const.team_roundtime_min = Const.team_roundtime_min - Const.team_roundtime_per * Const.min_people_tdm
Const.team_roundtime_max = 108060 --최대 라운드 시간 108060
Const.team_end_time = 900 --틱 단위. 팀전 종료 후 대기시간.
Const.capture_radius = 20 --점령구역 반지름 20
Const.capture_margin = 15 --점령구역 여백 15
Const.capture_speed = 1/1.2 --점령속도 1이면 1초/1인원. 0.5면 절반 2면 두배 등등
Const.capture_limit = 3 --동시 점령인원 한계
Const.team_spawn_line = 1/4 --팀 스폰지역 맵 세로의 1/4
Const.team_map_width_min = 150 --팀 데스매치 맵 최소폭 150
Const.team_map_height_min = 250 --팀 데스매치 맵 최소높이 250
Const.team_map_width_per = 4 --팀 데스매치 맵 사람당 추가폭 4
Const.team_map_height_per = 5 --팀 데스매치 맵 사람당 추가높이 5
Const.recover_capture_per_hit = 0.001 --타격당 감소시키는 점령수치(점령은 0.0~1.0)
Const.offline_limit = 30.0 --(Hour) 오프라인 이후 삭제까지 걸리는 시간(1시간=216000, 30시간=6480000)
Const.ffa_reset_interval = 6 --(Hour)
Const.team_defines = {
  [1] = {
    index = 1,
    direction = -1,
    capture_tile = 'red-refined-concrete',
    force = 'team1',
    color = {r=1,g=0.15,b=0,a=1}
  },
  [2] = {
    index = 2,
    direction = 1,
    capture_tile = 'blue-refined-concrete',
    force = 'team2',
    color = {r=0.25,g=0.5,b=1,a=1}
  }
}
Const.team_defines_key = {
  ['team1'] = Const.team_defines[1],
  ['team2'] = Const.team_defines[2]
}
Const.defines = {
  player_mode = {
    normal = 1, --ffa 기본
    ffa_spectator = 2, --ffa 사람많을 때 관전자
    team = 3, --team 참가자
    team_spectator = 4, --team 사망자
    whole_team_spectator = 5 --team에 나중에 참여한 관전자
  }
}
Const.ammo_categories = {
  'artillery-shell', 'biological', 'bullet', 'cannon-shell', 'capsule', 'combat-robot-beam',
  'combat-robot-laser', 'electric', 'flamethrower', 'grenade', 'landmine', 'laser-turret',
  'melee', 'railgun', 'rocket', 'shotgun-shell'
}

if testmode and testmode ~= 0 then
  test_redefine()
end

return Const