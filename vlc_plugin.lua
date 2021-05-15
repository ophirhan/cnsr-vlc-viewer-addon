local dlg2 = nil
types= {}

function descriptor()
    return { title = "cnsr" ;
             version = "0.1" ;
             author = "EEO" ;
             capabilities = {"menu","playing-listener", "input-listener"} }
	
end

function strip_extension(uri)
	uri = string.sub(uri,9)
	i = string.find(uri, ".[^.]*$")
	return string.sub(uri, 0, i)
end

function hms_ms_to_ms(time_string)
		hms , ms = string.match(time_string, "([^,]+),([^,]+)") -- maybe use find and sub instead of slow regex
		h, m ,s = string.match(hms, "([^:]+):([^:]+):([^:]+)")
		return tonumber(h)*3600000 + tonumber(m)*60000 + tonumber(s)*1000 + tonumber(ms)
end

function load_cnsr_file()
	input = vlc.object.input()
	if input == nil then
		return
	end
	tags = {}
	duration_ms = vlc.input.item():duration() * 1000
	tag_index = 1
	local uri = vlc.input.item():uri()
	uri = unescape(uri)
	local uri_sans_extension = strip_extension(uri)
	local cnsr_uri = uri_sans_extension .. "cnsr"
	
	local cnsr_file = io.open(cnsr_uri,"r")
	if cnsr_file == nil then
		dlg = vlc.dialog("failed: " .. cnsr_uri)
		dlg:show()
	end
	io.input(cnsr_file)
	
	local i = 1
	for line in io.lines() do
		line = string.gsub(line," ","")
		local times, typ = string.match(line,"([^;]+);([^;]+)") -- maybe use find and sub instead of slow regex
		local start_time, end_time = string.match(times,"([^-]+)-([^-]+)")
		typ = tonumber(typ)
		
		if types[typ] then
			timeline = {}
			timeline["start"] = hms_ms_to_ms(start_time)
			timeline["end"] = hms_ms_to_ms(end_time)
			tags[i] = timeline
			i = i+1
		end
	end
	io.close(cnsr_file)
	cnsr_file = nil
	collectgarbage()
	--vlc.msg.info("read success")
end

-- Function triggered when the extension is activated
function activate()
	dlg2 = vlc.dialog("censor")
	checkbox_1 = dlg2:add_check_box("violence",20,2,3,3)
	checkbox_2 = dlg2:add_check_box("verbal abuse",20,5,3,3)
	checkbox_3 = dlg2:add_check_box("nudity",20,8,3,3)
	checkbox_4 = dlg2:add_check_box("alcohol and drug consumption",20,11,3,3)
	button_apply = dlg2:add_button("apply categories to censor",click_play, 6, 10, 3, 3)
    dlg2:show()
	
end

function unescape (s)
	s = string.gsub(s, "+", " ")
	s = string.gsub(s, "%%(%x%x)", 
		function (h)
			return string.char(tonumber(h, 16))
		end)
	return s
end


function click_play()
	types[1] = checkbox_1:get_checked()
	types[2] = checkbox_2:get_checked()
	types[3] = checkbox_3:get_checked()
	types[4] = checkbox_4:get_checked()
	close_dlg()
	load_cnsr_file()
	loop()
end

function loop()
	if vlc.playlist.status() ~= "playing" then
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
		local current_time = vlc.var.get(input,"time") / 1000
		while tag_index > 1 and current_time < tags[tag_index-1]["end"] do --while current_time < previous tag end time
			tag_index = tag_index - 1
		end
		while tag_index < #tags and current_time > tags[tag_index]["end"] do --while current_time > current tag end time?
			tag_index = tag_index + 1 --both while loops not thought out, what about collisions, maybe sort by end time?
		end
		
		local next_tag_start = tags[tag_index]["start"]
		local next_end_time = tags[tag_index]["end"]
		
		if (current_time > next_tag_start and current_time < next_end_time) then
			vlc.var.set(input,"position",(next_end_time+1) / duration_ms)
		end
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
	if dlg2 then
		dlg2:hide()
	end
end

function close_dlg()
  if dlg2 ~= nil then
    dlg2:hide() 
  end
  
  dlg2 = nil
  collectgarbage() --~ !important	
end

--MAJOR problem VLC doesn't always properly close- check the task manager

function close()
    vlc.deactivate()
end