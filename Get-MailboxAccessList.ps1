function MailboxAccess
    {
        PARAM
        (
            [Parameter(Mandatory=$true)]$Address
        )
        
		#Check for required address, if it is not supplied prompts for an address.
        if(-not($Address))
        {
            Throw "You must supply a value for -Address" 
        }
		
		#Get users and groups who have access to the mailbox and sort out default users and network admins.
        $Address = "$Address" 
        $MemberList = (Get-MailboxPermission $Address | select user | Where-Object {$_.user -notlike "OREGONSTATE*"} | Where-Object {$_.user -notlike "NT*"} | Where-Object {$_.user -notlike "FS*"} | Where-Object {$_.user -notlike "*CN_ITAdmins*"}) | Out-String
        $split = $MemberList.Split("`n")
        
		#Initalize Arrays for storing names, groups and the final list of users with access.
        [string[]]$NameArr = @()
        [string[]]$GroupList = @()
        $AccessList = @()
		
		#Remove any extra prefixes and parse down to just the user and group names
        foreach ($item in $split)
        {
            if(($item -notlike "*CN*") -and ($item.Length -gt 8))
            {
                #do nothing
            }
            else
            {
                $tempsltip = $item.Split("\")
                $NameArr += $tempsltip[1]
            }
        }
        
		#Cast system object to a string and remove any whitespace.
        $StringArr = $NameArr[1] | Out-String 
        $FinArr = $StringArr.Trim() 
        
		#Check for a null list, if it is then there are no special permissions.
        if($FinArr[0] -eq $null)
        {
            Write-Warning "No special premission were found on this mailbox."
        }
		#If list is not null then check for ONID user or group.
        else
        { 
            Write-Host "Groups that give access:" $FinArr
            foreach ($item in $FinArr)
            {
				#Check for ONID usernames and add them directly to the access list.
                if($item.Length -le 8) #check for ONID
                {
                    $AccessList += $item
                }
				#If it is not a user gather usernames from the AD group.
                else
                {
                    $AccessList += (Get-ADGroupMember -Identity $item -Server tss.oregonstate.edu -Recursive | select name | Out-String) 
                }
            }
            
        }
		#Return all of the users who have access to the mailbox.
        $AccessList
    }
 