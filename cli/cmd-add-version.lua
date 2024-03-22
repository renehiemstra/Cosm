package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")
local Lang = require("lang.lua.cosm")

local function abort()
    print("ArgumentError: the signature is 'cosm add <package name> [--latest, --version <version>]'. See 'cosm --help'. \n \n")
    os.exit(1)
end

local function printstats(name, version)
    print("Added package "..name.." v"..version.." as a dependency.")
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local root = arg[1]
    local args = {root = root, dep = arg[2]}
    Pkg.add(args)
    Lang.init(root)
    printstats(args.dep, "-latest")
elseif nargs==3 then
    local root = arg[1]
    local args = {root = root, dep = arg[2], version = arg[3]}
    Pkg.add(args)
    Lang.init(root)
    printstats(args.dep, args.version)
else
    abort()
end