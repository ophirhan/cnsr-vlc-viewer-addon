config={}
cfg={}
dropdowns = {}
SHOW = 1
SKIP = 2
MUTE = 3
HIDE = 4
intf_script = "cnsr_intf" -- Location: \lua\intf\cnsr_intf.lualocal dlg = nil
local dlg

--add epilepsy category
CATEGORIES = { [1] = { description = "violence", action=SKIP},
			   [2] = {description = "verbal abuse", action=SKIP},
			   [3] =  {description = "nudity", action=SKIP},
			   [4] =  {description = "alcohol and drug consumption", action=SKIP}}
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
	get_config()
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
		load_and_set_tags()
	elseif dlg_id==3 then -- Settings
		if dlg then dlg:delete() end
		create_dialog_S() --configure interface script to start when VLC starts
	end
end

options = {"Show", "Skip", "Mute", "Hide"}

function show_category_selection()
	close_dlg()
	dlg = vlc.dialog("Category selection")
	local y = 1
	local x = 1
	for idx, value in ipairs(CATEGORIES) do
		dlg:add_label(value.description, 1, y, 1, 1)
		dropdowns[idx] = create_drop_down(x, y)
		y = y + 1
	end
	button_apply = dlg:add_button("Apply and save", click_play, x + 1, y, 1, 1)
    dlg:show()
end


function create_drop_down(x, y)
	local dropdown = dlg:add_dropdown(x + 2, y, 2, 1)
	for idx, word in ipairs(options) do
		dropdown:add_value(word, idx)
	end
	return dropdown
end


function click_play()
	for idx, value in ipairs(CATEGORIES) do
		value.action = dropdowns[idx]:get_value()
	end
	Log("click play")
	close_dlg() --add option to reopen dialog and reload tags according to new filters
	load_and_set_tags()
end

function get_cnsr_uri()
	if vlc.input.item() == nil then
		set_config(cfg, "CNSR")
		return nil
	end
	local uri = vlc.input.item():uri()
	uri = vlc.strings.decode_uri(uri)
	local uri_sans_extension = strip_extension(uri)
	return uri_sans_extension .. "cnsr"
end

function load_tags_from_file()
	local cnsr_uri = get_cnsr_uri()
	if cnsr_uri == nil then
		return nil
	end
	cnsr_file = io.open(cnsr_uri,"r")
	if cnsr_file == nil then
		vlc.osd.message("Failed to load cnsr file", nil, "bottom-right")
		return nil
	end
	io.input(cnsr_file)

	raw_tags ={}
	for line in io.lines() do
		table.insert(raw_tags, line_to_tag(line))
	end
	io.close(cnsr_file)
	cnsr_file = nil
	collectgarbage()

	return raw_tags
end

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

require 'common'

function load_and_set_tags()
	Log("load")
	raw_tags = load_tags_from_file()
	if raw_tags == nil then
		return
	end
	Log("loaded")
	cfg.tags = raw_tags
	cfg.tags_by_end_time = common.table_copy(raw_tags)
	table.sort(cfg.tags_by_end_time, function(a, b) return a.end_time < b.end_time end)


	for _, v in ipairs(cfg.tags_by_end_time) do
		Log("start: " .. tostring(v.start_time/1000000))
		Log("end: " .. tostring(v.end_time/1000000))
		Log("description: " .. tostring(CATEGORIES[v.category].description))
		Log("action: " .. tostring(options[v.action]))
	end
	set_config(cfg, "CNSR")
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
	load_and_set_tags()
end


function Log(lm)
	vlc.msg.info("[cnsr_ext] " .. lm)
end

-----------------------------------------

function strip_extension(uri)
	uri = string.sub(uri,9)
	i = string.find(uri, ".[^\.]*$")
	return string.sub(uri, 0, i)
end

-----------------------------------------

function get_config()
	local s = vlc.config.get("bookmark10")
	if not s or not string.match(s, "^config={.*}$") then s = "config={}" end
	assert(loadstring(s))() -- global var
end

function set_config(cfg_table, cfg_title)
	if not cfg_table then cfg_table={} end
	if not cfg_title then cfg_title=descriptor().title end
	get_config()
	config[cfg_title]=cfg_table
	vlc.config.set("bookmark10", "config=".. serialize(config))
end

function serialize(t)
	if type(t)=="table" then
		local s='{'
		for k,v in pairs(t) do
			if type(k)~='number' then k='"'..k..'"' end
			s = s..'['..k..']='.. serialize(v)..',' -- recursion
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

	--Lua README titles to explore: "Objects" (player, libvlc), "Renderer discovery"
