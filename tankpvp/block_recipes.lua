local Block_recipes = {}

Block_recipes.disable_tech_of_force = function(f)
  --퀵바 필터 등록시 사용할 수 있도록 일부 기술만 해금
  local force = game.forces[f]
  force.disable_research()
  force.disable_all_prototypes()
  force.recipes['repair-pack'].enabled = true
  force.recipes['firearm-magazine'].enabled = true

  force.technologies['military-2'].researched = true
  force.technologies['military-3'].researched = true
  force.technologies['military-4'].researched = true
  force.technologies['tanks'].researched = true
  force.technologies['uranium-ammo'].researched = true
  force.technologies['flamethrower'].researched = true
  force.technologies['construction-robotics'].researched = true
  force.technologies['combat-robotics'].researched = true
  force.technologies['combat-robotics-2'].researched = true
  force.technologies['combat-robotics-3'].researched = true
  force.technologies['discharge-defense-equipment'].researched = true

  force.recipes['tank'].enabled = false
  force.recipes['shotgun-shell'].enabled = false
  force.recipes['piercing-shotgun-shell'].enabled = false
  force.recipes['combat-shotgun'].enabled = false
  force.recipes['shotgun'].enabled = false
  force.recipes['flamethrower'].enabled = false
  force.recipes['flamethrower-turret'].enabled = false
  force.recipes['logistic-chest-passive-provider'].enabled = false
  force.recipes['logistic-chest-storage'].enabled = false
  force.recipes['roboport'].enabled = false
  force.recipes['discharge-defense-equipment'].enabled = false

  --force.enable_all_recipes() --테스트 용
  --force.enable_all_technologies() --테스트 용
end

return Block_recipes