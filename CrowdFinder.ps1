# Script - Search CrowdStrike Process Remote - @RenatoBorbolla
# Run as Administrator
cls
#check RSAT 
echo "----------------------------Check Module AD-----------------------------------------"
$mod = @(Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online | Select-Object -Property State | findstr "NotPresent Installed")
if ($mod -like "Installed") {echo "AD.Module exist"} else { Get-WindowsCapability -Name Rsat.ActiveDirectory* -Online | Add-WindowsCapability -Online}
New-Item output.txt ; New-Item hosts.txt ; Remove-Variable mod
echo ""
#for more domains, add new line but with $domain2, $domain3"
$domain = Read-Host "Please enter your Domain"
nltest /DOMAIN_TRUSTS /ALL_TRUSTS
echo ""
nltest /dclist:$domain
echo ""
echo ""
echo "Add server list in dcs.txt and then"
pause
cls
echo "----------------------------Searching Hosts--------------------------------------------"
foreach($dc in Get-Content .\dcs.txt) {
$srv = @(Get-ADComputer -Server $dc -Filter 'operatingsystem -like "*Windows*" -and enabled -eq "True"' | Select-Object DNSHostName | findstr ".$domain" 2>$null)
$hosts = @(if ( $null -like $srv) { echo "No Hosts" } else { $srv >> output.txt | out-null })
Remove-Variable srv, hosts
}
type output.txt | sort -unique | out-file output.txt
Get-Content output.txt | foreach { $_.Trim()} | Set-Content hosts.txt
del output.txt ; del output.txt
echo "-------------------------------Running----------------------------------------------"
foreach($pc in Get-Content .\hosts.txt) {
$process = @(Get-Process -Computername $pc -Name "*CS*" 2>$null)
$parse = @(if ( $null -like $process) { echo "$pc --> No Access" } else { $filter = @($process | Select-Object ProcessName | findstr "CSFalconContainer CSFalconService") ; $result = @(if ( $filter -like '*Falcon*') { echo "$pc  - Have the CrowdStrike" } else { echo "$pc --> No CrowdStrike" >> scan.txt })} )
Remove-Variable pc, parse
}
echo "DONE!"