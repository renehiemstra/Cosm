package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")
local Lang = require("lang.lua.cosm")

local function abort()
    print("ArgumentError: the signature is 'cosm develop <package name>'. See 'cosm --help'. \n")
    os.exit(1)
end

local function printstats(pkg)
    print("You can now develop "..pkg.name.." v"..pkg.version.." located at "..pkg.path..".")
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local root, pkg = arg[1], arg[2]
    local dep = Pkg.develop(root, pkg)
    Lang.init(root)
    printstats(dep)
else
    abort()
end