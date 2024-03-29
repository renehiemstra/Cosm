local Base = require("src.base") 
local Cm = require("src.command")
local Git = require("src.git")
local Proj = require("src.project")
local Reg = require("src.registry")
local Semver = require("src.semver")
local Color = require("src.color")

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

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

--list the project status
--expects that `root` directory is a valid pkg root
function Pkg.status(root)
    local pkg = {}
    if not Proj.ispkg(root, pkg) then
        error("Current directory is not a valid package.")
    end
    local project = pkg.table
    print(Color.fg.BLUE..Color.bold..firstToUpper(project.language).." project "..project.name.." version "..project.version..Color.normal..Color.reset)
    print("Status `"..Cm.currentworkdir().."/Project.lua`")
    if Cm.isfile(root.."/.cosm/buildlist.lua") then
        local buildlist = Pkg.fetchbuildlist(root)
        print("Dependencies:")
        local sorted = Base.getsortedkeys(buildlist)
        for i,key in ipairs(sorted) do
            local specs = buildlist[key]
            if project.deps[specs.name]~=nil then
                print(Color.fg.BLUE..Color.bold.."  "..specs.name.."\t\tv"..specs.version..Color.normal..Color.reset)
            else
                print("  "..specs.name.."\t\tv"..specs.version)
            end
        end
    end
    print()
end

--check out the source code
local function checkout(specs)
    local root=Proj.terrahome.."/clones/"..specs.uuid
    if Cm.isdir(root) then
        if Git.isdetached(root) then
            Cm.throw{cm="git checkout -", root=root}
        end
        if Git.isdetached(root) then
            error("HEAD is still detached")
        end
        Cm.throw{cm="git pull", root=root} --get updates from remote - this is buggy
        Cm.throw{cm="git checkout "..specs.sha1, root=root}
    else
        print("directory "..root.." does not exists")
    end
end

--clone package in ~.cosm/clones/<pkg-uuid>
--assumes specs {name=<pkgname>, version=<pkgversion>, uuid=<...>}
function Pkg.fetch(specs)
    local root = Proj.terrahome.."/clones"
    if not Cm.isdir(root.."/"..specs.uuid) then
        Cm.throw{cm="git clone "..specs.url.." "..specs.uuid, root=root}
    end
    checkout(specs)
end

--assumes registry is initialized via Reg.loadregistry(...)
local function loadpkgspecs(registry, pkgname, pkgversion)
    local versionpath = registry.path.."/"..registry.table.packages[pkgname].path.."/"..pkgversion
    if not Cm.isdir(versionpath) then
        error("Package "..pkgname.." is registered in "..registry.name..", but version "..pkgversion.." is lacking.")
        os.exit(1)
    end
    return dofile(versionpath.."/Specs.lua")
end

local function packageid(pkgname, version)
    --create package id - 
    local v = Semver.parse(version)
    --for stable releases (v.major>0) every major release is considered
    --as a different package
    return pkgname.."@v"..v.major
end

local function addtominrequirmentslist(list, pkgname, version, constraints, upgrade, upgrade_option)
    --get package identifier
    local pkgid = packageid(pkgname, version)
    --create table on first entry
    if list[pkgid]==nil then
        list[pkgid] = {}
        Base.mark_as_general_keys(list[pkgid])
    end
    --add entry: 'version' -> latest compatible with 'version'
    --only do work if case is not yet treated.
    if list[pkgid][version]==nil then
        --load package from registry
        local registry = {}
        local specs
        local pkg = {name=pkgname, version=version}
        --Implement constraint on package
        if constraints[pkgid]~=nil then
            local vold = Semver.parse(constraints[pkgid])
            local vnew = Semver.parse(pkg.version)
            if vold.build=="dev" or vold > vnew then
                pkg.version = constraints[pkgid]
            end
        end
        --load package from registry
        if Semver.parse(pkg.version).build=="dev" then
            specs = Pkg.loaddevpkg(pkg)
        else
            Pkg.loadpkg(registry, pkg, upgrade, upgrade_option)
            specs = loadpkgspecs(registry, pkg.name, pkg.version)
        end
        --update requirement list
        list[pkgid][version] = pkg.version
        --recursively add to minimal requirement list
        for depname,depversion in pairs(specs.deps) do
            addtominrequirmentslist(list, depname, depversion, constraints, upgrade, upgrade_option)
        end
    end
end

--compute the minimum requirement list
--<pkg : table> contains the specs of the top-level package
--<latest : boolean> signals that latest versions are used
local function minrequirmentslist(pkg, constraints, upgrade, upgrade_option)
    --our minimal requirement list
    local list = {}
    --loop over direct dependencies of our project
    for depname,depversion in pairs(pkg.deps) do
        addtominrequirmentslist(list, depname, depversion, constraints, upgrade, upgrade_option)
    end
    return list
end

local function addtobuildlist(list, req, pkgname, version)
    --get package identifier
    local pkgid = packageid(pkgname, version)
    --create table entry of version for this dependency
    if list[pkgid]==nil then
        list[pkgid] = {}
        Base.mark_as_general_keys(list[pkgid])
    end
    --get version requirement
    if req[pkgid]~=nil then
        version = req[pkgid]
    end
    --insert version of dependency in associated table
    --checking for nil: if dependencies of this version
    --are already treated then move on without redoing work.
    if list[pkgid][version]==nil then
        local registry = {} --{name, path, table}
        local pkg = {name=pkgname, version=version}
        local specs
        local sv = Semver.parse(version)
        --special treatement for dev-packages
        if sv.build=="dev" then
            --load package from registry
            pkg.version = tostring(sv.major)
            Pkg.loadpkg(registry, pkg, true, "constrained")
            --get specs of this package
            specs = loadpkgspecs(registry, pkg.name, pkg.version)
            --add to raw build list
            list[pkgid][tostring(sv)] = {
                name=specs.name,
                version=version,
                language=specs.language,
                path="dev/"..pkgid,
                uuid=specs.uuid,
                url=specs.url
            }
        else
            --load package from registry
            Pkg.loadpkg(registry, pkg, false) --latest=true/false
            --get specs of this package
            specs = loadpkgspecs(registry, pkg.name, pkg.version)
            --add to raw build list
            list[pkgid][version] = {
                name=specs.name,
                version=specs.version,
                language=specs.language,
                path="packages/"..specs.name.."/"..specs.sha1,
                uuid=specs.uuid,
                sha1=specs.sha1,
                url=specs.url
            }
        end
        --recursively add dependencies to buildlist
        for depname,depversion in pairs(specs.deps) do
            addtobuildlist(list, req, depname, depversion)
        end
    end
end

--expects table with keys the version number
local function selectmaximalversion(listentry)
    local vold = Semver(0,0,0)
    for v,_ in pairs(listentry) do
        local vnew = Semver.parse(v)
        if vnew > vold then
            vold = vnew
        end
    end
    return tostring(vold)
end

--save `projtable` to a Project.lua file
local function saverequirementlist(req, rfile, root)
    --open Project.t and set to stdout
    local oldout = io.output() 
    local file = io.open(root.."/"..rfile, "w")
    io.output(file)
    --write main project data to file
    io.write("local Require = {\n")
    local keys = Base.getsortedkeys(req)
    for _,key  in ipairs(keys) do
        io.write("    [\"", key, "\"] = ")
        Base.serialize(req[key], 2)
    end
    io.write("}\n")
    io.write("return Require")
    --close file
    io.close(file)
    io.output(oldout)
end

local function mark_as_buildlist(t)
    setmetatable(t, {__isbuildlist = true})
end

function Pkg.isbuildlist(t)
    local mt = Base.getcustommetatable(t)
    return mt.__isbuildlist==true
end

--fetch buildlist, if it exists
function Pkg.fetchbuildlist(root)
    local buildlist = {}
    if Cm.isfile(root.."/.cosm/Buildlist.lua") then
        buildlist = dofile(root.."/.cosm/Buildlist.lua")
        mark_as_buildlist(buildlist)
    end
    return buildlist
end

local function simplifybuildlist(buildlist)
    local simplebuildlist = {}
    for key, t in pairs(buildlist) do
        simplebuildlist[key] = t.version
    end
    return simplebuildlist
end

--fetch a simplified version of the buildlist, if it exists
local function fetchsimplebuildlist(root)
    local buildlist = Pkg.fetchbuildlist(root)
    return simplifybuildlist(buildlist)
end

--fetches the Require.lua file in .cosm if it exists
--assumes root is a valid cosm package root
local function fetchrequirmentstable(root, recompute)
    if Cm.isfile(root.."/.cosm/Require.lua") and recompute==false then
        return dofile(root.."/.cosm/Require.lua")
    else
        --create directory if it does not exist
        Cm.throw{cm="mkdir -p .cosm", root=root}
        --compute minimal requirement list without upgrades (false)
        local constraints = fetchsimplebuildlist(root)
        local pkg = fetchprojecttable(root)
        local req = Pkg.getminimalrequirementlist(pkg, constraints, false)
        Base.mark_as_general_keys(req)
        saverequirementlist(req, ".cosm/Require.lua", root)
        return req
    end
end

--get the raw build list that lists all minimum requirements
--and still needs to be filtered to obtain the maximum of all 
--minimal requirements
local function getrawbuildlist(root, recompute_requirments)
    if not Proj.ispkg(root) then
        print("Current directory is not a valid package.")
        os.exit()
    end
    --our build list
    local list = {}
    local pkg = fetchprojecttable(root)
    --our requirment list
    local req = fetchrequirmentstable(root, recompute_requirments)
    --loop over direct dependencies of our project
    for depname,depversion in pairs(pkg.deps) do
        addtobuildlist(list, req, depname, depversion)
    end
    return list
end

local function minimalversionselection(rawbuildlist)
    for pkgid,vdata in pairs(rawbuildlist) do
        --determine the maximum of the minimal requirements
        local maxversion = selectmaximalversion(vdata)
        --overwrite the raw-build list entry with maximum version of
        --the minimum requirements and save path to the package version
        rawbuildlist[pkgid] = vdata[maxversion]
        Base.mark_as_simple_keys(rawbuildlist[pkgid])
        mark_as_buildlist(rawbuildlist)
    end
end

--determine the top-level requirment list
local function reducerequirementlist(list, constraints)
    local minreq = {}
    for dep,versions in pairs(list) do
        local implied = false
        local v
        for vold,vnew in pairs(versions) do
            v = vnew
            if vold==vnew then
                implied = true
                break
            end
        end
        --if not implied by other packages, then add requirment
        if not implied then
            minreq[dep] = v
        else
            if type(constraints[dep])=="string" then
                --if implied version is lower than the one in the current build  
                --list, then add requirement
                local vn = Semver.parse(v)
                local vc = Semver.parse(constraints[dep])
                --we don't want an upgrade of one package to cause a downgrade 
                --of another package
                if vn < vc then
                    minreq[dep] = constraints[dep]
                end
            end
        end
    end
    return minreq
end

--determine the top-level requirements 
function Pkg.getminimalrequirementlist(pkg, constraints, upgrade, upgrade_option)
    local list = minrequirmentslist(pkg, constraints, upgrade, upgrade_option)
    --compute the top-level external requirments
    local minreq = reducerequirementlist(list, constraints)
    return minreq
end

local function savebuildlist(list, root)
    --open Buildlist.lua and set to stdout
    Cm.throw{cm="touch Buildlist.lua", root=root}
    local oldout = io.output() 
    local file = io.open(root.."/Buildlist.lua", "w")
    io.output(file)
    --write main project data to file
    io.write("local Buildlist = {\n")
    --write table in sorted order
    local keys = Base.getsortedkeys(list)
    for _,key  in ipairs(keys) do
        io.write("    [\"", key, "\"] = ")
        Base.serialize(list[key], 2)
    end
    io.write("}\n")
    io.write("return Buildlist")
    --close file
    io.close(file)
    io.output(oldout)
end

local function makepkgavailable(specs, including_version_control)
    local dest = Proj.terrahome.."/"..specs.path
    if not Cm.isdir(dest) then
        Pkg.fetch(specs) --checkout version in .cosm/clones/<uuid> or checkout from remote repo
        --leads to a detached HEAD
        --copy source to .cosm/packages
        local src = Proj.terrahome.."/clones/"..specs.uuid
        --copy all files and directories, except .git*
        if including_version_control then
            --copy source code, including git version control
            Git.resethead(src) --reset HEAD before copying
            Cm.throw{cm="cp -r "..src.." "..dest}
        else
             --copy source code, exluding git version control
            Cm.throw{cm="mkdir -p "..dest}
            Cm.throw{cm="rsync -av --exclude=\".git*\" "..src.."/ "..dest}
            Git.resethead(src) --reset HEAD after copying
        end
    end
end

function Pkg.makeavailable(buildlist)
    if not Pkg.isbuildlist(buildlist) then
        error("Not a valid build list.")
    end
    --make packages in build list available
    for _,pkgspecs in pairs(buildlist) do
        local topleveldir = pkgspecs.path:match("(.-)/")
        local including_version_control
        --for now we only support the 'dev' and 'packages' directory
        if topleveldir=="dev" then
            including_version_control = true
        elseif topleveldir=="packages" then
            including_version_control = false
        else
            error("Toplevel directory should be the 'packages' or 'dev' directory.")
        end
        --make the actual source code available
        makepkgavailable(pkgspecs, including_version_control)
    end
end

function Pkg.buildlist(root, recompute_requirements)
    --compute raw build list
    local list = getrawbuildlist(root, recompute_requirements)
    --determine maximum of the minimum requirements
    minimalversionselection(list)
    --save build list
    Cm.throw{cm="mkdir -p .cosm", root=root}
    savebuildlist(list, root.."/.cosm")
    --make packages available in the buildlist
    -- Pkg.makeavailable(list)
    return list
end

--retreive metadata of a pkg and load the registry
function Pkg.loadpkg(registry, pkg, upgrade, upgrade_option)
    if not type(upgrade)=="boolean" then
        error("'upgrade' should be 'true' or 'false'.\n")
    end
    if type(pkg.version) ~= "string" then
        error("Provide table with `version` as a string.\n\n")
    end
    --find package in available registries
    local found = Reg.loadregistry(registry, pkg.name)
    --case where pkgdep is not found in any of the registries
    if not found then
        error("Package "..pkg.name.." is not a registered package.\n\n")
    end
    --select version
    pkg.path = registry.table.packages[pkg.name].path
    --possibly upgrade to the latest/compatible version
    if upgrade==true then
        local versions = dofile(registry.path.."/"..pkg.path.."/Versions.lua")
        if upgrade_option=="latest" then
            --by default pick the latest (incompatible) version
            pkg.version = Semver.latest(versions, pkg.version)
        elseif upgrade_option=="compat" then
            --otherwise, pick the latest one that is compatible
            --according to semver 2.0
            pkg.version = Semver.latestCompatible(versions, pkg.version)
        elseif upgrade_option=="constrained" then
            --otherwise, pick the latest one, given a constraint
            pkg.version = Semver.latestConstrained(versions, pkg.version)
        end
    end
    --sanity-check if version is present in registry
    local versionpath = registry.path.."/"..pkg.path.."/"..pkg.version
    if not Cm.isdir(versionpath) then
        if not upgrade then
            print("Package "..pkg.name.." is registered in "..registry.name..", but version "..pkg.version.." is lacking.")
        else
            print("Package "..pkg.name.." is registered in "..registry.name..", but there is no version compatible to "..pkg.version..".")
        end
        os.exit(1)
    end
end

--load a development package - assumes that it has already been made available
--input: pkg = {name=..., version=...}
function Pkg.loaddevpkg(pkg)
    local pkgid = packageid(pkg.name, pkg.version)
    --retrieve specs of package
    pkg.path = "dev/"..pkgid
    --make package available in /cosm/dev/<pkgid>
    if not Cm.isdir(Proj.terrahome.."/"..pkg.path) then
        error("Directory "..Proj.terrahome.."/"..pkg.path.." does not exist.")
    end
    local project = fetchprojecttable(Proj.terrahome.."/"..pkg.path)
    --update package info
    pkg.version = project.version.."+dev"
    pkg.sha1 = Git.hash(Proj.terrahome.."/"..pkg.path)
    pkg.deps = project.deps
    return pkg
end

local function loadspecs(buildlist, pkgname)
    --extract package info from previous build list
    for id, specs in pairs(buildlist) do
        if specs.name==pkgname then
            return specs
        end
    end
    print("Package "..pkgname.." is not a dependency.")
    os.exit(1)
end

function Pkg.upgradeall(root, upgrade_option)
    if not Proj.ispkg(root) then
        error("Current directory is not a valid package.")
    end
    --fetch current project details
    local pkg = fetchprojecttable(root)
    --compute minimal requirements and save
    local minreq = Pkg.getminimalrequirementlist(pkg, {}, true, upgrade_option) --upgrade all = true
    Base.mark_as_general_keys(minreq)
    Cm.throw{cm="mkdir -p .cosm", root=root}
    saverequirementlist(minreq, ".cosm/Require.lua", root)
    --compute induced build list (without recomputing minimal requirment list)
    Pkg.buildlist(root, false)
end

local function decomposeid(id)
    local a,b = id:match("(.+)@v(.+)")
    return a, tostring(Semver.parse(b))
end

local function pkgnamefromid(id)
    local a,b = id:match("(.+)@v(.+)")
    return a
end

local function pkgmajorversionfromid(id)
    local a,b = id:match("(.+)@v(.+)")
    return b
end

local function addconstraint(constraints, depname, version)
    local id = packageid(depname, version)
    constraints[id] = version
end

function Pkg.upgradesinglepkg(root, depname, new_incomplete_version, latest)
    --check we are inside a pkg
    if not Proj.ispkg(root) then
        print("Current directory is not a valid package.")
        os.exit(1)
    end
    --fetch a simplified representation of the previous build list
    --get current version
    local buildlist = fetchsimplebuildlist(root)
    local currentversion
    for id, version in pairs(buildlist) do
        if pkgnamefromid(id)==depname then
            currentversion = version
            break
        end
    end
    if currentversion==nil then
        print("Not a dependency. Can't upgrade.")
        os.exit(1)
    end
    --extract name and (incomplete) version
    local dep = {name=depname, version=currentversion}
    local upgrade_option
    if new_incomplete_version~=nil then
        dep.version = new_incomplete_version
        upgrade_option = "constrained"
    else
        if latest==true then
            upgrade_option = "latest"
        else
            upgrade_option = "compatible"
        end
    end
    --check if package exists and load the latest compatible version
    local registry = {}
    --load new version into dep.version
    --upgrade set to true
    Pkg.loadpkg(registry, dep, true, upgrade_option)
    --check if upgrade is possible
    local vold = Semver.parse(currentversion) --parse old version
    local vnew = Semver.parse(dep.version)   --parse new version
    if vold==vnew then
        print("Cannot upgrade: version already listed as a dependency.")
        os.exit(1)
    elseif vold>vnew then
        print("Cannot upgrade: version is older than the one installed.")
        os.exit(1)
    end
    --use constraints from buildlist: use upgraded version
    --also, we don't want that an upgrade in A causes a downgrade in B
    addconstraint(buildlist, dep.name, dep.version)
    --compute requirement list that induces build list we want
    local pkg = fetchprojecttable(root)
    local minreq = Pkg.getminimalrequirementlist(pkg, buildlist, false, false)
    Base.mark_as_general_keys(minreq)
    Cm.throw{cm="mkdir -p .cosm", root=root} --should not be needed - do it anyway
    saverequirementlist(minreq, ".cosm/Require.lua", root)
    --compute induced build list (without recomputing minimal requirment list)
    Pkg.buildlist(root, false)
    --return specs of upgraded package
    return dep
end

function Pkg.develop(root, depname)
    --check if we are inside a package
    if not Proj.ispkg(root) then
        print("Current directory is not a valid package.")
        os.exit(1)
    end
    --load package using previous build list
    local buildlist = Pkg.fetchbuildlist(root)
    --load specs of current dependency
    local specs = loadspecs(buildlist, depname)
    local dep = {name = depname, version=specs.version}
    specs.path = "dev/"..packageid(dep.name, dep.version)
    --make package available in development-mode
    makepkgavailable(specs, true)
    Pkg.loaddevpkg(dep)
    --also, we don't want that an upgrade in A causes a downgrade in B
    buildlist = fetchsimplebuildlist(root)
    addconstraint(buildlist, dep.name, dep.version)
    --compute requirement list that induces build list we want
    local pkg = fetchprojecttable(root)
    local minreq = Pkg.getminimalrequirementlist(pkg, buildlist, false, false)
    Base.mark_as_general_keys(minreq)
    Cm.throw{cm="mkdir -p .cosm", root=root} --should not be needed - do it anyway
    saverequirementlist(minreq, ".cosm/Require.lua", root)
    -- --compute induced build list (without recomputing minimal requirment list)
    Pkg.buildlist(root, false)
    return dep
end

function Pkg.free(root, depname)
    --check if we are inside a package
    if not Proj.ispkg(root) then
        print("Current directory is not a valid package.")
        os.exit(1)
    end
    --fetch current build list
    local buildlist = Pkg.fetchbuildlist(root)
    --load specs of current dependency
    local specs = loadspecs(buildlist, depname)
    --set build flag from "dev" to ""
    local v = Semver.parse(specs.version)
    if v.build=="dev" then
        v.build = nil
        local dep = {name = depname, version=tostring(v.major)}
        local registry = {}
        Pkg.loadpkg(registry, dep, true, "constrained")
        --also, we don't want that an upgrade in A causes a downgrade in B
        buildlist = fetchsimplebuildlist(root)
        addconstraint(buildlist, dep.name, dep.version)
        --compute requirement list that induces build list we want
        local pkg = fetchprojecttable(root)
        local minreq = Pkg.getminimalrequirementlist(pkg, buildlist, false, false)
        Base.mark_as_general_keys(minreq)
        Cm.throw{cm="mkdir -p .cosm", root=root} --should not be needed - do it anyway
        saverequirementlist(minreq, ".cosm/Require.lua", root)
        --compute induced build list (without recomputing minimal requirment list)
        Pkg.buildlist(root, false)
        return dep
    end
end

--add a dependency to a project
--signature Pkg.add{dep="...", version="xx.xx.xx"; root="."}
function Pkg.add(args)
    --check key-value arguments
    if type(args)~="table" then
        error("Provide table with `dep` (dependency) and optional `version` and `root` directory.\n\n")
    elseif args.dep==nil then
        error("Provide table with `dep` (dependency) and optional `version` and `root` directory.\n\n")
    elseif type(args.dep)~="string" then
        error("Provide table with `dep` (dependency) as a string.\n\n")
    elseif type(args.version)~="string" then
        error("Provide table with `version` as a string.\n\n")
    end
    --set and check pkg root
    if args.root==nil then
        args.root = "."
    end
    if not Proj.ispkg(args.root) then
        error("Current directory is not a valid package.")
    end
    --initialize package and dependency
    local pkg = fetchprojecttable(args.root)
    pkg.root = args.root
    --check that pkg and pkg.dep are not the same package
    if pkg.name==args.dep then
      error("Cannot add "..args.dep.."as a dependency to "..pkg.name..".\n\n")
    end
    --find pkg-dep and version in known registries
    local dep = {name=args.dep, version=args.version}
    local registry = {} --{name, path, table}
    Pkg.loadpkg(registry, dep, false) --false -> no upgrade
    --add pkg.dep to the project dependencies
    pkg.deps[dep.name] = dep.version
    --save pkg table
    Proj.save(pkg, "Project.lua", pkg.root)
    --create the updated buildlist
    Pkg.buildlist(pkg.root, true)
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
    --create the updated buildlist
    Pkg.buildlist(pkg.root, true)
end

--release a new pkg version to the registry
--signature: Reg.release{release=...("patch", "minor","major", or a version number)}
function Pkg.release(release)
    -- --check keyword argument `release`
    -- if not ((pkgrelease=="patch") or (pkgrelease=="minor") or (pkgrelease=="major")) then
    --   error("Provide `release` equal to \"patch\", \"minor\", or \"major\".\n\n")
    -- end
    --check if current directory is a valid package
    if not Proj.ispkg(".") then
      error("Current directory does not follow the specifications of a cosm pkg.\n")
    end
    --check if all work is added and committed
    if not Git.nodiff(".") or not Git.nodiffstaged(".") then
      error("Git repository has changes that are unstaged or uncommited. First stage and commit your work. Then release your package.\n")
    end
    --initialize package
    local pkg = dofile("Project.lua")
    pkg.dir = "."
    --increase package version
    local oldversion = Semver.parse(pkg.version)
    local version
    if release=="patch" then
      version = oldversion:nextPatch()
    elseif release=="minor" then
      version = oldversion:nextMinor()
    elseif release=="major" then
      version = oldversion:nextMajor()
    else
      version = Semver.parse(release)
      -- make sure the release is different than the current semantic version
      if version==oldversion then --check equality of version number and prerelease
        --check of build is the same
        if version.build==oldversion.build then
            error("Version nummber, prerelease and build is the same as the current one.")
        end
      end
    end
    pkg.version = tostring(version)
    Cm.throw{cm="git fetch --tags"}
    --check if version is already tagged
    if Git.istagged(".", "v"..pkg.version) then
        error("Exact same version is already released")
    end
    --save Project.lua with new version number
    Proj.save(pkg, "Project.lua", ".")
    --add and commit changes, push commit, and tag version and push to remote
    local commitmessage = "\"<release> "..pkg.name.."..v"..pkg.version.."\""
    Cm.throw{cm="git add ."}
    Cm.throw{cm="git commit -m "..commitmessage}
    Cm.throw{cm="git push"}
    Cm.throw{cm="git tag v"..pkg.version}
    Cm.throw{cm="git push origin v"..pkg.version}
    return pkg --return all updated pkg info
end
  

return Pkg