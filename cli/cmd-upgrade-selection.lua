package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Pkg = require("src.pkg")

local function abort()
    print("Invalid option arguments: use 'cosm upgrade-some'")
    os.exit()
end

local function printstats(root)
    print("Upgraded packages in "..root.."/.cosm.")
end

--extract command line arguments
local nargs = #arg
if nargs==1 then
    local root = arg[1]
    --write build list to file
    Pkg.upgradeselection(root)
    printstats(root)
else
    abort()
end