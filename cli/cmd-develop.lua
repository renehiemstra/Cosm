package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")

local function abort()
    print("ArgumentError: the signature is 'cosm develop <package name>'. See 'cosm --help'. \n")
    os.exit(1)
end

local function printstats(name)
    print("You can now develop "..name..".")
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local root, pkg = arg[1], arg[2]
    Pkg.develop(root, pkg)
    printstats(pkg)
else
    abort()
end