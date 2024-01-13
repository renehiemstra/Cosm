local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Cm = require(pkgdir.."command")

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
    lu.assertTrue(Cm.isfile(".gitignore"))
    lu.assertTrue(Cm.isfile("Project.lua"))
    lu.assertTrue(Cm.isfile("src/command.lua"))
    lu.assertFalse(Cm.isfile("src/invalid.lua"))
end

function testIsDir()
    lu.assertTrue(Cm.isdir("."))
    lu.assertTrue(Cm.isdir("src"))
    lu.assertTrue(Cm.isdir("test"))
    lu.assertFalse(Cm.isdir("invalid"))
end

function testWorkDir()
    local depotpath = Cm.capturestdout("echo $TERRA_PKG_ROOT")
    lu.assertEquals(Cm.currentworkdir(), depotpath.."/dev/Pkg")
    lu.assertEquals(Cm.namedir("."), "Pkg")
end

function testMkDir()
    Cm.mkdir("tmp")
    lu.assertTrue(Cm.isdir("tmp"))
    os.execute("rm -rf tmp")
end

lu.LuaUnit.run()