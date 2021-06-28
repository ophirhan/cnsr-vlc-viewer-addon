-- IMPORTANT! put your own location in the all package.path!
package.path = ";C:\\Program Files\\VideoLAN\\VLC\\lua\\modules\\?.luac"
json = require ("dkjson")
require ("common")
package.path = ";C:\\Program Files\\VideoLAN\\VLC\\lua\\modules\\?.lua"
Memory = require ('cnsr_memory')
package.path = ";C:\\Program Files\\VideoLAN\\VLC\\lua\\extensions\\?.lua"
require('cnsr_ext')

function test_valid_tag()
    --test 1: check good inputs
    local good_inputs  = {1,2,3,4}
    for i,k in ipairs(good_inputs) do
        line = "this should not pas;"..k
        result = valid_tag(line)
        assert(result==true,"error: returned false for good input")
    end
    --test 2: edges of bad input
    local bad_inputs  = {-1,0,5}
    for i,k in ipairs(bad_inputs) do
        line = "this should not pass;"..k
        result = valid_tag(line)
        assert(result==false,"error: returned true for bad input")
    end
    print("passed!")
end

function test_hms_ms_to_us()
    --test1: good inputs:
    local good_lines={"00:00:45,000","00:00:00,150","00:10:00,000","02:00:00,000","03:15:10,050"}
    local expected_good_lines={45000000,150000,600000000,7200000000,11710050000}
    for i,k in ipairs(good_lines) do
        result = hms_ms_to_us(k)
        assert(result==expected_good_lines[i],"error: returned true for bad input")
    end
    print("passed!")
end

function test_line_to_tag()
    --test1: good inputs:
    local good_lines={"00:00:45,000 - 00:01:10,100;1","00:00:00,150 - 00:01:10,100;2",
                      "00:10:00,000 - 00:01:10,100;3","02:00:00,000 - 00:01:10,100;4","03:15:10,050 - 00:01:10,100;1"}
    local expected_good_lines={1,2,3,4,1}
    for i,k in ipairs(good_lines) do
        result = line_to_tag(k)
        assert(result.category==expected_good_lines[i],"error: tag category does not match")
    end
    print("passed!")
end


-- class TestMyStuff

print("---tests for functions in cnsr_ext---")
print("checking valid_tag_function:")
test_valid_tag()
print("checking hms_ms_to_us function:")
test_hms_ms_to_us()
print("checking line_to_tag fugitnction:")
test_line_to_tag()