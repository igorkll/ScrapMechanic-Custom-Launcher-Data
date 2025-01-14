--not my code, this came from stackoverflow. doing this in cpp in a dll breaks the console for some reason
local function enableConsoleColors()
	local ffi = require( "ffi" )
	ffi.cdef[[
		typedef int BOOL;
		static const int INVALID_HANDLE_VALUE               = -1;
		static const int STD_OUTPUT_HANDLE                  = -11;
		static const int ENABLE_VIRTUAL_TERMINAL_PROCESSING = 4;
		intptr_t GetStdHandle( int nStdHandle );
		BOOL GetConsoleMode( intptr_t hConsoleHandle, int* lpMode );
		BOOL SetConsoleMode( intptr_t hConsoleHandle, int dwMode );
	]]
	local console_handle = ffi.C.GetStdHandle( ffi.C.STD_OUTPUT_HANDLE )
	assert( console_handle ~= ffi.C.INVALID_HANDLE_VALUE )
	local prev_console_mode = ffi.new'int[1]'
	assert( ffi.C.GetConsoleMode( console_handle, prev_console_mode) ~= 0, 'This script must be run from a console application' )
	assert( ffi.C.SetConsoleMode( console_handle, bit.bor( prev_console_mode[0], ffi.C.ENABLE_VIRTUAL_TERMINAL_PROCESSING ) ) ~= 0 )
end
pcall( enableConsoleColors )