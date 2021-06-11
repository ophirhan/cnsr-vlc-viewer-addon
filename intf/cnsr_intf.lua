
os.setlocale("C", "all") -- fixes numeric locale issue on Mac

config={}
SHOW = 1
SKIP = 2
MUTE = 3
HIDE = 4
FRAME_INTERVAL = 30000
SKIP_SAFTEY = 10000
MINIMUM_DISPLAY_TIME = 2000000
--MINIMUM_DISPLAY_TIME = 0


DESCRIPTIONS = { [1] = "violence",
			   [2] = "verbal abuse",
			   [3] =  "nudity",
			   [4] =  "alcohol and drug consumption"}


tags = {}
tag_index = 1
current_time = 0
prev_time = 0
reverse = false

mute = {}
mute.start_time = 0
mute.end_time = 0
mute.activated = false
mute.prev_volume = vlc.volume.get()

hide = {}
hide.start_time = 0
hide.end_time = 0
hide.activated = false





function Looper()
	next_loop_time = vlc.misc.mdate()
	while true do

		if vlc.volume.get() == -256 then break end  -- inspired by syncplay.lua; kills vlc.exe process in Task Manager
		Get_config()
		if vlc.playlist.status()~="stopped" and config.CNSR and config.CNSR.tags and #config.CNSR.tags ~= 0 then -- no input or stopped input
			tags = config.CNSR.tags

			input = vlc.object.input()
			current_time = vlc.var.get(input,"time")
			check_disable_actions(current_time)
			reverse = prev_time > current_time
			tag = get_current_tag()

			if (current_time > tag.start_time and current_time < tag.end_time) then -- maybe add slider leading to skip?
				if tag.action == SKIP then
					skip(tag.start_time, tag.end_time)
					--vlc.osd.message("skipped " .. CATEGORIES[tag.category], nil, "bottom-right") --what about collisions? add how many seconds were skipped?
					display_reason("skipped", tag.category, tag.end_time)
				elseif tag.action == MUTE then
					execute_tag(tag, mute)
					--vlc.osd.message("muted " .. CATEGORIES[tag.category], nil, "bottom-right")
					display_reason("muted", tag.category, tag.end_time)

				elseif tag.action == HIDE then
					execute_tag(tag, hide)
					--vlc.osd.message("hidden " .. CATEGORIES[tag.category], nil, "bottom-right")
					display_reason("hidden", tag.category, tag.end_time)
				end
			end
			prev_time = current_time
		end
		next_loop_time = next_loop_time + FRAME_INTERVAL
		vlc.misc.mwait(next_loop_time) --us. optional, optimally once every frame, something like vlc.var.get(config.CNSR.input, "framerate")?
	end
end

function display_reason(reason_string, category, tag_end)
	if tag_end - current_time > MINIMUM_DISPLAY_TIME and not reverse then
		vlc.osd.message(reason_string .. " " .. DESCRIPTIONS[category], nil, "bottom-right")
	end
end

function check_disable_actions(current_time)
	if mute.activated and (current_time > mute.end_time or current_time < mute.start_time) then
		vlc.volume.set(mute.prev_volume)
		mute.activated = false
	end

	if hide.activated and (current_time > hide.end_time or current_time < hide.start_time) then
		vlc.var.set(o, "video-filter", "")
		hide.activated = false
	end
end

function skip(skip_start, skip_end)
	--local time_delta = current_time - prev_time
	if not reverse then
		vlc.var.set(input,"time", skip_end + SKIP_SAFTEY)
	else -- we went back in time, cut the duration of skip tag from timeline
		skip_length = skip_end - skip_start
		vlc.var.set(input,"time", math.max(current_time - skip_length, 0))
	end
end

function get_current_tag()
	--[[
     relevant_tags = #[tag where (current_time < tag.end_time) in tags]
     relevant_tags_after_index = (#config.CNSR.tags - tag_index)
     while relevant_tags_after_index < relevant_tags do
         tag_index = tag_index - 1
         if tags[tag_index].end_time > current_time then
                relevant_tags_after_index = relevant_tags_after_index + 1
            end
     end--]]
	if reverse then
		tag_index = 1
	end


	while tag_index < #tags and current_time > tags[tag_index].end_time do
		tag_index = tag_index + 1
	end
	return tags[tag_index]
end

function check_collisions()
	if hide.activated and mute.activated then
		local skip_end = math.min(mute.end_time, hide.end_time)
		vlc.var.set(input,"time", skip_end + SKIP_SAFTEY)
	end
end

function execute_tag(tag, action_params)

	if not action_params.activated then
		action_params.start_time = tag.start_time
		action_params.end_time = tag.end_time
		action_params.activated = true
		if tag.action == MUTE then
			hide.prev_volume = vlc.volume.get()
			vlc.volume.set(0)
		elseif tag.action == HIDE then
			o = vlc.object.vout()
			vlc.var.create(o, "contrast", 0)
			vlc.var.set(o, "video-filter", "adjust")
		end
		check_collisions()
	else
		action_params.end_time = math.max(action_params.end_time, tag.end_time)
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