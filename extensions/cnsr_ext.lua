--some globals:
json = require ("dkjson")
require ("common")
Memory = require ('cnsr_memory')
config={}
cfg={}
dropdowns = {}
age_restriction_dropdown = nil
SHOW = 1
SKIP = 2
MUTE = 3
HIDE = 4
intf_script = "cnsr_intf" -- Location: \lua\intf\cnsr_intf.lualocal dlg = nil
was_playing = false;
local dlg

-- todo: add epilepsy category
CATEGORIES = { [1] = { description = "violence", action=SKIP},
			   [2] = {description = "verbal abuse", action=SKIP},
			   [3] =  {description = "nudity", action=SKIP},
			   [4] =  {description = "alcohol and drug consumption", action=SKIP}}
AGE_RESTRICTIONS = {}
AGE_RESTRICTIONS['G'] = {[1]= {"Skip", "Show", "Mute", "Hide"},[2]= {"Skip", "Show", "Mute", "Hide"},[3]= {"Skip", "Show", "Mute", "Hide"},[4]= {"Skip", "Show", "Mute", "Hide"}}
AGE_RESTRICTIONS['PG13'] = {[1]= {"Skip", "Show", "Mute", "Hide"},[2]= {"Mute", "Show", "Skip", "Hide"},[3]= {"Skip", "Show", "Mute", "Hide"},[4]= {"Hide", "Show", "Mute", "Skip"}}
AGE_RESTRICTIONS['R'] = {[1]= {"Show", "Skip", "Mute", "Hide"},[2]= {"Show", "Skip", "Mute", "Hide"},[3]= {"Hide", "Show", "Mute", "Skip"},[4]= {"Show", "Skip", "Mute", "Hide"}}
AGE_RESTRICTIONS['X'] = {[1]= {"Show", "Skip", "Mute", "Hide"},[2]= {"Show", "Skip", "Mute", "Hide"},[3]={"Show", "Skip", "Mute", "Hide"},[4]= {"Show", "Skip", "Mute", "Hide"}}

ACTION_TO_ID = {}
ACTION_TO_ID['Show'] = 1
ACTION_TO_ID['Skip'] = 2
ACTION_TO_ID['Mute'] = 3
ACTION_TO_ID['Hide'] = 4
-- defaults

--[[
in every extention, a descriptor function is a must.
this function describes the extention
--]]
function descriptor()
	return { title = "cnsr" ;
			 version = "0.1" ;
			 author = "EEO" ;
			 capabilities = {"menu", "input-listener"};
			 url =  "https://github.com/ophirhan/cnsr-vlc-viewer-addon"}
end

--[[
in every extention, an activate function is a must.
this function runs first. it starts the dialog and loads configs.
--]]
function activate()
	os.setlocale("C", "all") -- just in case
	get_config()
	pause_if_needed()
	pass_cfg = json.decode(vlc.config.get("bookmark8") or "")
	-- TODO: dont know what to do with that line
	--if config and config.CNSR then
	--	cfg = config.CNSR
	--end
	Log("activate")
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
	if not ti or VLC_luaintf ~= intf_script or type(pass_cfg) ~= "table" then
		trigger_menu(3)
	else
		trigger_menu(1)
	end
end

--[[
this function pauses the video if the user opened the cnsr menu while the video was playing,
	and updates the global value was_playing in order to act accordingly after closing the menu.
--]]

function pause_if_needed()
	if vlc.playlist.status() == "playing" then
		Log("Paused the video")
		vlc.playlist.pause()
		was_playing = true
	end
end



--[[
dig_id: the id of the wanted dialog
this function opens the wanted dialog based on id.
--]]
function trigger_menu(dlg_id)
	if dlg_id == 1 then
		if dlg then dlg:delete() end
		show_category_selection()
	elseif dlg_id == 2 then
		if dlg then dlg:delete() end
		load_and_set_tags()
	elseif dlg_id==3 then -- Settings
		if dlg then dlg:delete() end
		create_dialog_S() --configure interface script to start when VLC starts
	end
end

-- the user selects the wanted action when censoring is needed
options = {"Show", "Skip", "Mute", "Hide"}

age_options = {'G' , 'PG13', 'R', 'X'}


--[[
this function creates a category dialog(the main dialog)
the dialog contains 4 lists of actions, 4 labels to describe the categories and one "apply" button
--]]
function show_category_selection()
	close_dlg()
	dlg = vlc.dialog("Category selection")
	local y = 1
	local x = 1
	dlg:add_label("age restriction", 1, y, 1, 1)
	dlg:add_button("set by parental guidence", click_restrict_age, x +3, y, 2, 1)
	age_restriction_dropdown = create_drop_down(x-1, y, age_options)

	for idx, value in ipairs(CATEGORIES) do
		dlg:add_label(value.description, 1, y+1, 1, 1)
		dropdowns[idx] = create_drop_down(x, y+1, options)
		y = y + 1
	end
	dlg:add_label("Enter password:",1, y+1, 1, 1)
	text_box = dlg:add_text_input("", 1, y + 2, 1, 1)
	dlg:add_label("Hint: " .. pass_cfg["hint"],1, y + 3, 1, 1)

	dlg:add_label("set offset:",1, y + 4,1,1)

	key = get_memory("offset") or 0
	offset =dlg:add_text_input(tostring(key),1, y + 5,1,1)

	button_apply = dlg:add_button("Apply and save",click_play, x + 1, y + 6, 1, 1)
	pass_status = dlg:add_label('',1, y + 7, 1, 1)
	dlg:show()
	end

--[[
x: row position
y: col position
this function creats a dropdown list of options in location (x,y) and returns it
--]]
function create_drop_down(x, y, dropdown_options)
	local dropdown = dlg:add_dropdown(x + 2, y, 2, 1)
	for idx, word in ipairs(dropdown_options) do
		dropdown:add_value(word, idx)
	end
	return dropdown
end

--[[
when the user taps the "apply" button, insert the wanted actions inside CATEGORIES from the dropdown
close the dialog and call load_and_set_tags(start reading from the cnsr file)
--]]
function click_play()
	for idx, value in ipairs(CATEGORIES) do
		_, action_name = dropdowns[idx]:get_value()
		value.action = ACTION_TO_ID[action_name]
	end
    offset_num = tonumber(tostring(offset:get_text())) or 0
	local check_password = text_box:get_text()
	if check_password == pass_cfg["password"] then
		Log("click play")
		close_dlg()
		play_if_needed()
		load_and_set_tags()
	else
		pass_status:set_text("Invalid password!")
	end
end

--[[
when the user taps the "restrict_age" button, insert the wanted actions inside CATEGORIES from the dropdown
and apply restriction age according to the configuration
--]]
function click_restrict_age()
	_,age = age_restriction_dropdown:get_value()
	x = 1
	y = 2
	for idx, value in ipairs(CATEGORIES) do
		dlg:del_widget(dropdowns[idx])
		dropdowns[idx] = create_drop_down(x, y, AGE_RESTRICTIONS[age][idx])
		y=y+1
	end
	Log("click restrict age")
end


--[[
this function checks wheather we need to resume playing the video after the cnsr menu is closed.
--]]
function play_if_needed()
	if was_playing then
		Log("resumed playing the video")
		vlc.playlist.play()
		was_playing = false
	end
end


--[[
this function gets the uri of the movie and changes it to cnsr_uri
--]]
function get_cnsr_uri()
	if vlc.input.item() == nil then
		return nil
	end
	local uri = vlc.input.item():uri()
	uri = vlc.strings.decode_uri(uri)
	local uri_sans_extension = strip_extension(uri)
	return uri_sans_extension .. "cnsr"
end

--[[
This function prints both to the VLC message and to the log
--]]
function print_to_vlc_and_log(message)
	vlc.osd.message(message, nil, "bottom-right")
	Log(message)
end

--[[
this function is the main parser.
it reads the cnsr file, parse its lines, inserts it into a table and returns it.
--]]
function load_tags_from_file()
	local cnsr_uri = get_cnsr_uri()
	if cnsr_uri == nil then
		return nil
	end
	cnsr_file = vlc.io.open(cnsr_uri,"r")
	if cnsr_file == nil then
		print_to_vlc_and_log("Failed to load cnsr file")
		return nil
	end

	if not valid_cnsr_file(cnsr_file) then
		print_to_vlc_and_log("cnsr file bad format")
		return nil
	end

	cnsr_file:close()
	cnsr_file = vlc.io.open(cnsr_uri,"r")



	raw_tags ={}
	local line = cnsr_file:read("*line")
	while line ~= nil do
		table.insert(raw_tags, line_to_tag(line))
		line = cnsr_file:read("*line")
	end
	cnsr_file:close()
	cnsr_file = nil
	collectgarbage()

	return raw_tags
end

--[[
this function checks that the tag of the specific line in the file is valid
--]]
function valid_tag(line)
	local category = tonumber(SplitString(line,";")[2]) or -1
    return category<5 and category>0
end



--[[
this function checks that the format of the file is a cnsr format + the tag is of a legal class
--]]
function valid_cnsr_file(cnsr_file)
	local line = cnsr_file:read("*line")
	while line ~= nil do
		if not valid_tag(line) then return false end
		local start_time, end_time = string.match(line,"([^-]+)-([^-]+)")
		if start_time == nil or end_time == nil then return false end
		pat_for_start = "%d%d:%d%d:%d%d,%d%d%d"
		pat_for_end = "%d%d:%d%d:%d%d,%d%d%d; %d"
		if string.match(start_time,pat_for_start) == nil or string.match(end_time,pat_for_end) == nil then return false
		end
		line = cnsr_file:read("*line")
	end
	return true
end
--[[
this function gets a line of cnsr file and returns is as a tag
tag properties:
start_time- start of the tag in micro seconds
end_time- end of the tag in micro seconds
category- the category of the tag (for example 1 for violence) (int)
 action- the action to take when viewing the tag (can be one of these: HIDE,SHOW,MUTE,SKIP)
--]]
function line_to_tag(line)
	line = string.gsub(line," ","")
	local times, category = string.match(line,"([^;]+);([^;]+)") -- maybe use find and sub instead of slow regex
	local start_string, end_string = string.match(times,"([^-]+)-([^-]+)")
	category = tonumber(category)
	local action = CATEGORIES[category].action
	local tag = {}
	tag.start_time = hms_ms_to_us(start_string)
	tag.end_time = hms_ms_to_us(end_string)
	tag.category = category
	tag.action = action
	return tag
end

--[[
this function loads tags from cnsr file and saves them into config file
--]]
function load_and_set_tags()
	Log("load")
	raw_tags = load_tags_from_file()
	if raw_tags == nil then
		return
	end
	Log("loaded")
	cfg.tags = raw_tags
	cfg.offset=offset_num
	cfg.tags_by_end_time = common.table_copy(raw_tags)
    set_memory("offset",offset_num)
	table.sort(cfg.tags_by_end_time, function(a, b) return a.end_time < b.end_time end)


	for _, v in ipairs(cfg.tags_by_end_time) do
		Log("start: " .. tostring(v.start_time/1000000))
		Log("end: " .. tostring(v.end_time/1000000))
		Log("description: " .. tostring(CATEGORIES[v.category].description))
		Log("action: " .. tostring(options[v.action]))
	end

	set_config(cfg, "CNSR")
end

--[[
this function gets a string representing time (from this shape: hh:mm:ss,ms)
and converts it to microseconds
--]]
function hms_ms_to_us(time_string) -- microseconds
	hms , ms = string.match(time_string, "([^,]+),([^,]+)") -- maybe use find and sub instead of slow regex
	h, m ,s = string.match(hms, "([^:]+):([^:]+):([^:]+)")
	return (tonumber(h)*3600000 + tonumber(m)*60000 + tonumber(s)*1000 + tonumber(ms)) * 1000
end

--[[
this function is called only on the 1st activation of the extention
it makes the user to define the interface and enable it.
--]]
function create_dialog_S()
	dlg = vlc.dialog(descriptor().title .. " > SETTINGS")
	cb_extraintf = dlg:add_check_box("Enable interface: ", true,1,1,1,1)
	ti_luaintf = dlg:add_text_input(intf_script,2,1,2,1)
	dlg:add_label("Choose your password: Leave empty if you do not want any password.",1, 2, 1, 1)
	dlg:add_label("Password:",1, 3, 1, 1)
	set_password = dlg:add_text_input("", 2, 3, 3, 1)
	dlg:add_label("Password hint:",1, 4, 1, 1)
	set_hint = dlg:add_text_input("", 2, 4, 3, 1)
	dlg:add_button("SAVE!", click_SAVE_settings,1,5,1,1)
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
	lb_message = dlg:add_label("Current status: " .. (ti and "ENABLED" or "DISABLED") .. " " .. tostring(VLC_luaintf),1,6,3,1)
end

--[[
this function is called only on the 1st activation of the extention
it makes the user to define the interface and enable it.
--]]
function click_SAVE_settings()
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
	cfg["password"] = set_password:get_text()
	cfg["hint"] = set_hint:get_text()
	Log(cfg["password"])
	Log(cfg["hint"])
	vlc.config.set("bookmark8", json.encode(cfg))
	if cb_extraintf:get_checked() then
		if not ti then table.insert(t, "luaintf") end
		vlc.config.set("lua-intf", ti_luaintf:get_text())
	else
		if ti then table.remove(t, ti) end
	end
	vlc.config.set("extraintf", table.concat(t, ":"))

	lb_message:set_text("Please restart VLC for changes to take effect!")
end

--[[
in every extention, a deactivate function is a must.
when the extention dies, this function is called.
--]]
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

--[[
this function closes a dialog and release its resources
--]]
function close_dlg()
	if dlg ~= nil then
		dlg:hide()
	end

	dlg = nil
	collectgarbage() --~ !important
end

--[[
this function is called when the user has changed the video
it
--]]
function input_changed()
	load_and_set_tags()
end

--[[
use this function to print to console
--]]
function Log(lm)
	vlc.msg.info("[cnsr_ext] " .. lm)
end

-----------------------------------------
--[[
this function gets an uri and strips it.
--]]
function strip_extension(uri)
	uri = string.sub(uri,9)
	local index = string.find(uri, ".[^\.]*$")
	return string.sub(uri, 0, index)
end
-----------------------------------------
--[[
this function gets configs in a file
--]]
function get_config()
	config = json.decode(Memory.get_config_string())

	if config == nil then -- todo write config to an external file for later loads/use bookmarkN as caching mechanizm
		config = {}
	end

	if config.CNSR == nil then
		config.CNSR = {}
	end

	if config.CNSR.tags == nil then
		config.CNSR.tags = {}
	end

	if config.CNSR.tags_by_end_time  == nil then
		config.CNSR.tags_by_end_time  = {}
	end
	if config.CNSR.offset == nil then
		config.CNSR.offset = 0
	end
end

--[[
this function saves configs in a file
--]]
function set_config(cfg_table, cfg_title)
	if not cfg_table then cfg_table={} end
	if not cfg_title then cfg_title=descriptor().title end
	config[cfg_title]=cfg_table

	Memory.set_config_string(json.encode(config))
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

--Lua README titles to explore: "Objects" (player, libvlc), "Renderer discovery"
