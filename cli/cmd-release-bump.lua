local Reg = require("src.registry")
local Cm = require("src.command")

local function abort()
    print("Invalid option arguments: use `cosm release add <name> <giturl>`")
    os.exit(1)
end

local function printstats(pkg)
    print("Released "..pkg.name.." to "..pkg.reg..".\n")
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local pkg = {reg=arg[1], url=arg[2]}
    Reg.release(args)
    --abort() --ToDo: better error message
    pkg.name = Cm.namedir(".")
    printstats(pkg)
else
    abort()
end