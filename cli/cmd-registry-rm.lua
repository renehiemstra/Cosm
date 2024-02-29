package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Reg = require("src.registry")
local Git = require("src.git")
local Cm = require("src.command")

local function abort(message)
    print(message)
    os.exit(1)
end

--extract command line arguments
local nargs = #arg
if nargs==2 or nargs==3 then
    -- registry to operate on
    local registry = {name=arg[1]}
    if not Reg.islisted(registry.name) then
        abort("Invalid arguments: not a valid registry.")
    end
    --package (version) to be removed
    local pkg = {name=arg[2]}
    if nargs==2 then
        --remove package entirely
        Reg.rmpkg(registry, pkg)
        print("Removed package "..pkg.name.." from "..registry.name..".\n")
    else
        --remove package version
        local v = string.sub(arg[3],1,1)
        if v=="v" then
            pkg.version = string.sub(arg[3],2,-1)
            print("pkg version is "..pkg.version)
            Reg.rmpkgversion(registry, pkg)
            print("Removed package "..pkg.name.." v"..pkg.version.." from "..registry.name..".\n")
        else
            abort("Invalid arguments: version number should have the form 'v<version>'.\n")
        end
    end
else
    abort("Invalid arguments: try signature: cosm registry rm <registry name> <package name> [--version v<version>].\n")
end