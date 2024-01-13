local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Semver = require(pkgdir.."semver")

function testParse()
    local version = Semver.parse("2.11.3")
    lu.assertEquals(version.patch, 3)
    lu.assertEquals(version.minor, 11)
    lu.assertEquals(version.major, 2)
end

function testToString()
    local version = Semver(2,11,3)
    lu.assertEquals(version, Semver.parse(tostring(version)))
end

lu.LuaUnit.run()