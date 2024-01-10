lu = require("luaunit")
Base = require "src.base"

function testHaskey()
    local table = {a = 1, b = "hi"}
    lu.assertTrue(Base.haskeyoftype(table, "b", "string"))
    lu.assertTrue(Base.haskeyoftype(table, "a", "number"))
    lu.assertFalse(Base.haskeyoftype(table, "c", "number"))
    lu.assertFalse(Base.haskeyoftype(table, "b", "number"))
end

os.exit( lu.LuaUnit.run() )