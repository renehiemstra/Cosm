package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Cm = require("src.command")
local Base = require("src.base")
local Pkg = require("src.pkg")
local Lang = require("src.langext")

local cosm = {}

cosm.depot_path = os.getenv("COSM_DEPOT_PATH")

local function getinitenvpath(lang)
    if lang=="lua" then
        local save_luapath = os.getenv("__save_LUA_PATH")
        if save_luapath~=nil then
            return save_luapath
        else
            return os.getenv("LUA_PATH")
        end
    elseif lang=="terra" then
        local save_terrapath = os.getenv("__save_TERRA_PATH")
        if save_terrapath~=nil then
            return save_terrapath
        else
            return os.getenv("TERRA_PATH")
        end
    end
end

local function getupdatedenvpath(buildlist, lang)
    local path=""
    for id, specs in pairs(buildlist) do
        if specs.language==lang.name then
            path = path..cosm.depot_path.."/"..specs.path.."/src/?."..lang.ext..";"
        end
    end
    local PATH = getinitenvpath(lang.name)
    if PATH==nil then
        path = path..";"
    else
        path = path..PATH
    end
    return path
end

function cosm.init(root)
    --get initial path variables
    local save_luapath = getinitenvpath("lua")
    local save_terrapath = getinitenvpath("lua")
    --load buildlist
    local buildlist = Pkg.fetchbuildlist(root)
    --make packages available
    Pkg.makeavailable(buildlist)
    --add package paths to path variable
    local luapath = getupdatedenvpath(buildlist, {name="lua", ext="lua"})
    local terrapath = getupdatedenvpath(buildlist, {name="terra", ext="t"})
    --add a bashrc that sets up the cosm prompt
    if not Cm.isfile(root.."/.cosm/.bashrc") then
        Lang.savebashrc(root)
    end
    -- save local environment variables
    local env = {
        __save_LUA_PATH=Base.esc(save_luapath),
        __save_TERRA_PATH=Base.esc(save_terrapath),
        LUA_PATH=Base.esc(luapath),
        TERRA_PATH=Base.esc(terrapath)
    }
    Lang.savecosmenv(root, env)
end

return cosm