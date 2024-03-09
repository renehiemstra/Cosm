package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")

local function abort()
    print("Invalid option arguments: use 'cosm build'")
    os.exit()
end

local function printstats(root)
    print("Created build list in "..root.."/.cosm.")
end

--extract command line arguments
local nargs = #arg
if nargs==1 then
    local root = arg[1]
    --write build list to file
    Pkg.buildlist(root)
    printstats(root)
else
    abort()
end