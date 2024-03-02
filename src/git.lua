local Cm = require("src.command")
local Base = require("src.base")

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

--check if the root directory is a bare repo
function Git.isbarerepo(root)
    if Cm.isdir(root) then
        local isbare = Cm.capturestdout("cd "..root.."; git rev-parse --is-bare-repository")
        if isbare=="true" then
            return true
        end
    end
    return false
end

--check if we are dealing with a possible git url
function Git.isgiturl(string)
    if type(string)~="string" then
        return false
    else
        return string.sub(string, -4)==".git"
    end
end

--extract the pkg name from the git url
function Git.namefromgiturl(url)
    return string.sub(Cm.capturestdout("echo $(basename "..Base.esc(url)..")"), 1, -5)
end

--get the remote url
function Git.remotegeturl(root)
    return Cm.capturestdout("cd "..root.."; git remote get-url --push origin")
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

function Git.init(root, commitmessage)
    --create git repo and push to origin
    Cm.throw{cm="git init", root=root}
    Cm.throw{cm="git add .", root=root}
    Cm.throw{cm="git commit -m \""..commitmessage.."\"", root=root}
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

--check if all work has been added - 'git diff' returns empty
function Git.nodiff(root)
    local exitcode = Cm.capturestdout("cd "..root.."; git diff --exit-code &> /dev/null; echo $?")
    return exitcode=="0"
end
--check if all work has been committed - 'git diff --staged' returns empty
function Git.nodiffstaged(root)
    local exitcode = Cm.capturestdout("cd "..root.."; git diff --staged --exit-code &> /dev/null; echo $?")
    return exitcode=="0"
end

function Git.tag(root, version, message)
    os.execute(
        "cd "..root.."; "..
        "git tag -a "..Base.esc(version).." -m "..Base.esc(message))
end

function Git.istagged(root, version)
    return version==Cm.capturestdout("cd "..root.."; git tag -l "..version)
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

function Git.hash(root)
    return Cm.capturestdout("cd "..root.."; git rev-parse HEAD")
end

function Git.treehash(root)
    return Cm.capturestdout("cd "..root.."; git rev-parse HEAD^{tree}")
end

--generate .ignore file
function Git.ignore(root, list)
    local file = io.open(root.."/.gitignore", "w")
    for k,v in pairs(list) do
        if not type(v)=="string" then
            error("Provide a string as input.")
        else
            file:write(v.."\n")
        end
    end
    file:close()
end

return Git