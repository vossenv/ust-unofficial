param([String]$idtype="Adobe ID", $groups="")


Import-Module ActiveDirectory


function Get-ADNestedGroupMembers { 
<#  
.SYNOPSIS
Author: Piotr Lewandowski
Version: 1.01 (04.08.2015) - added displayname to the output, changed name to samaccountname in case of user objects.

.DESCRIPTION
Get nested group membership from a given group or a number of groups.

Function enumerates members of a given AD group recursively along with nesting level and parent group information. 
It also displays if each user account is enabled. 
When used with an -indent switch, it will display only names, but in a more user-friendly way (Sort-Object of a tree view) 
   
.EXAMPLE   
Get-ADNestedGroupMembers "MyGroup" | Export-CSV .\NedstedMembers.csv -NoTypeInformation

.EXAMPLE  
Get-ADGroup "MyGroup" | Get-ADNestedGroupMembers | ft -autosize
            
.EXAMPLE             
Get-ADNestedGroupMembers "MyGroup" -indent
 
#>

param ( 
[String] $groupname, 
[String] $idtype,
[int] $nesting = -1, 
[int]$circular = $null, 
[switch]$indent 
) 
    function indent  
    { 
    Param($list) 
        foreach($line in $list) 
        { 
        $space = $null 
         
            for ($i=0;$i -lt $line.nesting;$i++) 
            { 
            $space += "    " 
            } 
            $line.name = "$space" + "$($line.name)"
        } 
      return $List 
    } 

    $modules = get-module | Select-Object -expand name
    if ($modules -contains "ActiveDirectory") 
    { 
	    $table = $null 
        $nestedmembers = $null 
        $adgroupname = $null     
        $nesting++   
        $ADgroupname = Get-ADGroup $groupname -properties memberof,members 
        $memberof = $adgroupname | Select-Object -expand memberof 
        write-verbose "Checking group: $($adgroupname.name)" 
        if ($adgroupname) 
        {  
            if ($circular) 
            { 
                $nestedmembers = Get-ADGroupMember -Identity $groupname -recursive 
                $circular = $null 
            } 
            else 
            { 
                $nestedmembers = Get-ADGroupMember -Identity $groupname | Sort-Object objectclass -Descending
                if (!($nestedmembers))
                {
                    $unknown = $ADgroupname | Select-Object -expand members
                    if ($unknown)
                    {
                        $nestedmembers=@()
                        foreach ($member in $unknown)
                        {
                        
                        Get-ADObject $member -Properties *
                        $nestedmembers += Get-ADObject $member -Properties *

                        
                        }
                    }

                }
            } 
 
            foreach ($nestedmember in $nestedmembers) 
            { 
				
				# Expand Props to include all of the needed values.  Field names are written
				# as is intentionally so the CSV header matches what UST expects:
				# E.G: "firstname","lastname","email","country","groups"
				
                $Props = @{				
					Type=$nestedmember.objectclass;
					Name=$nestedmember.name;
					DisplayName="";
					ParentGroup=$ADgroupname.name;
					Enabled="";
					Nesting=$nesting;							
					DN=$nestedmember.distinguishedname;
					Comment="";
					lastname="";
					firstname="";
                    email="";
                    username="";
                    country="US";
                    idtype=$idtype;              
                    groups=$groupname;
                    domain=""
				} 
                 
                if ($nestedmember.objectclass -eq "user") 
                { 					
					# Select-Object the extra proprties					
                    $nestedADMember = get-aduser $nestedmember -properties enabled,displayname,sn,givenname,mail,c,userPrincipalName 
                    $table = new-object psobject -property $props 
                    $table.enabled = $nestedadmember.enabled                    
                    $table.displayname = $nestedadmember.displayname				
                    $table.name = $nestedadmember.samaccountname
                    $table.idtype = $idtype
					
					# Added properties needed by UST / Admin Console					
					$table.firstname = $nestedadmember.givenName
					$table.lastname = $nestedadmember.sn					
                    $table.email = $nestedadmember.mail
                    $table.username = $nestedadmember.userPrincipalName
                    $table.country = $nestedadmember.c                    
                    $table.domain = $nestedadmember.userPrincipalName.Split("@")[1]


					
                    if ($indent) 
                    { 
                    indent $table | Select-Object @{N="Name";E={"$($_.name)  ($($_.displayname))"}}
                    } 
                    else 
                    { 
					
                    $table | Select-Object firstname,lastname,email,country,groups,DN,idtype,username,domain
					} 
                } 
                elseif ($nestedmember.objectclass -eq "group") 
                {  
                    $table = new-object psobject -Property $props 
                     
                    if ($memberof -contains $nestedmember.distinguishedname) 
                    { 
                        $table.comment ="Circular membership" 
                        $circular = 1 
                    } 
                    if ($indent) 
                    { 
                    indent $table | Select-Object name,comment | ForEach-Object{
						
						if ($_.comment -ne "")
						{
						[console]::foregroundcolor = "red"
						write-output "$($_.name) (Circular Membership)"
						[console]::ResetColor()
						}
						else
						{
						[console]::foregroundcolor = "yellow"
						write-output "$($_.name)"
						[console]::ResetColor()
						}
                    }
					}
                    else 
                    { 
                    $table | Select-Object type,name,displayname,parentgroup,nesting,enabled,dn,comment 
                    } 
                    if ($indent) 
                    { 
                       Get-ADNestedGroupMembers -groupname $nestedmember.distinguishedName -nesting $nesting -circular $circular -indent -idtype $idtype                    
                    } 
                    else  
                    { 
                       Get-ADNestedGroupMembers -groupname $nestedmember.distinguishedName -nesting $nesting -circular $circular -idtype $idtype                     
                    } 
              	                  
               } 
                else 
                { 
                    
                    if ($nestedmember)
                    {
                        $table = new-object psobject -property $props
                        if ($indent) 
                        { 
    	                    indent $table | Select-Object type,name,displayname,parentgroup,nesting,enabled,dn,comment
                        } 
                        else 
                        { 
                        $table | Select-Object type,name,displayname,parentgroup,nesting,enabled,dn,comment										
                        } 
                     }
                } 
              
            } 
         } 
    } 
    else {Write-Warning "Active Directory module is not loaded"}        
}


$grouplist = $groups.Split(",")
$userlist = @()

foreach ($g in $grouplist){

    $userlist += Get-ADNestedGroupMembers -groupname $g -idtype $idtype
}

$unique = @{}
foreach($m in $userlist){
    if ($m.type -ne "group"){
        try {
            $unique.Add($m.DN, ($m | Select-Object idtype,username,domain,email,firstname,lastname,country))
        } catch{}
    }
}

$uniqueUsers = ($unique.Values | ConvertTo-Csv -NoTypeInformation )
$uniqueUsers[0] = "Identity Type, Username, Domain, Email, First Name, Last Name, Country Code"
$uniqueUsers | Foreach-Object {$_ -replace '"', ''} | Set-Content "users.csv" 

