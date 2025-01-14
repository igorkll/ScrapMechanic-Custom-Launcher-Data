if not unsafe_env or not unsafe_env.sm.player or _betterInit then
    return
end
_betterInit = true

if _set_better then
    print("calling _set_better...")
    _set_better()
    print("_set_better called")
else
    print("_set_better not found")
end

print("|-----------------------------------|")
print("|             BETTER API            |")
print("|              LOADER 2             |")
print("|-----------------------------------|")
print("---- env-table: " .. tostring(unsafe_env))

local code, err = loadfile("betterAPI.lua")
local success = not not code
if code then
    success, err = xpcall(code, debug.traceback)
end

if success then
    print("---- BETTER API: successfully")
else
    print("---- BETTER API: " .. tostring(err))
    os.execute("echo " .. string.char(7))
end