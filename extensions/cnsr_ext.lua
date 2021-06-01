--[[----------------------------------------
"cnsr_ext.lua" > Put this VLC Extension Lua script file in \lua\extensions\ folder
--------------------------------------------
Requires "cnsr_intf.lua" > Put the VLC Interface Lua script file in \lua\intf\ folder

Simple instructions:
1) "cnsr_ext.lua" > Copy the VLC Extension Lua script file into \lua\extensions\ folder;
2) "cnsr_intf.lua" > Copy the VLC Interface Lua script file into \lua\intf\ folder;
3) Start the Extension in VLC menu "View > Time v3.x (intf)" on Windows/Linux or "Vlc > Extensions > Time v3.x (intf)" on Mac and configure the Time interface to your liking.

Alternative activation of the Interface script:
* The Interface script can be activated from the CLI (batch script or desktop shortcut icon):
vlc.exe --extraintf=luaintf --lua-intf=cnsr_intf
* VLC preferences for automatic activation of the Interface script:
Tools > Preferences > Show settings=All > Interface >
> Main interfaces: Extra interface modules [luaintf]
> Main interfaces > Lua: Lua interface [cnsr_intf]

INSTALLATION directory (\lua\extensions\):
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\VLC\lua\extensions\
* Linux (all users): /usr/lib/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/
* Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua/extensions/
Create directory if it does not exist!
--]]----------------------------------------
-- TODO: timer/reminder/alarm; multiple time format inputs for different positions (1-9);

config={}
cfg={}
dropdowns = {}
SHOW = 1
SKIP = 2
MUTE = 3
HIDE = 4
intf_script = "cnsr_intf" -- Location: \lua\intf\cnsr_intf.lualocal dlg = nil
local dlg = nil

--add epilepsy category
categories = {[1] = {description = "violence", censor=2},
			[2] = {description = "verbal abuse", censor=2},
			[3] =  {description = "nudity", censor=2},
			[4] =  {description = "alcohol and drug consumption", censor=2}}
-- defaults

function descriptor()
    return { title = "cnsr" ;
             version = "0.1" ;
             author = "EEO" ;
             capabilities = {"menu", "input-listener"};
			 url =  "https://github.com/ophirhan/cnsr-vlc-viewer-addon"}
	
end


function activate()
	os.setlocale("C", "all") -- just in case
	Get_config()
	if config and config.CNSR then
		cfg = config.CNSR
	end
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
	if not ti or VLC_luaintf~=intf_script then
		trigger_menu(3)
	else
		trigger_menu(1)
	end
end


function trigger_menu(dlg_id)
	if dlg_id == 1 then
		if dlg then dlg:delete() end
		show_category_selection()
	elseif dlg_id == 2 then
		if dlg then dlg:delete() end
		load_cnsr_file()
	elseif dlg_id==3 then -- Settings
		if dlg then dlg:delete() end
		create_dialog_S() --configure inteface script to start when VLC starts
	end
end

options = {"Show", "Skip", "Mute", "Hide"}

function show_category_selection()
	close_dlg()
	dlg = vlc.dialog("Category selection")
	local pos = 2
	for i,v in ipairs(categories) do
		dlg:add_label(v.description, 3,pos,3,3)
		dropdowns[v.description] = dlg:add_dropdown(6,pos,3,3)
		for j,w in ipairs(options) do
			dropdowns[v.description]:add_value(w, j)
		end
		pos = pos + 3
	end
	button_apply = dlg:add_button("apply categories to censor",click_play, 4, pos, 3, 3)
    dlg:show()
end


function click_play()
	for i,v in ipairs(categories) do
		v.censor = dropdowns[v.description]:get_value()
	end
	
	close_dlg() --add option to reopen dialog and reload tags according to new filters
	load_cnsr_file()
end

function load_cnsr_file()
	cfg.tags = {}
	if vlc.input.item() == nil then
		Set_config(cfg, "CNSR")
		return
	end
	local uri = vlc.input.item():uri()
	uri = vlc.strings.decode_uri(uri)
	local uri_sans_extension = strip_extension(uri)
	local cnsr_uri = uri_sans_extension .. "cnsr"
	
	local cnsr_file = io.open(cnsr_uri,"r")
	if cnsr_file == nil then
		vlc.osd.message("Failed to load cnsr file", nil, "bottom-right")
		return
	end
	io.input(cnsr_file)
	prev_skip_to = 0
	open_tag = nil
	for line in io.lines() do
		line = string.gsub(line," ","")
		local times, typ = string.match(line,"([^;]+);([^;]+)") -- maybe use find and sub instead of slow regex
		typ = tonumber(typ)
		local action = categories[typ].censor
		if action ~= SHOW then -- only include tags to mute or skip
			local start_time, end_time = string.match(times,"([^-]+)-([^-]+)")
			end_us = hms_ms_to_us(end_time)
			if end_us > prev_skip_to then --only include tags that won't be entirely skipped by previous tag
				start_us = hms_ms_to_us(start_time)
				if open_tag ~= nil then
					if open_tag.end_time > start_us then --  if colliding cut open tag short
						open_tag_end = open_tag.end_time
						open_tag.end_time = start_us 
						table.insert(cfg.tags, open_tag)

						if open_tag_end > end_us then -- keep if there is a remainder of mute after current tag
							--open_tag = table.clone(open_tag) -- same catogry and action
							remainder_tag = {}
							remainder_tag.action = open_tag.action
							remainder_tag.category = open_tag.category
							remainder_tag.start_time = end_us
							remainder_tag.end_time = open_tag_end
							open_tag = remainder_tag
							
							if action ~= open_tag.action then --open_tag.action is MUTE or HIDE
								action = SKIP --skip if action is skip or is different than open_tag action
							end
						else --open_tag partly collides with current tag
							if action ~= SKIP and action ~= open_tag.action then
								collision_tag = {}
								collision_tag.action = SKIP
								collision_tag.category = typ --should be typ and open_tag.category
								collision_tag.start_time = start_us
								collision_tag.end_time = open_tag_end
								table.insert(cfg.tags, collision_tag)
								start_us = open_tag_end
							end
							open_tag = nil
						end
					else
						table.insert(cfg.tags, open_tag)
					end
				end
				tag = {}
				tag.start_time = math.max(start_us, prev_skip_to)
				tag.end_time = end_us
				tag.category = typ
				tag.action = action
				if action == SKIP then
					table.insert(cfg.tags, tag)
					prev_skip_to = end_us
				else -- action == MUTE or HIDE
					if open_tag == nil or tag.end_time > open_tag.end_time then
						open_tag = tag
					end
				end
			end
		end
	end
	if open_tag ~= nil then
		table.insert(cfg.tags, open_tag)
	end

	io.close(cnsr_file)
	for i, v in ipairs(cfg.tags) do
		Log("start: " .. tostring(v.start_time/1000000))
		Log("end: " .. tostring(v.end_time/1000000))
		Log("description: " .. tostring(categories[v.category].description))
		Log("action: " .. tostring(options[v.action]))
	end
	cnsr_file = nil
	collectgarbage()
	Set_config(cfg, "CNSR")
end


function hms_ms_to_us(time_string) -- microseconds
		hms , ms = string.match(time_string, "([^,]+),([^,]+)") -- maybe use find and sub instead of slow regex
		h, m ,s = string.match(hms, "([^:]+):([^:]+):([^:]+)")
		return (tonumber(h)*3600000 + tonumber(m)*60000 + tonumber(s)*1000 + tonumber(ms)) * 1000
end

function create_dialog_S()
	dlg = vlc.dialog(descriptor().title .. " > SETTINGS")
	cb_extraintf = dlg:add_check_box("Enable interface: ", true,1,1,1,1)
	ti_luaintf = dlg:add_text_input(intf_script,2,1,2,1)
	dlg:add_button("SAVE!", click_SAVE_settings,1,2,1,1)
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
	lb_message = dlg:add_label("Current status: " .. (ti and "ENABLED" or "DISABLED") .. " " .. tostring(VLC_luaintf),1,3,3,1)
end



function click_SAVE_settings()
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()

	if cb_extraintf:get_checked() then
		if not ti then table.insert(t, "luaintf") end
		vlc.config.set("lua-intf", ti_luaintf:get_text())
	else
		if ti then table.remove(t, ti) end
	end
	vlc.config.set("extraintf", table.concat(t, ":"))

	lb_message:set_text("Please restart VLC for changes to take effect!")
end


function deactivate()
	--if dlg then
	--	dlg:hide()
	--end
end

function close()
	vlc.deactivate()
end


function menu()
	return {"Modify censor categories", "Retry loading cnsr file"}
end

function close_dlg()
  if dlg ~= nil then
    dlg:hide() 
  end
  
  dlg = nil
  collectgarbage() --~ !important	
end



function input_changed()
	load_cnsr_file()
end


function Log(lm)
	vlc.msg.info("[cnsr_ext] " .. lm)
end
-----------------------------------------

--------------------



function strip_extension(uri)
	uri = string.sub(uri,9)
	i = string.find(uri, ".[^.]*$")
	return string.sub(uri, 0, i)
end

-----------------------------------------



function Get_config()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^config={.*}$") then s = "config={}" end
	assert(loadstring(s))() -- global var
end

function Set_config(cfg_table, cfg_title)
	if not cfg_table then cfg_table={} end
	if not cfg_title then cfg_title=descriptor().title end
	Get_config()
	config[cfg_title]=cfg_table
	vlc.config.set("bookmark10", "config="..Serialize(config))
end

function Serialize(t)
	if type(t)=="table" then
		local s='{'
		for k,v in pairs(t) do
			if type(k)~='number' then k='"'..k..'"' end
			s = s..'['..k..']='..Serialize(v)..',' -- recursion
		end
		return s..'}'
	elseif type(t)=="string" then
		return string.format("%q", t)
	else --if type(t)=="boolean" or type(t)=="number" then
		return tostring(t)
	end
end

function SplitString(s, d) -- string, delimiter pattern
	local t={}
	local i=1
	local ss, j, k
	local b=false
	while true do
		j,k = string.find(s,d,i)
		if j then
			ss=string.sub(s,i,j-1)
			i=k+1
		else
			ss=string.sub(s,i)
			b=true
		end
		table.insert(t, ss)
		if b then break end
	end
	return t
end

function VLC_intf_settings()
	local VLC_extraintf = vlc.config.get("extraintf") -- enabled VLC interfaces
	local VLC_luaintf = vlc.config.get("lua-intf") -- Lua Interface script name
	local t={}
	local ti=false
	if VLC_extraintf then
		t=SplitString(VLC_extraintf, ":")
		for i,v in ipairs(t) do
			if v=="luaintf" then
				ti=i
				break
			end
		end
	end
	return VLC_extraintf, VLC_luaintf, t, ti
end


--TODOs:

	--Investigate saving/loading configurations to/from a file.

	--Add mute support.

	--Lua README titles to explore: "Objects" (player, libvlc, vout), "Renderer discovery"

	--Fix readme