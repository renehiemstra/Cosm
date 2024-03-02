local lu = require "luaunit"

local Cm = require("src.command")
local Lang = require("src.langext")

function testPkgTemplate()
    Lang.project_from_template("lua","PkgTemplate", "Example", ".")
end

lu.LuaUnit.run()
