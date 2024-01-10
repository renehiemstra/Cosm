local lu = require "luaunit"
local Git = require "src.git"

function testNameFromGitUrl()
  lu.assertEquals("MyPackage", Git.namefromgiturl("git@gitlab.com:group/subgroup/MyPackage.git"))
  lu.assertEquals("MyPackage", Git.namefromgiturl("https://gitlab.com/group/subgroup/MyPackage.git"))
  lu.assertEquals("MyPackage", Git.namefromgiturl("https://github.com/group/subgroup/MyPackage.git"))
end

function testValidGitRepo()

  lu.assertTrue(Git.validgitrepo("git@github.com:terralang/terra.git"))
  lu.assertFalse(Git.validgitrepo("git@github.com:terralang/terra.gi"))    

  lu.assertTrue(Git.validemptygitrepo("git@github.com:renehiemstra/EmptyTestRepo.git"))
  lu.assertFalse(Git.validemptygitrepo("git@github.com:renehiemstra/EmptyTestRepo.gi"))
  lu.assertFalse(Git.validemptygitrepo("git@github.com:terralang/terra.git"))

  lu.assertTrue(Git.validnonemptygitrepo("git@github.com:terralang/terra.git"))
  lu.assertFalse(Git.validnonemptygitrepo("git@github.com:terralang/terra.gi"))
  lu.assertFalse(Git.validnonemptygitrepo("git@github.com:renehiemstra/EmptyTestRepo.git"))
end
-- lu.LuaUnit.run()