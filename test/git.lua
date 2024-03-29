local lu = require "luaunit"

local Git = require("src.git")
local Cm = require("src.command")

function testNameFromGitUrl()
  lu.assertEquals("MyPackage", Git.namefromgiturl("git@gitlab.com:group/subgroup/MyPackage.git"))
  lu.assertEquals("MyPackage", Git.namefromgiturl("https://gitlab.com/group/subgroup/MyPackage.git"))
  lu.assertEquals("MyPackage", Git.namefromgiturl("https://github.com/group/subgroup/MyPackage.git"))
  lu.assertEquals(Git.remotegeturl("~/dev/Cosm"), "git@github.com:renehiemstra/Cosm.git")
end

function testIsBareRepo()
  Cm.throw{cm="mkdir mybarerepo"}
  Cm.throw{cm="mkdir someotherrepo"}
  Cm.throw{cm="git init --bare", root="mybarerepo"}
  lu.assertTrue(Git.isbarerepo("mybarerepo"))
  lu.assertFalse(Git.isbarerepo("someotherrepo"))
  Cm.throw{cm="rm -rf mybarerepo someotherrepo"}
end

function testValidGitRepo()

  lu.assertTrue(Git.isgiturl("git@github.com:terralang/terra.git"))
  lu.assertFalse(Git.isgiturl("git@github.com:terralang/terra.gi"))
  lu.assertFalse(Git.isgiturl(1))
  lu.assertFalse(Git.isgiturl("a"))

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

  local first = Cm.capturestdout("head -1 tmp/.gitignore") --capture first line of file
  lu.assertEquals(first, ".DS_Store")
  
  local second = Cm.capturestdout("cat tmp/.gitignore | head -2 | tail -1") --capture second line of file
  lu.assertEquals(second, ".vscode")

  local third = Cm.capturestdout("cat tmp/.gitignore | head -3 | tail -1") --capture second line of file
  lu.assertEquals(third, "*.paint")

  Cm.rmdir("tmp") --cleanup
end

function testIsTagged()
  Cm.mkdir("tmp")
  Cm.throw{cm="git init", root="tmp"}
  Cm.throw{cm="touch README.md; echo \"my new project\" >> README.md", root="tmp"}
  Cm.throw{cm="git add .; git commit -m \"added readme\"", root="tmp"}
  lu.assertFalse(Git.istagged("tmp", "v0.1.0"))
  Cm.throw{cm="git tag v0.1.0", root="tmp"}
  lu.assertTrue(Git.istagged("tmp", "v0.1.0"))

  Cm.rmdir("tmp") --cleanup
end

lu.LuaUnit.run()