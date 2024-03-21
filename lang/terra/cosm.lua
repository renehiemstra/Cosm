package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"
local Pkg = require("src.pkg")

local cosm = {}

cosm.depot_path = os.getenv("COSM_DEPOT_PATH")

local function init()
    --parent project directory
    local parentprojectfile = arg[0]
    local parentprojectdir = parentprojectfile:match("(.*)/")
    local root = parentprojectdir.."/.."
    --load buildlist
    local buildlist = Pkg.fetchbuildlist(root)
    --make packages available
    Pkg.makeavailable(buildlist)
    --add to path variable
    for id, specs in pairs(buildlist) do
        cosm[id] = specs
        package.path = package.path .. ";"..cosm.depot_path.."/"..specs.path.."/src/?.lua"
    end
end
init()

return cosm