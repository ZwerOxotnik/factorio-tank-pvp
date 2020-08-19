return function(event, filters)
  local last_event_filter = script.get_event_filter(event)
  if not last_event_filter then last_event_filter = {} end
  local new_event_filter = filters
  if not filters then
    error('filter table not specified')
    return
  end
  local ii = 0
  for i = #last_event_filter + 1, #last_event_filter + #new_event_filter do
    ii = ii + 1
    last_event_filter[i] = new_event_filter[ii]
  end
  script.set_event_filter(event, last_event_filter)
end