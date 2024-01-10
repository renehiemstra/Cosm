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

return Cm