local Pkg = require("src.pkg")

local function abort()
    print("ArgumentError: the signature is 'cosm upgrade <package name> [--latest, --version <version>]'. See 'cosm --help'. \n \n")
    os.exit(1)
end

--extract command line arguments
local nargs = #arg
if nargs==2 then
    local args = {root=arg[1], dep=arg[2]}
    Pkg.upgrade(args)
    print("Upgraded package "..args.dep.."  to the latest version.")
else
    abort()
end