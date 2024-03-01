local Base = require("src.base")
local Cm   = require("src.command")
local Git  = require("src.git")
local Proj = require("src.project")
local Semver = require("src.semver")

local Reg = {}

--terra directories
Reg.regdir = Proj.terrahome.."/registries"

local function fetchregistrytable(root)
  return dofile(root.."/Registry.lua")
end

function Reg.getregistryspecs(root)
  if not Reg.isreg(root) then
    error("Not a registry")
  end
  return fetchregistrytable(root)
end

--check if table is a valid registry table
function Reg.isregtable(table)
  for k,v in ipairs{name="string", uuid="string", url="string", description="string", packages="table"} do
    if not Base.haskeyoftype(table, k, v) then
      return false
    end
  end
  return true
end

--check if root follows registry specifications
function Reg.isreg(root)
  if not Cm.isdir(root) then
    return false
  end
  if not Cm.isfile(root.."/Registry.lua") then
    return false
  end
  local table = dofile(root.."/Registry.lua")
  return Reg.isregtable(table)
end

--load all registries listed in List.lua
function Reg.loadregistries()
  if not Cm.isfile(Reg.regdir.."/List.lua") then
    error("List.lua does not exist.\n\n")
  end
  local list = dofile(Reg.regdir.."/List.lua")
  if not type(list)=="table" then
    error("List.lua should return a table with containing the names of all registries.\n\n")
  end
  return list
end

--find pkgname in known registries. Load name, path, and table to registry
function Reg.loadregistry(registry, pkgname)
  for _,regname in pairs(Reg.loadregistries()) do
      --load registry
      registry.name = regname
      registry.path = Reg.regdir.."/"..registry.name
      Cm.throw{cm="git pull", root=registry.path} --pull changes from remote
      registry.table = dofile(registry.path.."/Registry.lua")
      --check if pkgname is present
      if registry.table.packages[pkgname]~=nil then
          return true --currently we break with the first encountered package
      end
  end
  return false
end

--save all registries to List.lua
function Reg.saveregistries(registries)
  if not type(registries) == "table" then
    error("Not a lua table.\n\n")
  end
  table.sort(registries)
  if not Cm.isfile(Reg.regdir.."/List.lua") then
    Cm.throw{cm="touch List.lua", root=Reg.regdir}
  end
  local file = io.open(Reg.regdir.."/List.lua", "w")
  io.output(file)
  io.write("local List = {\n")
  for k,v in pairs(registries) do
    io.write(string.format("    %q,\n", v))
  end
  io.write("}\n")
  io.write("return List")
end

--check if registry is listed in List.lua
function Reg.islisted(registry)
  for _,listedreg in ipairs(Reg.loadregistries()) do
    if listedreg==registry then
      return true
    end
  end
  return false
end

--add registry name to the list
function Reg.addtolist(registry)
  local list = Reg.loadregistries()
  table.insert(list, registry)
  Reg.saveregistries(list)
end

--add registry name to the list
function Reg.rmfromlist(registry)
  local list = Reg.loadregistries()
  for i,v in ipairs(list) do
    if v==registry then
      table.remove(list, i)
      break
    end
  end
  Reg.saveregistries(list)
end

function Reg.registry_status(root)
  if not Reg.isreg(root) then
    error("Root directory is not a regisrtry.")
  end
  local registry = dofile(root.."/".."Registry.lua")
  print()
  print(registry.name..": "..registry.description)
  local npkg = 0
  local pkglist = {}
  for pkg, data in pairs(registry.packages) do
    npkg = npkg + 1
    table.insert(pkglist, pkg)
  end
  print("Status: "..npkg.." registered packages")
  table.sort(pkglist)
  for i, pkg in pairs(pkglist) do
    print("  "..pkg)
  end
  print()
end

--save `regtable` to a Registry.lua file
function Reg.save(regtable, regfile, root)
  --check input
  if not type(regtable) == "table" then
    error("Not a table.\n")
  end

  --open Registry.t and set to stdout
  local file = io.open(root.."/"..regfile, "w")
  io.output(file)

  --write main project data to file
  io.write("Registry = {\n")
  io.write(string.format("    name = %q,\n", regtable.name))
  io.write(string.format("    uuid = %q,\n", regtable.uuid))
  io.write(string.format("    url  = %q,\n", regtable.url))
  io.write(string.format("    description = %q,\n", regtable.description))
  io.write("    packages = ")
  Base.serialize(regtable.packages, 2)
  io.write("}\n")
  io.write("return Registry")
  --close file
  io.close(file)
end

--create a registry
--signature: Reg.create{name=..., url=...}
function Reg.create(registry)
  --check keyword arguments
  if registry.name==nil or registry.url==nil then
    error("Provide registry `name` and git `url`.\n")
  end
  if type(registry.name)~="string" then
    error("Provide registry `name` as a string.\n")
  elseif type(registry.url)~="string" then
    error("Provide git `url` as a string.\n")
  end
  --check if a registry with that name already exists
  if Reg.islisted(registry) then
    error("A registry with name "..registry.." already exists.\n\n")
  end
  --Throw an error if url is not valid
  if not Git.validemptygitrepo(registry.url) then
    error("Provide an empty git repository.\n")
  end
  --initialize registry {name, url, path, etc}
  registry.path = Reg.regdir.."/"..registry.name
  registry.uuid = Proj.uuid()
  registry.description = "Cosm local package registry"
  registry.packages = {}
  --clone repo
  Cm.throw{cm="git clone "..registry.url.." "..registry.name, root=Reg.regdir}
  --generate .ignore file
  Git.ignore(registry.path, {})
  --generate Registry.lua file
  Reg.save(registry, "Registry.lua", registry.path)
  --create git repo and push to origin\
  Cm.throw{cm="git add .", root=registry.path}
  Cm.throw{cm="git commit -m \"Initialized new registry.\"", root=registry.path}
  Cm.throw{cm="git push", root=registry.path}
  --add name of registry to the list of registries
  Reg.addtolist(registry.name)
end

function Reg.delete(registry)
  --remove from list of registries
  Reg.rmfromlist(registry)
  --remove folder and content
  Cm.throw{cm="rm -rf "..registry, root=Reg.regdir}
end

--initiates package specifics - assumes that input is already checked
local function initpkgspecs(reg, pkg)
  local root = reg.path.."/"..pkg.specpath

  --check if release does not already exist
  if Cm.isfile(root.."/"..pkg.version.."/Specs.lua") then
    error("Package version is already released")
  end

  --append pkg version to versions file
  local versions = {}
  if Cm.isfile(root.."/Versions.lua") then
    versions = dofile(root.."/Versions.lua")
  else
    --add versions file if it does not exist yet
    Cm.throw{cm="mkdir -p "..root, root="."}
    Cm.throw{cm="touch Versions.lua", root=root}
  end
  table.insert(versions, pkg.version)
  table.sort(versions)
  --write Versions.lua
  local file = io.open(root.."/Versions.lua", "w")
  io.output(file)
  io.write("Versions = {\n")
  for _,v in ipairs(versions) do
    io.write(string.format("    %q,\n", v))
  end
  io.write("}\n")
  io.write("return Versions")
  io.close(file)

  --create directory of new release and add specs file
  Cm.throw{cm="mkdir -p "..root.."/"..pkg.version}
  Cm.throw{cm="touch "..root.."/"..pkg.version.."/Specs.lua"}
  --write Specs.lua
  file = io.open(root.."/"..pkg.version.."/Specs.lua", "w")
  io.output(file)
  --write main project data to file
  io.write("Project = {\n")
  io.write(string.format("    name = %q,\n", pkg.name))
  io.write(string.format("    uuid = %q,\n", pkg.uuid))
  io.write(string.format("    version = %q,\n", pkg.version))
  io.write(string.format("    url  = %q,\n", pkg.url))
  io.write(string.format("    sha1 = %q,\n", pkg.sha1))
  --write dependencies
  io.write("    deps = ")
  Base.serialize(pkg.deps, 2)
  io.write("}\n")
  io.write("return Project")
  io.close(file)
end

function Reg.synchronize(registry)
  if type(registry)~="string" then
    error("Provide registry name.\n")
  end
  if not Reg.islisted(registry) then
    error("Not a valid registry.")
  end
  local root = Reg.regdir.."/"..registry
  if Git.nodiff(root) and Git.nodiffstaged(root) then
    --update git repository
    Cm.throw{cm="git pull; git push", root=Reg.regdir.."/"..registry}
  else
    error("Add and commit your changes before updating the repository.")
  end
end

-- signature: Reg.rmpackage(registry={name=...}, pkg={name=...})
function Reg.rmpkg(registry, pkg)
  --check keyword arguments
  if registry.name==nil or type(registry.name)~="string" then
    error("Provide `name` of registry as a string.\n")
  end
  if pkg.name==nil or type(pkg.name)~="string" then
    error("Provide package `pkg` name as a string.\n")
  end
  registry.path = Reg.regdir.."/"..registry.name
  --check if registry name points to a valid registry
  if not (Reg.islisted(registry.name) and Reg.isreg(registry.path)) then
    error("Registry is not listed or is invalid.\n")
  end
  -- get registry table with registered packages
  registry.table = dofile(registry.path.."/Registry.lua")
  --check of package is registered
  if registry.table.packages[pkg.name]==nil then
    error("Package "..pkg.name.." is not registerd to "..registry.name..".")
  end
  --update registry pkg list and save
  pkg.path = registry.table.packages[pkg.name].path
  registry.table.packages[pkg.name] = nil
  Cm.throw{cm="rm -rf "..pkg.path, root=registry.path}
  Reg.save(registry.table, "Registry.lua", registry.path)
  --update registry remote git repository
  local commitmessage = "\"<rm package> "..pkg.name.."\""
  Cm.throw{cm="git add .", root=registry.path}
  Cm.throw{cm="git commit -m "..commitmessage, root=registry.path}
  Cm.throw{cm="git pull", root=registry.path}
  Cm.throw{cm="git push", root=registry.path}
end

-- signature: Reg.rmpackage(registry={name=...}, pkg={name=...,version=...})
function Reg.rmpkgversion(registry, pkg)
  --check keyword arguments
  if registry.name==nil or type(registry.name)~="string" then
    error("Provide `name` of registry as a string.\n")
  end
  if pkg.name==nil or type(pkg.name)~="string" then
    error("Provide package `pkg` name as a string.\n")
  end
  if pkg.version==nil or type(pkg.version)~="string" then
    error("Provide package `pkg` name as a string.\n")
  end
  registry.path = Reg.regdir.."/"..registry.name
  --check if registry name points to a valid registry
  if not (Reg.islisted(registry.name) and Reg.isreg(registry.path)) then
    error("Registry is not listed or is invalid.\n")
  end
  -- get registry table with registered packages
  registry.table = dofile(registry.path.."/Registry.lua")
  --check of package is registered
  if registry.table.packages[pkg.name]==nil then
    error("Package "..pkg.name.." is not registerd to "..registry.name..".")
  end
  --check if version is present in registry
  pkg.path = registry.table.packages[pkg.name].path
  local versionpath = registry.path.."/"..pkg.path.."/"..pkg.version
  if not Cm.isdir(versionpath) then
      error("Package "..pkg.name.." is registered in "..registry.name..", but version "..pkg.version.." is lacking.\n\n")
  end
  pkg.versions = dofile(registry.path.."/"..pkg.path.."/Versions.lua")
  local count=0
  local index=-1
  for i,v in pairs(pkg.versions) do
    if v==pkg.version then
      index=i
    end
    count=count+1
  end
  --something's messed up with Versions.lua
  if index==-1 then
    error("Versions.lua is inconsistent with available versions in "..pkg.path)
  end
  --if there is only one registered version then remove package entirely
  if count<2 then
    registry.table.packages[pkg.name] = nil
    Cm.throw{cm="rm -rf "..pkg.path, root=registry.path}
    Reg.save(registry.table, "Registry.lua", registry.path)
  --else remove only specific version
  else
    --update versions table
    table.remove(pkg.versions, index)
    --remove version from Versions.lua
    local file = io.open(registry.path.."/"..pkg.path.."/Versions.lua", "w")
    io.output(file)
    io.write("Versions = {\n")
    for i,v in pairs(pkg.versions) do
      io.write(string.format("    %q,\n", v))
    end
    io.write("}\n")
    io.write("return Versions")
    io.close(file)
    --remove version folders
    Cm.throw{cm="rm -rf "..pkg.path.."/"..pkg.version, root=registry.path}
  end
  --update registry remote git repository
  local commitmessage = "\"<rm package> "..pkg.name.." v"..pkg.version.."\""
  Cm.throw{cm="git add .", root=registry.path}
  Cm.throw{cm="git commit -m "..commitmessage, root=registry.path}
  Cm.throw{cm="git pull", root=registry.path}
  Cm.throw{cm="git push", root=registry.path}
end

--register a package to a registry
--signature Reg.register{reg=..., url=...}
function Reg.register(args)
  --check keyword arguments
  if args.reg==nil then
    error("Provide `reg` (registry) name.\n")
  elseif args.url==nil then
    error("Provide package `url`.\n")
  end
  if type(args.reg)~="string" then
    error("Provide `reg` (registry) name as a string.\n")
  elseif not Git.validnonemptygitrepo(args.url) then
    error("Provide package git `url` as a string")
  end
  --check if registry name points to a valid registry
  if not Reg.isreg(Reg.regdir.."/"..args.reg) then
    error("Directory does not follow registry specifications.\n")
  end
  --download pkg associated with git url (error checking is done therein)
  local tmpdir = Proj.terrahome.."/clones/.tmp"
  Cm.throw{cm="rm -rf "..tmpdir}
  Proj.clone{name="tmp-cloned-pkg", url=args.url, root=tmpdir}

  --initialize registry properties
  local registry = {}
  registry.name = args.reg
  registry.path = Reg.regdir.."/"..registry.name
  registry.table = dofile(registry.path.."/Registry.lua")

  --copy package from tmp folder to .cosm/clones/<uuid>
  local src = tmpdir.."/tmp-cloned-pkg"
  local pkg = dofile(src.."/".."Project.lua")
  local dest = Proj.terrahome.."/clones/"..pkg.uuid
  --copy package to .cosm/clones/<uuid>
  Cm.throw{cm="cp -r "..src.." "..dest}
  Cm.throw{cm="rm -rf "..tmpdir}
  
  --initialize package properties
  pkg.dir = dest
  pkg.url = args.url
  pkg.specpath = string.sub(pkg.name, 1, 1).."/"..pkg.name --P/Pkg
  pkg.sha1 = Git.hash(pkg.dir)
  --push git tags
  Cm.throw{cm="git tag v"..pkg.version, root=pkg.dir }
  Cm.throw{cm="git push origin v"..pkg.version, root=pkg.dir }
  --update registry pkg list and save
  registry.table.packages[pkg.name] = { uuid = pkg.uuid, path = pkg.specpath}        
  Reg.save(registry.table, "Registry.lua", registry.path)
  --create pkg specs-list
  initpkgspecs(registry, pkg)
  --update registry remote git repository
  local commitmessage = "\"<new package> "..pkg.name.."\""
  Cm.throw{cm="git add .", root=registry.path}
  Cm.throw{cm="git commit -m "..commitmessage, root=registry.path}
  Cm.throw{cm="git pull", root=registry.path}
  Cm.throw{cm="git push", root=registry.path}
end

--register a package to a registry
--signature Reg.register{reg=..., pkg=..., version=...}
-- function Reg.deregister(args)
-- end

--release a new pkg version to the registry
--signature: Reg.release{release=...("patch", "minor","major", or a version number)}
function Reg.release(pkgrelease)
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
  --initialize registry
  local registry = {}
  if not Reg.loadregistry(registry, pkg.name) then
    error("Package "..pkg.name.." is not registered in any of the listed registries.")
  end
  --increase package version
  local oldversion = Semver.parse(pkg.version)
  local version
  if pkgrelease=="patch" then
    version = oldversion:nextPatch()
  elseif pkgrelease=="minor" then
    version = oldversion:nextMinor()
  elseif pkgrelease=="major" then
    version = oldversion:nextMajor()
  else
    version = Semver.parse(pkgrelease)
    if version <= oldversion then
      error("New version is older than old version.")
    end
  end
  pkg.version = tostring(version)
  pkg.url = Git.remotegeturl(".")
  pkg.registry = registry.name
  Proj.save(pkg, "Project.lua", ".")

  --create pkg specs-list
  local commitmessage = "\"<release> "..pkg.name.."..v"..pkg.version.."\""
  Cm.throw{cm="git add .", root="."}
  Cm.throw{cm="git commit -m "..commitmessage, root="."}
  Cm.throw{cm="git push", root="."}
  Cm.throw{cm="git tag v"..pkg.version, root="."}
  Cm.throw{cm="git push origin v"..pkg.version, root="."}
  pkg.sha1 = Git.hash(pkg.dir)

  --get specs and update them
  local specs = registry.table.packages[pkg.name]
  pkg.specpath = specs.path
  initpkgspecs(registry, pkg)

  --update registry remote git repository
  Cm.throw{cm="git add .", root=registry.path}
  Cm.throw{cm="git commit -m "..commitmessage, root=registry.path}
  Cm.throw{cm="git pull", root=registry.path}
  Cm.throw{cm="git push", root=registry.path}

  return pkg --return all updated pkg info
end

return Reg