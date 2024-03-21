package.path = package.path .. ";"..os.getenv("COSM_DEPOT_PATH").."/.cosm/?.lua"

local Reg = require("src.registry")
local Cm = require("src.command")
local Git = require("src.git")

local function abort(message)
    print(message)
    os.exit(1)
end

local function printstats(name, root)
    print("Added registry "..name.." to the list of registries in "..root..".")
end

--extract command line arguments
local nargs = #arg
if nargs==1 then
    local registry = {}
    --check remote url is a valid git url or bare repo
    if Cm.isdir(arg[1]) then
        registry.url  = Cm.absolutepath(arg[1])
        registry.name = Cm.basename(registry.url)
    elseif Git.validnonemptygitrepo(arg[1]) then
        registry.url = arg[1]
        registry.name = Git.namefromgiturl(registry.url)
    else
        abort("ArgumentError: argument "..arg[1].." is not a bare repo or valid git url.")
    end
    Cm.throw{cm="git clone "..registry.url, root=Reg.regdir}
    if Reg.isreg(Reg.regdir.."/"..registry.name)==true then
        Reg.addtolist(registry.name)
        printstats(registry.name, Reg.regdir)
    else
        Cm.throw{cm="rm -rf "..registry.name, root=Reg.regdir}
        abort("Cloned repository is not a valid registry.")
    end
else
    abort("Invalid arguments: use `cosm registry clone <remote>`")
end