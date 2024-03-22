package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")
local Lang = require("lang.lua.cosm")

local function abort()
    print("ArgumentError: the signature is 'cosm upgrade <package name> [--latest, --version <version>]'. See 'cosm --help'. \n")
    os.exit(1)
end

--extract command line arguments
local nargs = #arg
if nargs==3 then
    local root = arg[1]
    local args = {root=root, dep=arg[2], version=arg[3]}
    Pkg.upgrade(args)
    Lang.init(root)
    print("Upgraded package "..args.dep.."  to version v"..args.version..".")
else
    abort()
end