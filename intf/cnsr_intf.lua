
os.setlocale("C", "all") -- fixes numeric locale issue on Mac

-- constants
config={}
SHOW = 1
SKIP = 2
MUTE = 3
HIDE = 4
FRAME_INTERVAL = 30000
SKIP_SAFETY = 10000
MINIMUM_DISPLAY_TIME = 2000000
GET_CONFIG_INTERVAL = 500
-- end constants


DESCRIPTIONS = { [1] = "violence",
				 [2] = "verbal abuse",
				 [3] =  "nudity",
				 [4] =  "alcohol and drug consumption"}

-- globals
tag_index = 1
tag_by_end_time_index = 1
current_time = 0
prev_time = 0
reverse = false
done = false
-- end globals

-- mute
MuteParams = {
	start_time = 0,
	end_time = 0,
	activated = false,
	prev_volume = vlc.volume.get(),
	action_word = "muted"
}

function MuteParams.activate()
	MuteParams.prev_volume = vlc.volume.get()
	vlc.volume.set(0)
end
-- end mute

-- hide
HideParams = {
	start_time = 0,
	end_time = 0,
	activated = false,
	action_word = "hidden"
}


function HideParams.activate()
	hide_filter = vlc.object.vout()
	vlc.var.create(hide_filter, "contrast", 0)
	vlc.var.set(hide_filter, "video-filter", "adjust")
end
-- end hide

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

			local input = vlc.object.input()
			current_time = vlc.var.get(input,"time")
			check_disable_actions()
			reverse = prev_time > current_time
			local tag = get_current_tag(tags, tags_by_end_time)

			while not done and current_time > tag.start_time do
				if current_time < tag.end_time and tag.action ~= SHOW then
					execute_tag(tag, input)
				end
				done = tag_index == #tags
				if not done then
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

function display_reason(reason_string, category, tag_end)
	if tag_end - current_time > MINIMUM_DISPLAY_TIME and not reverse then
		vlc.osd.message(reason_string .. " " .. DESCRIPTIONS[category], nil, "bottom-right")
	end
end

function check_disable_actions()
	if MuteParams.activated and (current_time > MuteParams.end_time or current_time < MuteParams.start_time) then
		vlc.volume.set(MuteParams.prev_volume)
		MuteParams.activated = false
	end

	if HideParams.activated and (current_time > HideParams.end_time or current_time < HideParams.start_time) then
		vlc.var.set(hide_filter, "video-filter", "")
		HideParams.activated = false
	end
end

function skip(skip_start, skip_end, input)
	if not reverse then -- we went back in time, cut the duration of skip tag from timeline
		current_time = skip_end + SKIP_SAFETY
	else
		local skip_length = skip_end - skip_start
		current_time = math.max(current_time - skip_length, SKIP_SAFETY)
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
		log("relevant tags" .. tostring(relevant_tags))

		relevant_tags_after_index = #tags - tag_index
		if current_time < tags[tag_index].end_time  then
			relevant_tags_after_index = relevant_tags_after_index + 1
		end
		log("relevant_tags_after_index before loop" .. tostring(relevant_tags_after_index))
		while relevant_tags_after_index < relevant_tags do
			tag_index = tag_index - 1
			if current_time < tags[tag_index].end_time  then
				relevant_tags_after_index = relevant_tags_after_index + 1
			end
		end
		log("after reverse" .. tostring(tag_index))
		done = false
	end
	while tag_index < #tags and current_time > tags[tag_index].end_time do
		tag_index = tag_index + 1
	end
	return tags[tag_index]
end

function check_collision(input)
	if HideParams.activated and MuteParams.activated then
		local skip_end = math.min(MuteParams.end_time, HideParams.end_time)
		local skip_start = math.max(MuteParams.start_time, HideParams.start_time)
		skip(skip_start, skip_end, input)
	end
end

function execute_tag(tag, input)
	local action_params
	if tag.action == SKIP then
		skip(tag.start_time, tag.end_time, input)
		display_reason("skipped", tag.category, tag.end_time) --add how many seconds were skipped?
	else
		if tag.action == MUTE then
			action_params = MuteParams
		elseif tag.action == HIDE then
			action_params = HideParams
		else
			vlc.msg.err("unknown action")
		end

		if not action_params.activated then
			action_params.start_time = tag.start_time
			action_params.end_time = tag.end_time
			action_params.activated = true
			action_params.activate()
			check_collision(input)
		else
			action_params.end_time = math.max(action_params.end_time, tag.end_time)
		end
		display_reason(action_params.action_word, tag.category, tag.end_time)
	end
end

function log(lm)
	vlc.msg.info("[cnsr_intf] " .. lm)
end

function get_config()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^config={.*}$") then s = "config={}" end
	assert(loadstring(s))()  -- global var
end


looper() -- starter