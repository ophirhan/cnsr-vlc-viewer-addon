json = require ('dkjson')
Memory = require ('cnsr_memory')
os.setlocale("C", "all") -- fixes numeric locale issue on Mac

function protect(tbl)
	return setmetatable({}, {
		__index = tbl,
		__newindex = function(t, key, value)
			error("attempting to change constant " ..
					tostring(key) .. " to " .. tostring(value), 2)
		end
	})
end

constants = {
	MS_IN_SEC =1000000,
	SKIP=2,
	FRAME_INTERVAL = 30000,
	SKIP_SAFETY = 10000,
	MINIMUM_DISPLAY_TIME = 2000000,
	GET_CONFIG_INTERVAL = 500,
	DESCRIPTIONS = { [1] = "violence",
					 [2] = "verbal abuse",
					 [3] =  "nudity",
					 [4] =  "alcohol and drug consumption"}
}
-- constants
config={}
constants = protect(constants)
-- end constants

-- globals
tag_index = 1
tag_by_end_time_index = 1
current_time = 0
prev_time = 0
forward = false
SKIP=2
input = nil
actions = {}
-- end globals

--[[
this function does nothing.
used for SHOW action
--]]
function nothing()
end


--[[
action: one of SHOW, HIDE, MUTE, SKIP
this function checks if the action is no longer relevant(passed it or )
--]]
function check_deactivate(action)
	if action.activated and (current_time > action.end_time or current_time < action.start_time) then
		action.deactivate()
		action.activated = false
	end
end

--[[
action: one of SHOW, HIDE, MUTE, SKIP
tag: current relevant tag
this function checks if the action is activated.
if it is it updates its end time as the tag's ending time
else it activates it
--]]
function check_activate(action, tag)
	if action.activated then
		action.end_time = math.max(action.end_time, tag.end_time)
	else
		action.start_time = tag.start_time
		action.end_time = tag.end_time
		action.activated = true
		action.activate()
	end
	display_reason(action.action_word, tag.category, tag.end_time)
end

--[[
this function checks if both MUTE tag and HIDE tag are activated at the same time
and if they do, the tag becomes SKIP tag
--]]
function check_collision()
	if actions.hide.activated and actions.mute.activated then
		local skip_end = math.min(actions.mute.end_time, actions.hide.end_time)
		local skip_start = math.max(actions.mute.start_time, actions.hide.start_time)
		skip(skip_start, skip_end)
	end
end

--[[
SHOW handling starts here
--]]
actions.show = { execute= nothing, update= nothing }

table.insert(actions, actions.show) --1
-- end show

--[[
SKIP handling starts here
--]]
actions.skip = {}

function actions.skip.execute(tag)
	skip(tag.start_time, tag.end_time)
	display_reason("skipped", tag.category, tag.end_time)
end

actions.skip.update = nothing;

table.insert(actions, actions.skip) --2
-- end skip

--[[
MUTE handling starts here
--]]
actions.mute = { activated = false, action_word = "muted" }

actions.mute.execute= function(tag)	check_activate(actions.mute, tag) end

actions.mute.update= function() check_deactivate(actions.mute) end

function actions.mute.activate()
	actions.mute.prev_volume = vlc.volume.get()
	vlc.volume.set(0)
	check_collision()
end

actions.mute.deactivate= function() vlc.volume.set(actions.mute.prev_volume) end
table.insert(actions, actions.mute) --3
-- end mute


--[[
HIDE handling starts here
--]]
actions.hide = { activated = false, action_word = "hidden" }

actions.hide.execute= function(tag) check_activate(actions.hide, tag) end

actions.hide.update= function() check_deactivate(actions.hide) end

function actions.hide.activate()
	actions.hide.hide_filter = vlc.object.vout()
	vlc.var.create(actions.hide.hide_filter, "contrast", 0)
	vlc.var.create(actions.hide.hide_filter, "brightness", 0)
	vlc.var.create(actions.hide.hide_filter, "saturation", 0)
	vlc.var.create(actions.hide.hide_filter, "gamma", 0)
	vlc.var.set(actions.hide.hide_filter, "video-filter", "adjust")
	check_collision()
end

actions.hide.deactivate= function() vlc.var.set(actions.hide.hide_filter, "video-filter", "") end

table.insert(actions, actions.hide) --4
-- end hide

--[[
this function is the main and most important function.
it runs all the time in the background of VLC, finds the relevant tag and execute it.
--]]
function looper()
	local next_loop_time = vlc.misc.mdate()
	while true do
		if vlc.volume.get() == -256 then break end  -- inspired by syncplay.lua; kills vlc.exe process in Task Manager
		if Memory.get_written() then -- config invocation callback
			get_config()
			tag_index = 1
			tag_by_end_time_index = 1
		end
		if vlc.playlist.status()~="stopped" and config.CNSR and config.CNSR.tags then
			local tags = config.CNSR.tags
			local tags_by_end_time = config.CNSR.tags_by_end_time

			input = vlc.object.input()
			current_time = vlc.var.get(input,"time")
			update_actions()
			local tag = get_current_tag(tags, tags_by_end_time)

			while tag and current_time > tag.start_time do
				actions[tag.action].execute(tag)
				tag = get_current_tag(tags, tags_by_end_time, tag) --if we skipped back we need to rewind the index
			end
			prev_time = current_time
		end
		next_loop_time = next_loop_time + FRAME_INTERVAL
		vlc.misc.mwait(next_loop_time) --us. optional, optimally once every frame, something like vlc.var.get(input, "fps")?
	end
end

--[[
this function goes over all actions and calls their update function
--]]
function update_actions()
	for _, action in ipairs(actions) do
		action.update()
	end
end

--[[
reason string: message info
category: A category
tag_end: ending time of the tag
this function shows the user the reason for the skip and the category that caused it.
--]]
function display_reason(reason_string, category, tag_end)
	if tag_end - current_time > MINIMUM_DISPLAY_TIME and forward then
		vlc.osd.message(reason_string .. " " .. DESCRIPTIONS[category], nil, "bottom-right")
	end
end

--[[
skip_start: the starting time of skip tag
skip_end: the ending time of skip tag
this function does the logic for skipping in the video.
--]]
function skip(skip_start, skip_end)
	prev_time = current_time
	if forward then
		current_time = math.min(skip_end + SKIP_SAFETY, vlc.input.item():duration() * MS_IN_SEC) --think if we want to!
	else -- we went back in time, cut the duration of skip tag from timeline
		current_time = math.max(skip_start- MS_IN_SEC*5, 0)
	end
	update_actions()
	vlc.var.set(input,"time", current_time)
end

--[[
tags_by_end_time: all the tags ordered by ending time
this function finds the number of tags that are still relevant (didn't pass them)
--]]
function get_num_relevant_tags(tags_by_end_time)
	while tag_by_end_time_index > 1 and current_time < tags_by_end_time[tag_by_end_time_index - 1].end_time do
		tag_by_end_time_index = tag_by_end_time_index - 1
	end

	while tags_by_end_time[tag_by_end_time_index] and current_time > tags_by_end_time[tag_by_end_time_index].end_time do
		tag_by_end_time_index = tag_by_end_time_index + 1
	end

	relevant_tags = #tags_by_end_time - tag_by_end_time_index + 1

	return relevant_tags
end


--[[
tags_by_end_time: all the tags ordered by ending time
tags: all the tags sorted by starting time
this function finds the next relevant tag (the next tag that should be executed)
--]]
function get_current_tag(tags, tags_by_end_time, prev_tag)
	forward = prev_time <= current_time
	if prev_tag and prev_tag.action ~= SKIP then
		tag_index = tag_index + 1
	elseif forward then
		while tags[tag_index] and current_time > tags[tag_index].end_time do
			tag_index = tag_index + 1
		end
	else
		relevant_tags = get_num_relevant_tags(tags_by_end_time) --#(tags where current_time < tag.end_time)

		relevant_tags_after_index = #tags - tag_index + 1
		while relevant_tags_after_index < relevant_tags do
			tag_index = tag_index - 1
			if current_time < tags[tag_index].end_time  then
				relevant_tags_after_index = relevant_tags_after_index + 1
			end
		end
	end
	return tags[tag_index]
end

--[[
this function writes logs to console
--]]
function log(str,num)
	if num then str = str .. " " .. tostring(num) end
	vlc.msg.info("[cnsr_intf] " .. str)
end

--[[
this function reads configs from a file and sets the config parameter
--]]
function get_config()
	config = json.decode(Memory.get_config_string())

	if config.CNSR == nil then
		config.CNSR = {}
	end

	if config.CNSR.tags == nil then
		config.CNSR.tags = {}
	end

	if config.CNSR.tags_by_end_time  == nil then
		config.CNSR.tags_by_end_time  = {}
	end
end

looper() -- starter
