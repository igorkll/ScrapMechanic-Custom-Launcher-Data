local debugMode = false
local disableCoroutineFix = true

----------------------- init

_BETTERAPI_UNSAFE_GLOBAL_ENV = true --for additional verification in loadstring

assert(loadfile("forceConsole.lua"))()

local forceUpdate = false
if _betterAPI_forceUpdate then
    forceUpdate = true
end

local function _veryVeryRawRemove(path)
    os.execute("del /s /q \"" .. path .. "\"")
    os.execute("rmdir /s /q \"" .. path .. "\"")
    os.remove(path)
end

local function holeLen(tbl)
    local max = 0
    for k, v in pairs(tbl) do
        max = math.max(max, k)
    end
    return max
end

local userdataNames = {
    ["userdata"] = true,
    ["AiState"] = true,
    ["AreaTrigger"] = true,
    ["BlueprintVisualization"] = true,
    ["Body"] = true,
    ["BuilderGuide"] = true,
    ["Character"] = true,
    ["Color"] = true,
    ["Container"] = true,
    ["CullSphereGroup"] = true,
    ["Effect"] = true,
    ["GuiInterface"] = true,
    ["Harvestable"] = true,
    ["Interactable"] = true,
    ["Joint"] = true,
    ["Lift"] = true,
    ["LoadCellHandle"] = true,
    ["Network"] = true,
    ["PathNode"] = true,
    ["Player"] = true,
    ["Portal"] = true,
    ["Quat"] = true,
    ["RaycastResult"] = true,
    ["ScriptableObject"] = true,
    ["Shape"] = true,
    ["Storage"] = true,
    ["Tool"] = true,
    ["Unit"] = true,
    ["Uuid"] = true,
    ["Vec3"] = true,
    ["Widget"] = true,
    ["World"] = true
}

local metaKeys = {
    ["__index"] = true,
    ["__newindex"] = true,
    ["__call"] = true,
    ["__tostring"] = true,
    ["__concat"] = true,
    ["__len"] = true,
    ["__add"] = true,
    ["__sub"] = true,
    ["__mul"] = true,
    ["__div"] = true,
    ["__pow"] = true,
    ["__mod"] = true,
    ["__idiv"] = true,
    ["__eq"] = true,
    ["__lt"] = true,
    ["__le"] = true
}

local tempFolder = "../BetterTemp"
_veryVeryRawRemove(tempFolder)
os.execute("mkdir \"" .. tempFolder .. "\"")

package.path = package.path .. ";.\\python\\?.lua"
if not io then
    require("enableio")
end

local python = require("python")

local bellChar = string.char(7)
if debugMode then
    for i = 1, 10 do
        os.execute("echo " .. bellChar)
        print("ATTENTION!!!")
    end
    print("DEBUGGING MODE IS ENABLED IN THE BETTER API!!!")
end

--[[
require("enableio")
local wfile = io.popen("cd")
local workingDirectory = wfile:read("*a")
wfile:close()
for i = 1, 2 do
    local endChar = workingDirectory:sub(#workingDirectory, #workingDirectory)
    if endChar == "/" or endChar == "\\" or endChar == "\n" then
        workingDirectory = workingDirectory:sub(1, #workingDirectory - 1)
    end
end
local compatibility = workingDirectory .. "\\DLM_compatibility\\"

print("workingDirectory", workingDirectory)
print("package.path", package.path)
print("compatibility", compatibility)
local addToPath = ";" .. compatibility .. "?"
addToPath = addToPath .. (";" .. compatibility .. "?.lua")
addToPath = addToPath .. (";" .. compatibility .. "?.dll")
addToPath = addToPath .. (";" .. compatibility .. "?\\init.lua")
addToPath = addToPath .. (";" .. compatibility .. "?\\init.dll")
print("addToPath", addToPath)
package.path = package.path .. addToPath
print("package.path", package.path)
]]

package.path = package.path .. ";.\\DLM_compatibility\\?.lua"
package.cpath = package.cpath .. ";.\\DLM_compatibility\\?.dll"

local betterDLL = require("betterDLL")

local threadList = {}
local dlmTunnel = {
    shutdown = function()
        print("calling _release_better...")
        _release_better()
        print("_release_better called")

        print("calling betterDLL.stop...")
        betterDLL.stop()
        print("betterDLL.stop called")
        
        for _, thread in pairs(threadList) do
            betterDLL.thread_kill(thread)
        end
    end
}
assert(loadfile("DLM_compatibility/API.lua"))(dlmTunnel)
local misc = require("misc")
local dlm_util = require("util")

local nullUuid = "00000000-0000-0000-0000-000000000000"
local bit = bit or bit32
local sm = unsafe_env.sm

local json_open = sm.json.open
local json_save = sm.json.save
local game_getCurrentTick = sm.game.getCurrentTick

local registeredMods = {}
local fileReadonly = "betterAPI does not allow overwriting this file"

----------------------- get paths

local function rawRawExists(path)
    local ok, err, code = os.rename(path, path)
    if not ok then
        if code == 13 then
            return true
        end
    end
    return not not ok
end

local workshopFolder
local function tryWorkshop(path)
    if workshopFolder then return end
    if rawRawExists(path) then
        workshopFolder = path
        print("workshop finded in path: ", path)
    else
        print("attempt to search for a workshop: ", path)
    end
end

tryWorkshop("../../../workshop/content/387990/")
local checkDisks = {"C", "D", "E", "F"}
for _, chr in ipairs(checkDisks) do
    tryWorkshop(chr .. ":\\Program Files (x86)\\Steam\\steamapps\\workshop\\content\\387990\\")
    tryWorkshop(chr .. ":\\Program Files\\Steam\\steamapps\\workshop\\content\\387990\\")
    tryWorkshop(chr .. ":\\Steam\\steamapps\\workshop\\content\\387990\\")
end

if not workshopFolder then
    io.write("THE WORKSHOP FOLDER WAS NOT FOUND!!!\n")
    error("THE WORKSHOP FOLDER WAS NOT FOUND!!!")
end

local steamID = misc.getSteamId()
local selfWorkshopFolder = workshopFolder .. "3177944610/"
local selfWorkshopContentFolder = selfWorkshopFolder .. "content/"
local localFolder, localModsFolder, betterFsFolder
if steamID then
    localFolder = os.getenv("APPDATA") .. "/Axolot Games/Scrap Mechanic/User/User_" .. steamID .. "/"
    localModsFolder = localFolder .. "Mods/"
    betterFsFolder = localFolder .. "BetterFS/"
end

----------------------- functions

local function randomStr(len)
    local str = ""
    for i = 1, len or 16 do
        str = str .. tostring(math.random(0, 9))
    end
    return str
end

local function vbsExec(script)
    --return [[cmd /T:1F /K ^"cscript.exe //nologo //B "]] .. script .. [[" "%~1"^&&exit^"]]
    --return [[wscript.exe "invisible.vbs" "]] .. script .. '"'
    --return "nircmd.exe exec hide \"cscript " .. script .. "\""
    return "cscript \"" .. script .. "\""
end

local function startwith(str, startCheck)
    return string.sub(str, 1, string.len(startCheck)) == startCheck
end

local function clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

local function dist(pos1, pos2)
    return math.sqrt(((pos1.x - pos2.x) ^ 2) + ((pos1.y - pos2.y) ^ 2) + ((pos1.z - pos2.z) ^ 2))
end

local function noBell(str)
    local newstr = {}
    for i = 1, #str do
        local char = str:sub(i, i)
        if char == bellChar then
            table.insert(newstr, "<bell>")
        else
            table.insert(newstr, char)
        end
    end
    return table.concat(newstr)
end

local function debugPrint(...)
    if debugMode then
        print(...)
    end
end

local function vbsNumber(number)
    local maxnumber = 126
    if number > maxnumber then
        local add = number - maxnumber
        if add > maxnumber then
            return string.char(maxnumber) .. string.char(maxnumber)
        end
        return string.char(maxnumber) .. string.char(add)
    else
        return string.char(number) .. string.char(0)
    end
end

local function wait(time)
    local startTime = os.clock()
    repeat
    until os.clock() - startTime > time
end

local function spcall(func, ...)
    local result = {pcall(func, ...)}
    if result[1] then
        return unpack(result, 2)
    else
        error(result[2], 3)
    end
end

local function tableToPrint(tbl)
    local newtbl = {}
    for i, v in ipairs(tbl) do
        local ok, result = pcall(type, v)
        if ok and result == "number" then
            newtbl[i] = v
        else
            ok, result = pcall(tostring, v)
            if ok then
                newtbl[i] = result
            else
                newtbl[i] = "<undeserialized>"
            end
        end
    end
    return newtbl
end

local function logCall(tag, func, ...)
    print("----------------------------------------------")
    print("call", tag, ":", tableToPrint({...}))
    local result = {spcall(func, ...)}
    print("result", tag, ":", tableToPrint(result))
    print("----------------------------------------------")
    return unpack(result)
end

local function logExecute(...)
    return logCall("os.execute", os.execute, ...)
end

local function startWith(str, start)
    if str:sub(1, #start) == start then
        return true
    end
end

local function endWith(str, endCheck)
    return string.sub(str, string.len(str) - (string.len(endCheck) - 1), string.len(str)) == endCheck
end

local function checkArg(n, have, ...)
	have = type(have)
	local tbl = {...}
	for _, t in ipairs(tbl) do
		if have == t then
			return
		end
	end
	error(string.format("bad argument #%d (%s expected, got %s)", n, table.concat(tbl, " or "), have), 3)
end

local function isReadOnly(gamepath)
    if gamepath:sub(1, 1) ~= "$" then
        return true
    end
    gamepath = gamepath:lower()
    gamepath = gamepath:gsub("\\", "/")
    while gamepath:sub(#gamepath, #gamepath) == "/" do
        gamepath = gamepath:sub(1, #gamepath - 1)
    end
    if gamepath == "$CONTENT_DATA/description.json" then
        return true
    else
        local firstStr = "$CONTENT_"
        local lastStr = "/description.json"
        if startWith(gamepath, firstStr) or endWith(gamepath, lastStr) then
            return true
        end
    end
    return false
end

local function realBadCheck(path)
    if path:find("%.%.") and not startWith(path, "../../../workshop/content/") then
        --print("real-bad-path (1):", path)
        --return true
    elseif path:find("%/%/") or path:find("%\"") or path:find("%'") or path:find("%|") or path:find("%&") then
        print("real-bad-path (2):", path)
        return true
    end
    return false
end

local function nameBadCheck(path)
    if path:find("%.%.") or path:find("%\\") or path:find("%/") or path:find("%\"") or path:find("%'") or path:find("%&") then
        print("bad-name:", path)
        return true
    end
    return false
end

local function gameBadCheck(path)
    if path:find("%.%.") or path:find("%\\") or path:find("%/%/") or not path:find("%/") or path:find("%\"") or path:find("%'") or path:find("%&") then
        print("game-bad-path:", path)
        return true
    end
    return false
end

local function cmdEscapeWithoutCheck(path)
    return "\"" .. path .. "\""
end

local function cmdEscape(path)
    if realBadCheck(path) then
        error("invalid path")
    end

    return cmdEscapeWithoutCheck(path)
end

local function fpathWithoutCheck(path)
    path = path:gsub("/", "\\")
    if path:sub(#path, #path) == "\\" then
        path = path:sub(1, #path - 1)
    end

    return path
end

local function fpath(path)
    if realBadCheck(path) then
        error("invalid path")
    end

    return fpathWithoutCheck(path)
end

local function rawExists(path)
    return rawRawExists(fpath(path))
end

local function getRealPath(smPath, noContent, rootActionAllow)
    checkArg(1, smPath, "string")
    checkArg(2, noContent, "boolean", "nil")

    if smPath:find("%.%.") then
        error("'..' is not supported by betterAPI")
    elseif gameBadCheck(smPath) then
        error("invalid path")
    end
    
    if smPath:sub(1, 1) == "$" then
        if isReadOnly(smPath) then
            error(fileReadonly)
        elseif noContent then
            error("working with mod files is not available from this method")
        else
            if startWith(smPath, "$CONTENT_DATA") then
                error("$CONTENT_DATA is not supported, use $CONTENT_UUID")
            elseif startWith(smPath, "$CONTENT_") then
                local modUuid = smPath:sub(smPath:find("%_") + 1, smPath:find("%/") - 1)
                local lpath = smPath:sub(smPath:find("%/"), #smPath)
                if registeredMods[modUuid] then
                    local workshopPath = workshopFolder .. registeredMods[modUuid][1]
                    local localPath = localModsFolder .. registeredMods[modUuid][2]
                    if rawExists(localPath) then
                        return fpath(localPath .. lpath)
                    elseif rawExists(workshopPath) then
                        return fpath(workshopPath .. lpath)
                    else
                        print("workshop path: ", workshopPath)
                        print("local path: ", localPath)
                        error("couldn't find the " .. modUuid .. " mod")
                    end
                else
                    error("the " .. modUuid .. " mod is not registered")
                end
            else
                error(smPath:sub(1, smPath:find("%/") - 1) .. " is not supported, use $CONTENT_UUID")
            end
        end
    elseif smPath:sub(1, 1) == "/" then
        if #smPath == 1 and not rootActionAllow then
            error("it is not possible to perform an action with the better FS root directory")
        end
        return fpath(betterFsFolder .. smPath:sub(2, #smPath))
    else
        error("the path must start with '$' or '/'")
    end
end

local function getModRealPath(modUuid)
    if registeredMods[modUuid] then
        local workshopPath = workshopFolder .. registeredMods[modUuid][1]
        local localPath = localModsFolder .. registeredMods[modUuid][2]
        if rawExists(localPath) then
            return workshopPath, 0
        elseif rawExists(workshopPath) then
            return workshopPath, 1
        else
            print("workshop path: ", workshopPath)
            print("local path: ", localPath)
            error("couldn't find the " .. modUuid .. " mod")
        end
    else
        error("the " .. modUuid .. " mod is not registered")
    end
end

local function tableCopy(tbl)
    local newtbl = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            newtbl[k] = tableCopy(v)
        else
            newtbl[k] = v
        end
    end
    return newtbl
end

local function xor(...)
    local state = false
    for _, flag in ipairs({...}) do
        if flag then
            state = not state
        end
    end
    return state
end

local function checkUuid(str)
    if #str ~= #nullUuid then
        return false
    end

    for i = 1, #nullUuid do
        local need = nullUuid:sub(i, i)
        local char = str:sub(i, i)

        if xor(need == "-", char == "-") or (need ~= "-" and not tonumber(char, 16)) then
            return false
        end
    end
    
    return true
end

local function rawRawReadFile(path)
    local file, err = io.open(path, "rb")
    if not file then return nil, tostring(err or "unknown error") end
    local content = file:read("*a")
    file:close()
    return tostring(content)
end

local function rawRawWriteFile(path, content)
    local file, err = io.open(path, "wb")
    if not file then return nil, tostring(err or "unknown error") end
    file:write(tostring(content))
    file:close()
    return true
end

local function rawReadFile(path)
    return rawRawReadFile(fpath(path))
end

local function rawWriteFile(path, content)
    return rawRawWriteFile(fpath(path), content)
end

local function rawIsFile(path)
    path = fpath(path)
    if not rawExists(path) then return false end
    local f = io.open(path)
    if f then
        f:close()
        return true
    end
    return false
end

local function rawIsDir(path)
    return rawExists(path) and not rawIsFile(path)
end

local function rawList(path)
    path = fpath(path)
    local dir, err = logCall("io.popen", io.popen, "chcp 1251|dir /a /b " .. cmdEscape(path))
    if not dir then
        return nil, tostring(err or "unknown error")
    end

    local tbl = {}
    for filename in dir:lines() do
        table.insert(tbl, filename)
    end
    dir:close()
    return tbl
end

local function rawMakeDirectory(path)
    path = fpath(path)
    logExecute("mkdir " .. cmdEscape(path))
    return rawIsDir(path)
end

local function _veryRawDirCopy(fromPath, toPath)
    return logExecute("xcopy " .. cmdEscapeWithoutCheck(fromPath) .. " " .. cmdEscapeWithoutCheck(toPath) .. " /e /c /y") == 0
end

local function _veryRawRemove(path)
    os.execute("del /s /q " .. cmdEscapeWithoutCheck(path))
    os.execute("rmdir /s /q " .. cmdEscapeWithoutCheck(path))
    os.remove(path)
end

local function rawRemove(path)
    path = fpath(path)
    if not rawExists(path) then return false end
    _veryRawRemove(path)
    return not rawExists(path)
end

local function rawCopy(fromPath, toPath)
    fromPath = fpath(fromPath)
    toPath = fpath(toPath)
    if rawIsDir(fromPath) then
        rawMakeDirectory(toPath)
        return logExecute("xcopy " .. cmdEscape(fromPath) .. " " .. cmdEscape(toPath) .. " /e /c /y") == 0
    else
        return logExecute("copy " .. cmdEscape(fromPath) .. " " .. cmdEscape(toPath) .. " /y") == 0
    end
end



local modsWhitelist = sm.json.parseJsonString(rawRawReadFile("modsWhitelist.json"))
local modsAllowed = {}
local function isModInWhilelist()
    local trace = debug.traceback()
    if modsAllowed[trace] ~= nil then
        local cacheData = modsAllowed[trace]
        return true, cacheData[1]
    else
        local description = json_open("$CONTENT_DATA/description.json")
        if modsAllowed[description.localId] ~= nil then
            modsAllowed[trace] = modsAllowed[description.localId]
            return modsAllowed[description.localId]
        else
            print("(betterAPI) -------- checking mod on whitelist: ", description.name, description.localId)
            modsAllowed[trace] = nil
            modsAllowed[description.localId] = nil
            for _, mod in ipairs(modsWhitelist) do
                print("comparison with", mod)
                local ok = true
                for k, v in pairs(mod) do
                    if k ~= "apis" and description[k] ~= v then
                        print("bad parameter", k, "need", description[k], "there is", v)
                        ok = false
                        break
                    end
                end
                if ok then
                    print("(betterAPI) -------- the mod was successfully FOUND in the whitelist: ", description.name)
                    local cacheData = {mod.apis}
                    modsAllowed[trace] = cacheData
                    modsAllowed[description.localId] = cacheData
                    return true, mod.apis
                end
            end
            print("(betterAPI) -------- the mod was NOT found in the whitelist:" .. string.char(7), description.name)
        end
    end
end

local function modCheck(...)
    local requiredAPIcategory = {...}
    local allowed, apis = isModInWhilelist()
    if not allowed then
        error("your mod does not have permission to use betterAPI from bananapen. contact bananapen for permission to use betterAPI")
    end
    if apis then
        for _, requiredAPI in ipairs(requiredAPIcategory) do
            local finded = false
            for i, v in ipairs(apis) do
                if v == requiredAPI then
                    finded = true
                    break
                end
            end
            if not finded then
                error("you don't have access to " .. requiredAPI .. " in betterAPI")
            end
        end
    end
end
dlmTunnel.check = modCheck

rawMakeDirectory(betterFsFolder)

local versionFileName = "betterVersion.txt"
local currentVersion = rawRawReadFile(versionFileName)

----------------------- protection

function sm.json.save(root, path)
    checkArg(1, root, "table")
    checkArg(2, path, "string")
    if isReadOnly(path) then
        error(fileReadonly, 2)
    end
    return json_save(root, path)
end

----------------------- api

local oldTickTime
local audioScripts = {}
local better

local function findAudioScript(object, delete)
    for index, audioScript in ipairs(audioScripts) do
        if audioScript.object == object then
            if delete then
                table.remove(audioScripts, index)
            end
            return audioScript
        end
    end
    error("the audioobject was not found", 3)
end

local function createAudio(fakePath, realPath, wait)
    local audioScript = {path = fakePath, writes = {}, volume = 0}
    audioScript.object = setmetatable({}, {__index = better.audio})
    audioScript.file = io.popen(vbsExec("playsound.vbs"), "w")
    table.insert(audioScript.writes, realPath .. "\n")
    for i = 1, wait do
        table.insert(audioScript.writes, true)
    end
    table.insert(audioScripts, audioScript)
    return audioScript.object
end

local function genVolume(volume)
    volume = math.floor((volume * 255) + 0.5)
    if volume < 0 then
        volume = 0
    elseif volume > 255 then
        volume = 255
    end
    return "v" .. vbsNumber(volume)
end

local function genBalance(balance)
    balance = math.floor((((balance + 1) / 2) * 255) + 0.5)
    if balance < 0 then
        balance = 0
    elseif balance > 255 then
        balance = 255
    end
    return "b" .. vbsNumber(balance)
end

local function genVolume(volume)
    volume = math.floor((volume * 255) + 0.5)
    if volume < 0 then
        volume = 0
    elseif volume > 255 then
        volume = 255
    end
    return "v" .. vbsNumber(volume)
end

--[[
    listener_direction_y * vector_x / math.sqrt(listener_direction_x^2 + listener_direction_y^2) -
    listener_direction_x * vector_y / math.sqrt(listener_direction_x^2 + listener_direction_y^2)
]]

local function spatial_audio(listener_position, listener_direction, sound_position)
    local distance = math.sqrt((sound_position.x - listener_position.x)^2 +
                                (sound_position.y - listener_position.y)^2 +
                                (sound_position.z - listener_position.z)^2)
  
    local listener_direction_x, listener_direction_y = listener_direction.x, listener_direction.y
    local sound_position_x, sound_position_y, sound_position_z = sound_position.x, sound_position.y, sound_position.z
    local vector_x, vector_y, vector_z = sound_position_x - listener_position.x, sound_position_y - listener_position.y, sound_position_z - listener_position.z 
    local balance = listener_direction_y * vector_x / math.sqrt(listener_direction_x^2 + listener_direction_y^2) -
    listener_direction_x * vector_y / math.sqrt(listener_direction_x^2 + listener_direction_y^2)
    balance = math.max(math.min(balance, 1.0), -1.0)
    return balance
end

local function textEditor(exp, text)
    checkArg(1, exp, "string")
    checkArg(2, text, "string")
    modCheck("textEditor")
    local filePath = "../BetterTemp/textEditor_" .. randomStr() .. "." .. exp
    os.remove(filePath)
    rawRawWriteFile(filePath, text)
    os.execute("START /B CMD /C CALL \"%UserProfile%\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe\" " .. filePath, "r")
    local deleted = false
    return function (delete)
        if delete then
            deleted = true
            os.remove(filePath)
        elseif not deleted then
            return rawRawReadFile(filePath)
        end
    end
end

local optimizationState

local screenWidth, screenHeight = 1920, 1080
local realScreenSize = false

local thread_mt = {
    __index = function(self, key)
        return better.thread[key]
    end
}

better = {
    version = tonumber(currentVersion),

    isAvailable = function()
        return not not (isModInWhilelist())
    end,

    tick = function()
        if not sm.isServerMode() then
            if not realScreenSize then
                screenWidth, screenHeight = sm.gui.getScreenSize()
                realScreenSize = true
            end
        end

        local currentTickTime = game_getCurrentTick()
        if not oldTickTime or currentTickTime ~= oldTickTime then
            betterDLL.tick()

            local delta = oldTickTime and (currentTickTime - oldTickTime) or 1
            for i = #audioScripts, 1, -1 do
                local audioScript = audioScripts[i]
                if audioScript.destroyFlag then
                    debugPrint("audioScript-destroy", audioScript.path)
                    audioScript.file:write("d")
                    audioScript.file:flush()
                    --audioScript.file:close()
                    table.remove(audioScripts, i)
                else
                    local spatial = audioScript.spatial
                    if spatial then
                        local ear = spatial[1]
                        local volume = 0
                        local balance
                        local eardir = spatial[3]
                        if eardir then
                            balance = 0
                        end
                        for i, speaker in ipairs(spatial[2]) do
                            volume = volume + ((speaker[2] - dist(ear, speaker[1])) / speaker[2])
                            if balance then
                                balance = balance + (spatial_audio(ear, eardir, speaker[1]) * 0.6)
                            end
                        end
                        volume = volume * audioScript.volume
                        
                        -- sending volume and balance
                        local val = genVolume(volume)
                        if val ~= spatial.volume then
                            table.insert(audioScript.writes, val)
                            spatial.volume = val
                        end

                        if balance then
                            val = genBalance(balance)
                            if val ~= spatial.balance then
                                table.insert(audioScript.writes, val)
                                spatial.balance = val
                            end
                        end
                    end

                    local pkg
                    while #audioScript.writes > 0 do
                        local msg = table.remove(audioScript.writes, 1)
                        if msg ~= true then
                            debugPrint("audioScript-write", noBell(msg))
                            pkg = (pkg or "") .. msg
                        else
                            debugPrint("audioScript-write skip")
                            break
                        end
                    end
                    if pkg then
                        audioScript.file:write(pkg .. "E")
                        audioScript.file:flush()
                    end
                end
            end

            oldTickTime = currentTickTime
        end
    end,

    registration = function(mod_uuid, mod_steamid, mod_foldername)
        checkArg(1, mod_uuid, "string", "Uuid")
        checkArg(2, mod_steamid, "string", "number")
        checkArg(3, mod_foldername, "string")
        modCheck()
        mod_uuid = tostring(mod_uuid)
        mod_steamid = tostring(mod_steamid)
        mod_foldername = tostring(mod_foldername)

        if not checkUuid(mod_uuid) then
            error("invalid UUID", 2)
        elseif mod_steamid:find("[^%d]") then
            error("invalid steamID", 2)
        elseif nameBadCheck(mod_foldername) then
            error("invalid folder name", 2)
        end

        if not registeredMods[mod_uuid] then
            registeredMods[mod_uuid] = {mod_steamid, mod_foldername}
            local mod_path, pathType = getModRealPath(mod_uuid)
            if true then
                local mod_raw_name = ""
                if mod_path:sub(#mod_path, #mod_path) == "/" then
                    mod_path = mod_path:sub(1, #mod_path - 1)
                end
                for i = #mod_path, 1, -1 do
                    local char = mod_path:sub(i, i)
                    if char == "/" or char == "\\" then
                        break
                    else
                        mod_raw_name = char .. mod_raw_name
                    end
                end
                if mod_raw_name ~= mod_steamid then
                    registeredMods[mod_uuid] = nil
                    print("suspicion of a fake steam-id", mod_foldername)
                    print("mod_raw_name", type(mod_raw_name), #tostring(mod_raw_name), mod_raw_name)
                    print("mod_steamid", type(mod_steamid), #tostring(mod_steamid), mod_steamid)
                    error("suspicion of a fake steam-id", 2)
                end
            end
            print("the mod has been successfully registered in betterAPI", mod_uuid, mod_steamid, mod_foldername)
        end
    end,

    autoRegistration = function(mod_foldername)
        modCheck()
        local description = json_open("$CONTENT_DATA/description.json")
        local mod_uuid, mod_steamid = description.localId, tostring(description.fileId or "0000000000")
        if type(mod_uuid) ~= "string" then
            error("couldn't get the mod's UUID", 2)
        end
        better.registration(mod_uuid, mod_steamid, mod_foldername)
        return mod_uuid, mod_steamid
    end,

    fast = function()
        modCheck("fast")
        --[[
        print("better.fast", pcall(function()
            if optimizationState ~= nil then
                return optimizationState
            end

            if jit then
                print("better.fast: trying...")
                local ok, err = pcall(function ()
                    local optimizations = {
                        "-fold",
                        "-cse",
                        "-dce",
                        "-narrow",
                        "-loop",
                        "-fwd",
                        "-dse",
                        "-abc",
                        "-sink",
                        "-fuse",
                        "-fma",
                        "hotloop=100",
                        "maxmcode=4096",
                        "sizemcode=128",
                        "sizemcode=128",
                        "maxtrace=5000",
                        "maxrecord=8000",
                        "maxirconst=1000",
                        "tryside=32"
                    }
                    jit.on()
                    jit.opt.start(unpack(optimizations))
                end)
                if ok then
                    print("better.fast: done!")
                else
                    print("better.fast: err: ", err)
                end
                optimizationState = ok
                return true
            else
                print("better.fast: JIT LIB NOT FOUND")
                return false
            end
        end))
        ]]
    end,

    getSteamID = function()
        modCheck("getSteamID")
        if steamID then
            return tostring(steamID)
        end
    end,

    loadstring = function (chunk, chunkname, env)
        checkArg(1, chunk, "string")
        checkArg(2, chunkname, "string", "nil")
        checkArg(3, env, "table")
        modCheck("loadstring")
        chunk = chunk or ""
        env = env or {}

        -- preventing bytecode loading
        if chunk:byte(1) == 27 then
            return nil, "binary bytecode prohibited"
        end

        -- checking for loading to the global environment (additional precautions)
        local code = load("return _G", chunkname, "t", env)
        local result = {pcall(code)}
        if result[1] and result[2] == _G then
            return nil, "load to the global environment is not possible"
        end

        code = load("return _BETTERAPI_UNSAFE_GLOBAL_ENV", chunkname, "t", env)
        local result = {pcall(code)}
        if result[1] and result[2] then
            return nil, "load to the global environment is not possible"
        end

        -- loading the code
        return load(chunk, chunkname, "t", env)
    end,

    loadfile = function(path, env)
        checkArg(1, path, "string")
        checkArg(2, env, "table")
        modCheck("loadfile")
        local content, err = rawReadFile(getRealPath(path))
        if content then
            return better.loadstring(content, "=" .. path, env)
        end
        return nil, err
    end,

    setmetatable = function(...)
        modCheck("setmetatable")
        return setmetatable(...)
    end,
    getmetatable = function(...)
        modCheck("getmetatable")
        return getmetatable(...)
    end,
    date = function(...)
        modCheck("date")
        return os.date(...)
    end,

    textEditor_txt = function(text)
        return textEditor("txt", text)
    end,

    textEditor_lua = function(text)
        return textEditor("lua", text)
    end,

    filesystem = {
        show = function(path)
            checkArg(1, path, "string", "nil")
            modCheck("filesystem")
            local realPath = getRealPath(path or "/", false, true)
            if rawIsDir(realPath) then
                logExecute("explorer " .. cmdEscape(realPath))
                return true
            end
            return false
        end,
        readFile = function(path)
            checkArg(1, path, "string")
            modCheck("filesystem")
            return rawReadFile(getRealPath(path))
        end,
        writeFile = function(path, content)
            checkArg(1, path, "string")
            checkArg(2, content, "string")
            modCheck("filesystem")
            return rawWriteFile(getRealPath(path, true), content)
        end,
        makeDirectory = function(path)
            checkArg(1, path, "string")
            modCheck("filesystem")
            return rawMakeDirectory(getRealPath(path, true))
        end,
        isDirectory = function(path)
            checkArg(1, path, "string")
            modCheck("filesystem")
            return rawIsDir(getRealPath(path))
        end,
        exists = function(path)
            checkArg(1, path, "string")
            modCheck("filesystem")
            return rawExists(getRealPath(path))
        end,
        list = function(path)
            checkArg(1, path, "string")
            modCheck("filesystem")
            return rawList(getRealPath(path, false, true))
        end,
        rename = function(fromPath, toPath)
            checkArg(1, fromPath, "string")
            checkArg(2, toPath, "string")
            modCheck("filesystem")
            return not not os.rename(getRealPath(fromPath, true), getRealPath(toPath, true))
        end,
        remove = function(path)
            checkArg(1, path, "string")
            modCheck("filesystem")
            return not not rawRemove(getRealPath(path, true))
        end,
        copy = function(fromPath, toPath)
            checkArg(1, fromPath, "string")
            checkArg(2, toPath, "string")
            modCheck("filesystem")
            return not not rawCopy(getRealPath(fromPath, true), getRealPath(toPath, true))
        end
    },

    nativeCoroutine = { --it is not recommended for use. IN NO CASE SHOULD YOU USE IT AT THE SAME TIME AS "coroutine"
        create = function(...)
            modCheck("coroutine")
            return coroutine.create(...)
        end,
        status = function(...)
            modCheck("coroutine")
            return coroutine.status(...)
        end,
        running = function(...)
            modCheck("coroutine")
            return coroutine.running(...)
        end,
        resume = function(...)
            modCheck("coroutine")
            return coroutine.resume(...)
        end,
		wrap = function(...)
            modCheck("coroutine")
            return coroutine.wrap(...)
        end,
		yield = function(...)
            modCheck("coroutine")
            return coroutine.yield(...)
        end
    },

    debug = { --taken from opencomputers (safety debug-api)
        getinfo = function(...)
            modCheck("debug")
            local result = debug.getinfo(...)
            if result then
                -- Only make primitive information available in the sandbox.
                return {
                    source = result.source,
                    short_src = result.short_src,
                    linedefined = result.linedefined,
                    lastlinedefined = result.lastlinedefined,
                    what = result.what,
                    currentline = result.currentline,
                    nups = result.nups,
                    nparams = result.nparams,
                    isvararg = result.isvararg,
                    name = result.name,
                    namewhat = result.namewhat,
                    istailcall = result.istailcall
                }
            end
        end,
        traceback = debug.traceback,
        -- using () to wrap the return of debug methods because in Lua doing this
        -- causes only the first return value to be selected
        -- e.g. (1, 2) is only (1), the 2 is not returned
        -- this is critically important here because the 2nd return value from these
        -- debug methods is the value itself, which opens a door to exploit the sandbox
        getlocal = function(...)
            modCheck("debug")
            return (debug.getlocal(...))
        end,
        getupvalue = function(...)
            modCheck("debug")
            return (debug.getupvalue(...))
        end
    },

    audio = {
        createFromFile = function(path, wait)
            checkArg(1, path, "string")
            modCheck("audio")
            return createAudio(path, getRealPath(path), wait or 20)
        end,
        createFromUrl = function(url, wait)
            checkArg(1, url, "string")
            modCheck("audio", "http")
            if startwith(url, "http://") or startwith(url, "https://") then
                return createAudio(url, url, wait or 20)
            else
                error("incorrect url", 2)
            end
        end,
        destroy = function(self)
            local audioScript = findAudioScript(self)
            audioScript.destroyFlag = true
        end,
        stop = function(self)
            local audioScript = findAudioScript(self)
            table.insert(audioScript.writes, "0")
        end,
        start = function(self)
            local audioScript = findAudioScript(self)
            table.insert(audioScript.writes, "1")
        end,
        pause = function(self)
            local audioScript = findAudioScript(self)
            table.insert(audioScript.writes, "2")
        end,
        setVolume = function(self, volume)
            volume = clamp(volume, 0, 1)
            local audioScript = findAudioScript(self)
            if volume ~= audioScript.volume then
                audioScript.volume = volume

                if not audioScript.spatial then
                    table.insert(audioScript.writes, genVolume(volume))
                end
            end
        end,
        setBalance = function(self, balance)
            balance = clamp(balance, -1, 1)
            local audioScript = findAudioScript(self)
            if balance ~= audioScript.balance then
                audioScript.balance = balance
                
                if not audioScript.spatial then
                    table.insert(audioScript.writes, genBalance(balance))
                end
            end
        end,
        setRate = function(self, rate)
            rate = clamp(rate, 0, 4)
            local audioScript = findAudioScript(self)
            if rate ~= audioScript.rate then
                audioScript.rate = rate

                rate = math.floor(((rate / 4) * 255) + 0.5)
                if rate < 0 then
                    rate = 0
                elseif rate > 255 then
                    rate = 255
                end
                table.insert(audioScript.writes, "r" .. vbsNumber(rate))
            end
        end,
        setLoop = function(self, loop)
            local audioScript = findAudioScript(self)
            if loop ~= audioScript.loop then
                audioScript.loop = loop

                if loop then
                    table.insert(audioScript.writes, "5")
                else
                    table.insert(audioScript.writes, "6")
                end
            end
        end,
        setPosition = function(self, second)
            local audioScript = findAudioScript(self)
            table.insert(audioScript.writes, "p" .. vbsNumber(second))
        end,
        seek = function(self, seek)
            local audioScript = findAudioScript(self)
            if seek > 0 then
                table.insert(audioScript.writes, "s" .. vbsNumber(math.ceil(seek)))
            elseif seek < 0 then
                table.insert(audioScript.writes, "S" .. vbsNumber(math.ceil(-seek)))
            end
        end,
        updateSpatialSound = function(self, earpos, speakers, eardir)
            checkArg(2, earpos, "Vec3")
            checkArg(3, speakers, "table")
            checkArg(4, eardir, "Vec3", "nil")

            for i, v in ipairs(speakers) do
                if type(v) == "table" then
                    if type(v[1]) ~= "Vec3" then
                        error("the values of 1 in speaker " .. i .. " are not Vec3 (position)", 2)
                    elseif type(v[2]) ~= "number" then
                        error("the values of 2 in speaker " .. i .. " are not number (distance)", 2)
                    end
                else
                    error("speaker " .. i .. " is not a table. speaker table: {pos:vec3, dist:number}", 2)
                end
            end
            local audioScript = findAudioScript(self)
            audioScript.spatial = {earpos, tableCopy(speakers), eardir}
        end,
        noSpatialSound = function(self)
            local audioScript = findAudioScript(self)
            audioScript.spatial = nil
        end
    },

    canvas = {
        alphaColor = -1,
        create = function(sizeX, sizeY)
            modCheck("canvas")
            return betterDLL.canvas_create(sizeX, sizeY)
        end,

        clear = betterDLL.canvas_clear,
        get = betterDLL.canvas_get,
        set = betterDLL.canvas_set,
        fill = betterDLL.canvas_fill,
        destroy = betterDLL.canvas_destroy,

        noUpdate = function(self)
            modCheck("canvas")
            betterDLL.canvas_noUpdate(self)
        end,
        update_raw = function(self, topLeftX, topLeftY, topRightX, topRightY, bottomLeftX, bottomLeftY, bottomRightX, bottomRightY)
            modCheck("canvas")
            betterDLL.canvas_update(self, topLeftX, topLeftY, topRightX, topRightY, bottomLeftX, bottomLeftY, bottomRightX, bottomRightY)
        end,
        update_2d = function(self, x, y, sizeX, sizeY)
            modCheck("canvas")
            local x2, y2 = (x + sizeX) - 1, (y + sizeY) - 1
            betterDLL.canvas_update(self, x, y, x2, y, x, y2, x2, y2)
        end,
        update_3d = function(self, worldPosition, upDir, leftDir, scaleX, scaleY)
            modCheck("canvas")
            upDir = upDir:normalize() * scaleY
            leftDir = leftDir:normalize() * scaleX
            local topLeftX, topLeftY = sm.render.getScreenCoordinatesFromWorldPosition(worldPosition + upDir + leftDir, screenWidth, screenHeight)
            local topRightX, topRightY = sm.render.getScreenCoordinatesFromWorldPosition((worldPosition + upDir) - leftDir, screenWidth, screenHeight)
            local bottomLeftX, bottomLeftY = sm.render.getScreenCoordinatesFromWorldPosition((worldPosition - upDir) + leftDir, screenWidth, screenHeight)
            local bottomRightX, bottomRightY = sm.render.getScreenCoordinatesFromWorldPosition(worldPosition - upDir - leftDir, screenWidth, screenHeight)
            betterDLL.canvas_update(self, topLeftX, topLeftY, topRightX, topRightY, bottomLeftX, bottomLeftY, bottomRightX, bottomRightY)
        end
    },

    thread = {
        new = function(code)
            checkArg(1, code, "string")
            modCheck("thread")
            local threadObj = setmetatable({}, thread_mt)
            threadList[threadObj] = betterDLL.thread_new(code)
            return threadObj
        end,
        threadTunnelSet = function(self, index, value)
            checkArg(2, index, "number")
            checkArg(3, value, "string", "number", "boolean", "nil")
            modCheck("thread")
            betterDLL.thread_set(assert(threadList[self]), index, value)
        end,
        threadTunnelGet = function(self, index)
            checkArg(2, index, "number")
            modCheck("thread")
            return betterDLL.thread_get(assert(threadList[self]), index)
        end,
        free = function(self)
            modCheck("thread")
            local result = betterDLL.thread_free(assert(threadList[self]))
            if result then
                threadList[self] = nil
            end
            return result
        end,
        kill = function(self)
            modCheck("thread")
            betterDLL.thread_kill(assert(threadList[self]))
        end,
        result = function(self)
            modCheck("thread")
            return betterDLL.thread_result(assert(threadList[self]))
        end
    },

    mouse = {
        isLeft = function()
            modCheck("mouse")
            return not not (misc.getAsyncKeyState(dlm_util.KEY_INPUTS.lmb))
        end,
        isRight = function()
            modCheck("mouse")
            return not not (misc.getAsyncKeyState(dlm_util.KEY_INPUTS.rmb))
        end,
        isCenter = function()
            modCheck("mouse")
            return not not (misc.getAsyncKeyState(dlm_util.KEY_INPUTS.mmb))
        end
    },

    keyboard = {
        keys = dlm_util.KEY_INPUTS,
        isKey = function(keycode)
            checkArg(1, keycode, "number")
            modCheck("keyboard")
            return not not (misc.getAsyncKeyState(keycode))
        end
    },

    openAI = {
        textRequest = function(apikey, model, prompt, request)
            checkArg(1, apikey, "string", "nil") --nil will try to use a custom server
            checkArg(2, model, "string", "nil")
            checkArg(3, prompt, "string")
            checkArg(4, request, "string")
            modCheck("openAI")

            local returnPath = "../BetterTemp/ai_return.txt"
            local promptPath = "../BetterTemp/ai_prompt.txt"
            local requestPath = "../BetterTemp/ai_request.txt"

            os.remove(returnPath)
            os.remove(promptPath)
            os.remove(requestPath)
            rawRawWriteFile(promptPath, prompt)
            rawRawWriteFile(requestPath, request)

            python.async("ai_textRequest.py", apikey or "", model or "")

            local timer
            return function ()
                if timer or rawRawExists(returnPath) then
                    timer = (timer or 20) - 1
                end
                if timer == 0 then
                    local returnData = rawRawReadFile(returnPath)
                    os.remove(returnPath)
                    os.remove(promptPath)
                    os.remove(requestPath)
                    if type(returnData) == "string" then
                        return returnData
                    else
                        return nil, "failed to read file"
                    end
                end
            end
        end
    }
}

if not disableCoroutineFix then
    better.coroutine = { --for strange reasons, calling the game API methods inside coroutine calls bugsplat. this coroutine implementation is recognized to work around this
        fixed = true, --tells SComputers that it is not necessary to prevent the use of API methods from coroutine

        create = function(...)
            modCheck("coroutine")
            return coroutine.create(...)
        end,
        status = function(...)
            modCheck("coroutine")
            return coroutine.status(...)
        end,
        running = function(...)
            modCheck("coroutine")
            return coroutine.running(...)
        end,

        resume = function(co, ...)
            checkArg(1, co, "thread")
            modCheck("coroutine")
            local args = {...}
            while true do
                local result = {coroutine.resume(co, args and unpack(args, 1, holeLen(args)))}
                args = nil
                if result[1] then
                    if coroutine.status(co) == "dead" then 
                        return true, unpack(result, 2, holeLen(result))
                    elseif result[2] ~= nil then
                        if coroutine.running() then
                            args = {coroutine.yield(result[2])}
                        else
                            args = {{pcall(result[2][1], unpack(result[2][2]))}}
                        end
                    else
                        return true, unpack(result, 3, holeLen(result))
                    end
                else
                    return false, result[2]
                end
            end
        end,
		wrap = function(f)
            modCheck("coroutine")
            local co = coroutine.create(f)
            return function(...)
                local result = {better.coroutine.resume(co, ...)}
                if result[1] then
                    return unpack(result, 2, holeLen(result))
                else
                    error(result[2], 0)
                end
            end
        end,
		yield = function(...)
            modCheck("coroutine")
            return coroutine.yield(nil, ...)
        end
    }
else
    better.coroutine = better.nativeCoroutine
end

----------------------- api hook

local function upcall(func, ...)
    local result = coroutine.yield({func, {...}})
    if result[1] then
        return unpack(result, 2, holeLen(result))
    else
        error(result[2], 3)
    end
end

local metaFilled = setmetatable({}, {__mode = "k"})
local hookedFunctions = setmetatable({}, {__mode = "k"})
local whook = "withoutHook_"

local function hookObject(object, recursionTableInfo)
    recursionTableInfo = recursionTableInfo or {}

    local t = type(object)
    if userdataNames[t] then
        local metatable = getmetatable(object)
        if metatable and not metaFilled[metatable] then
            for metaKey in pairs(metaKeys) do
                local old_func = metatable[metaKey]
                if old_func then
                    local new_func
                    new_func = function (...)
                        if coroutine.running() then
                            return upcall(new_func, ...)
                        end

                        local ret = {spcall(old_func, ...)}
                        for i = 1, holeLen(ret) do
                            ret[i] = hookObject(ret[i], recursionTableInfo)
                        end
                        return unpack(ret, 1, holeLen(ret))
                    end
                    metatable[metaKey] = new_func
                    metatable[whook .. metaKey] = old_func
                end
            end

            --[[
            function metatable:__tostring()
                if coroutine.running() then
                    return upcall(metatable.__tostring, self)
                end

                return tostring(self)
            end
            ]]

            metaFilled[metatable] = true
        end
    elseif t == "function" then
        if not hookedFunctions[object] then
            hookedFunctions[object] = function(...)
                if coroutine.running() then
                    return upcall(object, ...)
                end

                local ret = {spcall(object, ...)}
                for i = 1, holeLen(ret) do
                    ret[i] = hookObject(ret[i], recursionTableInfo)
                end
                return unpack(ret, 1, holeLen(ret))
            end
        end

        return hookedFunctions[object]
    elseif t == "table" then
        if not recursionTableInfo[object] then
            recursionTableInfo[object] = true
            for k, v in pairs(object) do
                object[k] = hookObject(v, recursionTableInfo)
            end
        end
    end

    return object
end

local hookedApis = setmetatable({}, {__mode = "k"})

local function hookApi(tbl)
    if disableCoroutineFix then
        return
    end
    
    if hookedApis[tbl] then
        return
    end
    hookedApis[tbl] = true

    for k, v in pairs(tbl) do
        local t = type(v)
        if t == "table" then
            hookApi(v)
        elseif type(k) ~= "string" or k:sub(1, #whook) ~= whook then
            local nv = hookObject(v)
            tbl[k] = nv
            if nv ~= v then
                tbl[whook .. k] = v
            end
        end
    end
end

local sm_exists = sm.exists
function unsafe_env.sm.exists(obj)
    better.tick()
    return sm_exists(obj)
end

hookApi(sm)

function unsafe_env.class(super)

	local klass = {}

	-- Copy members from super.
	if super then
		for k,v in pairs(super) do
			klass[k] = v
		end
	end

	local meta = {}

	-- Emulate constructor syntax.
	-- Triggers when a value is called like a function.
	meta.__call = function(self, ...)
		local instance = setmetatable({}, self)

		return instance
	end

	-- Emulate classes using prototyping.
	setmetatable(klass, meta)
	klass.__index = function(self, key)
        if key == "server_onCreate" or key == "client_onCreate" then
            local userfunc = rawget(klass, key)
            if userfunc then
                return function (self, ...)
                    hookApi(self)
                    return userfunc(self, ...)
                end
            end
        end
        
        return klass[key]
    end

	return klass

end

----------------------- update check

local workshopVersion = rawRawReadFile(selfWorkshopContentFolder .. versionFileName)
if forceUpdate or (currentVersion and workshopVersion and currentVersion ~= workshopVersion) then
    print("start of automatic betterAPI update. force: ", forceUpdate)
    print("version: ", currentVersion, ">", workshopVersion)
    local from, to = fpathWithoutCheck(selfWorkshopContentFolder), "."
    print("copy", from, ">", to)
    python.async("betterUpdate.py", from, to, "ScrapMechanic.exe -last_save", workshopVersion)
    os.exit()
    --print("update end with code", _veryRawDirCopy(from, to)) - old update code
else
    print("there are no updates")
    print("currentVersion", currentVersion)
    print("workshopVersion", workshopVersion)
end

-----------------------

local betterShadow = tableCopy(better)

--[[
    betterDebug.lua in fact, it can be used not only for debugging betterAPI.
    it can be used to create custom functionality in the better API without changing its files without disrupting updates.
]]
local betterDebug, err = loadfile("betterDebug.lua")
if betterDebug then
    print("betterDebug...")
    print("betterDebug result: ", xpcall(betterDebug, debug.traceback, betterShadow))
else
    print("betterDebug err: ", err)
end

unsafe_env.better = betterShadow
unsafe_env.setmetatable = betterShadow.setmetatable
unsafe_env.getmetatable = betterShadow.getmetatable

local dlm = unsafe_env.dlm
dlm.setmetatable = betterShadow.setmetatable
dlm.getmetatable = betterShadow.getmetatable
dlm.coroutine = betterShadow.coroutine