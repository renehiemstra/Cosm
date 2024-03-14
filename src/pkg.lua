local Base = require("src.base") 
local Cm = require("src.command")
local Git = require("src.git")
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
--assumes specs {name=<pkgname>, version=<pkgversion>, uuid=<...>}
function Pkg.fetch(specs)
    if Cm.isdir(Proj.terrahome.."/clones/"..specs.uuid) then
        print("directory exists, checking out "..specs.version)
        checkout(specs)
    else
        fetchfromremote(specs)
    end
end

--assumes registry is initialized via Reg.loadregistry(...)
local function loadpkgspecs(registry, pkgname, pkgversion)
    local versionpath = registry.path.."/"..registry.table.packages[pkgname].path.."/"..pkgversion
    if not Cm.isdir(versionpath) then
        error("Package "..pkgname.." is registered in "..registry.name..", but version "..pkgversion.." is lacking.\n\n")
    end
    return dofile(versionpath.."/Specs.lua")
end

local function packageid(pkgname, version)
    --create package id - 
    local v = Semver.parse(version)
    --for unstable releases (v.major==0) every minor release is considered
    --as a different package    
    if v.major==0 then
        return pkgname.."@".."v"..v.major.."."..v.minor
    --for stable releases (v.major>0) every major release is considered
    --as a different package
    else
        return pkgname.."@".."v"..v.major
    end
end

local function packageidext(pkgname, version)
    return pkgname.."@v"..version
end

local function addtominrequirmentslist(list, pkgname, version, upgrades, latest)
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
        local pkg = {name=pkgname, version=version}
        if latest==true then
            Pkg.loadpkg(registry, pkg, true) --upgrade to latest=[true, false]
        else
            Pkg.loadpkg(registry, pkg, upgrades[pkgid]==true) --upgrade to latest=[true, false]
        end
        --update requirement list
        list[pkgid][version] = pkg.version
        --get specs of this package
        local specs = loadpkgspecs(registry, pkg.name, pkg.version)
        --recursively add to minimal requirement list
        for depname,depversion in pairs(specs.deps) do
            addtominrequirmentslist(list, depname, depversion, upgrades, latest)
        end
    end
end

--compute the minimum requirement list
--<pkg : table> contains the specs of the top-level package
--<latest : boolean> signals that latest versions are used
local function minrequirmentslist(pkg, upgrades, latest)
    --our minimal requirement list
    local list = {}
    --loop over direct dependencies of our project
    for depname,depversion in pairs(pkg.deps) do
        addtominrequirmentslist(list, depname, depversion, upgrades, latest)
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
    if req[pkgid]~=nil then
        version = req[pkgid]
    end
    --insert version of dependency in associated table
    --checking for nil: if dependencies of this version
    --are already treated then move on without redoing work.
    if list[pkgid][version]==nil then
        --load package from registry
        local registry = {} --{name, path, table}
        local pkg = {name=pkgname, version=version}
        Pkg.loadpkg(registry, pkg, false) --latest=true/false
        --get specs of this package
        local specs = loadpkgspecs(registry, pkg.name, pkg.version)
        --add to build list
        list[pkgid][version] = {
            name=specs.name,
            version=specs.version,
            path="packages/"..specs.name.."/"..specs.sha1,
            uuid=specs.uuid,
            sha1=specs.sha1,
            url=specs.url
        }
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
end

--fetch buildlist, if it exists
local function fetchbuildlist(root)
    local buildlist = {}
    if Cm.isfile(root.."/.cosm/Buildlist.lua") then
        buildlist = dofile(root.."/.cosm/Buildlist.lua")
    end
    return buildlist
end

--fetch a simplified version of the buildlist, if it exists
local function fetchsimplebuildlist(root)
    local buildlist = fetchbuildlist(root)
    local simplebuildlist = {}
    for key, t in pairs(buildlist) do
        simplebuildlist[key] = t.version
    end
    return simplebuildlist
end

--fetches the Require.lua file in .cosm if it exists
--assumes root is a valid cosm package root
local function fetchrequirmentstable(root, recompute)
    if recompute==true then
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
    if Cm.isfile(root.."/.cosm/Require.lua") then
        return dofile(root.."/.cosm/Require.lua")
    else
        error("File '"..root.."/.cosm/Require.lua' does not exist.\n")
    end
end

--get the raw build list that lists all minimum requirements
--and still needs to be filtered to obtain the maximum of all 
--minimal requirements
local function getrawbuildlist(root, recompute_requirments)
    print(root)
    if not Proj.ispkg(root) then
        error("Current directory is not a valid package.")
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

local function mark_as_buildlist(t)
    setmetatable(t, {__isbuildlist = true})
end

function Pkg.isbuildlist(t)
    local mt = Base.getcustommetatable(t)
    return mt.__isbuildlist==true
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
function Pkg.getminimalrequirementlist(pkg, constraints, latest)
    local list = minrequirmentslist(pkg, constraints, latest)
    --compute the top-level external requirments
    local minreq = reducerequirementlist(list, constraints)
    --insert direct dependencies
    for depname,depversion in pairs(pkg.deps) do
        local pkgid = packageid(depname, depversion)
        if minreq[pkgid]==nil then
            minreq[pkgid] = depversion
        end
    end
    return minreq
end

local function savebuildlist(list, root)
    --open Buildlist.lua and set to stdout
    Cm.throw{cm="touch Buildlist.lua", root=root}
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
end

--assumes a valid specs-entry from a build-list
--{name=<pkgname>, version=<pkgversion>, path=<packages/...>, clone=<clones/...>}
local function makepkgavailable(specs)
    local dest = Proj.terrahome.."/"..specs.path
    if not Cm.isdir(specs.path) then
        Pkg.fetch(specs) --checkout version in .cosm/clones/<uuid> or checkout from remote repo
        --leads to a detached HEAD
        --copy source to .cosm/packages
        local src = Proj.terrahome.."/clones/"..specs.uuid
        Cm.throw{cm="mkdir -p "..dest}
        --copy all files and directories, except .git*
        Cm.throw{cm="rsync -av --exclude=\".git*\" "..src.."/ "..dest}
        Cm.throw{cm="git checkout -", root=src} --reset HEAD to previous
        print("Done copying, package added")
    end
end

function Pkg.makeavailable(buildlist)
    if not Pkg.isbuildlist(buildlist) then
        error("Not a valid build list.")
    end
    --make packages in build list available
    for _,pkgspecs in pairs(buildlist) do
        makepkgavailable(pkgspecs)
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
end

--get latest version that is compatible with v
--assumes input is a table loaded from a Versions.lua file
--implicitly assumes that vmin is a listed version
local function getlatestcompatible(versions, vmin)
    local save = Semver.parse(vmin)
    if save.major==0 then
        for i,v in ipairs(versions) do
            local current = Semver.parse(v)
            if current.major==save.major and current.minor==save.minor and current>save then
                save = current
            end
        end
    else
        for i,v in ipairs(versions) do
            local current = Semver.parse(v)
            if current.major==save.major and current>save then
                save = current
            end
        end
    end
    return tostring(save)
end

--retreive metadata of a pkg and load the registry
function Pkg.loadpkg(registry, pkg, latest)
    -- if not type(upgrades)=="boolean" then
    --     error("latest should be 'true' or 'false'.\n")
    -- end
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
    --possibly pick the last version
    if latest then
        local versions = dofile(registry.path.."/"..pkg.path.."/Versions.lua")
        pkg.version = getlatestcompatible(versions, pkg.version)
    end
    --sanity-check if version is present in registry
    local versionpath = registry.path.."/"..pkg.path.."/"..pkg.version
    if not Cm.isdir(versionpath) then
        error("Package "..pkg.name.." is registered in "..registry.name..", but version "..pkg.version.." is lacking.\n\n")
    end
end

function Pkg.upgradeall(root)
    if not Proj.ispkg(root) then
        error("Current directory is not a valid package.")
    end
    --our minimal requirement list
    local pkg = fetchprojecttable(root)
    local minreq = Pkg.getminimalrequirementlist(pkg, {}, true) --upgrade all = true
    Base.mark_as_general_keys(minreq)
    Cm.throw{cm="mkdir -p .cosm", root=root}
    saverequirementlist(minreq, ".cosm/Require.lua", root)
    --compute induced build list (without recomputing minimal requirment list)
    Pkg.buildlist(root, false)
end

local function pkgnamefromid(id)
    local a,b = id:match("(.+)@(.+)")
    return a
end

local function pkgmajorversionfromid(id)
    local a,b = id:match("(.+)@(.+)")
    return b
end

local function addconstraint(constraints, depname, version)
    local depid
    local count = 0
    for id,_ in pairs(constraints) do
        count = count + 1
        if depname==pkgnamefromid(id) then
            depid = id
            break
        end
    end
    if count~=nil then
        if depid~=nil then
            constraints[depid] = version
        else
            error("Package "..depname.." is not listed as a direct or transitive dependency.")
        end
    end
    return constraints
end

function Pkg.upgradesinglepkg(root, depname, depversion)
    --check arguments
    if type(depname)~="string" then
        error("Provide dependency name as a string.\n")
    end
    if type(depversion)~="string" then
        error("Version number should be a string.")
    end
    if not Proj.ispkg(root) then
        error("Current directory is not a valid package.")
    end
    --check versions and update the project table
    local pkg = fetchprojecttable(root)
    local dep = {name=depname, version=pkg.deps[depname]}
    local registry = {}
    --in the case of a direct dependency, update Project.lua file
    if dep.version~=nil then
        --special case when checking out the latest version
        if depversion=="latest" then
            Pkg.loadpkg(registry, dep, true) --load new version into dep.version
        else
            local vold = Semver.parse(dep.version) --parse old version
            local vnew = Semver.parse(depversion)  --parse new version
            if vold==vnew then
                error("Cannot upgrade: version already listed as a dependency.")
            elseif vold>vnew then
                error("Cannot upgrade: version is older than the one installed.")
            end
            dep.version = depversion --set new version    
            Pkg.loadpkg(registry, dep, false) --load new version to see if it exists
        end
        --update version on Project.lua table
        pkg.deps[depname] = dep.version
        Proj.save(pkg, "Project.lua", root)
    end
    --fetch a simplified representation of the previous build list
    --and add constraint 
    --(we don't want that an upgrade in A causes a downgrade in B)
    local constraints = fetchsimplebuildlist(root)
    addconstraint(constraints, depname, true)
    --compute requirement list that induces build list we want
    local minreq = Pkg.getminimalrequirementlist(pkg, constraints, false) --upgrade all = false
    Base.mark_as_general_keys(minreq)
    Cm.throw{cm="mkdir -p .cosm", root=root} --should not be needed - do it anyway
    saverequirementlist(minreq, ".cosm/Require.lua", root)
    --compute induced build list (without recomputing minimal requirment list)
    Pkg.buildlist(root, false)
    return dep.version
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

-- --downgrade a package to a lower version
-- --signature Pkg.downgrade{dep="...", version="xx.xx.xx"; root="."}
-- function Pkg.downgrade(args)
--     --check key-value arguments
--     if type(args)~="table" then
--         error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
--     elseif args.dep==nil or args.version==nil then
--         error("Provide table with `dep` (dependency) and `version` and optional `root` directory.\n\n")
--     elseif type(args.dep)~="string" or type(args.version)~="string" then
--         error("Provide table with `dep` (dependency) and `version` as a string.\n\n")
--     end
--     --set and check pkg root
--     if args.root==nil then
--         args.root = "."
--     end
--     if not Proj.ispkg(args.root) then
--         error("Current directory is not a valid package.")
--     end
--     --initialize dependency
--     local dep = {name=args.dep, version=args.version}

--     --initialize package properties
--     local pkg = fetchprojecttable(args.root)
--     pkg.root = args.root
--     --cannot remove a package that is not a dependency
--     local oldversion = pkg.deps[dep.name]
--     if oldversion==nil then
--         error("Provided package is not listed as a dependency.")
--     end
--     local v1 = Semver.parse(oldversion)
--     local v2 = Semver.parse(dep.version)
--     if v1==v2 then
--         error("Cannot downgrade: version already listed as a dependency.")
--     elseif v1<v2 then
--         error("Cannot downgrade: version is newer than the one installed.")
--     end
--     --rm and add new version
--     Pkg.rm(args)
--     Pkg.add(args)
-- end

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