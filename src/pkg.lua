local Cm = require("src.command")
local Proj = require("src.project")
local Reg = require("src.registry")
local Semver = require("src.semver")

local Pkg = {}

--fetches the Project.lua file and returns the table. 
--expects that root directory is a valid pkg root
local function fetchprojecttable(root)
    return dofile(root.."/Project.lua")
end

--checks if `pkgname` is a dependency of the current project.
--expects that `root` directory is a valid pkg root
local function isdep(root, pkgname)
    local project = fetchprojecttable(root)
    return project.deps[pkgname]
end
--list the project status
--expects that `root` directory is a valid pkg root
function Pkg.status()
    if not Proj.ispkg(".") then
        error("Current directory is not a valid package.")
    end
    local project = fetchprojecttable(".")
    print("Project "..project.name.."v"..project.version.."\n")
    print("Status `"..Cm.currentworkdir().."Project.lua` \n")
    for name,version in pairs(project.deps) do
        print("  "..name.."\t\tv"..version)
    end
end

--find pkgname in known registries. Load name, path, and table to registry
local function loadregistry(registry, pkgname)
    for _,regname in pairs(Reg.loadregistries("List.lua")) do
        --load registry
        registry.name = regname
        registry.path = Reg.regdir.."/"..registry.name
        registry.table = dofile(registry.path.."/Registry.lua")
        --check if pkgname is present
        if registry.table.packages[pkgname]~=nil then
            return true --currently we break with the first encountered package
        end
    end
    return false
end

--add a dependency to a project
--signature Pkg.add{dep="...", version="xx.xx.xx"; root="."}
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
    pkg.table = fetchprojecttable(pkg.root)
    pkg.name = pkg.table.name
    --check that pkg and pkg.dep are not the same package
    if pkg.name==pkg.dep.name then
      error("Cannot add "..pkg.dep.name.."as a dependency to "..pkg.name..".\n\n")
    end
    --find pkgdep in known registries
    local registry = {} --{name, path, table}
    local found = loadregistry(registry, pkg.dep.name)
    --case where pkgdep is not found in any of the registries
    if not found then
        error("Package "..pkg.dep.name.." is not a registered package.\n\n")
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

--remove a project dependency
--signature Pkg.rm{dep="..."; root="."}
function Pkg.rm(args)
    local pkg = {}
    --check key-value arguments
    if type(args)~="table" then
        error("Provide table with `dep` (dependency) and optional `root` directory.\n\n")
    elseif args.dep==nil then
        error("Provide table with `dep` (dependency) and optional `root` directory.\n\n")
    elseif type(args.dep)~="string" then
        error("Provide table with `dep` (dependency) as a string.\n\n")
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
    pkg.dep = { name=args.dep }
    pkg.table = fetchprojecttable(pkg.root)
    pkg.name = pkg.table.name
    --cannot remove a package that is not a dependency
    if pkg.table.deps[pkg.dep.name]==nil then
        error("Provided package is not listed as a dependency.")
    end
    --removing pkg dependency
    pkg.table.deps[pkg.dep.name] = nil
    --save pkg table
    Proj.save(pkg.table,"Project.lua", pkg.root)
end

--upgrade a package to a higher version
--signature Pkg.upgrade{dep="...", version="xx.xx.xx"; root="."}
function Pkg.upgrade(args)
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
    pkg.table = fetchprojecttable(pkg.root)
    pkg.name = pkg.table.name
    --cannot remove a package that is not a dependency
    local oldversion = pkg.table.deps[pkg.dep.name]
    if oldversion==nil then
        error("Provided package is not listed as a dependency.")
    end
    local v1 = Semver.parse(oldversion)
    local v2 = Semver.parse(pkg.dep.version)
    if v1==v2 then
        error("Cannot upgrade: version already listed as a dependency.")
    elseif v1>v2 then
        error("Cannot upgrade: version is older than the one installed.")
    end
    --rm and add new version
    Pkg.rm(args)
    Pkg.add(args)
end

--downgrade a package to a lower version
--signature Pkg.downgrade{dep="...", version="xx.xx.xx"; root="."}
function Pkg.downgrade(args)
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
    pkg.table = fetchprojecttable(pkg.root)
    pkg.name = pkg.table.name
    --cannot remove a package that is not a dependency
    local oldversion = pkg.table.deps[pkg.dep.name]
    if oldversion==nil then
        error("Provided package is not listed as a dependency.")
    end
    local v1 = Semver.parse(oldversion)
    local v2 = Semver.parse(pkg.dep.version)
    if v1==v2 then
        error("Cannot downgrade: version already listed as a dependency.")
    elseif v1<v2 then
        error("Cannot downgrade: version is newer than the one installed.")
    end
    --rm and add new version
    Pkg.rm(args)
    Pkg.add(args)
end

return Pkg