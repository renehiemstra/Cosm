local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Proj = require(pkgdir.."project")

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

-- lu.LuaUnit.run()