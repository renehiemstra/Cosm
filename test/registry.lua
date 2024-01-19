local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Cm = require(pkgdir.."command")
local Reg = require(pkgdir.."registry")

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

function testIsListed()
    local registry = "TestRegistryName"
    Reg.addtolist(registry)
    lu.assertTrue(Reg.islisted(registry))
    Reg.rmfromlist(registry)
    lu.assertFalse(Reg.islisted(registry))
end

lu.LuaUnit.run()