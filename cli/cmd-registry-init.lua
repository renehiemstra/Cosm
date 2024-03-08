package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Reg = require("src.registry")
local Cm = require("src.command")
local Git = require("src.git")

local function abort(message)
    print(message)
    os.exit(1)
end

local function printstats(name, root)
    print("Created registry "..name.." in "..root)
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local registry = {}
    --check root is a registry
    registry.name = arg[1]
    --check remote url is a valid git url or bare repo
    if Cm.isdir(arg[2]) then
        registry.url  = Cm.absolutepath(arg[2])
    elseif Git.validemptygitrepo(arg[2]) then
        registry.url = arg[2]
    else
        abort("ArgumentError: argument "..arg[2].." is not a bare repo or valid git url.")
    end
    Reg.create(registry)
    printstats(registry.name, Reg.regdir)
else
    abort("Invalid arguments: use `cosm registry init <name> <remote>`")
end