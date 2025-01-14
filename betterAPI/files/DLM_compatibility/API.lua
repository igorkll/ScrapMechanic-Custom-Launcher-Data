
--[[
	COPYRIGHT (c) 2022 MrCrackx02
	I do NOT give ANYONE the permission to copy, modify or redistribute ANY part of the code in this file!
	If you do want to use part of it for your own project(s), you have to ask me for permission first!
	You can do so on Discord: https://discord.gg/2eACct5FDm or https://discordapp.com/users/518349368500420618
]]

--[[ MR.Logic
	since the mod is no longer supported by the author,
	I don't see anything wrong with supporting it myself
]]

if not unsafe_env.sm.player then
	return
end

local dlmTunnel = ...

--unsafe_env.test = require( "experimental" )

local DLM_VERSION = "2.7"

local http = require( "https" )
local xml = require( "xml2lua" )
local xml_tree = require( "xml_tree" )

local util = require( "util" )

loadfile( "DLM_compatibility\\enableColorConsole.lua" )()
local fmod = require( "fmodlua" )
local misc = require( "misc" )
local Objects = loadfile( "DLM_compatibility\\Objects.lua" )( fmod )


--initialize APIs

local userSteamId = misc.getSteamId()
if not userSteamId then
	util.colorPrint( "red", "ERROR: Failed to get user steam ID!" )
else
	util.colorPrint( "magenta", "Found steam ID!" )
end

local fmod_result, fmod_state = fmod.init( 0, 64, 256, 0 )
local fmodLoaded = ( fmod_result == 0 and fmod_state == 4 )
local previousUpdateTick = -1
if not fmodLoaded then
	util.colorPrint( "red", "ERROR: Failed to initialize FMOD API!" )
else
	util.colorPrint( "magenta", "FMOD API initialized successfully!" )
	util.colorPrint( "magenta", fmod.loadBank( "Master.bank", false ) )
end



local temporaryLayouts = {}

local getCurrentTick = sm.game.getCurrentTick
local previousClearTick = 0
local createGuiFromLayout = sm.gui.createGuiFromLayout
local fmodUpdateResultCache

local audioBankGuids = {}

local contentPaths = {
	["$TEMP_DATA"] = os.getenv( "LOCALAPPDATA" ) .. "/Axolot Games/Scrap Mechanic/Temp",
	["$CACHE_DATA"] = "../Cache",
	["$GAME_DATA"] = "../Data",
	["$SURVIVAL_DATA"] = "../Survival",
	["$CHALLENGE_DATA"] = "../ChallengeData"
	--["$CONTENT_uuid"] = "...../workshop/content/387990/[modId]/...",
	--["$CONTENT_uuid"] = "%AppData%"/Axolot Games/Scrap Mechanic/User/User_[userId]/Mods/[modName]/...
}

local workshop = "../../../workshop/content/387990/"
local appData = os.getenv( "APPDATA" ) .. "/Axolot Games/Scrap Mechanic/User"

local function resolveContentPath( contentPath, check )
	if contentPath:gsub( "%.%.", "" ) ~= contentPath then
		util.colorPrint( "red", "ERROR: Illegal Path!" )
		return
	end
	if contentPath:gsub( "$CONTENT_DATA", "" ) ~= contentPath then
		util.colorPrint( "red", "ERROR: Failed to resolve content path - $CONTENT_DATA is not supported, use $CONTENT_uuid instead!" )
		return
	end
	for key, filePath in pairs( contentPaths ) do
		local newPath = contentPath:gsub( key:gsub( "%-", "%%-" ), filePath )
		if newPath ~= contentPath then
			return newPath
		end
	end
	if not check then
		util.colorPrint( "red", "ERROR: Failed to resolve content path: '" .. contentPath .. "'!" )
		util.colorPrint( "red", "Make sure you setup the content path with 'setupContentPath' before using path-dependent functions!" )
	end
	return
end

local function setupContentPath( name, localId, steamId )
	assert( userSteamId, "No user steam ID!" )
	if contentPaths["$CONTENT_" .. localId] then
		util.colorPrint( "yellow", "WARNING: Content path for content '" .. name .. "' is already set!"  )
		return 0
	end
	util.colorPrint( "magenta", "Try getting content path, name: '" .. name .. "', localId:", localId, ", steamId:", tostring( steamId ) )

	util.colorPrint( "magenta", "Try getting local path..." )
	local path = appData .. "/User_" .. userSteamId .. "/Mods/" .. name .. "/"

	local file, err = io.open( path .. "description.json", "r" )
	if file and not err then
		util.colorPrint( "green", "Found local path for content: '" .. name .. "', localId:", localId, ", steamId:", tostring( steamId ) )
		util.colorPrint( "green", "Path:", path )
		contentPaths["$CONTENT_" .. localId] = path
		file:close()
		return path
	else
		util.colorPrint( "yellow", "Failed to find local path!" )
		--util.colorPrint( "red", err )
		util.colorPrint( "magenta", "Try getting workshop path..." )
		path = workshop .. tostring( steamId ) .. "/"
		local file, err = io.open( path .. "description.json", "r" )
		if file and not err then
			util.colorPrint( "green", "Found workshop path for content: '" .. name .. "', localId:", localId, ", steamId:", tostring( steamId ) )
			util.colorPrint( "green", "Path:", path )
			contentPaths["$CONTENT_" .. localId] = path
			file:close()
			return path
		else
			util.colorPrint( "red", "ERROR: Failed to find path for content: name: '" .. name .. ", localId: ", localId, ", steamId:", tostring( steamId ) )
			--util.colorPrint( "red", err )
			return
		end
	end
end


local function parseGuidsFile( file )
	local guids = {}
	for line in file:lines() do
		if line:gsub( "event:/", "" ) ~= line then
			local guid = line:sub( 1, 38 )
			local event = line:sub( 40, #line )
			util.colorPrint( "blue", "Found GUID:", guid, ", Event Name:", event )
			guids[event] = guid
		end
	end
	return guids
end

local function onAudioBankUnloaded( bank )
	if audioBankGuids[bank] then
		audioBankGuids[bank] = nil
	end
end

Objects.setBankUnloadCallback( onAudioBankUnloaded )

local function unsafe_loadfile( filepath, env )
	dlmTunnel.check()
	assert( type( env ) == 'table', "bad argument #3 to 'dlm.loadfile' (table expected, got " .. type( env ) .. ")" )
	local f, err = loadfile( resolveContentPath( filepath, false ), "t", env or unsafe_env )
	return f, err
end

local function unsafe_loadstring( str, chunkname, env )
	dlmTunnel.check()
	assert( type( env ) == 'table', "bad argument #3 to 'dlm.loadstring' (table expected, got " .. type( env ) .. ")" )
	local f, err = loadstring( str, chunkname, "t", env or unsafe_env )
	return f, err
end

----------------------------------------------------------

local bit = bit or bit32

--[[
local function readFileDialogWindow()
	local ffi = require("ffi")

	ffi.cdef([[
		typedef int BOOL;
		typedef unsigned int DWORD;
		typedef void* HINSTANCE;
		typedef void* LPSTR;
		typedef void* LPARAM;
		typedef void* WORD;


	typedef void* HWND;
	typedef const char* LPCSTR;

	HWND GetConsoleWindow(void);
	int GetOpenFileNameA(void* ofn);
	] ])

	local OFN_MAX_PATH = 260
	local OFN_FILEMUSTEXIST = 0x00001000
	local OFN_PATHMUSTEXIST = 0x00000800

	local OPENFILENAMEA = ffi.typeof([[struct {
		DWORD        lStructSize;
		HWND         hwndOwner;
		HINSTANCE    hInstance;
		LPCSTR       lpstrFilter;
		LPSTR        lpstrCustomFilter;
		DWORD        nMaxCustFilter;
		DWORD        nFilterIndex;
		LPSTR        lpstrFile;
		DWORD        nMaxFile;
		LPSTR        lpstrFileTitle;
		DWORD        nMaxFileTitle;
		LPCSTR       lpstrInitialDir;
		LPCSTR       lpstrTitle;
		DWORD        Flags;
		WORD         nFileOffset;
		WORD         nFileExtension;
		LPCSTR       lpstrDefExt;
		LPARAM       lCustData;
		void*        lpfnHook;
		LPCSTR       lpTemplateName;
		void*        pvReserved;
		DWORD        dwReserved;
		DWORD        FlagsEx;
	}] ])

	local function openFileDialog()
		local ofn = OPENFILENAMEA()
		ofn.lStructSize = ffi.sizeof(OPENFILENAMEA)
		ofn.hwndOwner = ffi.C.GetConsoleWindow()
		ofn.lpstrFile = ffi.new("char[?]", OFN_MAX_PATH)
		ofn.nMaxFile = OFN_MAX_PATH
		ofn.Flags = bit.bor(OFN_FILEMUSTEXIST, OFN_PATHMUSTEXIST)

		if ffi.C.GetOpenFileNameA(ffi.cast("void*", ofn)) then
			return ffi.string(ofn.lpstrFile)
		else
			return nil
		end
	end

	return openFileDialog()
end

local function writeFileDialogWindow()
	local ffi = require("ffi")

	ffi.cdef([[
		typedef int BOOL;
		typedef unsigned int DWORD;
		typedef void* HINSTANCE;
		typedef void* LPSTR;
		typedef void* LPARAM;
		typedef void* WORD;
		

	typedef void* HWND;
	typedef const char* LPCSTR;

	HWND GetConsoleWindow(void);
	int GetSaveFileNameA(void* ofn);
	] ])

	local OFN_MAX_PATH = 260
	local OFN_OVERWRITEPROMPT = 0x00000002
	local OFN_PATHMUSTEXIST = 0x00000800

	local OPENFILENAMEA = ffi.typeof([[struct {
	DWORD        lStructSize;
	HWND         hwndOwner;
	HINSTANCE    hInstance;
	LPCSTR       lpstrFilter;
	LPSTR        lpstrCustomFilter;
	DWORD        nMaxCustFilter;
	DWORD        nFilterIndex;
	LPSTR        lpstrFile;
	DWORD        nMaxFile;
	LPSTR        lpstrFileTitle;
	DWORD        nMaxFileTitle;
	LPCSTR       lpstrInitialDir;
	LPCSTR       lpstrTitle;
	DWORD        Flags;
	WORD         nFileOffset;
	WORD         nFileExtension;
	LPCSTR       lpstrDefExt;
	LPARAM       lCustData;
	void*        lpfnHook;
	LPCSTR       lpTemplateName;
	void*        pvReserved;
	DWORD        dwReserved;
	DWORD        FlagsEx;
	}] ])

	local function saveFileDialog()
		local ofn = OPENFILENAMEA()
		ofn.lStructSize = ffi.sizeof(OPENFILENAMEA)
		ofn.hwndOwner = ffi.C.GetConsoleWindow()
		ofn.lpstrFile = ffi.new("char[?]", OFN_MAX_PATH)
		ofn.nMaxFile = OFN_MAX_PATH
		ofn.Flags = bit.bor(OFN_OVERWRITEPROMPT, OFN_PATHMUSTEXIST)

		if ffi.C.GetSaveFileNameA(ffi.cast("void*", ofn)) then
			return ffi.string(ofn.lpstrFile)
		else
			return nil
		end
	end
	return saveFileDialog()
end
]]


local powershellScriptOpen = [[
	Add-Type -AssemblyName System.Windows.Forms
	$dialog = New-Object System.Windows.Forms.OpenFileDialog
	$dialog.Filter = "All Files (*.*)|*.*"
	$dialog.Title = "Select File"
	if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
		Write-Output $dialog.FileName
	}
]]

local powershellScriptSave = [[
	Add-Type -AssemblyName System.Windows.Forms
	$dialog = New-Object System.Windows.Forms.SaveFileDialog
	$dialog.Filter = "All Files (*.*)|*.*"
	$dialog.Title = "Сохраните файл"
	if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
		Write-Output $dialog.FileName
	}
]]

function explorerDialogWindow(saveMode)
    local powershellScript = saveMode and powershellScriptSave or powershellScriptOpen

    local scriptFile = os.tmpname() .. ".ps1"
    local file = assert(io.open(scriptFile, "w"))
    file:write(powershellScript)
    file:close()

    local command = 'powershell -ExecutionPolicy Bypass -File "' .. scriptFile .. '"'
    local handle = io.popen(command)
	if not handle then os.remove(scriptFile) return end
    local result = handle:read("*a")
    handle:close()

    os.remove(scriptFile)

    local str = result:match("(.+)%s*$")
	if str then
		local newstr = ""
		for i = 1, #str do
			local char = str:sub(i, i)
			if char ~= "\n" then
				newstr = newstr .. char
			end
		end
		return newstr
	end
end

----------------------------------------------------------

local api = {
	-- added by me (MR.Logic)
	--[[ --overwritten in betterAPI
	coroutine = { --The behavior of any scrap mechanic and other api methods may be unpredictable from coroutine, so they should not be called from there.
		create = coroutine.create,
		status = coroutine.status,
		resume = coroutine.resume,
		yield = coroutine.yield,
		running = coroutine.running,
		wrap = coroutine.wrap
	},
	]]

	debug = { --an extremely simplified debug api so that it cannot be used to exit the sandbox
		traceback = debug.traceback
	},

	--[[
	io = {
		readFile = function ()
			local userSelect = explorerDialogWindow()
			if not userSelect then
				return nil, "the user did not select the file"
			end

			local file, err = io.open(userSelect, "rb")
			if not file then
				return nil, tostring(err)
			end
			local content, err = file:read("*a")
			if not content then
				return nil, tostring(err)
			end
			file:close()
			return content
		end,
		writeFile = function (content)
			assert( Objects.checkType( content ) == 'string', "bad argument #1 to 'writeFile' (string expected, got " .. Objects.checkType( content ) .. ")" )

			local userSelect = explorerDialogWindow(true)
			if not userSelect then
				return nil, "the user canceled the writing of the file"
			end

			local file, err = io.open(userSelect, "wb")
			if not file then
				return nil, tostring(err)
			end
			file:write(content)
			file:close()
			return true
		end
	},
	]]

	-- ORIGINAL DLM APIS
	constants = {
		audio = {
			api_results = util.API_RESULTS,
			fmod_playback_states = util.FMOD_PLAYBACK_STATES,
			fmod_loading_states = util.FMOD_LOADING_STATES,
			fmod_results = util.FMOD_RESULTS
		},
		input = util.KEY_INPUTS
	},

	loadfile = unsafe_loadfile,
	loadstring = unsafe_loadstring,

	game = {
		getGameMode = function()
			dlmTunnel.check()
			return misc.getGameMode()
		end
	},

	http = {
		get = function( url, headers )
			error("the http api is not available", 2)
			--[[
			dlmTunnel.check("http")
			assert( Objects.checkType( url ) == 'string', "bad argument #1 to 'get' (string expected, got " .. Objects.checkType( url ) .. ")" )
			assert( Objects.checkType( headers ) == 'table', "bad argument #2 to 'get' (table expected, got " .. Objects.checkType( headers ) .. ")" )
			return http.request( url, { method = 'GET', headers = headers } )
			]]
		end,

		post = function( url, data, headers )
			error("the http api is not available", 2)
			--[[
			dlmTunnel.check("http")
			assert( Objects.checkType( url ) == 'string', "bad argument #1 to 'post' (string expected, got " .. Objects.checkType( url ) .. ")" )
			assert( Objects.checkType( data ) == 'string', "bad argument #2 to 'post' (string expected, got " .. Objects.checkType( data ) .. ")" )
			assert( Objects.checkType( headers ) == 'table', "bad argument #3 to 'post' (table expected, got " .. Objects.checkType( headers ) .. ")" )
			return http.request( url, { method = 'POST', data = data, headers = headers } )
			]]
		end
	},

	xml = {
		parseXmlString = function( str, handler )
			dlmTunnel.check()
			assert( Objects.checkType( str ) == 'string', "bad argument #1 to 'parseXmlString' (string expected, got " .. Objects.checkType( str ) .. ")" )
			if handler then
				util.colorPrint( "yellow", "WARNING: 'parseXmlString': Parameter #2 is deprecated and will be removed in DLM version 1.2! Do not use." )
			end
			local handler = xml_tree:new()
			xml.parser( handler ):parse( str )
			return handler.root
		end,

		writeXmlString = function( tbl, root )
			dlmTunnel.check()
			assert( Objects.checkType( tbl ) == 'table', "bad argument #1 to 'writeXmlString' (table expected, got " .. Objects.checkType( tbl ) .. ")" )
			assert( Objects.checkType( root ) == 'string' or root == nil, "bad argument #2 to 'writeXmlString' (string expected, got " .. Objects.checkType( root ) .. ")" )
			return xml.toXml( tbl, root )
		end
	},

	gui = {
		createGuiFromXmlString = function( str, destroyOnClose, settings )
			dlmTunnel.check()
			assert( util.isClient(), "'createGuiFromXmlString' Is a clientside function!" )
			assert( Objects.checkType( str ) == "string", "bad argument #1 to 'createGuiFromXmlString' (string expected, got " .. Objects.checkType( str ) .. ")" )
			assert( Objects.checkType( destroyOnClose ) == "boolean", "bad argument #2 to 'createGuiFromXmlString' (boolean expected, got " .. Objects.checkType( destroyOnClose ) .. ")" )
			assert( Objects.checkType( settings ) == "table", "bad argument #1 to 'createGuiFromXmlString' (table expected, got " .. Objects.checkType( settings ) .. ")" )
			
			local uuid = tostring( sm.uuid.new() )
			local f, err = io.open( "../Data/layout_temp_" .. uuid .. ".layout", "w" )
			if f and not err then
				f:write( str )
				f:close()
				local gui = createGuiFromLayout( "$GAME_DATA/layout_temp_" .. uuid .. ".layout", destroyOnClose, settings )
				temporaryLayouts[#temporaryLayouts + 1] = { getCurrentTick(), uuid }
				return gui
			else
				error( "Failed to open temporary layout file!" )
			end
		end,

		clearTemporaryLayouts = function()
			dlmTunnel.check()
			assert( util.isClient(), "'clearTemporaryLayouts' Is a clientside function!" )
			local tick = getCurrentTick()

			if tick > previousClearTick then
				previousClearTick = tick + 5	--every 5 ticks max
				for k, data in pairs( temporaryLayouts ) do
					if tick ~= data[1] then
						os.remove( "../Data/layout_temp_" .. data[2] .. ".layout" )
						temporaryLayouts[k] = nil
					end
				end
			end
		end,

		getHypertext = function( text, textShadow, background, color, spacing )
			dlmTunnel.check()
			assert( Objects.checkType( text ) == "string", "bad argument #1 to 'getHypertext' (string expected, got " .. Objects.checkType( text ) .. ")" )
			assert( Objects.checkType( textShadow ) == "boolean" or textShadow == nil, "bad argument #2 to 'getHypertext' (boolean expected, got " .. Objects.checkType( textShadow ) .. ")" )
			assert( Objects.checkType( background ) == "string" or background == nil, "bad argument #3 to 'getHypertext' (string expected, got " .. Objects.checkType( background ) .. ")" )
			assert( Objects.checkType( color ) == "Color" or color == nil, "bad argument #4 to 'getHypertext' (Color expected, got " .. Objects.checkType( color ) .. ")" )
			assert( Objects.checkType( spacing ) == "number" or spacing == nil, "bad argument #5 to 'getHypertext' (number expected, got " .. Objects.checkType( spacing ) .. ")" )
			
			return "<p textShadow='" .. tostring( textShadow or false ) .. "' bg='" .. ( background or "gui_keybinds_bg_orange" ) .. "' color='#" .. ( tostring( color ) or "66440C" ) .. "' spacing='" .. ( spacing or 9 ) .. "'>" .. text .. "</p>"
		end,

		getHypertextImage = function( name, background, spacing )
			dlmTunnel.check()
			assert( Objects.checkType( name ) == "string", "bad argument #1 to 'getHypertextImage' (string expected, got " .. Objects.checkType( name ) .. ")" )
			assert( Objects.checkType( background ) == "string" or background == nil, "bad argument #2 to 'getHypertextImage' (string expected, got " .. Objects.checkType( background ) .. ")" )
			assert( Objects.checkType( spacing ) == "number" or spacing == nil, "bad argument #3 to 'getHypertextImage' (number expected, got " .. Objects.checkType( spacing ) .. ")" )
			
			return "<img bg='" .. ( background or "gui_keybinds_bg" ) .. "' spacing='" .. ( spacing or 0 ) .. "'>" .. name .. "</img>"
		end
	},

	audio = {
		updateSystem = function()
			dlmTunnel.check("audio")
			assert( util.isClient(), "'updateSystem' Is a clientside function!" )
			assert( fmodLoaded, "FMOD API is not loaded!" )
			local tick = getCurrentTick()
			if previousUpdateTick ~= tick then
				previousUpdateTick = tick
				fmodUpdateResultCache = fmod.update()
			end
			return fmodUpdateResultCache
		end,

		loadBank = function( filePath, async, guids_file )
			dlmTunnel.check("audio")
			assert( util.isClient(), "'loadBank' Is a clientside function!" )
			assert( fmodLoaded, "FMOD API is not loaded!" )
			assert( Objects.checkType( filePath ) == "string", "bad argument #1 to 'loadBank' (string expected, got " .. Objects.checkType( filePath ) .. ")" )
			assert( Objects.checkType( async ) == "boolean" or async == nil, "bad argument #2 to 'loadBank' (boolean expected, got " .. Objects.checkType( async ) .. ")" )
			assert( Objects.checkType( guids_file ) == "string" or guids_file == nil, "bad argument #3 to 'loadBank' (string expected, got " .. Objects.checkType( guids_file ) .. ")" )
			
			local path = resolveContentPath( filePath )
			if path then
				local api_result, fmod_result, bank_id = fmod.loadBank( path, async )
				local valid = ( api_result == 0 and fmod_result == 0 )

				if valid then
					local bank = Objects.Bank( bank_id )
					if guids_file then
						local guids_path = resolveContentPath( guids_file )
						if guids_path then
							local file, err = io.open( guids_path, "r" )
							if err or not file then
								util.colorPrint( "red", "ERROR: Failed to read file: ", guids_file, " - ", err )
							else
								local guids = parseGuidsFile( file )
								file:close()
								audioBankGuids[bank] = guids
							end
						end
					end

					return api_result, fmod_result, bank
				else
					util.colorPrint( "red", "ERROR: Failed to create sound! API Result:", util.API_RESULTS[api_result], "FMOD Result:", util.FMOD_RESULTS[fmod_result] )
					return api_result, fmod_result
				end
			end
		end,

		createEvent = function( name, bank )
			dlmTunnel.check("audio")
			assert( util.isClient(), "'createEvent' Is a clientside function!" )
			assert( Objects.checkType( name ) == "string", "bad argument #1 to 'createEvent' (string expected, got " .. Objects.checkType( name ) .. ")" )
			assert( Objects.checkType( bank ) == "AudioBank" or bank == nil, "bad argument #2 to 'createEvent' (AudioBank expected, got " .. Objects.checkType( bank ) .. ")" )
			if bank then
				local guids = audioBankGuids[bank]
				assert( guids, "Failed to find GUIDs list for bank:", tostring( bank ) )
				local guid = guids[name]
				assert( guid, "Failed to find event:", name, "in bank:", tostring( bank ), ". Did you use the correct GUIDs.txt?" )
				name = guid
			end
			local api_result, fmod_result, event_id = fmod.createEvent( name )
			local valid = ( api_result == 0 and fmod_result == 0 )
			if valid then
				return api_result, fmod_result, Objects.Event( event_id )
			else
				util.colorPrint( "red", "Failed to create event '" .. name .. "' - API Result:", util.API_RESULTS[api_result], "FMOD Result:", util.FMOD_RESULTS[fmod_result] )
				return api_result, fmod_result
			end
		end
	},

	input = {
		getKeyState = function( keyCode )
			dlmTunnel.check("keyboard", "mouse")
			if type(keyCode) == "number" then
				return not not (misc.getAsyncKeyState( keyCode ))
			end
		end
	},

	setupContentPath = function( modName, localId, steamId )
		dlmTunnel.check()
		assert( userSteamId, "No user steam ID found! Please report this issue." )
		assert( Objects.checkType( modName ) == 'string', "bad argument #1 to 'setupContentPath' (string expected, got " .. Objects.checkType( modName ) .. ")" )
		assert( Objects.checkType( localId ) == 'Uuid', "bad argument #2 to 'setupContentPath' (Uuid expected, got " .. Objects.checkType( localId ) .. ")" )
		assert( Objects.checkType( steamId ) == 'number', "bad argument #3 to 'setupContentPath' (string expected, got " .. Objects.checkType( steamId ) .. ")" )
		assert( setupContentPath( modName, tostring( localId ), steamId ), "Failed to setup content path!" )
	end,

	version = DLM_VERSION
}

unsafe_env.dllmod = api
unsafe_env.dlm = api

--unsafe_env.getmetatable = getmetatable --overwritten in betterAPI
--unsafe_env.setmetatable = setmetatable

__g_proxy__ = newproxy( true )
local mt = getmetatable( __g_proxy__ )
mt.__gc = function( self )
	util.colorPrint( "magenta", "LuaVM Shutdown" )

	dlmTunnel.shutdown()

	if fmodLoaded then
		fmod.shutdown()
	end
	--if steamLoaded then
		--steam.shutdown()	--don't do this
	--end
	for k, data in pairs( temporaryLayouts ) do
		os.remove( "../Data/layout_temp_" .. data[2] .. ".layout" )
	end
end

if not g_printed then
	local r = '\x1B[91m'
	print( r .. '####################################' )
	print( r .. '##                                ##' )
	print( r .. '##  ######    ##       ##     ##  ##' )
	print( r .. '##  ##     ## ##       ###   ###  ##' )
	print( r .. '##  ##     ## ##       #### ####  ##' )
	print( r .. '##  ##     ## ##       ## ### ##  ##' )
	print( r .. '##  ##     ## ##       ##     ##  ##' )
	print( r .. '##  ##     ## ##       ##     ##  ##' )
	print( r .. '##  ######    ######## ##     ##  ##' )
	print( r .. '##                                ##' )
	print( r .. '##          Version ' .. DLM_VERSION .. '           ##' )
	print( r .. '##      Created by MrCrackx02     ##' )
	print( r .. '##    Made for SM Version 0.6.5   ##' )
	print( r .. '##  from better API compatibility ##' )
	print( r .. '####################################' )
	g_printed = true
end
