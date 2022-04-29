$currentFolder=(pwd).Path
$TargetFolder2="..\..\GoCGuardrailsSolutionAccelerator\"
$TargetFolder="..\public"
$mainRunbookLocation='../GUARDRAIL COMMON/main.ps1'
if((Get-Item $TargetFolder) -eq $null)
{
    mkdir $TargetFolder
}
copy .\guardrails.bicep $TargetFolder
copy .\config.json $TargetFolder
copy .\parameters_template.json $TargetFolder
copy .\Readme.md $TargetFolder -Verbose
copy .\Controls.md $TargetFolder -Verbose
copy .\Setup.md $TargetFolder -Verbose
copy .\setup.ps1 $TargetFolder
copy .\SolutionDiagram.png $TargetFolder
copy $mainRunbookLocation $TargetFolder
if (!(get-item "$TargetFolder\PSModules2" -ErrorAction SilentlyContinue))
{
    mkdir "$TargetFolder\PSModules"
}
copy ..\PSModules\*.zip "$TargetFolder\PSModules\" -Force
"Local Public folder created."
$answer=Read-Host "Do you want to update the public repository?"
if ($answer -eq 'Y')
{
    dir $TargetFolder
    copy "$TargetFolder\*.*" $TargetFolder2 -Force
    cd $TargetFolder2
    git status
    git add .
    git commit -m "$(get-date) - New public Guardrails commit By $($(whoami).split("\")[1])"
    git push
}
cd $currentFolder