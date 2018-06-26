Set-Location -Path "$PSScriptRoot\.."

If(-Not (Test-Path -Path "libs")){
	New-Item -ItemType Directory -Path libs
}

If(-Not (Test-Path -Path "libs\LibContainer")){
	New-Item -ItemType SymbolicLink -Path "libs" -Name LibContainer -Value ..\LibContainer
} ElseIf(-Not (((Get-Item -Path "libs\LibContainer").Attributes.ToString()) -Match "ReparsePoint")){
	Remove-Item -Path "libs\LibContainer"
	New-Item -ItemType SymbolicLink -Path "libs" -Name LibContainer -Value ..\LibContainer
}
