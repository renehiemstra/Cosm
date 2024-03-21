package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Cm = require("src.command")
local Proj = require("src.project")
local Lang = require("src.langext")

local function abort()
    print("Invalid option arguments: use `cosm init <name> --template <(cosm/lang)/path/to/template>`")
    os.exit()
end

local function printstats(pkgname, lang, root)
    print("Created "..lang.." package "..pkgname.." in "..root..".")
end

--extract command line arguments
local nargs = #arg

if nargs==2 then
    local root = arg[1]
    local pkgname = arg[2]
    Proj.create(pkgname, "lua", root)
    printstats(pkgname, "lua", root)
elseif nargs==4 then
    local root = arg[1]
    local pkgname = arg[2]
    if arg[3]=="--template" then
        local template = arg[4]
        local pkglang = Cm.parentdirname(template)
        Proj.createfromtemplate(template, pkgname, root)
        printstats(pkgname, pkglang, root)
    elseif arg[3]=="--language" then
        local pkglang = arg[4]
        Proj.create(pkgname, pkglang, root)
        printstats(pkgname, pkglang, root)
    else
        abort()
    end
else
    abort()
end