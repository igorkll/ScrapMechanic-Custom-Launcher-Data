_betterAPI_forceUpdate = true
print("OLD lua51.dll DETECTED!!! force update!")

local code, err = loadfile("newbetter.lua")
if code then
    print("newbetter.lua loaded successfully")
    print("newbetter.lua result: ", xpcall(code, debug.traceback))
else
    print("newbetter.lua loaded error: ", err)
end