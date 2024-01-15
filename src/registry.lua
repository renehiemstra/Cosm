local pkgdir = "dev.Pkg.src."
local Base = require(pkgdir.."base")
local Cm   = require(pkgdir.."command")
local Git  = require(pkgdir.."git")
local Proj = require(pkgdir.."project")
local Semver  = require(pkgdir.."semver")

local Reg = {}

--terra directories
Reg.regdir = Proj.terrahome.."/registries"

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
function Reg.isreg(name)
  if not type(name)=="string" then
    error("Provide a string as input.")
  end
  local root = Reg.regdir.."/"..name
  if not Cm.isdir(root) then
    return false
  end
  if not Cm.isfile(root.."/Registry.lua") then
    return false
  end
  local table = dofile(Reg.regdir.."/"..name.."/Registry.lua")
  return Reg.isregtable(table)
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

  --Throw an error if url is not valid
  if not Git.validemptygitrepo(registry.url) then
    error("Provide an empty git repository.\n")
  end

  --path to registry root
  local root = Reg.regdir.."/"..registry.name

  --generate registry folder
  Cm.throw{cm="mkdir -p "..root}

  --generate .ignore file
  Git.ignore(root, {".DS_Store", ".vscode"})

  --generate Registry.toml
  local file = io.open(root.."/Registry.lua", "w")
  file:write("Registry = {\n")
  file:write("    name = \""..registry.name.."\",\n")
  file:write("    uuid = \""..Proj.uuid().."\",\n")
  file:write("    url  = \""..registry.url.."\",\n")
  file:write("    description = \""..registry.name.." local package registry\",\n")
  file:write("    packages = {}\n")
  file:write("}\n")
  file:write("return Registry")
  file:close()

  --create git repo and push to origin
  Cm.throw{cm="git init", root=root}
  Cm.throw{cm="git add .", root=root}
  Cm.throw{cm="git commit -m \"Initialized new registry.\"", root=root}
  Cm.throw{cm="git remote add origin "..registry.url, root=root}
  Cm.throw{cm="git push --set-upstream origin main", root=root}
end

--initiates package specifics - assumes that input is already checked
local function initpkgspecs(reg, pkg)

  --create  .terra/registries/${reg}/${specpath}/Project.t 
  local root = reg.path.."/"..pkg.specpath.."/"..pkg.table.version
  local filename = "Specs.lua" --the version name is the main filename specifier
  Cm.throw{cm="mkdir -p "..root}
  Cm.throw{cm="touch "..root.."/"..filename}
  
  --write Project.t
  local file = io.open(root.."/"..filename, "w")
  io.output(file)

  --write main project data to file
  io.write("Project = {\n")
  io.write(string.format("    name = %q,\n", pkg.table.name))
  io.write(string.format("    uuid = %q,\n", pkg.table.uuid))
  io.write(string.format("    version = %q,\n", pkg.table.version))
  io.write(string.format("    url  = %q,\n", pkg.url))
  io.write(string.format("    sha1 = %q,\n", pkg.sha1))
  --write dependencies
  io.write("    deps = ")
  Base.serialize(pkg.table.deps, 2)
  io.write("}\n")
  io.write("return Project")
  io.close(file)
end

--register a package to a registry
function Reg.register(args)
  --check keyword arguments
  if args.reg==nil then
    error("Provide `reg` (registry) name.\n")
  elseif args.url==nil then
    error("Provide package `url`.\n")
  end
  if type(args.reg)~="string" then
    error("Provide `reg` (registry) name as a string.\n")
  elseif type(args.url)~="string" then
    error("Provide package git `url` as a string")
  end
  --check if registry name points to a valid registry
  if not Reg.isreg(args.reg) then
    error("Directory does not follow registry specifications.\n")
  end
  --download pkg associated with git url (error checking is done therein)
  Proj.clone{root=Proj.terrahome.."/".."packages", url=args.url}

  --initialize registry properties
  local registry = {}
  registry.name = args.reg
  registry.path = Reg.regdir.."/"..registry.name
  registry.table = dofile(registry.path.."/Registry.lua")

  --initialize package properties
  local pkg = {}
  pkg.dir = Proj.terrahome.."/".."packages".."/"..Git.namefromgiturl(args.url)
  pkg.table = dofile(pkg.dir.."/".."Project.lua")
  pkg.name = pkg.table.name
  pkg.url = args.url
  pkg.specpath = string.sub(pkg.name, 1, 1).."/"..pkg.name --P/Pkg
  pkg.sha1 = Git.treehash(pkg.dir)

  --update registry pkg list and save
  registry.table.packages[pkg.table.name] = { uuid = pkg.table.uuid, path = pkg.specpath}        
  Reg.save(registry.table, "Registry.lua", registry.path)

  --create pkg specs-list
  initpkgspecs(registry, pkg)

  --update registry remote git repository
  local commitmessage = "\"<new package> "..pkg.name.."\""
  Cm.throw{cm="git add .", root=registry.path}
  Cm.throw{cm="git commit -m "..commitmessage, root=registry.path}
  Cm.throw{cm="git pull", root=registry.path}
  Cm.throw{cm="git push --set-upstream origin main", root=registry.path}
end

function Reg.release(args)
  --check keyword argument `release`
  local v = args.release
  if not ((v=="patch") or (v=="minor") or (v=="major")) then
    error("Provide `release` equal to \"patch\", \"minor\", or \"major\".\n\n")
  end
  --check keyword argument `reg`
  if type(args.reg)~="string" then
    error("Provide `reg` (registry) name as a string.\n\n")
  end
  --check if registry name points to a valid registry
  if not Reg.isreg(args.reg) then
    error("Directory does not follow registry specifications.\n")
  end
  --check of current directory is a valid package
  if not Proj.ispkg(".") then
    error("Current directory does not follow the specifications of a terra pkg.\n")
  end

  --initialize registry properties
  local registry = {}
  registry.name = args.reg
  registry.path = Reg.regdir.."/"..registry.name
  registry.table = dofile(registry.path.."/Registry.lua")

  --initialize package properties
  local pkg = {}
  pkg.table = dofile("Project.lua")
  pkg.name = pkg.table.name
  pkg.url = args.url
  pkg.specpath = string.sub(pkg.name, 1, 1).."/"..pkg.name --P/Pkg
  pkg.sha1 = Git.treehash(pkg.dir)

  --throw error if package is not registered.
  if registry.table.packages[pkg.name] == nil then
    error("Package "..pkg.name.." is not a registered in "..registry.name..".\n\n")
  end

  --increase package version
  local version = Semver.parse(pkg.table.version)
  if args.release=="patch" then
    version:nextPatch()
  elseif args.release=="minor" then
    version:nextMinor()
  elseif args.release=="major" then
    version:nextMajor()
  end
  pkg.table.version = tostring(version)

  --create pkg specs-list
  initpkgspecs(registry, pkg)

  --update registry remote git repository
  local commitmessage = "\"<release> "..pkg.name.."..v"..pkg.table.version.."\""
  Cm.throw{cm="git add .", root=registry.path}
  Cm.throw{cm="git commit -m "..commitmessage, root=registry.path}
  Cm.throw{cm="git pull", root=registry.path}
  Cm.throw{cm="git push --set-upstream origin main", root=registry.path}
end

return Reg