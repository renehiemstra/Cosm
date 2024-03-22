package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Cm = require("src.command")
local Proj = require("src.project")
local Pkg = require("src.pkg")

local function abort(message)
    print(message)
    os.exit(1)
end

local function printstats(root)
    print("Activated cosm project in "..root)
end

--extract command line arguments
local nargs = #arg
if nargs==1 then
    local root = arg[1]
    --write build list to file
    local pkg = {}
    if Proj.ispkg(root, pkg) then
        local Lang = require("lang."..pkg.table.language..".cosm")
        if not Cm.isfile(root.."/.cosm/Buildlist.lua") then
            Pkg.buildlist(root, true)
        end
        Lang.init(root)
        printstats(root)
    else
        abort("Root is not a valid cosm package.")
    end
else
    abort("ArgumentError: use 'cosm activate'")
end