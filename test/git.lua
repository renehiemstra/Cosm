local lu = require("luaunit")
local Git = require "src.git"

function testNameFromGitUrl()
  lu.assertEquals("MyPackage", Git.namefromgiturl("git@gitlab.com:group/subgroup/MyPackage.git"))
  lu.assertEquals("MyPackage", Git.namefromgiturl("https://gitlab.com/group/subgroup/MyPackage.git"))
  lu.assertEquals("MyPackage", Git.namefromgiturl("https://github.com/group/subgroup/MyPackage.git"))
end

os.exit( lu.LuaUnit.run() )