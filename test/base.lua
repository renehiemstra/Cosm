local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Base = require(pkgdir.."base")

function testHaskey()
    local table = {a = 1, b = "hi"}
    lu.assertTrue(Base.haskeyoftype(table, "b", "string"))
    lu.assertTrue(Base.haskeyoftype(table, "a", "number"))
    lu.assertFalse(Base.haskeyoftype(table, "c", "number"))
    lu.assertFalse(Base.haskeyoftype(table, "b", "number"))
end

-- lu.LuaUnit.run()