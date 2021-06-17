json = require 'dkjson'
os.setlocale("C", "all") -- fixes numeric locale issue on Mac
-- foo
-- constants
config={}
MS_IN_SEC =1000000
FRAME_INTERVAL = 30000
SKIP_SAFETY = 10000
MINIMUM_DISPLAY_TIME = 2000000
GET_CONFIG_INTERVAL = 500
DESCRIPTIONS = { [1] = "violence",
				 [2] = "verbal abuse",
				 [3] =  "nudity",
				 [4] =  "alcohol and drug consumption"}
-- end constants

-- globals
tag_index = 1
tag_by_end_time_index = 1
current_time = 0
prev_time = 0
reverse = false
done = false
input = nil
actions = {}
-- end globals

function nothing()
end


-- show
actions.show = { execute= nothing, update= nothing }

table.insert(actions, actions.show) --1
-- end show

-- skip
actions.skip = {}

function actions.skip.execute(tag)
	skip(tag.start_time, tag.end_time)
	display_reason("skipped", tag.category, tag.end_time)
end

actions.skip.update = nothing;

table.insert(actions, actions.skip) --2
-- end skip

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

function check_deactivate(action)
	if action.activated and (current_time > action.end_time or current_time < action.start_time) then
		action.deactivate()
		action.activated = false
	end
end

-- mute
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

-- hide
actions.hide = { activated = false, action_word = "hidden" }

actions.hide.execute= function(tag) check_activate(actions.hide, tag) end

actions.hide.update= function() check_deactivate(actions.hide) end

function actions.hide.activate()
	actions.hide.hide_filter = vlc.object.vout()
	vlc.var.create(actions.hide.hide_filter, "contrast", 0)
	vlc.var.set(actions.hide.hide_filter, "video-filter", "adjust")
	check_collision()
end

actions.hide.deactivate= function() vlc.var.set(actions.hide.hide_filter, "video-filter", "") end

table.insert(actions, actions.hide) --4
-- end hide


function check_collision()
	if actions.hide.activated and actions.mute.activated then
		local skip_end = math.min(actions.mute.end_time, actions.hide.end_time)
		local skip_start = math.max(actions.mute.start_time, actions.hide.start_time)
		skip(skip_start, skip_end)
	end
end

-- Main app entry point
function looper()
	local next_loop_time = vlc.misc.mdate()
	local loop_counter = 0
	while true do
		if vlc.volume.get() == -256 then break end  -- inspired by syncplay.lua; kills vlc.exe process in Task Manager
		if loop_counter == 0 then
			get_config() -- We don't want to call it more then we have to.
		end
		loop_counter = (loop_counter + 1) % GET_CONFIG_INTERVAL
		if vlc.playlist.status()~="stopped" and config.CNSR and config.CNSR.tags and #config.CNSR.tags ~= 0 then
			local tags = config.CNSR.tags
			local tags_by_end_time = config.CNSR.tags_by_end_time

			input = vlc.object.input()
			current_time = vlc.var.get(input,"time")
			update_actions()
			reverse = prev_time > current_time
			local tag = get_current_tag(tags, tags_by_end_time)

			while not done and current_time > tag.start_time do
				if current_time < tag.end_time and tag.action ~= SHOW then
					actions[tag.action].execute(tag)
				end
				done = tag_index == #tags
				if not done and current_time>tag.start_time then
					tag_index = tag_index + 1
					tag = tags[tag_index]
				end
			end
			prev_time = current_time
		end
		next_loop_time = next_loop_time + FRAME_INTERVAL
		vlc.misc.mwait(next_loop_time) --us. optional, optimally once every frame, something like vlc.var.get(input, "fps")?
	end
end

function update_actions()
	for _, action in ipairs(actions) do
		action.update()
	end
end

function display_reason(reason_string, category, tag_end)
	if tag_end - current_time > MINIMUM_DISPLAY_TIME and not reverse then
		vlc.osd.message(reason_string .. " " .. DESCRIPTIONS[category], nil, "bottom-right")
	end
end

function skip(skip_start, skip_end)
	local skip_length = skip_end - skip_start
	if reverse then -- we went back in time, cut the duration of skip tag from timeline
		current_time = math.max(current_time - skip_length, 0)
	else
		current_time = math.min(current_time + skip_length + SKIP_SAFETY,vlc.input.item():duration()*MS_IN_SEC) --think if we want to!
	end
	vlc.var.set(input,"time", current_time)
end

function get_num_relevant_tags(tags_by_end_time)
	while tag_by_end_time_index > 1 and current_time < tags_by_end_time[tag_by_end_time_index - 1].end_time do
		tag_by_end_time_index = tag_by_end_time_index - 1
	end

	while tag_by_end_time_index < #tags_by_end_time and current_time > tags_by_end_time[tag_by_end_time_index].end_time do
		tag_by_end_time_index = tag_by_end_time_index + 1
	end

	relevant_tags = #tags_by_end_time - tag_by_end_time_index
	if current_time < tags_by_end_time[#tags_by_end_time].end_time then
		relevant_tags = relevant_tags + 1
	end

	return relevant_tags
end

function get_current_tag(tags, tags_by_end_time)
	if reverse then
		relevant_tags = get_num_relevant_tags(tags_by_end_time) --#(tags where current_time < tag.end_time)

		relevant_tags_after_index = #tags - tag_index
		if current_time < tags[tag_index].end_time  then
			relevant_tags_after_index = relevant_tags_after_index + 1
		end
		while relevant_tags_after_index < relevant_tags do
			tag_index = tag_index - 1
			if current_time < tags[tag_index].end_time  then
				relevant_tags_after_index = relevant_tags_after_index + 1
			end
		end
		done = false
	end
	while tag_index < #tags and current_time > tags[tag_index].end_time do
		tag_index = tag_index + 1
	end
	return tags[tag_index]
end

function log(str,num)
	if num then str = str .. " " .. tostring(num) end
	vlc.msg.info("[cnsr_intf] " .. str)
end


function get_config()
	config = json.decode(vlc.config.get("bookmark10"))
end


looper() -- starter