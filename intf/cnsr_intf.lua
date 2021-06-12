
os.setlocale("C", "all") -- fixes numeric locale issue on Mac

config={}
SHOW = 1
SKIP = 2
MUTE = 3
HIDE = 4
FRAME_INTERVAL = 30000
SKIP_SAFETY = 10000
MINIMUM_DISPLAY_TIME = 2000000
GET_CONFIG_INTERVAL = 500


DESCRIPTIONS = { [1] = "violence",
			   [2] = "verbal abuse",
			   [3] =  "nudity",
			   [4] =  "alcohol and drug consumption"}


tags = {}
tag_index = 1
current_time = 0
prev_time = 0
loop_counter = 0
reverse = false
done = false

mute_params = {}
mute_params.start_time = 0
mute_params.end_time = 0
mute_params.activated = false
mute_params.prev_volume = vlc.volume.get()
mute_params.action_word = "muted"

function mute()
	mute_params.prev_volume = vlc.volume.get()
	vlc.volume.set(0)
end

mute_params.activate = mute

hide_params = {}
hide_params.start_time = 0
hide_params.end_time = 0
hide_params.activated = false
hide_params.action_word = "hidden"

function hide()
	hide_filter = vlc.object.vout()
	vlc.var.create(hide_filter, "contrast", 0)
	vlc.var.set(hide_filter, "video-filter", "adjust")
end

hide_params.activate = hide



function Looper()
	next_loop_time = vlc.misc.mdate()
	while true do
		if vlc.volume.get() == -256 then break end  -- inspired by syncplay.lua; kills vlc.exe process in Task Manager
		if loop_counter == 0 then
			Get_config() -- We don't want to call it more then we have to.
			Log("got config")
		end
		loop_counter = (loop_counter + 1) % GET_CONFIG_INTERVAL
		if vlc.playlist.status()~="stopped" and config.CNSR and config.CNSR.tags and #config.CNSR.tags ~= 0 then
			tags = config.CNSR.tags

			input = vlc.object.input()
			current_time = vlc.var.get(input,"time")
			check_disable_actions()
			reverse = prev_time > current_time
			tag = get_current_tag()

			while not done and current_time > tag.start_time do
				if current_time < tag.end_time and tag.action ~= SHOW then
					execute_tag(tag)
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
	if mute_params.activated and (current_time > mute_params.end_time or current_time < mute_params.start_time) then
		vlc.volume.set(mute_params.prev_volume)
		mute_params.activated = false
	end

	if hide_params.activated and (current_time > hide_params.end_time or current_time < hide_params.start_time) then
		vlc.var.set(hide_filter, "video-filter", "")
		hide_params.activated = false
	end
end

function skip(skip_start, skip_end)
	if not reverse then
		current_time = skip_end + SKIP_SAFETY
	else -- we went back in time, cut the duration of skip tag from timeline
		skip_length = skip_end - skip_start
		current_time = math.max(current_time - skip_length, 0)
	end
	vlc.var.set(input,"time", current_time)
end

function get_current_tag()
	--[[
	if reverse then
		relevant_tags = #[tag where (current_time < tag.end_time) in tags] -> sort tags by end time once-> binary search starting at tag_index
		relevant_tags_after_index = (#config.CNSR.tags - tag_index)
		while relevant_tags_after_index < relevant_tags do
			tag_index = tag_index - 1
			if tags[tag_index].end_time > current_time then
				relevant_tags_after_index = relevant_tags_after_index + 1
			end
		end
		done = false
	end
     --]]
	if reverse then
		tag_index = 1
		done = false
	end


	while tag_index < #tags and current_time > tags[tag_index].end_time do
		tag_index = tag_index + 1
	end
	return tags[tag_index]
end

function check_collision()
	if hide_params.activated and mute_params.activated then
		local skip_end = math.min(mute_params.end_time, hide_params.end_time)
		local skip_start = math.max(mute_params.start_time, hide_params.start_time)
		skip(skip_start, skip_end)
	end
end

function execute_tag(tag)

	if tag.action == SKIP then
		skip(tag.start_time, tag.end_time)
		display_reason("skipped", tag.category, tag.end_time) --add how many seconds were skipped?
	else
		if tag.action == MUTE then
			action_params = mute_params
		elseif tag.action == HIDE then
			action_params = hide_params
		else
			vlc.msg.err("unknown action")
		end

		if not action_params.activated then
			action_params.start_time = tag.start_time
			action_params.end_time = tag.end_time
			action_params.activated = true
			action_params.activate()
			check_collision()
		else
			action_params.end_time = math.max(action_params.end_time, tag.end_time)
		end
		display_reason(action_params.action_word, tag.category, tag.end_time)
	end
end

function Log(lm)
	vlc.msg.info("[cnsr_intf] " .. lm)
end

function Get_config()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^config={.*}$") then s = "config={}" end
	assert(loadstring(s))() -- global var
end


Looper() --starter