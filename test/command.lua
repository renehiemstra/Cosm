local lu = require "luaunit"
local Cm = require "src.command"

function testGetFileExtension()
    lu.assertEquals(Cm.getfileextension("hello.t"), "t")
    lu.assertEquals(Cm.getfileextension("Project.lua"), "lua")
end

function testIsFile()
    lu.assertTrue(Cm.isfile(".gitignore"))
    lu.assertTrue(Cm.isfile("Project.lua"))
    lu.assertTrue(Cm.isfile("src/command.lua"))
    lu.assertFalse(Cm.isfile("src/invalid.lua"))
end

function testIsFolder()
    lu.assertTrue(Cm.isfolder("."))
    lu.assertTrue(Cm.isfolder("src"))
    lu.assertTrue(Cm.isfolder("test"))
    lu.assertFalse(Cm.isfolder("invalid"))
end
-- lu.LuaUnit.run()