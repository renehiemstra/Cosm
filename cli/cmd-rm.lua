package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")

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
    local args = {root=arg[1], dep=arg[2]}
    Pkg.rm(args)
    printstats(args.dep)
else
    abort()
end