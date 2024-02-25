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

local function checkout(specs)
    local root=Proj.terrahome.."/clones/"..specs.uuid
    Cm.throw{cm="git pull", root=root} --get updates from remote - this is buggy
    Cm.throw{cm="git checkout "..specs.sha1, root=root}
end

local function fetchfromremote(specs)
    --clone package in ~.cosm/clones/<pkg-uuid>
    Cm.throw{cm="git clone "..specs.url.." "..specs.uuid, root=Proj.terrahome.."/clones"}
    checkout(specs)
end

--clone package in ~.cosm/clones/<pkg-uuid> and checkout the correct
--version number
function Pkg.fetch(specs)
    if Cm.isdir(Proj.terrahome.."/clones/"..specs.uuid) then
        print("directory exists, checking out "..specs.version)
        checkout(specs)
    else
        fetchfromremote(specs)
    end
end

--add a dependency to a project
--signature Pkg.add{dep="...", version="xx.xx.xx"; root="."}
function Pkg.add(args)
    --check key-value arguments
    if type(args)~="table" then
        error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
    elseif args.dep==nil or args.version==nil then
        error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
    elseif type(args.dep)~="string" or type(args.version)~="string" then
        error("Provide table with `dep` (dependency) and `version` as a string.\n\n")
    end
    --set and check pkg root
    if args.root==nil then
        args.root = "."
    end
    if not Proj.ispkg(args.root) then
        error("Current directory is not a valid package.")
    end
    --initialize package and dependency
    local dep = {name=args.dep, version=args.version}
    local pkg = fetchprojecttable(args.root)
    pkg.root = args.root

    --check that pkg and pkg.dep are not the same package
    if pkg.name==dep.name then
      error("Cannot add "..dep.name.."as a dependency to "..pkg.name..".\n\n")
    end
    --find pkgdep in known registries
    local registry = {} --{name, path, table}
    local found = Reg.loadregistry(registry, dep.name)
    --case where pkgdep is not found in any of the registries
    if not found then
        error("Package "..dep.name.." is not a registered package.\n\n")
    end
    --check if version is present in registry
    dep.path = registry.table.packages[dep.name].path
    local versionpath = registry.path.."/"..dep.path.."/"..dep.version
    if not Cm.isdir(versionpath) then
        error("Package "..dep.name.." is registered in "..registry.name..", but version "..dep.version.." is lacking.\n\n")
    end
    --make depdendency available (fetch from remote, copy source to packages)
    dep.specs = dofile(versionpath.."/Specs.lua")
    local dest = Proj.terrahome.."/packages/"..dep.name.."/"..dep.specs.sha1
    if not Cm.isdir(dest) then
        Pkg.fetch(dep.specs) --checkout version in .cosm/clones/<uuid> or checkout from remote repo
        --leads to a detached HEAD
        --copy source to .cosm/packages
        local src = Proj.terrahome.."/clones/"..dep.specs.uuid
        Cm.throw{cm="mkdir -p "..Proj.terrahome.."/packages/"..dep.name}
        --copy all files and directories, except .git*
        Cm.throw{cm="rsync -av --exclude=\".git*\" "..src.."/ "..dest}
        Cm.throw{cm="git checkout -", root=src} --reset HEAD to previous
    end
    --add pkg.dep to the project dependencies
    pkg.deps[dep.name] = dep.version
    --save pkg table
    Proj.save(pkg, "Project.lua", pkg.root)
end

--remove a project dependency
--signature Pkg.rm{dep="..."; root="."}
function Pkg.rm(args)
    --check key-value arguments
    if type(args)~="table" then
        error("Provide table with `dep` (dependency) and optional `root` directory.\n\n")
    elseif args.dep==nil then
        error("Provide table with `dep` (dependency) and optional `root` directory.\n\n")
    elseif type(args.dep)~="string" then
        error("Provide table with `dep` (dependency) as a string.\n\n")
    end
    --set and check pkg root
    if args.root==nil then
        args.root = "."
    end
    if not Proj.ispkg(args.root) then
        error("Current directory is not a valid package.")
    end
    --initialize package and dependency
    local dep = {name=args.dep}
    local pkg = fetchprojecttable(args.root)
    pkg.root = args.root
    --cannot remove a package that is not a dependency
    if pkg.deps[dep.name]==nil then
        error("Provided package is not listed as a dependency.")
    end
    --removing pkg dependency
    pkg.deps[dep.name] = nil
    --save pkg table
    Proj.save(pkg,"Project.lua", pkg.root)
end

--upgrade a package to a higher version
--signature Pkg.upgrade{dep="...", version="xx.xx.xx"; root="."}
function Pkg.upgrade(args)
    --check key-value arguments
    if type(args)~="table" then
        error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
    elseif args.dep==nil or args.version==nil then
        error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
    elseif type(args.dep)~="string" or type(args.version)~="string" then
        error("Provide table with `dep` (dependency) and `version` as a string.\n\n")
    end
    --set and check pkg root
    if args.root==nil then
        args.root = "."
    end
    if not Proj.ispkg(args.root) then
        error("Current directory is not a valid package.")
    end
    --initialize dependency
    local dep = {name=args.dep, version=args.version}

    --initialize package properties
    local pkg = fetchprojecttable(args.root)
    pkg.root = args.root
    --cannot remove a package that is not a dependency
    local oldversion = pkg.deps[dep.name]
    if oldversion==nil then
        error("Provided package is not listed as a dependency.")
    end
    local v1 = Semver.parse(oldversion)
    local v2 = Semver.parse(dep.version)
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
    --check key-value arguments
    if type(args)~="table" then
        error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
    elseif args.dep==nil or args.version==nil then
        error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
    elseif type(args.dep)~="string" or type(args.version)~="string" then
        error("Provide table with `dep` (dependency) and `version` as a string.\n\n")
    end
    --set and check pkg root
    if args.root==nil then
        args.root = "."
    end
    if not Proj.ispkg(args.root) then
        error("Current directory is not a valid package.")
    end
    --initialize dependency
    local dep = {name=args.dep, version=args.version}

    --initialize package properties
    local pkg = fetchprojecttable(args.root)
    pkg.root = args.root
    --cannot remove a package that is not a dependency
    local oldversion = pkg.deps[dep.name]
    if oldversion==nil then
        error("Provided package is not listed as a dependency.")
    end
    local v1 = Semver.parse(oldversion)
    local v2 = Semver.parse(dep.version)
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