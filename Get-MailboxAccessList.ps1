function MailboxAccess {
        PARAM (
            [Parameter(Mandatory=$true)]$EmailAddress
        )
        
        if(-not($EmailAddress)) {
            Throw "You must supply a value for -Address" 
        }

        $Address = "$EmailAddress" 
        #Filter out default users and permissions
        $MemberList = (Get-MailboxPermission $Address | select user | Where-Object {$_.user -notlike "OREGONSTATE*"} | Where-Object {$_.user -notlike "NT*"} | Where-Object {$_.user -notlike "FS*"} | Where-Object {$_.user -notlike "*CN_ITAdmins*"}) | Where-Object {$_.user -notlike "FS_*"}| Out-String
        $split = $MemberList.Split("`n")
        
        [string[]]$NameArr = @()
        [string[]]$GroupList = @()
        $AccessList = @()

        foreach ($item in $split) {
            if(($item -notlike "*CN*") -and ($item.Length -gt 8))
            {
                #do nothing
            } else {
                $tempsplit = $item.Split("\")
                $NameArr += $tempsplit | Where-Object {$_ -notlike "cn"} | Where-Object {$_ -notlike "FS*"}
            }
        }
        foreach ($item in $NameArr) {
            $StringArr += $Item | Out-String
        }
        $FinArr = $StringArr.Split("`n")
        if([string]::IsNullOrWhiteSpace($FinArr)) {
            Write-Warning "No special premission were found on this mailbox."
        } else { 
            #If there is a group that contains "Mailbox" then print that, else print the usernames
            $MainGroup = $FinArr | Where-Object {$_ -like "*mailbox*"}
            Write-Host "Groups that give access: " $MainGroup
            foreach ($item in $FinArr) {
                #Remove weird white spaces
                $item = $item.Trim()
                #Check for ONID
                if($item.Length -le 8) {
                    if([string]::IsNullOrEmpty($item) -or [string]::IsNullOrWhiteSpace($item)){
                        #Ignore that item
                    }else{
                        $AccessList += "Added direclty: " +$item
                    }
                } else {
                    $AccessList += (Get-ADGroupMember -Identity $item -Server tss.oregonstate.edu -Recursive | select name | Out-String) 
                }
            }
            
        }
        #Format and print the output
        $AccessList = $AccessList.Split("`n")
        $AccessList = $AccessList | Where-Object{$_ -notlike "*--*"} | Where-Object{$_ -notlike "*name*"} 
        Write-Host "`nUsers who have access:" 
        #Needed to remove unwanted new lines
        $AccessList[1..$AccessList.Length]
    }


    #remove after testing
    MailboxAccess -EmailAddress BAF.Scheduler@oregonstate.edu
