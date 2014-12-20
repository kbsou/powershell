
#Profile é desnecessário em outros hosts
if ($host.Name -ne 'ConsoleHost') { Exit }


#Constantes:
$myPath = Split-Path -parent $PSCommandPath
$AutoloadFolder = "$myPath\Modules"


#Salva um Alias no arquivo de Aliases
function create-alias 
{
	param 
   (
		[Parameter (Mandatory = $true)] [string] $Name,
		[Parameter (Mandatory = $true)] [string] $Path
  	)

	$filePath = "$AutoloadFolder\aliases.ps1"

	$stream = new-object System.IO.StreamWriter($filePath, $true, [System.Text.Encoding]::UTF8)
  	$stream.WriteLine("`nset-alias $Name `"$Path`"") 
  	$stream.close()

	set-alias $Name "$Path"
}

function prompt
{
   # Guarda o histórico de comandos
   #Get-History -Count 1KB | Export-CSV ~\PowerShell\history.csv
  
   # Erros
   if (!$?)
   {
      Write-Host "[Error]: Exit Code $LastExitCode`n" -foregroundcolor "red"
   }


   $div = "-" * 80
   $dir = "`nPS {0}" -f ($PWD -replace [regex]::Escape((Resolve-Path ~)), "~")
   $usr = "{0}@{1}"  -f $env:UserName, $env:ComputerName

   Write-Host  $div -ForegroundColor "darkgray" 
   Write-Host  $dir -ForegroundColor "green" 
   Write-Host "[" -NoNewline 
   Write-Host  $usr -ForegroundColor "darkgreen" -NoNewline
   "]>> " 
}



function load-env
{
    Write-Host "Loading modules. " -foregroundcolor "white"
    <#
    get-childitem -Directory "$AutoloadFolder" | %{ Import-Module "$_.psm1" }
    
    #if (Test-path ~\PowerShell\History.csv)
    #{   
    #   Import-CSV ~\PowerShell\History.csv | Add-History
    #   Write-Host "Loading command history. " -foregroundcolor "white"
    #}
    #>
   
    $modules = @(
        'aliases',
        'SearchEngines',
        'tools'
    )

    foreach ($module in $modules) {
        $mp = "$AutoloadFolder\$module\$module" + ".psm1"
        Import-Module $mp
    }

    Write-Host "Done"
}


Register-EngineEvent PowerShell.Exiting –Action { 
   Write-Host "Bye!"
}

<# Removendo os Aliases por causa do GOW #>
try
{
   ri alias:ls -ea Stop
   ri alias:pwd -ea Stop
}
catch {}

load-env
Write-Host "https://github.com/lzybkr/PSReadLine"


# Load Jump-Location profile
Import-Module 'C:\Chocolatey\lib\Jump-Location.0.6.0\tools\Jump.Location.psd1'
Import-Module PSReadLine


<#
---------------------------------------------------------------------------------------------
PSReadLine Configuration 
#>

$PSRL = [PSConsoleUtilities.PSConsoleReadLine]

Set-PSReadlineOption -ExtraPromptLineCount 1

Set-PSReadlineKeyHandler -Key '"',"'" `
                         -BriefDescription SmartInsertQuote `
                         -LongDescription "Insert paired quotes if not already on a quote" `
                         -ScriptBlock {
    param($key, $arg)

    $line   = $null
    $cursor = $null
    $PSRL::GetBufferState([ref]$line, [ref]$cursor)

    if ($line[$cursor] -eq $key.KeyChar) {
        # Just move the cursor
        $PSRL::SetCursorPosition($cursor + 1)
    }
    else {
        # Insert matching quotes, move cursor to be in between the quotes
        $PSRL::Insert("$($key.KeyChar)" * 2)
        $PSRL::GetBufferState([ref]$line, [ref]$cursor)
        $PSRL::SetCursorPosition($cursor - 1)
    }
}

Set-PSReadlineKeyHandler -Key '(','{','[' `
                         -BriefDescription InsertPairedBraces `
                         -LongDescription "Insert matching braces" `
                         -ScriptBlock {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar)
    {
        <#case#> '(' { [char]')'; break }
        <#case#> '{' { [char]'}'; break }
        <#case#> '[' { [char]']'; break }
    }
    $line = $null
    $cursor = $null

    $PSRL::Insert("$($key.KeyChar)$closeChar")
    $PSRL::GetBufferState([ref]$line, [ref]$cursor)
    $PSRL::SetCursorPosition($cursor - 1)        
}

Set-PSReadlineKeyHandler -Key ')',']','}' `
                         -BriefDescription SmartCloseBraces `
                         -LongDescription "Insert closing brace or skip" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    $PSRL::GetBufferState([ref]$line, [ref]$cursor)

    if ($line[$cursor] -eq $key.KeyChar)
    {
        $PSRL::SetCursorPosition($cursor + 1)
    }
    else
    {
        $PSRL::Insert("$($key.KeyChar)")
    }
}

Set-PSReadlineKeyHandler -Key Backspace `
                         -BriefDescription SmartBackspace `
                         -LongDescription "Delete previous character or matching quotes/parens/braces" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    $PSRL::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0)
    {
        $toMatch = $null
        switch ($line[$cursor])
        {
            <#case#> '"' { $toMatch = '"'; break }
            <#case#> "'" { $toMatch = "'"; break }
            <#case#> ')' { $toMatch = '('; break }
            <#case#> ']' { $toMatch = '['; break }
            <#case#> '}' { $toMatch = '{'; break }
        }

        if ($toMatch -ne $null -and $line[$cursor-1] -eq $toMatch)
        {
            $PSRL::Delete($cursor - 1, 2)
        }
        else
        {
            $PSRL::BackwardDeleteChar($key, $arg)
        }
    }
}


# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadlineKeyHandler -Key 'Alt+(' `
                         -BriefDescription ParenthesizeSelection `
                         -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
                         -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    $PSRL::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    $PSRL::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        $PSRL::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
        $PSRL::SetCursorPosition($selectionStart + $selectionLength + 2)
    }
    else
    {
        $PSRL::Replace(0, $line.Length, '(' + $line + ')')
        $PSRL::EndOfLine()
    }
}

# Each time you press Alt+', this key handler will change the token
# under or before the cursor.  It will cycle through single quotes, double quotes, or
# no quotes each time it is invoked.
Set-PSReadlineKeyHandler -Key "Alt+'" `
                         -BriefDescription ToggleQuoteArgument `
                         -LongDescription "Toggle quotes on the argument under the cursor" `
                         -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    $PSRL::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $tokenToChange = $null
    foreach ($token in $tokens)
    {
        $extent = $token.Extent
        if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor)
        {
            $tokenToChange = $token

            # If the cursor is at the end (it's really 1 past the end) of the previous token,
            # we only want to change the previous token if there is no token under the cursor
            if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext())
            {
                $nextToken = $foreach.Current
                if ($nextToken.Extent.StartOffset -eq $cursor)
                {
                    $tokenToChange = $nextToken
                }
            }
            break
        }
    }

    if ($tokenToChange -ne $null)
    {
        $extent = $tokenToChange.Extent
        $tokenText = $extent.Text
        if ($tokenText[0] -eq '"' -and $tokenText[-1] -eq '"')
        {
            # Switch to no quotes
            $replacement = $tokenText.Substring(1, $tokenText.Length - 2)
        }
        elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'")
        {
            # Switch to double quotes
            $replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
        }
        else
        {
            # Add single quotes
            $replacement = "'" + $tokenText + "'"
        }

        $PSRL::Replace(
            $extent.StartOffset,
            $tokenText.Length,
            $replacement)
    }
}



# F1 for help on the command line - naturally
Set-PSReadlineKeyHandler -Key F1 `
                         -BriefDescription CommandHelp `
                         -LongDescription "Open the help window for the current command" `
                         -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    $PSRL::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $commandAst = $ast.FindAll( {
        $node = $args[0]
        $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.Extent.StartOffset -le $cursor -and
            $node.Extent.EndOffset -ge $cursor
        }, $true) | Select-Object -Last 1

    if ($commandAst -ne $null)
    {
        $commandName = $commandAst.GetCommandName()
        if ($commandName -ne $null)
        {
            $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
            if ($command -is [System.Management.Automation.AliasInfo])
            {
                $commandName = $command.ResolvedCommandName
            }

            if ($commandName -ne $null)
            {
                Get-Help $commandName -ShowWindow
            }
        }
    }
}

