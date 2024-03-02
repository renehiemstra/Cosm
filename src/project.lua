local Base = require("src.base")
local Cm = require("src.command")
local Git = require("src.git")
local Lang = require("src.langext")

local Proj = {}

Proj.homedir = Cm.capturestdout("echo ~$user")
Proj.terrahome = os.getenv("COSM_DEPOT_PATH")

--load a terra package
function Proj.require(depname)
  --determine file where the function call emenates from
  local callfile = debug.getinfo(2, "S").source:sub(2)
  --determine the folder of this file
  local calldir = callfile:match("(.*/)")
  --special case where the call emenates from same dir as lua file
  if calldir==nil then
    calldir = "."
  end
  --check if root is an actual pkg
  if not Proj.ispkg(calldir.."/..") then
    error("Error: Directory does not satisfy the requirements of a package.\n\n")
  end
  -- load package table
  local pkg = {}
  pkg.table = dofile(calldir.."/../Project.lua")
  local dep = {}
  --check if dep is listed as such in the Project.lua file
  dep.name = depname
  dep.version = pkg.table.deps[dep.name]
  if dep.version==nil then
    error("Error: package "..dep.name.." is not listed as a dependency in Project.lua.\n\n")
  end
  local found = false
  for _,path in pairs{"dev", "packages"} do --directories in .terra to look for package
    if Proj.ispkg(Proj.terrahome.."/"..path.."/"..dep.name) then
      found = true
      dep.req = path.."."..dep.name..".src."..dep.name
      break
    end
  end
  if not found then
    error("Error: package dependency "..dep.name.." could not be located. Please register it to a package registry. \n\n")
  end
  --load dependency
  return require(dep.req)
end

--check if table is a valid project table
function Proj.isprojtable(table)
  for k,v in ipairs{name="string", uuid="string", authors="string", version="string", deps="table"} do
    if not Base.haskeyoftype(table, k, v) then
      return false
    end
  end
  return true
end

--check if the folder at `root` is a valid package
function Proj.ispkg(root)
  if not type(root)=="string" then
    error("Provide a string as input.")
  end
  if not Cm.isdir(root) then
    print("not a directory")
    return false
  end
  if not Cm.isfile(root.."/Project.lua") then
    print("not a project file")
    return false
  end
  local pkg = dofile(root.."/Project.lua")
  local c2 = Cm.isfile(root.."/src/"..pkg.name..".lua")
  local c3 = Cm.isfile(root.."/src/"..pkg.name..".t")
  if not (c2 or c3) then
    print("not a lua or terra file")
    return false
  end
  return Proj.isprojtable(table)
end

local random = math.random
math.randomseed()

function Proj.uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c) 
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

--save `projtable` to a Project.lua file
function Proj.save(projtable, projfile, root)
  if not type(projtable) == "table" then
    error("Not a table.\n")
  end
  if not Proj.ispkg(root) then
    error("Not a valid project specification.\n")
  end

  --open Project.t and set to stdout
  local file = io.open(root.."/"..projfile, "w")
  io.output(file)

  --write main project data to file
  io.write("Project = {\n")
  io.write(string.format("  name = %q,\n",projtable.name))
  io.write(string.format("  uuid = %q,\n",projtable.uuid))
  -- write author list
  io.write("  authors = {")
  for _,v in ipairs(projtable.authors) do
      io.write(string.format("%q, ", v))
  end
  io.write("}, \n")
  --write version
  io.write(string.format("  version = %q,\n",projtable.version))
  --write dependencies
  io.write("  deps = ")
  Base.serialize(projtable.deps, 2)
  io.write("}\n")
  io.write("return Project")

  --close file
  io.close(file)
end

--clone a git-remote terra package. throw an error if input is invalid.
--signature: {name=..., url=..., root=...}
function Proj.clone(args)
  --check keyword arguments
  if args.root==nil or args.url==nil then
    error("Provide `root` and git `url`.\n")
  end
  if type(args.root)~="string" then
      error("Provide `root` folder as a string.\n")
  elseif type(args.url)~="string" then
      error("Provide git `url` as a string.\n")
  end

  --throw an error if repo is not valid
  if not Git.validnonemptygitrepo(args.url) then
      error("Provide a non-empty git repository.\n")
  end
  --clone remote repo
  Cm.throw{cm="mkdir -p "..args.root}
  Cm.throw{cm="git clone "..args.url.." "..args.name, root=args.root}

  --check that cloned repo satisfies basic package structure
  if not Proj.ispkg(args.root.."/"..args.name) then
      --remove terra cloned repo 
      Cm.throw{cm="rm -rf "..args.name, root=args.root}
      --throw error
      error("Cloned repository does not follow the specifications of a terra pkg.\n")
  end
end

--generate Package.lua
local function genprojfile(pkgname, root)
  local pkguuid = Proj.uuid()
  local file = io.open(root.."/"..pkgname.."/Project.lua", "w")
  file:write("Project = {\n")
  file:write("    name = \""..pkgname.."\",\n")
  file:write("    uuid = \""..pkguuid.."\",\n")
  file:write("    authors = {\""..Git.user.name.."<"..Git.user.email..">".."\"},\n")
  file:write("    version = \"".."0.1.0".."\",\n")
  file:write("    deps = {}\n")
  file:write("}\n")
  file:write("return Project")
  file:close()
end

--create a terra pkg template
function Proj.create(template, pkgname, root)
  --create a project from a template
  Lang.project_from_template(template, pkgname, root)
  --crete Project.lua file
  genprojfile(pkgname, root)
  --initialize a git version control and commit initial project
  local commitmessage = "\"<new package> "..pkgname.."\""
  Cm.throw{cm="git init", root=root.."/"..pkgname}
  Cm.throw{cm="git add .", root=root.."/"..pkgname}
  Cm.throw{cm="git commit -m "..commitmessage, root=root.."/"..pkgname}
end


return Proj