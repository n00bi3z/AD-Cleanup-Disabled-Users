##################################################################
#Create list of disabled users in OU saved to CSV file
##################################################################

$currentdate = Get-Date

$wrongoudis = Get-ADUser -Filter * -SearchBase "OU=Users,DC=contoso,DC=com" -Properties Samaccountname | Where-Object {$_.Enabled -eq $false} | Select-Object SAMAccountName 

$wrongoudis | Export-Csv -Path "C:\disabled.csv" -NoTypeInformation



Start-Sleep -Seconds 20




##########################################################################################################################
# Create new local directory for each terminated employee, then save groups to text file in each directory before deleting
##########################################################################################################################



$groups = ForEach ($user in $(Import-Csv -Path "C:\disabled.csv")) {

    $user = [string]$user
    $user = $user[17..30] -join ''
    $user = $user.TrimEnd('}')
    New-Item -ItemType "directory" -Path "C:\Termination\$user"  
    $adprop = get-aduser -identity "$user" -properties memberof | select -ExpandProperty memberof 
    $adprop | Out-File -FilePath "C:\Termination\$user\$user groupmem.txt"



}


Start-Sleep -Seconds 20


#############################################
# Remove groups and move to a termination ou
#############################################



$adServer = "contoso.com"


$users = ForEach ($employeeSAN in $(Get-Content "C:\Disabled.csv")){

	Write-Host $employeeSAN
	$employeeSAN =  $employeeSAN -replace '[""]',''
	Get-ADUser -Filter {SamAccountName -like $employeeSAN} 
	$ADgroups = Get-ADPrincipalGroupMembership -Identity $employeeSAN | where {$_.Name -ne "Domain Users"}
	
    if ($ADgroups -ne $null){
		Remove-ADPrincipalGroupMembership -Identity $employeeSAN -MemberOf $ADgroups -Server $adServer -Confirm:$false
	}
	
	Get-ADUser -Filter {SamAccountName -like $employeeSAN} | Move-ADObject -TargetPath 'OU=TERMINATED,DC=MA-ComTech,DC=com'
	
	}

