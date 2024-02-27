package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Proj = require("src.project")

local function abort()
    print("Invalid option arguments: use `cosm init <name> --lang lua`")
    os.exit()
end

local function printstats(pkgname, root)
    print("Created package "..pkgname.." in "..root)
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local root = arg[1]
    local pkgname = arg[2]
    Proj.create(pkgname, root)
    printstats(pkgname, root)
elseif nargs==4 then
    local root = arg[1]
    local pkgname = arg[2]
    if arg[3]=="--lang" or arg[3]=="-l" then
        local lang = arg[4]
        Proj.create(pkgname, root)
        printstats(pkgname, root)
    else
        abort()
    end
else
    abort()
end