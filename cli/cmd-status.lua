package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"
local Pkg = require("src.pkg")

--run package status
Pkg.status()