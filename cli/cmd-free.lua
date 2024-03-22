package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")
local Lang = require("lang.lua.cosm")

local function abort()
    print("ArgumentError: the signature is 'cosm free <package name>'. See 'cosm --help'. \n")
    os.exit(1)
end

local function printstats(pkg)
    print("Package "..pkg.name.." in dev-mode set to release "..pkg.version..".")
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local root, pkg = arg[1], arg[2]
    local dep = Pkg.free(root, pkg)
    Lang.init(root)
    if dep~=nil then
        printstats(dep)
    end
else
    abort()
end