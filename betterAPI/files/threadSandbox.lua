local codeStr, threadObj = ...

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

_BETTERAPI_UNSAFE_GLOBAL_ENV = true

local env
env = {
    _VERSION = _VERSION,

	type = type,
	assert = assert,
	error = error,
	ipairs = ipairs,
	next = next,
	pairs = pairs,
	pcall = pcall,
	select = select,
	tonumber = tonumber,
	tostring = tostring,
	unpack = unpack,
	xpcall = xpcall,

	setmetatable = setmetatable,
	getmetatable = getmetatable,

    loadstring = function (chunk, chunkname, env)
        checkArg(1, chunk, "string")
        checkArg(2, chunkname, "string", "nil")
        checkArg(3, env, "table")
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

	threadTunnelSet = function(index, value)
		checkArg(1, index, "number")
		checkArg(2, value, "string", "number", "boolean", "nil")
		thread_set(threadObj, index, value)
	end,
	threadTunnelGet = function(index)
		checkArg(1, index, "number")
		return thread_get(threadObj, index)
	end,
	sleep = function(time)
		checkArg(1, time, "number")
		thread_sleep(time)
	end,
	
    coroutine = coroutine,
	string = string,
	table = table,
	math = math,
	bit = bit,
	os = {
		clock = os.clock,
		difftime = os.difftime,
		time = os.time,
		date = os.date
	}
}

env._G = env

assert(env.loadstring(codeStr, nil, env))()