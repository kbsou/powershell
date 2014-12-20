# use the OS system shell process to execute, useful for URL handlers and other registered system file types
function StartSystemProcess {[System.Diagnostics.Process]::Start("" + $args + $input)}

function gsearch   {StartSystemProcess ("http://www.google.com/search?hl=en&q=" + $args + $input)}
function gimg      {StartSystemProcess ("http://images.google.com/images?sa=N&tab=wi&q=" + $args + $input)}
function youtube   {StartSystemProcess ("http://www.youtube.com/results?search_query=" + $args + $input)}
function duck      {StartSystemProcess ("https://duckduckgo.com/?q=" + $args + $input)}
function arrr      {StartSystemProcess ("http://thepiratebay.se/search/" + $args + $input)}
function wikipedia {StartSystemProcess ("http://en.wikipedia.org/wiki/" + $args + $input)}


Set-Alias goog   gsearch
Set-Alias !g     gsearch
Set-Alias !yt    youtube
Set-Alias !wiki  wikipedia
Set-Alias !pb    arrr
Set-Alias !ddg   duck

Export-ModuleMember -Function * -Alias * 
Write-Host "Loaded Search Engine Utils" -foregroundcolor "darkgray"