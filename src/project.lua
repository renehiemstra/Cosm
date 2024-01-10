local Proj = {}
local Base = require "src.base"
local Cm = require "src.command"
local Git = require "src.git"

Proj.homedir = Cm.capturestdout("echo ~$user")
Proj.terrahome = Cm.capturestdout("echo $TERRA_PKG_ROOT")

--load a terra package
function Proj.require(package)
  return require(package..".src."..package)
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
    return false
  end
  if not Cm.isfile(root.."/Project.lua") then
    return false
  end
  local pkgname = Cm.namedir(root)
  local c2 = Cm.isfile(root.."/src/"..pkgname..".lua")
  local c3 = Cm.isfile(root.."/src/"..pkgname..".t")
  if not (c2 or c3) then
    return false
  end
  local table = dofile(root.."/Project.lua")
  return Proj.isprojtable(table)
end

--create a universal unique identifier (uuid)
local random = math.random
math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 9)))
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
  io.write("  ", "authors = {")
  for k,v in pairs(projtable.authors) do
      io.write(string.format("%q, ", v))
  end
  io.write("}, \n")
  --write version
  io.write(string.format("  version = %q,\n",projtable.version))
  --write dependencies
  io.write("  ", "deps = {\n")
  for k,v in pairs(projtable.deps) do
      io.write(string.format("    %q,\n", v))
  end
  io.write("  }\n")
  io.write("}\n")
  io.write("return Project")

  --close file
  io.close(file)
end

--clone a git-remote terra package. throw an error if input is invalid.
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
  os.execute("mkdir -p "..args.root..";"..
      "cd "..args.root..";"..
      "git clone "..args.url)

  --check that cloned repo satisfies basic package structure
  local pkgname = Git.namefromgiturl(args.url)          
  if not Proj.ispkg(args.root.."/"..pkgname) then
      --remove terra cloned repo 
      os.execute("cd "..args.root..";".."rm -rf "..pkgname)
      --throw error
      error("Cloned repository does not follow the specifications of a terra pkg.\n")
  end
end

--generate package folders
local function genpkgdirs(pkgname)
  Cm.mkdir(pkgname) --package root folder
  Cm.mkdir(pkgname.."/src") --package source folder
  Cm.mkdir(pkgname.."/.pkg") --package managing folder
end

--generate main source file
local function gensrcfile(pkgname)
  local file = io.open(pkgname.."/src/"..pkgname..".t", "w")                                       
  file:write("local Pkg = require(\"Pkg\")\n")
  file:write("local Example = Pkg.require(\"Example\")\n\n")
  file:write("local S = {}\n\n")
  file:write("Example.helloterra()\n\n")
  file:write("function S.helloterra()\n")
  file:write("  print(\"hello terra!\")\n")
  file:write("end\n\n")
  file:write("return S")
  file:close()
end

--generate Package.lua
local function genprojfile(pkgname)
  local file = io.open(pkgname.."/Project.lua", "w")
  file:write("Project = {\n")
  file:write("    name = \""..pkgname.."\",\n")
  file:write("    uuid = \""..Proj.uuid().."\",\n")
  file:write("    authors = {\""..Git.user.name.."<"..Git.user.email..">".."\"},\n")
  file:write("    version = \"".."0.1.0".."\",\n")
  file:write("    deps = {}\n")
  file:write("}\n")
  file:write("return Project")
  file:close()
end

--create a terra pkg template
function Proj.create(pkgname)
  genpkgdirs(pkgname)
  gensrcfile(pkgname)
  genprojfile(pkgname)
  Git.initrepo(pkgname)
end

return Proj