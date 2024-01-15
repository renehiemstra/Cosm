local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Proj = require(pkgdir.."project")
local Cm = require(pkgdir.."command")

function testIsProjTable()
  local table = require("Project")
  lu.assertTrue(Proj.isprojtable(table))
end

function testPkgCreate()
    Proj.create("MyPackage", "tmp")
    lu.assertTrue(Proj.ispkg("tmp/MyPackage"))
    os.execute("rm -rf tmp")
    lu.assertFalse(Proj.ispkg("tmp/MyPackage"))
    lu.assertFalse(Proj.ispkg(Proj.terrahome.."/dev/"))
end

function testReadWriteProjfile()
  Proj.create("MyPackage", "tmp")
  local table1 = require("tmp.MyPackage.Project")
  Proj.save(table1, "tmpProject.lua", "tmp/MyPackage")
  local table2 = require("tmp.MyPackage.tmpProject")

  lu.assertEquals(table1.name, "MyPackage")
  lu.assertEquals(table2.name, "MyPackage")
  lu.assertEquals(table1.uuid, table2.uuid)
  os.execute("rm -rf tmp")
end

local function create_pkg(pkgname, path)
  local root = path.."/"..pkgname
  Proj.create(pkgname, path)
  Cm.throw{cm="gh repo create "..pkgname.." --public"}
  Cm.throw{cm="git remote add origin git@github.com:renehiemstra/"..pkgname..".git", root=root}
  Cm.throw{cm="git push --set-upstream origin main", root=root}
end

local function delete_pkg(pkgname, path)
  local root = path.."/"..pkgname
  Cm.throw{cm="gh repo delete "..pkgname.." --yes"}
  Cm.throw{cm="rm -rf "..path}
end

function testPkgCreateAndClone()
  create_pkg("ExamplePkg", "tmp1")
  local status, err = pcall(Proj.clone, {root="tmp2", url="git@github.com:renehiemstra/ExamplePkg.git"})
  lu.assertTrue(status)
  Cm.throw{cm="rm -rf tmp2"}
  delete_pkg("ExamplePkg", "tmp1")
end

-- lu.LuaUnit.run()