package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")
local Lang = require("lang.lua.cosm")

local function abort()
    print("Invalid option arguments: use 'cosm dependency rm <name>'.\n")
    os.exit(1)
end

local function printstats(name)
    print("Removed package "..name.." as a dependency.")
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local root=arg[1]
    local args = {root=root, dep=arg[2]}
    Pkg.rm(args)
    Lang.init(root)
    printstats(args.dep)
else
    abort()
end