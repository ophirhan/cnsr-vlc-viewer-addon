tags= {}
local dlg2 = nil
types= {}

function descriptor()
    return { title = "cnsr" ;
             version = "0.1" ;
             author = "EEO" ;
             capabilities = {"menu","playing-listener"} }
	
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
	local uri = vlc.input.item():uri()
	uri = unescape(uri)
	local uri_sans_extension = strip_extension(uri)
	local cnsr_uri = uri_sans_extension .. "cnsr"
	
	local cnsr_file = io.open(cnsr_uri,"r")
	if cnsr_file == nil then
		dlg = vlc.dialog("failed: ".. cnsr_uri)
		dlg:show()
	end
	io.input(cnsr_file)
	
	local i =0
	for line in io.lines() do
		line = string.gsub(line," ","")
		local times, typ = string.match(line,"([^;]+);([^;]+)") -- maybe use find and sub instead of slow regex
		local start_time, end_time = string.match(times,"([^-]+)-([^-]+)")
		
		timeline = {}
		timeline[0] = hms_ms_to_ms(start_time) -- maybe store in timeline["start"]
		timeline[1] = hms_ms_to_ms(end_time)
		timeline[2] = tonumber(typ) --maybe close dialog first and keep only tags with suitable tags, would save major headaches after.
		tags[i] = timeline
		i = i+1
	end
	io.close(cnsr_file)
	cnsr_file = nil
	collectgarbage()
end

-- Function triggered when the extension is activated
function activate()
	load_cnsr_file()
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
	--maybe parse cnsr file here and busy wait while the video file wasn't selected?
	
	-- maybe refactor from this point to loop function?
	local input = vlc.object.input()
	local duration_ms = vlc.input.item():duration() * 1000
	local i = 0
	local loop_counter = 0
	while true do --should exit when paused and triggered again when resumed
		loop_counter = (loop_counter + 1) % 1000000
		if loop_counter == 0 then
			vlc.keep_alive() -- might be slow function so we don't want to call it more then we have to.
		end
		
		--find right i
		local current_time = vlc.var.get(input,"time") / 1000
		while i > 0 and current_time < tags[i-1][1] do --while current_time < previous tag end time
			i = i - 1
		end
		while i < (#tags - 1) and current_time > tags[ i + 1 ][0] do --both while loops not thought out, what about collisions, maybe sort by end time?
			i = i + 1 --while current_time > next tag start/end time? my head hurts
		end
		
		local next_tag_start = tags[i][0]
		local next_end_time = tags[i][1]
		local typ = tags[i][2] -- don't want to deal with types here
		
		if (current_time > next_tag_start and current_time < next_end_time) then
			if (types[typ] == true) then -- don't want to deal with types here
				vlc.var.set(input,"position",(next_end_time+1) / duration_ms)
			end
			i = i + 1
		end
	end   
end

--MAJOR problem VLC doesn't always properly close- check the task manager


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

function close()
    vlc.deactivate()
end