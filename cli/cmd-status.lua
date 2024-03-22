package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"
local Pkg = require("src.pkg")

local function abort(message)
    print(message)
    os.exit(1)
end

--extract command line arguments
local nargs = #arg
if nargs==1 then
    local root = arg[1]
    Pkg.status(root)
else
    abort("ArgumentError: use 'cosm status'")
end