package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")

local function abort()
    print("Invalid option arguments: use 'cosm upgrade-some'.\n")
    os.exit()
end

local function printstats(root, pkg, version)
    print("Upgraded package "..pkg.." in "..root.." to v"..version..".")
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local root = arg[1]
    local depname = arg[2]
    Pkg.upgradesingle(root, depname, true) --upgrade single package
    Pkg.buildlist(root) --write build list to file
    printstats(root, depname, "-latest")
elseif nargs==3 then
    local root = arg[1]
    local depname = arg[2]
    local depversion = arg[3]
    --write build list to file
    Pkg.upgradesingle(root, depname, depversion) --upgrade single package
    Pkg.buildlist(root) --write build list to file
    printstats(root, depname, depversion)
else
    abort()
end