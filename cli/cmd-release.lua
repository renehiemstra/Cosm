local Reg = require("src.registry")
local Cm = require("src.command")

local function abort()
    print("Invalid option arguments: use `cosm release --[patch,minor,major]")
    os.exit(1)
end

local function printstats(pkg)
    print("Released "..pkg.name.." v"..pkg.version.." to "..pkg.registry.."\n")
end

--extract command line arguments
local nargs = #arg
if nargs==1 then
    local release = arg[1]
    local pkg = Reg.release(release)
    printstats(pkg)
else
    abort()
end