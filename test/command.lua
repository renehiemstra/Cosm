local lu = require "luaunit"
local Cm = require("src.command")

function testSuccess()
    os.execute("mkdir tmp; touch tmp/tmp.lua")
    lu.assertTrue(Cm.success{cm="test -f tmp/tmp.lua"})
    lu.assertTrue(Cm.success{cm="test -f tmp.lua", root="tmp"})
    lu.assertFalse(Cm.success{cm="test -f tmp/tmp.cpp"})
    os.execute("rm -rf tmp")
end

function testGetFileExtension()
    lu.assertEquals(Cm.getfileextension("hello.t"), "t")
    lu.assertEquals(Cm.getfileextension("Project.lua"), "lua")
end

function testIsFile()
    lu.assertTrue(Cm.isfile("../.gitignore"))
    lu.assertTrue(Cm.isfile("../README.md"))
    lu.assertTrue(Cm.isfile("../src/command.lua"))
    lu.assertFalse(Cm.isfile("../src/invalid.lua"))
end

function testIsDir()
    lu.assertTrue(Cm.isdir("."))
    lu.assertTrue(Cm.isdir("../src"))
    lu.assertTrue(Cm.isdir("../test"))
    lu.assertFalse(Cm.isdir("invalid"))
end

function testWorkDir()
    local home = Cm.capturestdout("echo $HOME")
    lu.assertEquals(Cm.currentworkdir(), home.."/dev/Cosm/test")
    lu.assertEquals(Cm.namedir("."), "test")
end

function testMkDir()
    Cm.mkdir("tmp")
    lu.assertTrue(Cm.isdir("tmp"))
    os.execute("rm -rf tmp")
end

-- lu.LuaUnit.run()