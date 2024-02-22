local Pkg = require("src.pkg")
local Semver = require("src.semver")

local function abort()
    print("Invalid option arguments: use `cosm dependency add <name> <version>`")
    os.exit(1)
end

local function printstats(name, version)
    print("Added package "..name.." v"..version.." as a dependency")
end

--extract command line arguments
local nargs = #arg
if nargs==3 then
    local args = {root=arg[1], dep=arg[2], version=arg[3]}
    local v_new = Semver.parse(args.version)
    

    Pkg.add(args)
    printstats(args.dep, args.version)
else
    abort()
end