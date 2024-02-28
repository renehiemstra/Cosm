package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Reg = require("src.registry")
local Git = require("src.git")
local Cm = require("src.command")

local function abort(message)
    print(message)
    os.exit(1)
end

local function printstats(registry, pkg)
    print("Registered package "..pkg.." to "..registry..".\n")
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
    --check url is a valid git url
    local url = arg[2]
    if not Git.validnonemptygitrepo(url) then
        abort("Invalid arguments: git url does not point to a valid repository.")
    end
    --register package
    Reg.register{reg=regname, url=url}
    printstats(regname, url)
else
    abort("Invalid arguments: try signature: cosm registry add <giturl>.\n")
end