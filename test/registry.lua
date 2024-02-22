local lu = require "luaunit"

local Cm = require("src.command")
local Reg = require("src.registry")

--load convenience functions for testing
local Conv = require("test.conv")

function testLoadRegistries()
    local registries = {"R1", "R2", "R3"}
    Reg.saveregistries(registries, "tmpList.jl")
    local regtmp = Reg.loadregistries("tmpList.jl")
    lu.assertEquals(registries[1], regtmp[1])
    lu.assertEquals(registries[2], regtmp[2])
    lu.assertEquals(registries[3], regtmp[3])
    Cm.throw{cm="rm tmpList.jl", root=Reg.regdir}
end

function testSaveRegistry()
    Conv.create_reg("ExampleRegistry")

    local table1 = require("registries.ExampleRegistry.Registry")
    print(table1)
    Reg.save(table1, "tmpRegistry.lua", ".")
    local table2 = require("tmpRegistry")

    lu.assertTrue(table1.name == "ExampleRegistry" and table2.name=="ExampleRegistry")
    lu.assertEquals(table1.uuid, table2.uuid)
    os.execute("rm tmpRegistry.lua")

    lu.assertTrue(Reg.isreg("ExampleRegistry"))
    lu.assertFalse(Reg.isreg("RegistryDoesntExist"))

    --cleanup registry
    Conv.delete_reg("ExampleRegistry")
end

function testIsListed()
    local registry = "TestRegistryName"
    Reg.addtolist(registry)
    lu.assertTrue(Reg.islisted(registry))
    Reg.rmfromlist(registry)
    lu.assertFalse(Reg.islisted(registry))
end

function testIsRemoved()
    lu.assertFalse(Reg.isreg("ExampleRegistry"))
    lu.assertFalse(Reg.islisted("ExampleRegistry"))
end

-- lu.LuaUnit.run()