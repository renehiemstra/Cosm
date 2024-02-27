package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Reg = require("src.registry")
local Git = require("src.git")
local Cm = require("src.command")

local function abort(message)
    print(message)
    os.exit(1)
end

local function printstats(registry, pkg)
    print("Released package"..pkg.." to "..registry..".\n")
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    --check root is a registry
    local root = arg[1]
    if not Reg.isreg(root) then
        abort("Invalid arguments: root directory is not a valid registry.")
    end
    local regname = Cm.namedir(root)
    --register package
    local pkgname = arg[2]
    if string.lower(pkgname) ~= string.lower(Git.namefromgiturl(url)) then
        abort("Invalid arguments: package name is not consistent with git url.\n")
    end
    Reg.register{reg=regname, url=url}
    printstats(regname, pkgname)
else
    abort("Invalid arguments: try signature: cosm registry add <giturl>.\n")
end