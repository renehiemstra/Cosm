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
    local registry = {}
    local remote = {}
    --check root is a registry
    registry.name = arg[1]
    if not Reg.islisted(registry.name) then
        abort("Invalid arguments: not a valid registry.")
    end
    --check pkg url is a valid git url or bare repo
    if Cm.isdir(arg[2]) then
        remote.url = Cm.absolutepath(arg[2])
    elseif Git.validnonemptygitrepo(arg[2]) then
        remote.url = arg[2]
    else
        abort("ArgumentError: argument "..arg[2].." is not a bare repo or valid git url.")
    end
    --register package
    Reg.register{reg=registry.name, url=remote.url}
    printstats(registry.name, remote.url)
else
    abort("Invalid arguments: try signature: cosm registry add <remote url/path>.\n")
end