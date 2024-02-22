local lu = require "luaunit"

require("test.semver")
require("test.base")
require("test.command")
require("test.git")
require("test.project")
require("test.registry")
-- require("test.integration")

os.exit(lu.LuaUnit.run())