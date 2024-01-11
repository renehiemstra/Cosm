local Base = require "src.base"
local Cm   = require "src.command"
local Git  = require "src.git"
local Proj = require "src.project"

local Reg = {}

--terra directories
local terradir = Cm.capturestdout("echo $TERRA_PKG_ROOT")
local regdir = terradir.."/registries"

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
  local root = regdir.."/"..name
  if not Cm.isdir(root) then
    return false
  end
  if not Cm.isfile(root.."/Registry.lua") then
    return false
  end
  local table = dofile(regdir.."/"..name.."/Registry.lua")
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
  local root = regdir.."/"..registry.name

  --generate registry folder 
  os.execute("mkdir "..root)

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
  Git.initrepo(root)
  Git.addremote(root, registry.url)
end

--initiates package specifics - assumes that input is already checked
local function initpkgspecs(reg, pkg)

  --create  .terra/registries/${reg}/${specpath}/Project.t 
  local root = reg.path.."/"..pkg.specpath
  local filename = pkg.table.version..".lua" --the version name is the main filename specifier
  os.execute( "mkdir -p "..root..";"..
              "cd "..root..";"..
              "touch "..filename)

  --write Project.t
  local file = io.open(root.."/"..filename, "w")
  io.output(file)

  --write main project data to file
  io.write("Project = {\n")
  io.write(string.format("    name = %q,\n", pkg.table.name))
  io.write(string.format("    uuid = %q,\n", pkg.table.uuid))
  io.write(string.format("    version = %q,\n", pkg.table.version))
  io.write(string.format("    url  = %q,\n", "not implemented"))
  io.write(string.format("    [\"git-tree-sha1\"] = %q,\n", "not implemented"))
  io.write(string.format("    deps = %q,\n", "not implemented"))
  io.write("}\n")
  io.write("return Project")
  io.close(file)
end

--register a package to a registry
function Reg.register(regname)
  --check keyword arguments
  if regname==nil then
    error("Provide registry name.\n")
  end
  if type(regname)~="string" then
    error("Provide registry name as string.\n")
  end
  --check if current folder is a valid package
  if not Proj.ispkg(".") then
    error("Current folder does not follow package specifications.\n")
  end
  --check if registry name points to a valid registry
  if not Reg.isreg(regname) then
    error("Directory does not follow registry specifications.\n")
  end

  --initialize registry properties
  local registry = {}
  registry.name = regname
  registry.path = regdir.."/"..regname
  registry.table = dofile(registry.path.."/Registry.lua")

  --initialize package properties
  local pkg = {}
  pkg.name = Cm.namedir(".")
  pkg.path = Cm.currentworkdir()
  pkg.specpath = string.sub(pkg.name, 1, 1).."/"..pkg.name --P/Pkg
  pkg.table = dofile("Project.lua")

  --update registry pkg list and save
  registry.table.packages[pkg.table.name] = { uuid = pkg.table.uuid, path = pkg.specpath}        
  Reg.save(registry.table, "Registry.lua", registry.path)

  --create pkg specs-list
  initpkgspecs(registry, pkg)
end

return Reg