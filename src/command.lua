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
    local exitcode = Cm.capturestdout("cd "..args.root.."; "..args.cm.." &> /dev/null; echo $?")
    return exitcode=="0"
end

--run command and throw an error if command failed
function Cm.throw(args)
    if not Cm.success(args) then
        if args.message==nil then
            args.message = "Command failed.\n\n"
        elseif type(args.message)~="string" then
            error("Provide error `message` as a string.\n\n")
        end
        error(args.message)
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

--make a directory if it does not exist yet
function Cm.rmdir(dirname)
    os.execute("rm -rf "..dirname)
end

--make a directory if it does not exist yet
function Cm.touch(filename)
    os.execute("touch "..filename)
end


return Cm