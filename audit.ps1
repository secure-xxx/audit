###################################################################
$key = '###SECRET###';
###################################################################
New-Item -ItemType directory -Force -Path $ENV:UserProfile\TMP
New-Item -ItemType directory -Force -Path $ENV:UserProfile\TMP\LOGS
New-Item -ItemType directory -Force -Path $ENV:UserProfile\TMP\ZIP
echo "`n"
echo "
                                                        xxx   xxx
 xxxx   xxxxx   xxxxx   xxx  xx  xxxxxx  xxxxx           xxx xxx
 xx      xx      xx  xx  xx  xx   xx  xx  xx              xxxxx
  xxxx   xxxx    xx      xx  xx   xxxxx   xxxx   xxxxx     xxx
     xx  xx      xx  xx  xx  xx   xx  xx  xx              xxxxx
  xxxx   xxxxx    xxxx    xxxx    xx  xx  xxxxx          xxx xxx
                                                        xxx   xxx"
echo "`n"
echo "CREATING TEMPORARY FOLDER... `n"
echo "COLLECTING MSINFO... `n"
msinfo32 /report $ENV:UserProfile\TMP\LOGS\MSINFO.txt
echo "COLLECTING SYSTEMINFO... `n"
systeminfo > $ENV:UserProfile\TMP\LOGS\SYSTEMINFO.txt
echo "COLLECTING UPDATES... `n"
Get-wmiobject -class win32_quickfixengineering | Out-File $ENV:UserProfile\TMP\LOGS\UPDATES.txt
echo "COLLECTING SOFTWARE... `n"
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table –AutoSize > $ENV:UserProfile\TMP\LOGS\SOFTWARE.txt
echo "CHECKING OPEN PORTS... `n"
Get-NetTCPConnection -State Listen | Select-Object -Property LocalAddress, LocalPort, RemoteAddress, RemotePort, State | Sort-Object LocalPort > $ENV:UserProfile\TMP\LOGS\PORTS.txt
echo "CHECKING ESTABILISHED CONNECTIONS... `n"
Get-NetTCPConnection -State Established |Select-Object -Property LocalAddress, LocalPort,@{name='RemoteHostName';expression={(Resolve-DnsName $_.RemoteAddress).NameHost}},RemoteAddress, RemotePort, State,@{name='ProcessName';expression={(Get-Process -Id $_.OwningProcess). Path}},OffloadState,CreationTime > $ENV:UserProfile\TMP\LOGS\CONNECTIONS.txt
echo "CHECKING SYSTEM LOG CLEANUP... `n"
Get-EventLog system -after (get-date).AddDays(-365) | where {$_.InstanceId -eq 1102} | Select-Object -Property * > $ENV:UserProfile\TMP\LOGS\1102-sys.txt
echo "CHECKING SECURITY LOG CLEANUP... `n"
Get-EventLog security -after (get-date).AddDays(-365) | where {$_.InstanceId -eq 1102} | Select-Object -Property * > $ENV:UserProfile\TMP\LOGS\1102-sec.txt
echo "CHECKING UNSUCCESSFULL AUTHENTIFICATIONS 4625... `n"
Get-EventLog security -after (get-date).AddDays(-365) | where {$_.InstanceId -eq 4625} | Select-Object -Property * > $ENV:UserProfile\TMP\LOGS\4625.txt
echo "CHECKING UNSUCCESSFULL AUTHENTIFICATIONS 4771... `n"
Get-EventLog security -after (get-date).AddDays(-365) | where {$_.InstanceId -eq 4771} | Select-Object -Property * > $ENV:UserProfile\TMP\LOGS\4771.txt
echo "CHECKING UNSUCCESSFULL AUTHENTIFICATIONS 4768... `n"
Get-EventLog security -after (get-date).AddDays(-365) | where {$_.InstanceId -eq 4768} | Select-Object -Property * > $ENV:UserProfile\TMP\LOGS\4768.txt
echo "CHECKING UNSUCCESSFULL AUTHENTIFICATIONS 4776... `n"
Get-EventLog security -after (get-date).AddDays(-365) | where {$_.InstanceId -eq 4776} | Select-Object -Property * > $ENV:UserProfile\TMP\LOGS\4776.txt
echo "CHECKING BLOCKED ACCOUNTS 4740... `n"
Get-EventLog security -after (get-date).AddDays(-365) | where {$_.InstanceId -eq 4740} | Select-Object -Property * > $ENV:UserProfile\TMP\LOGS\4740.txt


echo "CREATING ARCHIVE... `n"
$myfqdn=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
Add-Type -Assembly System.IO.Compression.FileSystem
$source = "$ENV:UserProfile\TMP\LOGS"
$destination = "$ENV:UserProfile\TMP\ZIP\$myFQDN.zip"
[io.compression.zipfile]::CreateFromDirectory($source, $destination)


echo "UPLOADING FILES... `n"

$FilePath = "$ENV:UserProfile\TMP\ZIP\$myFQDN.zip";
$URL = 'https://data.secure-x.ru';
$fileBytes = [System.IO.File]::ReadAllBytes($FilePath);
$content = [Convert]::ToBase64String($fileBytes);
$boundary = [System.Guid]::NewGuid().ToString(); 
$LF = "`r`n";

$bodyLines = ( 

"--$boundary",
    "Content-Disposition: form-data; name=`"myfqdn`"",
  "Content-Type: text/html$LF",
    $myfqdn,
     "--$boundary--$LF",

    "--$boundary",
    "Content-Disposition: form-data; name=`"content`"",
  "Content-Type: text/html$LF",
    $content,
     "--$boundary--$LF",
    
    
 "--$boundary",
    "Content-Disposition: form-data; name=`"key`"",
  "Content-Type: text/html$LF",
    $key,
     "--$boundary--$LF"

    

) -join $LF


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-RestMethod -Uri $URL -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines

echo "CLEANUP... "
Remove-Item -Path $ENV:UserProfile\TMP -Recurse
