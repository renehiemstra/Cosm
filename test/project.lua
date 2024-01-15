local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Proj = require(pkgdir.."project")
local Cm = require(pkgdir.."command")

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

function testPkgCreateAndClone()
  Proj.create("PkgExample")
  Cm.throw{cm="gh repo create PkgExample --public"}
  Cm.throw{cm="git remote add origin git@github.com:renehiemstra/PkgExample.git", root="PkgExample"}
  Cm.throw{cm="git push --set-upstream origin main", root="PkgExample"}

  local status, err = pcall(Proj.clone, {root="tmp", url="git@github.com:renehiemstra/PkgExample.git"})
  lu.assertTrue(status)

  --cleanup
  Cm.throw{cm="gh repo delete PkgExample --yes", root="PkgExample"}
  Cm.throw{cm="rm -rf tmp"}
  Cm.throw{cm="rm -rf PkgExample"}
end

-- lu.LuaUnit.run()