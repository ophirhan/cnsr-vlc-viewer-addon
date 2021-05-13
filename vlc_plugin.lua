--[[
 Streaming Radio Player extension for VLC &gt;= 1.1.0
 Authors: Ben Dowling (http://www.coderholic.com)
--]]
tags= {}
local dlg2 = nil
stations = {
    { name = "Ophir the king", url = "http://somafm.com/startstream=groovesalad.pls" },
    { name = "Elder the lerner", url = "http://listen.di.fm/public3/chillout.pls" },
}

function descriptor()
    return { title = "cnsr" ;
             version = "0.1" ;
             author = "EBT" ;
             capabilities = {"menu"} }
	
end

-- Function triggered when the extension is activated
function activate()
	--1. this is new: 
	a = vlc.input.item():uri()
	a= unescape(a)
	a= string.sub(a,9)
	i = string.find(a, ".[^.]*$")
	b = string.sub(a, 0, i)
	cnsr_name = b .. "cnsr"
	cnsr_file = io.open(cnsr_name,"r")
	if cnsr_file == nil then
		dlg = vlc.dialog("failed: ".. cnsr_name)
		dlg:show() end
	io.input(cnsr_file)
	i =0
	for line in io.lines() do
		--line = io.read("*line")	
		line = string.gsub(line," ","")
		times, typ = string.match(line,"([^;]+);([^;]+)")
		start_time,end_time = string.match(times,"([^-]+)-([^-]+)")
		start_hms , start_ms = string.match(start_time, "([^,]+),([^,]+)")
		h, m ,s = string.match(start_hms, "([^:]+):([^:]+):([^:]+)")
		start_in_ms = tonumber(h)*3600000 + tonumber(m)*60000 + tonumber(s)*1000 + start_ms
		
		end_hms , end_ms = string.match(end_time, "([^,]+),([^,]+)")
		h, m ,s = string.match(end_hms, "([^:]+):([^:]+):([^:]+)")
		end_in_ms = tonumber(h)*3600000 + tonumber(m)*60000 + tonumber(s)*1000 + end_ms
		
		timeline = {}
		timeline[0] = tonumber(start_in_ms)
		timeline[1] = tonumber(end_in_ms)
		timeline[2] = tonumber(typ)
		tags[i] = timeline
		i = i+1
	end
	io.close(cnsr_file)
	cnsr_file = nil
	collectgarbage()
	--1. until here we dont know if it works!
	--vlc.misc.mwait(vlc.misc.mdate()+1000000)
	--vlc.msg.info("paused")
	dlg2 = vlc.dialog("sencor")
	checkbox_1 = dlg2:add_check_box("violence",20,2,3,3)
	checkbox_2 = dlg2:add_check_box("verbal abuse",20,5,3,3)
	checkbox_3 = dlg2:add_check_box("nudity",20,8,3,3)
	checkbox_4 = dlg2:add_check_box("alcohol and drug consumption",20,11,3,3)
	button_apply = dlg2:add_button("apply categories to censor",click_play, 6, 10, 3, 3)
	--button_apply = dlg2:add_button(tags[0][2],click_play, 6, 10, 3, 3)
    dlg2:show()
	
end

function unescape (s)
      s = string.gsub(s, "+", " ")
      s = string.gsub(s, "%%(%x%x)", function (h)
            return string.char(tonumber(h, 16))
          end)
      return s
    end


function click_play()
	type1= checkbox_1:get_checked()
	type2= checkbox_2:get_checked()
	type3= checkbox_3:get_checked()
	type4= checkbox_4:get_checked()
	close_dlg()
	i=0
	did_jump=0
	local duration = vlc.input.item():duration()*1000
	while true do
		local input = vlc.object.input()
		local current_time = vlc.var.get(input,"time")/1000
		next_tag_start = tags[i][0]
		next_end_time=tags[i][1]
		typ = tags[i][2]
		if (current_time< next_tag_start or current_time> next_end_time) then
			j=0
		else
			if (type1==true and typ ==1 and did_jump==0) then
				
				vlc.var.set(input,"position",next_end_time/duration)
				did_jump=1
			end
	--		if (type2==true and tags[i].typ==2) then
	--			vlc.var.set(input,"position",next_end_time/duration)
	--		end
	--		if (type3==true tags[i].typ==3) then
	--			vlc.var.set(input,"position",next_end_time/duration)
	--		end
	--		if (type4==true tags[i].typ==4) then
	--			vlc.var.set(input,"position",next_end_time/duration)
	--		end
		end
	end
	
    
end

function sleep(s)
  local ntime = os.time() + s
  repeat until os.time() > ntime
end


-- Function triggered when the extension is deactivated
function deactivate()
	if dlg2 then
		dlg2:hide()
	end
end

function close_dlg()
  if dlg2 ~= nil then 
    --~ dlg:delete() -- Throw an error
    dlg2:hide() 
  end
  
  dlg2 = nil
  collectgarbage() --~ !important	
end

function close()
    vlc.deactivate()
end