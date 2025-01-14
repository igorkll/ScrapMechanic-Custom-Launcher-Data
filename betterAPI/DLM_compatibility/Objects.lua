
--[[
	COPYRIGHT (c) 2022 MrCrackx02
	I do NOT give ANYONE the permission to copy, modify or redistribute ANY part of the code in this file!
	If you do want to use part of it for your own project(s), you have to ask me for permission first!
	You can do so on Discord: https://discord.gg/2eACct5FDm or https://discordapp.com/users/518349368500420618
]]

local fmod = ...
assert( fmod, "Objects.lua: FMOD API not found!" )

local objects = {}

local types = {
	[1] = "AudioBank",
	[2] = "AudioEvent",
	[3] = "EventInstance"
}

local function isClient()
	return pcall( sm.gui.getKeyBinding, "" )
end

local function checkType( obj )
	if objects[obj] then
		return types[objects[obj][2].__typeid] or "Unknown"
	else
		return type( obj )
	end
end

local function cannotModify( k )
	error( "Cannot modify member '" .. k .. "' in object", 3 )
end

local function unknownMember( k )
	error( "Unknown member '" .. k .. "' in object", 3 )
end

local function setupMetatable( typeid )
	local name = types[typeid]
	assert( name )
	local mt = {
		__typeid = typeid,
		__index = function( proxy, k )
			local ptype = checkType( proxy )
			local ktype = checkType( k )
			assert( ptype == name, "bad argument #1 to '__index' (" .. name .. " expected, got " .. ptype .. ")" )
			assert( ktype == "string", "bad argument #2 to '__index' (string expected, got " .. ktype .. ")" )
			return objects[proxy][1][k] or unknownMember( k )
		end,
		__newindex = function( proxy, k, v )
			local ptype = checkType( proxy )
			local ktype = checkType( k )
			assert( ptype == name, "bad argument #1 to '__newindex' (" .. name .. " expected, got " .. ptype .. ")" )
			assert( ktype == "string", "bad argument #2 to '__newindex' (string expected, got " .. ktype .. ")" )
			return cannotModify( k )
		end,
		__tostring = function( proxy )
			local ptype = checkType( proxy )
			assert( ptype == name, "bad argument #1 to '__tostring' (" .. name .. " expected, got " .. ptype .. ")" )
			return "{<" .. ptype .. ">, id = " .. objects[proxy][1].id .. "}"
		end,
		__metatable = false,
		__gc = function( proxy )
			local ptype = checkType( proxy )
			assert( ptype == name, "bad argument #1 to '__gc' (" .. name .. " expected, got " .. ptype .. ")" )
			proxy:destroy()
		end
	}
	return mt
end



local onBankUnloaded = function( ... ) end	--dummy function

setBankUnloadCallback = function( cb )
	onBankUnloaded = cb
end

--Bank--

local bank_mt = setupMetatable( 1 )
local highest_bank_id = 0

local function createBank( bank_id )
	local bank = {
		id = highest_bank_id,
		bankId = bank_id,

		getLoadingState = function( self )
			assert( isClient(), "<AudioBank>:getLoadingState is a clientside function!" )
			assert( checkType( self ) == "AudioBank", "bad argument #1 to 'getLoadingState' (AudioBank expected, got " .. checkType( self ) .. ")" )
			return fmod.bank_getLoadingState( objects[self][1].bankId )
		end,

		isValid = function( self )
			assert( isClient(), "<AudioBank>:isValid is a clientside function!" )
			assert( checkType( self ) == "AudioBank", "bad argument #1 to 'isValid' (AudioBank expected, got " .. checkType( self ) .. ")" )
			return fmod.bank_isValid( objects[self][1].bankId )
		end,
		
		destroy = function( self )
			assert( isClient(), "<AudioBank>:destroy is a clientside function!" )
			assert( checkType( self ) == "AudioBank", "bad argument #1 to 'destroy' (AudioBank expected, got " .. checkType( self ) .. ")" )
			local api_result, fmod_result = fmod.bank_unload( objects[self][1].bankId )
			if api_result == 0 and fmod_result == 0 then
				objects[self] = nil
				onBankUnloaded( self )
			end
			return api_result, fmod_result
		end
	}
	highest_bank_id = highest_bank_id + 1
	local proxy = setmetatable( {}, bank_mt )
	objects[proxy] = {
		bank,
		bank_mt
	}
	return proxy
end




local event_mt = setupMetatable( 2 )
local highest_event_id = 0
local createInstance

function createEvent( event_id )
	local event = {
		id = highest_event_id,
		eventId = event_id,

		getLength = function( self )
			assert( isClient(), "<AudioEvent>:getLength is a clientside function!" )
			assert( checkType( self ) == "AudioEvent", "bad argument #1 to 'getLength' (AudioEvent expected, got " .. checkType( self ) .. ")" )
			return fmod.event_getLength( objects[self][1].eventId )
		end,

		createInstance = function( self )
			assert( isClient(), "<AudioEvent>:createInstance is a clientside function!" )
			assert( checkType( self ) == "AudioEvent", "bad argument #1 to 'createInstance' (AudioEvent expected, got " .. checkType( self ) .. ")" )
			local api_result, fmod_result, instance_id = fmod.createInstance( objects[self][1].eventId )
			return api_result, fmod_result, ( api_result == 0 and fmod_result == 0 ) and createInstance( instance_id ) or nil
		end,

		isValid = function( self )
			assert( isClient(), "<AudioEvent>:isValid is a clientside function!" )
			assert( checkType( self ) == "AudioEvent", "bad argument #1 to 'isValid' (AudioEvent expected, got " .. checkType( self ) .. ")" )
			return fmod.event_isValid( objects[self][1].eventId )
		end,

		destroy = function( self )
			assert( isClient(), "<AudioEvent>:destroy is a clientside function!" )
			assert( checkType( self ) == "AudioEvent", "bad argument #1 to 'destroy' (AudioEvent expected, got " .. checkType( self ) .. ")" )
			local api_result = fmod.event_destroy( objects[self][1].eventId )
			if api_result == 0 then
				objects[self] = nil
			end
			return api_result
		end
	}
	highest_event_id = highest_event_id + 1
	local proxy = setmetatable( {}, event_mt )
	objects[proxy] = {
		event,
		event_mt
	}
	return proxy
end




local instance_mt = setupMetatable( 3 )
local highest_instance_id = 0

createInstance = function( instance_id )
	local instance = {
		id = highest_instance_id,
		instanceId = instance_id,

		start = function( self )
			assert( isClient(), "<EventInstance>:start is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'start' (EventInstance expected, got " .. checkType( self ) .. ")" )
			return fmod.instance_start( objects[self][1].instanceId )
		end,

		stop = function( self, stopImmediate )
			assert( isClient(), "<EventInstance>:stop is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'stop' (EventInstance expected, got " .. checkType( self ) .. ")" )
			assert( checkType( stopImmediate ) == "boolean" or stopImmediate == nil, "bad argument #2 to 'stop' (boolean expected, got " .. checkType( stopImmediate ) .. ")" )
			return fmod.instance_stop( objects[self][1].instanceId, stopImmediate )
		end,

		getPlaybackState = function( self )
			assert( isClient(), "<EventInstance>:getPlaybackState is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'getPlaybackState' (EventInstance expected, got " .. checkType( self ) .. ")" )
			return fmod.instance_getPlaybackState( objects[self][1].instanceId )
		end,

		setPaused = function( self, paused )
			assert( isClient(), "<EventInstance>:setPaused is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'setPaused' (EventInstance expected, got " .. checkType( self ) .. ")" )
			assert( checkType( paused ) == "boolean", "bad argument #2 to 'setPaused' (boolean expected, got " .. checkType( paused ) .. ")" )
			return fmod.instance_setPaused( objects[self][1].instanceId, paused )
		end,

		getPaused = function( self )
			assert( isClient(), "<EventInstance>:getPaused is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'getPaused' (EventInstance expected, got " .. checkType( self ) .. ")" )
			return fmod.instance_getPaused( objects[self][1].instanceId )
		end,

		setPitch = function( self, pitch )
			assert( isClient(), "<EventInstance>:setPitch is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'setPitch' (EventInstance expected, got " .. checkType( self ) .. ")" )
			assert( checkType( pitch ) == "number", "bad argument #1 to 'setPitch' (number expected, got " .. checkType( pitch ) .. ")" )
			return fmod.instance_setPitch( objects[self][1].instanceId, pitch )
		end,

		getPitch = function( self )
			assert( isClient(), "<EventInstance>:getPitch is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'getPitch' (EventInstance expected, got " .. checkType( self ) .. ")" )
			return fmod.instance_getPitch( objects[self][1].instanceId )
		end,

		setPlaybackPosition = function( self, position )
			assert( isClient(), "<EventInstance>:setPlaybackPosition is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'setPlaybackPosition' (EventInstance expected, got " .. checkType( self ) .. ")" )
			assert( checkType( position ) == "number", "bad argument #1 to 'setPlaybackPosition' (number expected, got " .. checkType( position ) .. ")" )
			return fmod.instance_setTimelinePosition( objects[self][1].instanceId, position )
		end,

		getPlaybackPosition = function( self )
			assert( isClient(), "<EventInstance>:getPlaybackPosition is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'getPlaybackPosition' (EventInstance expected, got " .. checkType( self ) .. ")" )
			return fmod.instance_getTimelinePosition( objects[self][1].instanceId )
		end,

		setVolume = function( self, volume )
			assert( isClient(), "<EventInstance>:setVolume is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'setVolume' (EventInstance expected, got " .. checkType( self ) .. ")" )
			assert( checkType( volume ) == "number", "bad argument #1 to 'setVolume' (number expected, got " .. checkType( volume ) .. ")" )
			return fmod.instance_setVolume( objects[self][1].instanceId, volume )
		end,

		getVolume = function( self )
			assert( isClient(), "<EventInstance>:getVolume is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'getVolume' (EventInstance expected, got " .. checkType( self ) .. ")" )
			return fmod.instance_getVolume( objects[self][1].instanceId )
		end,

		setParameter = function( self, name, value, ignoreSeekSpeed )
			assert( isClient(), "<EventInstance>:setParameter is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'setParameter' (EventInstance expected, got " .. checkType( self ) .. ")" )
			assert( checkType( name ) == "string", "bad argument #2 to 'setParameter' (string expected, got " .. checkType( name ) .. ")" )
			assert( checkType( value ) == "number", "bad argument #3 to 'setParameter' (number expected, got " .. checkType( value ) .. ")" )
			assert( checkType( ignoreSeekSpeed ) == "boolean" or ignoreSeekSpeed == nil, "bad argument #4 to 'setParameter' (boolean expected, got " .. checkType( ignoreSeekSpeed ) .. ")" )
			return fmod.instance_setVolume( objects[self][1].instanceId, name, value, ignoreSeekSpeed )
		end,

		getParameter = function( self, name )
			assert( isClient(), "<EventInstance>:getParameter is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'getParameter' (EventInstance expected, got " .. checkType( self ) .. ")" )
			assert( checkType( name ) == "string", "bad argument #1 to 'getParameter' (string expected, got " .. checkType( name ) .. ")" )
			return fmod.instance_getParameter( objects[self][1].instanceId )
		end,

		isValid = function( self )
			assert( isClient(), "<EventInstance>:isValid is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'isValid' (EventInstance expected, got " .. checkType( self ) .. ")" )
			return fmod.instance_isValid( objects[self][1].instanceId )
		end,

		destroy = function( self )
			assert( isClient(), "<EventInstance>:destroy is a clientside function!" )
			assert( checkType( self ) == "EventInstance", "bad argument #1 to 'destroy' (EventInstance expected, got " .. checkType( self ) .. ")" )
			fmod.instance_stop( objects[self][1].instanceId, true )
			local api_result, fmod_result = fmod.instance_destroy( objects[self][1].instanceId )
			if api_result == 0 and fmod_result == 0 then
				objects[self] = nil
			end
			return api_result, fmod_result
		end
	}
	highest_instance_id = highest_instance_id + 1
	local proxy = setmetatable( {}, instance_mt )
	objects[proxy] = {
		instance,
		instance_mt
	}
	return proxy
end




local objects = {
	Bank = createBank,
	Event = createEvent,

	checkType = checkType,
	setBankUnloadCallback = setBankUnloadCallback
}

return objects







