local lu = require "luaunit"

local Semver = require("src.semver")

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

function testUpgradeCompatibility()
    --major version 0
    lu.assertTrue(Semver'0.1.1' ^ Semver'0.1.9')
    lu.assertFalse(Semver'0.1.1' ^ Semver'0.2.0')
    lu.assertFalse(Semver'0.1.1' ^ Semver'1.0.0')
    --major version > 0
    lu.assertTrue(Semver'2.11.3' ^ Semver'2.12.2')
    lu.assertFalse(Semver'2.11.3' ^ Semver'3.0.0')
end

function testUpgradeToLatestCompatible()
    local versions = {"0.1.19","0.1.1","0.1.0","0.1.4","0.2.1", "0.2.5", "1.2.3"}
    lu.assertEquals(Semver.latestCompatible(versions, "0.1.3"), "0.1.19")
    lu.assertEquals(Semver.latestCompatible(versions, "0.2.0"), "0.2.5")
    lu.assertEquals(Semver.latestCompatible(versions, "1.0.0"), "1.2.3")
end

function testUpgradeToLatestConstrained()
    local versions = {"0.1.19","0.1.1","0.1.0","0.1.4","0.2.1", "0.2.5", "1.2.3"}
    lu.assertEquals(Semver.latestConstrained(versions, "0"), "0.2.5")
    lu.assertEquals(Semver.latestConstrained(versions, "1"), "1.2.3")
    lu.assertEquals(Semver.latestConstrained(versions, "0.1"), "0.1.19")
    lu.assertEquals(Semver.latestConstrained(versions, "1.2"), "1.2.3")
    lu.assertEquals(Semver.latestConstrained(versions, "0.2.1"), "0.2.1")
end

lu.LuaUnit.run()