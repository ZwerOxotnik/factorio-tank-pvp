local test_const = {}
--.gitignore 에서 제외된 테스트 파일.
--_example_test_const.lua의 이름을 _test_const.lua로 변경.
--테스트 목적. github에 push하지 않음.


--test_const.sw를 0, false, nil을 하면 꺼지고, 1, true를 하면 가동
test_const.sw = 1

test_const.func = function(Const)
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
Const.supply_drop_interval = 120
--test-end----------------------
end

return test_const