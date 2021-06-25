-- This module acts as a shared memory between the ext and the intf modules

require('common')
json = require("dkjson")

Memory = {}

function Memory.set_config_string(config)
    set_memory("config", config)
    set_memory("written", true)
end

function Memory.get_config_string()
    set_memory("written", false)
    return get_memory("config") or ""
end

function Memory.get_written()
    return get_memory("written")
end

function Memory.get_key(key)
    return get_memory(key)
end

function Memory.set_key(key,val)
    set_memory(key,val)
end

function set_memory(key, val)
    local value = get_memory(key)
    if value == val then
        return
    end
    if value == nil then
        vlc.var.create(vlc.object.playlist(), key, val)
        return
    end

    vlc.var.set(vlc.object.playlist(), key, val)
end

function get_memory(key)
    return vlc.var.get(vlc.object.playlist(), key)
end

return Memory