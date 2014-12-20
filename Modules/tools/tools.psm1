function now {[DateTime]::Now}
function ts  {$input | %{$_ -as [string]} }

function cd.. {cd ..}
function cd...{cd ..\..}

function Search 
{
  param 
  (
    [Parameter(ValueFromPipeline = $true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Pattern  
  )
  
  if($Path -eq ""){$Path = $PWD;}
  
    $con = New-Object -ComObject ADODB.Connection
    $rs = New-Object -ComObject ADODB.Recordset

    $con.Open("Provider=Search.CollatorDSO;Extended Properties='Application=Windows';")
    $pattern = $pattern -replace "\*", "%"  
    $path = $path + "\%"

    $rs.Open("SELECT System.ItemPathDisplay FROM SYSTEMINDEX WHERE System.FileName LIKE '" + $pattern + "' AND System.ItemPathDisplay LIKE '" + $path + "'" , $con)

    While(-Not $rs.EOF)
    {
        $rs.Fields.Item("System.ItemPathDisplay").Value
        $rs.MoveNext()
    }

}


function printTarefas
{
    
    $patharq = "~\tarefas.txt"
    
    Write-host "`nTarefas:" -foregroundcolor "green";
    
    import-csv -Delimiter ";" -Path $patharq |
    foreach-object{
        $nome = $_.nome
        switch -wildcard($_.tipo){
            "d"                                                             {Write-Host "`n * $nome" -nonewline -foregroundcolor "magenta";}
            
            "seg"   {if((Get-Date).DayOfWeek -eq "Monday")                  {write-host "`n * $nome" -nonewline -foregroundcolor "cyan";}}
            "ter"   {if((Get-Date).DayOfWeek -eq "Tuesday")                 {write-host "`n * $nome" -nonewline -foregroundcolor "cyan";}}
            "qua"   {if((Get-Date).DayOfWeek -eq "Wednesday")               {write-host "`n * $nome" -nonewline -foregroundcolor "cyan";}}
            "qui"   {if((Get-Date).DayOfWeek -eq "Thursday")                {write-host "`n * $nome" -nonewline -foregroundcolor "cyan";}}
            "sex"   {if((Get-Date).DayOfWeek -eq "Friday")                  {write-host "`n * $nome" -nonewline -foregroundcolor "cyan";}}
            
            "men1"  {if((Get-Date).Day -lt 10)                              {write-host "`n $nome" -nonewline -foregroundcolor "red";}}
            "men2"  {if((Get-Date).Day -lt 17 -and (Get-Date).Day -gt 5)    {write-host "`n $nome" -nonewline -foregroundcolor "red";}}
            "men3"  {if((Get-Date).Day -lt 27  -and  (Get-Date).Day -gt 10) {write-host "`n $nome" -nonewline -foregroundcolor "red";}}
            "men4"  {if((Get-Date).Day -gt 15)                              {write-host "`n $nome" -nonewline -foregroundcolor "red";}}
        }
    }
    Write-host "`n"
}

function bored
{
    $rand = New-Object system.random
    
    while(1)
    {
        $char = [char] $rand.next(15,128)
        write-host -NoNewline $char -foregroundcolor "green";
        [System.Threading.Thread]::Sleep(5)
    }
}

#function GetClip {[System.Windows.Forms.Clipboard]::GetText()}
#function SetClip {[System.Windows.Forms.Clipboard]::SetText($input + $args)}
function clipcd {Get-Clipboard | cd}

function spark() 
{
    $ticks = @(" ", "_")

    $minmax = $args | measure -min -max
    $range = $minmax.Maximum - $minmax.Minimum
    $scale = $ticks.length - 1
    $output = @()

    foreach ($x in $args) {
       $output += $ticks[([Math]::round((($x - $minmax.Minimum) / $range) * $scale))]
    }

    write ([String]::join('', $output))
}



function Out-Speech(){
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]$Collection, 
        [switch]$wait, 
        [switch]$purge, 
        [switch]$readfiles, 
        [switch]$readxml, 
        [switch]$notxml, 
        [switch]$passthru)

    
    if ($args -eq '-?') {
        ''
        'Usage: Out-Speech [[-Collection] <array>]'
        ''
        'Parameters:'
        '    -Collection : A collection of items to speak.'
        '    -?          : Display this usage information'
        '  Switches:'
        '    -wait       : Wait for the machine to read each item (NOT asynchronous).'
        '    -purge      : Purge all other speech requests before making this call.'
        '    -readfiles  : Read the contents of the text files indicated.'
        '    -readxml    : Treat input as speech XML markup.'
        '    -notxml     : Do NOT parse XML (if text starts with "<" but is not XML).'
        '    -passthru   : Pass on the input as output.'
        ''
        'Examples:'
        '    PS> Out-Speech "Hello World"'
        '    PS> Select-RandomLine quotes.txt | Out-Speech -wait'
        '    PS> Out-Speech -readfiles "Hitchhiker''s Guide To The Galaxy.txt"'
        ''
        exit
    }
    
    # To override this default, use the other flag values given below.
    $SPF_DEFAULT = 0          # Specifies that the default settings should be used.  
        ## The defaults are:
        #~ * Speak the given text string synchronously
        #~ * Not purge pending speak requests
        #~ * Parse the text as XML only if the first character is a left-angle-bracket (<)
        #~ * Not persist global XML state changes across speak calls
        #~ * Not expand punctuation characters into words.
    $SPF_ASYNC = 1            # Specifies that the Speak call should be asynchronous.
    $SPF_PURGEBEFORESPEAK = 2 # Purges all pending speak requests prior to this speak call.
    $SPF_IS_FILENAME = 4      # The string passed is a file name, and the file text should be spoken.
    $SPF_IS_XML = 8           # The input text will be parsed for XML markup. 
    $SPF_IS_NOT_XML= 16       # The input text will not be parsed for XML markup.
      
      
    $SPF = $SPF_DEFAULT
    if(!$wait){ $SPF += $SPF_ASYNC }
    if($purge){ $SPF += $SPF_PURGEBEFORESPEAK }
    if($readfiles){ $SPF += $SPF_IS_FILENAME }
    if($readxml){ $SPF += $SPF_IS_XML }
    if($notxml){ $SPF += $SPF_IS_NOT_XML }
    
    $Voice = new-object -com SAPI.SpVoice
      
    if ($collection.count -gt 0) {
        foreach( $item in $collection ) {
            $exit = $Voice.Speak( ($item | out-string), $SPF )
        }
    }
    
    if ($_)
    {
        $exit = $Voice.Speak( ($_ | out-string), $SPF )
        if($passthru) { $_ }
    }
}


Export-ModuleMember -Function * -Alias * 
Write-Host "Loaded Tools" -foregroundcolor "darkgray"
