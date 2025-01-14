print("> forceControl.lua")
local ffi = require("ffi")
ffi.cdef([[
bool AllocConsole();
]])
ffi.C.AllocConsole()
function betterConsoleSplash()
    os.execute("echo ------                                  betterAPI console has been created                             ------")
    os.execute("echo ------                      there may be several of these consoles (this is normal)                    ------")
    os.execute("echo ------         DO NOT CLOSE THIS WINDOW UNDER ANY CIRCUMSTANCES. OTHERWISE, THE GAME WILL CLOSE        ------")
    os.execute("echo ------                      THE INFORMATION HERE MAY SEEM LIKE A BUG, ALTHOUGH IT IS NOT               ------")
    os.execute("echo ------ IF YOU SEE A MESSAGE ABOUT MISSING FILES HERE, JUST IGNORE IT. THAT'S HOW IT'S MEANT TO BE!!!!  ------")
    os.execute("echo ------                       just ignore this window, if you see it then minimize it                   ------")
end
betterConsoleSplash()
--assert(python.dofile("minimize.py"))