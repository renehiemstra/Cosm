local Base = require("src.base")
local Cm = require("src.command")
local Git = require("src.git")
local Lang = require("src.langext")
local Semver = require("src.semver")

local Proj = {}

Proj.homedir = Cm.capturestdout("echo ~$user")
Proj.terrahome = os.getenv("COSM_DEPOT_PATH")

local function packageid(pkgname, version)
  --create package id - 
  local v = Semver.parse(version)
  --for stable releases (v.major>0) every major release is considered
  --as a different package
  return pkgname.."@v"..v.major
end

function Proj.init()
  --parent project directory
  local parentprojectfile = arg[0]
  local parentprojectdir = parentprojectfile:match("(.*)/")
  local cosm = parentprojectdir.."/../.cosm/"
  --load buildlist
  local buildlist = dofile(cosm.."/buildlist.lua")
  --add to path variable
  for id, specs in pairs(buildlist) do
    package.path = package.path .. "; "..Proj.terrahome.."/"..specs.path.."/src/?.lua"
  end
end

--load a lua/terra package
function Proj.require(depname)
  --parent project directory
  local parentprojectfile = arg[0]
  local parentprojectdir = parentprojectfile:match("(.*)/")
  local cosm = parentprojectdir.."/../.cosm/"
  --load buildlist
  local buildlist = dofile(cosm.."/buildlist.lua")
  --determine file where the function call emenates from
  local callfile = debug.getinfo(2, "S").source:sub(2)
  --determine the folder of this file
  local calldir = callfile:match("(.*/)")
  --special case where the call emenates from same dir as lua file
  if calldir==nil then
    calldir = "."
  end
  --check if current directory is an actual pkg
  if not Proj.ispkg(calldir.."/..") then
    print("Error: Directory does not satisfy the requirements of a package.")
    os.exit(1)
  end
  -- load package table
  local pkg = dofile(calldir.."/../Project.lua")
  local dep = {}
  --check if dep is listed as such in the Project.lua file
  dep.name = depname
  dep.version = pkg.deps[dep.name]
  if dep.version==nil then
    print("Error: package "..dep.name.." is not listed as a dependency in Project.lua.")
    os.exit(1)
  end
  local id = packageid(dep.name, dep.version)
  local specs = buildlist[id]
  if specs==nil then
    print("Error: package"..dep.name.." version "..dep.version.." is not listed in the buildlist. Please regenerate buildlist.")
    os.exit(1)
  end
  --add to path variable
  package.path = package.path .. "; "..Proj.terrahome.."/"..specs.path.."/src/?.lua"
  Base.serialize(package.path, 1)
  --load dependency
  return require("src."..depname)
end

--check if table is a valid project table
function Proj.isprojtable(table)
  for k,v in ipairs{name="string", uuid="string", authors="string", language="string", version="string", deps="table"} do
    if not Base.haskeyoftype(table, k, v) then
      return false
    end
  end
  return true
end

--check if the folder at `root` is a valid package
function Proj.ispkg(root, pkg)
  if not Cm.isdir(root) then
    print("Not a valid directory.")
    return false
  end
  if not Cm.isfile(root.."/Project.lua") then
    print("Not a project file")
    return false
  end
  local table = dofile(root.."/Project.lua")
  if Proj.isprojtable(table) then
    if type(pkg)=="table" then
      pkg.table = table
    end
    return true
  else
    return false
  end
end

-- math.randomseed(1)
function Proj.uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c) 
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--save `projtable` to a Project.lua file
function Proj.save(projtable, projfile, root)
  if not type(projtable) == "table" then
    error("Not a table.\n")
  end
  --open Project.t and set to stdout
  local oldout = io.output()
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
  --write language
  io.write(string.format("  language = %q,\n",projtable.language))
  --write version
  io.write(string.format("  version = %q,\n",projtable.version))
  --write dependencies
  io.write("  deps = ")
  Base.serialize(projtable.deps, 2)
  io.write("}\n")
  io.write("return Project")
  --close file
  io.close(file)
  io.output(oldout)
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
local function genprojfile(pkgname, pkglang, root)
  local pkguuid = Proj.uuid()
  local oldout = io.output() 
  local file = io.open(root.."/Project.lua", "w")
  io.output(file)
  io.write("Project = {\n")
  io.write("    name = \""..pkgname.."\",\n")
  io.write("    uuid = \""..pkguuid.."\",\n")
  io.write("    authors = {\""..Git.user.name.."<"..Git.user.email..">".."\"},\n")
  io.write("    language = \""..pkglang.."\",\n")
  io.write("    version = \"".."0.0.0".."\",\n")
  io.write("    deps = {}\n")
  io.write("}\n")
  io.write("return Project")
  io.close(file)
  io.output(oldout)
end

--create a terra pkg template
function Proj.create(pkgname, pkglang, root)
  --crete Project.lua file
  genprojfile(pkgname, pkglang, root)
end

--create a terra pkg template
function Proj.createfromtemplate(templatedir, pkgname, root)
  local pkglang = Cm.parentdirname(templatedir)
  --create a project from a template
  Lang.project_from_template(templatedir, pkgname, root)
  --crete Project.lua file
  genprojfile(pkgname, pkglang, root.."/"..pkgname)
  --initialize a git version control and commit initial project
  local commitmessage = "\"<new "..pkglang.." package> "..pkgname.."\""
  Cm.throw{cm="git init", root=root.."/"..pkgname}
  Cm.throw{cm="git add .", root=root.."/"..pkgname}
  Cm.throw{cm="git commit -m "..commitmessage, root=root.."/"..pkgname}
end

return Proj