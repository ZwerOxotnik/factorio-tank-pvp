local Chat = {}

Chat.on_console_chat = function(event)
	if not event.message then return end
	if not event.player_index then return end
  local player = game.get_player(event.player_index)
  if not player then return end

  local force = player.force
  local color = player.chat_color
  local tag = player.tag
  if tag then tag = ' ' .. tag end

  --다른 세력에게도 채팅을 보여주기
  if force == game.forces[4] then return end
  if force == game.forces[5] then return end
  for _, otherforce in pairs(game.forces) do
    if otherforce ~= force then
      otherforce.print(player.name .. tag .. " : " .. event.message, color)
    end
  end

end

return Chat