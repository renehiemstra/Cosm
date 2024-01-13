local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Proj = require(pkgdir.."project")

function testIsProjTable()
  local table = require("Project")
  lu.assertTrue(Proj.isprojtable(table))
end

function testPkgCreate()
    Proj.create("MyPackage")
    lu.assertTrue(Proj.ispkg("MyPackage"))
    os.execute("rm -rf MyPackage")
    lu.assertFalse(Proj.ispkg("MyPackage"))
    lu.assertFalse(Proj.ispkg(Proj.terrahome.."/dev/"))
end

function testReadWriteProjfile()
  Proj.create("MyPackage")
  local table1 = require("MyPackage.Project")
  Proj.save(table1, "tmpProject.lua", "MyPackage")
  local table2 = require("MyPackage.tmpProject")

  lu.assertEquals(table1.name, "MyPackage")
  lu.assertEquals(table2.name, "MyPackage")
  lu.assertEquals(table1.uuid, table2.uuid)
  os.execute("rm -rf MyPackage")
end

function testPkgClone()
  local status, err = pcall(Proj.clone, {root="tmp", url="git@github.com:renehiemstra/Example.git"})
  lu.assertTrue(status)
  os.execute("rm -rf tmp")
end

-- lu.LuaUnit.run()