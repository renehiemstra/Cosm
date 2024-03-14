package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Reg = require("src.registry")
local Git = require("src.git")
local Cm = require("src.command")

local function abort(message)
    print(message)
    os.exit(1)
end

local function printstats(registry, version, pkg)
    print("Registered package "..pkg.." v"..version.." to "..registry..".")
end

--extract command line arguments
local nargs = #arg
if nargs==3 then
    local registry = {}
    local remote = {}
    local pkg = {}
    --check root is a registry
    registry.name = arg[1]
    if not Reg.islisted(registry.name) then
        abort("Invalid arguments: not a valid registry.")
    end
    --check provided release version
    if type(arg[2])~="string" or string.sub(arg[2],1,1)~="v" then
        abort("ArgumentError: argument "..arg[2].." is not a valid release.")
    end
    pkg.release = string.sub(arg[2],2,-1)
    --check pkg url is a valid git url or bare repo
    if Cm.isdir(arg[3]) then
        remote.url = Cm.absolutepath(arg[3])
    elseif Git.validnonemptygitrepo(arg[3]) then
        remote.url = arg[3]
    else
        abort("ArgumentError: argument "..arg[3].." is not a bare repo or valid git url.")
    end
    --register package
    Reg.register{reg=registry.name,release=pkg.release,  url=remote.url}
    printstats(registry.name, pkg.release, remote.url)
else
    abort("Invalid arguments: try signature: cosm registry add <remote url/path>.\n")
end