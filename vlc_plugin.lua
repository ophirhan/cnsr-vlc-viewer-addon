local dlg = nil
categories = {[1] = {description = "violence", censor=true},
			[2] = {description = "verbal abuse", censor=true},
			[3] =  {description = "nudity", censor=true},
			[4] =  {description = "alcohol and drug consumption", censor=true}} --add epilepsy category

function descriptor()
    return { title = "cnsr" ;
             version = "0.1" ;
             author = "EEO" ;
             capabilities = {"menu", "playing-listener", "input-listener"};
			 url =  "https://github.com/ophirhan/cnsr-vlc-viewer-addon"}
	
end


function menu()
	return {"Modify censor categories", "Retry loading cnsr file"}
  end

  function trigger_menu(dlg_id)
	if dlg_id == 1 then
	  show_category_selection()
	elseif dlg_id == 2 then
	  load_cnsr_file()
	end
	collectgarbage() --~ !important	
  end 

function strip_extension(uri)
	uri = string.sub(uri,9)
	i = string.find(uri, ".[^.]*$")
	return string.sub(uri, 0, i)
end

function hms_ms_to_us(time_string) -- microseconds
		hms , ms = string.match(time_string, "([^,]+),([^,]+)") -- maybe use find and sub instead of slow regex
		h, m ,s = string.match(hms, "([^:]+):([^:]+):([^:]+)")
		return (tonumber(h)*3600000 + tonumber(m)*60000 + tonumber(s)*1000 + tonumber(ms)) * 1000
end

function load_cnsr_file()
	input = vlc.object.input()
	if input == nil then
		return
	end
	tags = {}
	tag_index = 1
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
	
	for line in io.lines() do
		line = string.gsub(line," ","")
		local times, typ = string.match(line,"([^;]+);([^;]+)") -- maybe use find and sub instead of slow regex
		local start_time, end_time = string.match(times,"([^-]+)-([^-]+)")
		typ = tonumber(typ)
		
		if categories[typ].censor then
			timeline = {}
			timeline.start_time = hms_ms_to_us(start_time)
			timeline.end_time = hms_ms_to_us(end_time)
			timeline.category = typ
			table.insert(tags, timeline)
		end
	end
	io.close(cnsr_file)
	cnsr_file = nil
	collectgarbage()
	--vlc.msg.info("read success")
end

function show_category_selection()
	close_dlg()
	dlg = vlc.dialog("Category selection")
	local pos = 2
	for i,v in ipairs(categories) do
		v.checkbox = dlg:add_check_box(v.description,20,pos,3,3)
		v.checkbox:set_checked(v.censor)
		pos = pos + 3
	end
	button_apply = dlg:add_button("apply categories to censor",click_play, 6, 10, 3, 3)
    dlg:show()
end

-- Function triggered when the extension is activated
function activate()
	show_category_selection()
end

function click_play()
	for i,v in ipairs(categories) do
		v.censor = v.checkbox:get_checked()
	end
	close_dlg() --add option to reopen dialog and reload tags according to new filters
	load_cnsr_file()
	loop()
end

function loop()
	if #tags == 0 or vlc.playlist.status() ~= "playing" then
		return
	end
	
	local loop_counter = 0
	while true do
		loop_counter = (loop_counter + 1) % 1000000
		if loop_counter == 0 then  -- might be slow functions so we don't want to call them more then we have to.
			if vlc.playlist.status() ~= "playing" then
				break
			end
			vlc.keep_alive()
		end
		
		--find right tag_index
		local current_time = vlc.var.get(input,"time")
		while tag_index > 1 and current_time < tags[tag_index-1].end_time do --while current_time < previous tag end time
			tag_index = tag_index - 1
		end
		while tag_index < #tags and current_time > tags[tag_index].end_time do --while current_time > current tag end time?
			tag_index = tag_index + 1 --both while loops not thought out, what about collisions, maybe sort by end time?
		end
		
		local next_tag_start = tags[tag_index].start_time
		local next_end_time = tags[tag_index].end_time
		local category = tags[tag_index].category

		--osd.slider( position, type, [id] ): Display slider. Position is an integer from 0 to 100. Type can be "horizontal" or "vertical".
		if (current_time > next_tag_start and current_time < next_end_time) then -- maybe add slider leading to skip?
			vlc.var.set(input,"time", next_end_time + 10000) --add option to mute
			vlc.osd.message("skipped " .. categories[category].description, nil, "bottom-right") --what about collisions? add how many seconds were skipped?
		end
		vlc.win.console_wait(30) --ms. optinal. only works on windows. maybe check if platform is windows.
	end
end


function input_changed()
	load_cnsr_file()
end

function playing_changed()
	loop()
end



-- Function triggered when the extension is deactivated
function deactivate()
	if dlg then
		dlg:hide()
	end
end

function close_dlg()
  if dlg ~= nil then
    dlg:hide() 
  end
  
  dlg = nil
  collectgarbage() --~ !important	
end

function close()
    vlc.deactivate()
end



--MAJOR problems:
	--(1) VLC doesn't always properly close- check the task manager
	--(2) clicking on the "view" menu while VLC is playing makes VLC crash.

--TODOs:
	--Solve (1): investigate dialog closing, garbage collection.

	--Solve (2): Try refactoring loop() to a separate extension residing in the lua\interface folder,
	--this *might* solve (2). We might have to find a threading solution or create a separte windows
	--service/program to externally control vlc.

	--Investigate saving/loading configurations to/from a file.

	--Add mute support.

	--Lua README titles to explore: "Objects" (player, libvlc, vout), "Renderer discovery"

	--Fix readme