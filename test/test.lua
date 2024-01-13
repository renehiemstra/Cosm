local lu = require "luaunit"

local pkgdir = "dev.Pkg.test."

require(pkgdir.."semver")
require(pkgdir.."base")
require(pkgdir.."command")
require(pkgdir.."git")
require(pkgdir.."project")

lu.LuaUnit.run()