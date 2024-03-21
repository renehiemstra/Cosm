package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Cm = require("src.command")
local Pkg = require("src.pkg")
local Lang = require("src.langext")

local cosm = {}

cosm.depot_path = os.getenv("COSM_DEPOT_PATH")

function cosm.init(root)
    --load buildlist
    local buildlist = Pkg.fetchbuildlist(root)
    --make packages available
    Pkg.makeavailable(buildlist)
    --add package paths to path variable
    local path=""
    for id, specs in pairs(buildlist) do
        cosm[id] = specs
        path = path..cosm.depot_path.."/"..specs.path.."/src/?.t;"
    end
    local terrapath = os.getenv("TERRA_PATH")
    if terrapath==nil then
        path = "\""..path..";\""
    else
        path = "\""..path..terrapath.."\""
    end
    --add a bashrc that sets up the cosm prompt
    if not Cm.isfile(root.."/.cosm/.bashrc") then
        Lang.savebashrc(root)
    end
    -- save local environment variables
    Lang.savecosmenv(root, {TERRA_PATH=path})
end

return cosm