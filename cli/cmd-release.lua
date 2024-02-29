package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Reg = require("src.registry")
local Cm = require("src.command")

local function abort()
    print("Invalid option arguments: use `cosm release [v<version>,--patch,--minor,--major]")
    os.exit(1)
end

local function printstats(pkg)
    print("Released "..pkg.name.." v"..pkg.version.." to "..pkg.registry.."\n")
end

--extract command line arguments
local nargs = #arg
if nargs==1 then
    local option=arg[1]
    local release
    if option=="--patch" or option=="--minor" or option=="--major" then
        release=string.sub(option,3,-1)
    elseif string.sub(option,1,1)=="v" then
        release = string.sub(option,2,-1)
    else
        abort()
    end
    local pkg = Reg.release(release)
    printstats(pkg)
else
    abort()
end