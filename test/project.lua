lu = require("luaunit")
Proj = require "src.project"

function testIsProjTable()
  local table = require("Project")
  lu.assertTrue(Proj.isprojtable(table))
end

function testIsPkg()
    lu.assertTrue(Proj.ispkg(Proj.terrahome.."/dev/Pkg"))
    lu.assertFalse(Proj.ispkg(Proj.terrahome.."/dev/"))
end

function testPkgCreate()
    Proj.create("MyPackage")
    lu.assertTrue(Proj.ispkg("./MyPackage"))
    os.execute("rm -rf ./MyPackage")
end

function testReadWriteProjfile()
  local table1 = require("Project")
  Proj.save(table1, "tmpProject.lua", ".")
  local table2 = require("tmpProject")

  lu.assertEquals(table1.name, "Pkg")
  lu.assertEquals(table2.name, "Pkg")
  lu.assertEquals(table1.uuid, table2.uuid)
  os.execute("rm  tmpProject.lua")
end

function testPkgClone()
  local status, err = pcall(Proj.clone, {root="tmp", url="git@github.com:renehiemstra/Pkg.git"})
  lu.assertTrue(status)
  os.execute("rm -rf tmp")
end

os.exit( lu.LuaUnit.run() )