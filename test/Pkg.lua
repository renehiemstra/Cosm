


testset "validate terra pkg" do

    local t5 = Pkg.ispkg(Pkg.terrahome.."/dev/Pkg")
    test t5

    Pkg.create("MyPackage")
    local t6 = Pkg.ispkg("./MyPackage")
    test t6
    os.execute("rm -rf ./MyPackage")
end


testset "get repo name from url" do
    local t1 = Pkg.namefromgiturl("git@gitlab.com:group/subgroup/MyPackage.git")
    test t1=="MyPackage"
 
    local t2 = Pkg.namefromgiturl("https://gitlab.com/group/subgroup/MyPackage.git") 
    test t2=="MyPackage"
 
    local t3 = Pkg.namefromgiturl("git@gitlab.com:group/subgroup/MyPackage.git") 
    test t3=="MyPackage" 
 
    local t4 = Pkg.namefromgiturl("https://github.com/group/subgroup/MyPackage.git")
    test t4=="MyPackage"   
end

--[[
testset "validate git remote repo url" do
    local t1 = Pkg.validgitrepo("git@github.com:terralang/terra.git")
    local t2 = Pkg.validgitrepo("git@github.com:terralang/terra.gi")     
    test t1 and not t2
    
    local t3 = Pkg.validemptygitrepo("git@github.com:renehiemstra/EmptyTestRepo.git")
    local t4 = Pkg.validemptygitrepo("git@github.com:renehiemstra/EmptyTestRepo.gi")
    local t5 = Pkg.validemptygitrepo("git@github.com:terralang/terra.git")
    test t3 and not t4 and not t5

    local t6 = Pkg.validnonemptygitrepo("git@github.com:terralang/terra.git")
    local t7 = Pkg.validnonemptygitrepo("git@github.com:terralang/terra.gi")
    local t8 = Pkg.validnonemptygitrepo("git@github.com:renehiemstra/EmptyTestRepo.git")
    test t6 and not t7 and not t8
end]]

testset "clone package" do
    os.execute("rm -rf Pkg")
    local status, err = pcall(Pkg.clone, {root=".", url="git@github.com:renehiemstra/Pkg.git"})
    test status
    os.execute("rm -rf Pkg")
end

end --testenv

return Pkg
