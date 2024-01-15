local lu = require "luaunit"

local pkgdir = "dev.Pkg.src."
local Git = require(pkgdir.."git")
local Cm = require(pkgdir.."command")

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

function testIgnoreFile()

  Cm.mkdir("tmp") --make a temporary directory
  Git.ignore("tmp", {".DS_Store", ".vscode", "*.paint"})

  local first = Cm.capturestdout("head -1 tmp/.ignore") --capture first line of file
  lu.assertEquals(first, ".DS_Store")
  
  local second = Cm.capturestdout("cat tmp/.ignore | head -2 | tail -1") --capture second line of file
  lu.assertEquals(second, ".vscode")

  local third = Cm.capturestdout("cat tmp/.ignore | head -3 | tail -1") --capture second line of file
  lu.assertEquals(third, "*.paint")

  Cm.rmdir("tmp") --cleanup
end

function testRepoUpToDate()

  Cm.capturestdout("")

end

-- lu.LuaUnit.run()