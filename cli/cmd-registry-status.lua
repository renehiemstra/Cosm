local Reg = require("src.registry")

local function abort()
    print("Invalid option arguments: use `cosm registry status <registry name>`")
    os.exit(1)
end

--run package status
--extract command line arguments
local nargs = #arg
if nargs==1 then
    local regname = arg[1]
    Reg.registry_status(Reg.regdir.."/"..regname)
else
    abort()
end