local Reg = require("src.registry")

local function abort()
    print("Invalid option arguments: use `cosm registry add <name> <giturl>`")
    os.exit(1)
end

local function printstats(name, root)
    print("Created registry "..name.." in "..root)
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local registry = {}
    registry.name = arg[1]
    registry.url = arg[2]
    if not pcall(Reg.create, registry) then
        abort() --ToDo: better error message
    end
    printstats(registry.name, Reg.regdir)
else
    abort()
end