local Block_recipes = {}

Block_recipes.disable_tech_of_force = function(f)
  --퀵바 필터 등록시 사용할 수 있도록 일부 기술만 해금
  local force = game.forces[f]
  force.disable_research()
  force.disable_all_prototypes()

  force.technologies['military-2'].researched = true
  force.technologies['military-3'].researched = true
  force.technologies['military-4'].researched = true
  force.technologies['uranium-ammo'].researched = true
  force.technologies['flamethrower'].researched = true
  force.technologies['construction-robotics'].researched = true
  force.technologies['defender'].researched = true
  force.technologies['distractor'].researched = true
  force.technologies['destroyer'].researched = true
  force.technologies['worker-robots-speed-1'].researched = true
  force.technologies['worker-robots-speed-2'].researched = true
  force.technologies['worker-robots-speed-3'].researched = true
  force.technologies['worker-robots-speed-4'].researched = true
  force.technologies['worker-robots-speed-5'].researched = true
  force.technologies['worker-robots-speed-6'].researched = true
  force.technologies['worker-robots-speed-6'].researched = true --입력을 반복하면 무한연구가 됨
  force.technologies['follower-robot-count-1'].researched = true
  force.technologies['follower-robot-count-2'].researched = true
  force.technologies['follower-robot-count-3'].researched = true
  force.technologies['discharge-defense-equipment'].researched = true
  force.technologies['automobilism'].researched = true
  force.technologies['tank'].researched = true
  force.technologies['spidertron'].researched = true
  force.technologies['railway'].researched = true
  force.technologies['artillery'].researched = true
  force.technologies['oil-processing'].researched = true
  force.technologies['rocketry'].researched = true
  force.technologies['explosive-rocketry'].researched = true
  force.technologies['atomic-bomb'].researched = true

  for _, r in pairs(force.recipes) do r.enabled = false end
  force.recipes['car'].enabled = true
  force.recipes['tank'].enabled = true
  force.recipes['spidertron'].enabled = true
  -- force.recipes['rts-tool'].enabled = true -- TODO: recheck
  force.recipes['construction-robot'].enabled = true
  force.recipes['repair-pack'].enabled = true
  --force.recipes['solid-fuel-from-petroleum-gas'].enabled = true
  force.recipes['firearm-magazine'].enabled = true
  force.recipes['piercing-rounds-magazine'].enabled = true
  force.recipes['uranium-rounds-magazine'].enabled = true
  force.recipes['cannon-shell'].enabled = true
  force.recipes['explosive-cannon-shell'].enabled = true
  force.recipes['uranium-cannon-shell'].enabled = true
  force.recipes['explosive-uranium-cannon-shell'].enabled = true
  force.recipes['rocket'].enabled = true
  force.recipes['explosive-rocket'].enabled = true
  force.recipes['atomic-bomb'].enabled = true
  --force.recipes['artillery-shell'].enabled = true
  --force.recipes['artillery-targeting-remote'].enabled = true
  --force.recipes['locomotive'].enabled = true
  --force.recipes['artillery-wagon'].enabled = true
  force.recipes['flamethrower-ammo'].enabled = true
  force.recipes['grenade'].enabled = true
  force.recipes['cluster-grenade'].enabled = true
  force.recipes['poison-capsule'].enabled = true
  force.recipes['slowdown-capsule'].enabled = true
  force.recipes['defender-capsule'].enabled = true
  force.recipes['distractor-capsule'].enabled = true
  force.recipes['destroyer-capsule'].enabled = true
  -- force.recipes['discharge-defense-remote'].enabled = true --TODO: recheck

  --force.enable_all_recipes() --테스트 용
  --force.enable_all_technologies() --테스트 용
end

return Block_recipes