local pkgdir = "dev.Pkg.src."
local Cm = require(pkgdir.."command")
local Base = require(pkgdir.."base")

local Git = {}
Git.user = {}
Git.user.name = Cm.capturestdout("git config user.name")
Git.user.email = Cm.capturestdout("git config user.email")

function Git.giturlexitcode(url)
    return Cm.capturestdout("git ls-remote --exit-code "..url.." &> /dev/null; echo $?")
end

function Git.validemptygitrepo(url)
    local exitcode = Git.giturlexitcode(url)
    return exitcode=="2"
end

function Git.validnonemptygitrepo(url)
    local exitcode = Git.giturlexitcode(url)
    return exitcode=="0"
end

--check if the git-url points to a valid repository
function Git.validgitrepo(url)
    local exitcode = Git.giturlexitcode(url)
    return exitcode=="0" or exitcode=="2"
end

--extract the pkg name from the git url
function Git.namefromgiturl(url)
    return string.sub(Cm.capturestdout("echo $(basename "..Base.esc(url)..")"), 1, -5)
end

--initialize git repository
function Git.initrepo(root)
    os.execute("cd "..root..";".. 
        "git init"..";"..          
        "git add ."..";"..         
        "git commit -m \"First commit\"")
end

--add origin and push
function Git.addremote(root, url)
    if not Git.validemptygitrepo(url) then
        error("Not a valid empty remote repository.")
    end
    os.execute(
        "cd "..root.."; "..
        "git remote add origin "..url..";"..
        "git push -u origin main")
end

function Git.add(root, options)
    os.execute(
        "cd "..root.."; "..
        "git add "..options)
end

function Git.commit(root, message)
    os.execute(
        "cd "..root.."; "..
        "git commit -m ".."\""..message.."\"")
end

function Git.tag(root, version, message)
    os.execute(
        "cd "..root.."; "..
        "git tag -a "..Base.esc(version).." -m "..Base.esc(message))
end

function Git.push(root, options)
    os.execute(
        "cd "..root.."; "..
        "git push "..options)
end

function Git.pull(root)
    os.execute(
        "cd "..root.."; "..
        "git pull")
end

function Git.treehash(root)
    return Cm.capturestdout("cd "..root.."; git rev-parse HEAD^{tree}")
end

return Git