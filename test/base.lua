local lu = require "luaunit"

local Base = require("src.base")

function testHaskey()
    local table = {a = 1, b = "hi"}
    lu.assertTrue(Base.haskeyoftype(table, "b", "string"))
    lu.assertTrue(Base.haskeyoftype(table, "a", "number"))
    lu.assertFalse(Base.haskeyoftype(table, "c", "number"))
    lu.assertFalse(Base.haskeyoftype(table, "b", "number"))
end

function testGetSortedKeys()
    local table = {e = 5, c = 3, b = 2, d = 4, a = 1, f = 6}
    local sortedkeys = Base.getsortedkeys(table)
    lu.assertEquals(sortedkeys[1], "a")
    lu.assertEquals(sortedkeys[2], "b")
    lu.assertEquals(sortedkeys[3], "c")
    lu.assertEquals(sortedkeys[4], "d")
    lu.assertEquals(sortedkeys[5], "e")
    lu.assertEquals(sortedkeys[6], "f")
end


--lu.LuaUnit.run()