print("> python.lua")

local function readFile(path)
   local file, err = io.open(path, "rb")
   if not file then return nil, tostring(err or "unknown error") end
   local content = file:read("*a")
   file:close()
   return tostring(content)
end

local function writeFile(path, data)
   local file, err = io.open(path, "wb")
   if not file then return nil, tostring(err or "unknown error") end
   file:write(tostring(data))
   file:close()
   return true
end

local pyVersionPath = "python/unpackVersion.txt"
local betterVersion = readFile("betterVersion.txt")
local unpackVersion = readFile(pyVersionPath)
if not unpackVersion or betterVersion ~= unpackVersion then
   print("unpacking python...")
   os.execute("unzip -o -q python/bin.zip -d python")
   print("python is unpacked!")
   writeFile(pyVersionPath, betterVersion)
end

local workingDirectory = io.popen("cd"):read("*l")
workingDirectory = workingDirectory:gsub("%\\", "%/")
if workingDirectory:sub(#workingDirectory, #workingDirectory) ~= "/" then
   workingDirectory = workingDirectory .. "/"
end

local python = {}
local selfDelBat = [[del /f/q "%~0" | exit]]

local function getArgs(...)
   local tbl = {...}
   for i, v in ipairs(tbl) do
      tbl[i] = " \"" .. tostring(v) .. "\""
   end
   return table.concat(tbl, "")
end

local function newBat(cmd)
   local batPath = workingDirectory .. "../BetterTemp/" .. math.floor(math.random(0, 99999999)) .. ".bat"
   writeFile(batPath, cmd)
   return batPath
end

local function writeBat(path, ...)
   local cmd = "@echo off\n" .. selfDelBat .. "\ncd \"" .. workingDirectory .. "\"\n\"" .. workingDirectory .. "python/python312/python.exe\" \"" .. workingDirectory .. "python/init.py\" \"" .. workingDirectory .. path .. "\"" .. getArgs(...)
   return "\"" .. newBat(cmd) .. "\""
end

function python.dofile(path, ...)
   return os.execute(writeBat(path, ...))
end

function python.async(path, ...)
   return os.execute("START /B CMD /C CALL " .. writeBat(path, ...))
end

return python