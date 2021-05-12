--[[
 Streaming Radio Player extension for VLC &gt;= 1.1.0
 Authors: Ben Dowling (http://www.coderholic.com)
--]]

local dlg2 = nil
stations = {
    { name = "Ophir the king", url = "http://somafm.com/startstream=groovesalad.pls" },
    { name = "Elder the lerner", url = "http://listen.di.fm/public3/chillout.pls" },
}

function descriptor()
    return { title = "cnsr" ;
             version = "0.1" ;
             author = "EBT" ;
             capabilities = {} }
	
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
	tags= {}
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
		timeline[0] = start_in_ms
		timeline[1] = end_in_ms
		timeline[2] = typ
		tags[i] = timeline
		i = i+1
	end
	io.close(cnsr_file)
	cnsr_file = nil
	collectgarbage()
	--1. until here we dont know if it works!	
	dlg2 = vlc.dialog("sencor")
	checkbox_1 = dlg2:add_check_box("violence",20,2,3,3)
	checkbox_2 = dlg2:add_check_box("verbal abuse",20,5,3,3)
	checkbox_3 = dlg2:add_check_box("nudity",20,8,3,3)
	checkbox_4 = dlg2:add_check_box("alcohol and drug consumption",20,11,3,3)
	button_apply = dlg2:add_button("apply categories to censor",click_play, 6, 10, 3, 3)
	--local input = vlc.object.input()
	--local current_time = vlc.var.get(input,"time")
	--button_apply = dlg2:add_button("h",click_play, 6, 10, 3, 3)
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
	while true do
		vlc.misc.mwait(vlc.misc.mdate() + 1000)

	end
	
	if (type1==true) then
		local input = vlc.object.input()
		local current_time = vlc.var.get(input,"position")
		local duration = vlc.input.item():duration()
		vlc.var.set(input,"position",70/duration)
	end
	if (type2==true) then
		local input = vlc.object.input()
		local current_time = vlc.var.get(input,"position")
		local duration = vlc.input.item():duration()
		vlc.var.set(input,"position",700/duration)
	end
	if (type3==true) then
		local input = vlc.object.input()
		local current_time = vlc.var.get(input,"position")
		local duration = vlc.input.item():duration()
		vlc.var.set(input,"position",5000/duration)
	end
	if (type4==true) then
		local input = vlc.object.input()
		local current_time = vlc.var.get(input,"position")
		local duration = vlc.input.item():duration()
		vlc.var.set(input,"position",7000/duration)
	end
    
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