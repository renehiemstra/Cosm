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
    local luapath=""
    local terrapath=""
    for id, specs in pairs(buildlist) do
        cosm[id] = specs
        if specs.language=="lua" then
            luapath = luapath..cosm.depot_path.."/"..specs.path.."/src/?.lua;"
        elseif specs.language=="terra" then
            terrapath = terrapath..cosm.depot_path.."/"..specs.path.."/src/?.t;"
        end
    end
    local TERRAPATH = os.getenv("TERRA_PATH")
    if TERRAPATH==nil then
        terrapath = "\""..terrapath..";\""
    else
        terrapath = "\""..terrapath..TERRAPATH.."\""
    end
    local LUAPATH = os.getenv("LUA_PATH")
    if LUAPATH==nil then
        luapath = "\""..luapath..";\""
    else
        luapath = "\""..luapath..LUAPATH.."\""
    end
    --add a bashrc that sets up the cosm prompt
    if not Cm.isfile(root.."/.cosm/.bashrc") then
        Lang.savebashrc(root)
    end
    -- save local environment variables
    Lang.savecosmenv(root, {LUA_PATH=luapath, TERRA_PATH=terrapath})
end

return cosm