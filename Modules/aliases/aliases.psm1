
$apps = "C:\Utils"

function Get-AliasesFromRegistry 
{
   $allCommands = Get-Command -CommandType All | Select-Object -ExpandProperty Name
   
   Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths' | Where-Object { $_.Property -icontains 'Path' } | ForEach-Object {
      $executable = $_.Name | Split-Path -Leaf
      $shortName = $executable -creplace '\.[^.]*$',''
      $path = $_ | Get-ItemProperty | Select-Object -ExpandProperty Path
      $fqPath = $path | Join-Path -ChildPath $executable

      if ( ($allCommands -icontains $executable) -or ($allCommands -icontains $shortName) ) 
      {
          Write-Verbose "Skipping $executable and $shortName because a command already exists with that name."
      } 
      else 
      {
          Write-Verbose "Creating aliases for $executable."
          New-Alias -Name $executable -Value $fqPath
          New-Alias -Name $shortName -Value $fqPath
      }
   }
}


set-alias open  invoke-item
set-alias lsd   ls # Allow meself to mistype a little

#set-alias pdflatex  "C:\Program Files\MiKTeX 2.9\miktex\bin\pdflatex.exe"
set-alias moz       "C:\Program Files\Mozilla Firefox\firefox.exe"
set-alias xl        "C:\Program Files\Microsoft Office\Office12\EXCEL.exe"
set-alias acro      "C:\Program Files\Adobe\Reader 9.0\Reader\AcroRd32.exe"
set-alias zip       "C:\Program Files\7-Zip\7z"
set-alias far       "C:\Users\eserafim\AppData\Local\FarManager\Far.exe"

set-alias perl      "$apps\Strawberry\perl\bin\perl.exe"
set-alias gvim      "$apps\Vim\vim73\gvim.exe"
set-alias npp       "$apps\Notepad++\notepad++.exe"
set-alias suv       "C:\Program Files\Sublime Text 3\sublime_text.exe"
set-alias sumatra   "$apps\sumatrapdf.exe"
set-alias ex 	    "C:\Windows\explorer.exe" -Scope Global

Export-ModuleMember -Function * -Alias * 

Write-Host "Loaded Aliases List" -foregroundcolor "darkgray"