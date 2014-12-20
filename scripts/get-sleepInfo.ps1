param($Newest = 50)

function Parse-EventLogEntry
{
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [System.Diagnostics.EventLogEntry[]]
        $eventInfo
    )

    Process
    {
        foreach ($info in $eventInfo)
        {
            $enterSleep = [DateTime]::Parse($info.ReplacementStrings[0]);
            $exitSleep = [DateTime]::Parse($info.ReplacementStrings[1]);
            $duration = $exitSleep - $enterSleep
            $wakeSource = 'Unknown'
            if ($info.Message -match 'Wake Source:\s*(.*)$')
            {
                $wakeSource = $matches[1]
            }
            new-object psobject -Property @{Duration = $duration; Sleep = $enterSleep; 
                                            Wake = $exitSleep; WakeSource = $wakeSource}
        }
    }
}

Get-EventLog -LogName System -Source Microsoft-Windows-Power-Troubleshooter -Newest $Newest | 
     Sort TimeGenerated | Parse-EventLogEntry