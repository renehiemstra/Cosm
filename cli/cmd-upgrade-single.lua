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
if nargs==3 then
    local root = arg[1]
    local pkgname = arg[2]
    local latest = (arg[3]=="latest")
    --upgrade package to latest compatible
    local dep = Pkg.upgradesinglepkg(root, pkgname, nil, latest) --upgrade single package
    printstats(root, dep.name, dep.version)
elseif nargs==4 then
    local root = arg[1]
    local pkgname = arg[2]
    local version = arg[3]
    --upgrade package to latest compatible
    local dep = Pkg.upgradesinglepkg(root, pkgname, version, false) --upgrade single package
    printstats(root, dep.name, dep.version)
else
    abort()
end