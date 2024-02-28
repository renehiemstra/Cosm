local Cm = {}

function Cm.capturestdout(command)
    local handle = io.popen(command)
    local output = handle:read("*a")
    handle:close()
    return output:gsub('[\n\r]', '')
end

function Cm.isfile(filename)
    local exitcode = Cm.capturestdout("test -f "..filename.."; echo $?")
    return exitcode=="0"
end

function Cm.isdir(dirname)
    local exitcode = Cm.capturestdout("test -d "..dirname.."; echo $?")
    return exitcode=="0"
end

--extract the absolute path give a relative (absolute) path
function Cm.absolutepath(dir)
    if Cm.isdir(dir) then
        return Cm.capturestdout("realpath "..dir)
    else
        error("ArgumentError: not a valid path to a directory.")
    end
end

--run command and return success or failure
function Cm.success(args)
    if type(args.cm)~="string" then
        error("Provide `cm` (command) to execute as a string.\n\n")
    end
    if args.root==nil then
        args.root = "." --choose current directory if unspecified
    elseif not Cm.isdir(args.root) then
        error("Provide `root` directory of command.\n\n")
    end
    --run command and output to an io device
    local handle = io.popen("cd "..args.root.."; "..args.cm.."; echo \"exitcode=\"$?")
    local s = handle:read("*a")
    handle:close()
    --extract message and exitcode
    local i, j = string.find(s, "exitcode=")
    args.message = string.sub(s, 1, i-1)
    args.exitcode = tonumber(string.sub(s, j+1, -1))
    return args.exitcode==0
end

--run command and throw an error if command failed
function Cm.throw(args)
    if not Cm.success(args) then
        if args.message==nil then
            args.message = "Command: <"..args.cm.."> failed with exitcode "..args.exitcode..".\n\n"
        elseif type(args.message)~="string" then
            error("Provide error `message` as a string.\n\n")
        end
        print("command failed with exitcode: "..args.exitcode)
        print("message: "..args.message)
        os.exit()
    end
end

function Cm.getfileextension(file)
    return file:match "[^.]+$"
end

--print path working directory
function Cm.currentworkdir()
    return Cm.capturestdout("pwd")
end

--print name of directory
function Cm.namedir(root)
    return Cm.capturestdout("cd "..root.."; echo \"${PWD##*/}\"")
end

--make a directory if it does not exist yet
function Cm.mkdir(dirname)
    os.execute("mkdir -p "..dirname)
end

--remove a directory
function Cm.rmdir(dirname)
    os.execute("rm -rf "..dirname)
end

--make a file if it does not exist yet
function Cm.touch(filename)
    os.execute("touch "..filename)
end


return Cm