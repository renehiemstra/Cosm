package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"
local Proj = require("src.project")

local cosm = {}

function cosm.require(depname)
    return Proj.require(depname)
end

return cosm