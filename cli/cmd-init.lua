package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Proj = require("src.project")
local Lang = require("src.langext")

local function abort()
    print("Invalid option arguments: use `cosm init <name> --lang lua`")
    os.exit()
end

local function printstats(pkgname, root)
    print("Created package "..pkgname.." in "..root)
end

--extract command line arguments
local nargs = #arg
if nargs==3 then
    local root = arg[1]
    local pkgname = arg[2]
    local template = arg[3]
    Proj.create(template, pkgname, root)
    printstats(pkgname, root)
else
    abort()
end