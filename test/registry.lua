local lu = require "luaunit"
local Reg = require "src.registry"
local Proj = require "src.project"

function testSaveRegistry()

    local table1 = require "registries.MyRegistry.Registry"
    Reg.save(table1, "tmpRegistry.lua", ".")
    local table2 = require "tmpRegistry"

    lu.assertTrue(table1.name == "MyRegistry" and table2.name=="MyRegistry")
    lu.assertEquals(table1.uuid, table2.uuid)
    os.execute("rm tmpRegistry.lua")
end

function testIsRegistry()
    lu.assertTrue(Reg.isreg("MyRegistry"))
    lu.assertFalse(Reg.isreg("RegistryDoesntExist"))
end

lu.LuaUnit.run()