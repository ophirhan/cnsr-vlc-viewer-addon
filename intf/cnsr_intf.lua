--[[----- cnsr v3.2 ------------------------
"cnsr_intf.lua" > Put this VLC Interface Lua script file in \lua\intf\ folder
--------------------------------------------
Requires "cnsr_ext.lua" > Put the VLC Extension Lua script file in \lua\extensions\ folder

Simple instructions:
1) "cnsr_ext.lua" > Copy the VLC Extension Lua script file into \lua\extensions\ folder;
2) "cnsr_intf.lua" > Copy the VLC Interface Lua script file into \lua\intf\ folder;
3) Start the Extension in VLC menu "View > cnsr v3.x (intf)" on Windows/Linux or "Vlc > Extensions > cnsr v3.x (intf)" on Mac and configure the cnsr interface to your liking.

Alternative activation of the Interface script:
* The Interface script can be activated from the CLI (batch script or desktop shortcut icon):
vlc.exe --extraintf=luaintf --lua-intf=cnsr_intf
* VLC preferences for automatic activation of the Interface script:
Tools > Preferences > Show settings=All > Interface >
> Main interfaces: Extra interface modules [luaintf]
> Main interfaces > Lua: Lua interface [cnsr_intf]

INSTALLATION directory (\lua\intf\):
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\intf\
* Windows (current user): %APPDATA%\VLC\lua\intf\
* Linux (all users): /usr/lib/vlc/lua/intf/
* Linux (current user): ~/.local/share/vlc/lua/intf/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/intf/
* Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua/intf/
Create directory if it does not exist!
--]]----------------------------------------

os.setlocale("C", "all") -- fixes numeric locale issue on Mac

config={}
SHOW = 1
SKIP = 2
MUTE = 3
HIDE = 4


categories = {[1] = "violence",
			[2] = "verbal abuse",
			[3] =  "nudity",
			[4] =  "alcohol and drug consumption"}

function Looper()
	tag_index = 1
	mute_start = 0
	mute_end = 0
	hide_start = 0
	hide_end = 0
	hide = false
	vol = vlc.volume.get()
	


	while true do
		if vlc.volume.get() == -256 then break end  -- inspired by syncplay.lua; kills vlc.exe process in Task Manager
		loop_start_time = vlc.misc.mdate()
		Get_config()
		new_vol = vlc.volume.get()
		if new_vol ~=  0 then
			vol = new_vol
		end
		if vlc.playlist.status()~="stopped" and config.CNSR and config.CNSR.tags and #config.CNSR.tags ~= 0 then -- no input or stopped input

			--find right tag_index
			--current_time = vlc.var.get(config.CNSR.input,"time")
			current_time = vlc.var.get(vlc.object.input(),"time")
			
			while tag_index > 1 and current_time < config.CNSR.tags[tag_index-1].end_time do --while current_time < previous tag end time
				tag_index = tag_index - 1
			end
			
			
			while tag_index < #config.CNSR.tags and current_time > config.CNSR.tags[tag_index].end_time do --while current_time > current tag end time?
				tag_index = tag_index + 1 --both while loops not thought out, what about collisions, maybe sort by end time?
			end
			
			local tag_start = config.CNSR.tags[tag_index].start_time
			local end_time = config.CNSR.tags[tag_index].end_time
			local category = config.CNSR.tags[tag_index].category
			local action = config.CNSR.tags[tag_index].action
			
			if current_time > mute_end and mute_end ~= 0 then
				vlc.volume.set(vol)
				mute_end = 0
				mute_start = 0
			end
			if current_time < mute_start then
				vlc.volume.set(vol)
				mute_start = 0
				mute_end = 0
			end

			if hide and current_time > hide_end and hide_end ~= 0 then
				hide_end = 0
				hide_start = 0
				hide = false
				vlc.var.set(o, "video-filter", "")
			end
			if current_time < hide_start then
				hide_end = 0
				hide_start = 0
				hide = false
				vlc.var.set(o, "video-filter", "")
			end
			--osd.slider( position, type, [id] ): Display slider. Position is an integer from 0 to 100. Type can be "horizontal" or "vertical".
			if (current_time > tag_start and current_time < end_time) then -- maybe add slider leading to skip?
				if action == SKIP then --skip
					vlc.var.set(vlc.object.input(),"time", end_time + 10000) --add option to mute
					vlc.osd.message("skipped " .. categories[category], nil, "bottom-right") --what about collisions? add how many seconds were skipped?
				elseif action == MUTE then
					if new_vol ~= 0 then
						vlc.volume.set(0)
					end

					vlc.osd.message("muted " .. categories[category], nil, "bottom-right")
					mute_end = math.max(mute_end, end_time)
					mute_start = math.max(mute_start, tag_start)
				else -- action == HIDE
					if not hide then
						o = vlc.object.vout()
						vlc.var.create(o, "contrast", 0)
						vlc.var.set(o, "video-filter", "adjust")
						hide = true
					end

					vlc.osd.message("hidden " .. categories[category], nil, "bottom-right")
					hide_end = math.max(hide_end, end_time)
					hide_start = math.max(mute_start, tag_start)
				end
			end
			
		end
		vlc.misc.mwait(loop_start_time + 30000) --us. optional, optimaly once every frame, something like vlc.var.get(config.CNSR.input, "framerate")?
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