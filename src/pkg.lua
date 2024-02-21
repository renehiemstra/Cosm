local Cm = require("command")
local Proj = require("project")
local Reg = require("registry")

local Pkg = {}

--add a dependency to a project
--signature Pkg.add{dep="...", version="xx.xx.xx"; root="..."}
function Pkg.add(args)
    local pkg = {}
    --check key-value arguments
    if type(args)~="table" then
        error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
    elseif args.dep==nil or args.version==nil then
        error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
    elseif type(args.dep)~="string" or type(args.version)~="string" then
        error("Provide table with `dep` (dependency) and `version` as a string.\n\n")
    end
    --set and check pkg root
    pkg.root = "."
    if args.root~=nil then
        pkg.root = args.root
    end
    if not Proj.ispkg(pkg.root) then
        error("Current directory is not a valid package.")
    end
    --initialize package properties
    pkg.dep = {name=args.dep, version=args.version}
    pkg.table = dofile(pkg.root.."/".."Project.lua")
    pkg.name = pkg.table.name
    --check that pkg and pkg.dep are not the same package
    if pkg.name==pkg.dep.name then
      error("Cannot add "..pkg.dep.name.."as a dependency to "..pkg.name..".\n\n")
    end
    --find pkgdep in known registries
    local registry = {}
    local found = false
    for _,regname in pairs(Reg.loadregistries("List.lua")) do
        --load registry
        registry.name = regname
        registry.path = Reg.regdir.."/"..registry.name
        registry.table = dofile(registry.path.."/Registry.lua")
        --check if pkg.dep is present
        if registry.table.packages[pkg.dep.name]~=nil then
            found = true --package is found
            break --currently we break with the first encountered package
        end
    end
    --case where pkgdep is not found in any of the registries
    if not found then
        error("Package "..pkg.dep.name.."is not a registered package.\n\n")
    end
    --check if version is present in registry
    pkg.dep.specs = registry.table.packages[pkg.dep.name]
    local versionpath = registry.path.."/"..pkg.dep.specs.path.."/"..pkg.dep.version
    if not Cm.isdir(versionpath) then
        error("Package "..pkg.dep.name.." is registered in "..registry.name..", but version "..pkg.dep.version.." is lacking.\n\n")
    end
    --add pkg.dep to the project dependencies
    pkg.table.deps[pkg.dep.name] = pkg.dep.version
    --save pkg table
    Proj.save(pkg.table, "Project.lua", pkg.root)
end

function Pkg.rm(pkg)
    --check key-value arguments
    if type(pkg)~="table" then
        error("Provide table with `dep` (dependency) and optional `root` directory.\n\n")
    elseif pkg.dep==nil then
        error("Provide table with `dep` (dependency) and optional `root` directory.\n\n")
    elseif type(pkg.dep)~="string" then
        error("Provide table with `dep` (dependency) as a string.\n\n")
    end
    --set and check pkg root
    if pkg.root==nil then
        pkg.root = "."
    end
    if not Proj.ispkg(pkg.root) then
        error("Current directory is not a valid package.")
    end
    --load package properties
    pkg.table = dofile(pkg.root.."/Project.lua")
    --removing pkg dependency
    pkg.table.deps[pkg.dep] = nil
    --save pkg table
    Proj.save(pkg.table,"Project.lua", pkg.root)
end

return Pkg