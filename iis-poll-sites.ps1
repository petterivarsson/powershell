import-module WebAdministration

# CONFIG ##################################
$smtpServer = "smtp.konet.se"
$smtpPort = 25
$from = "10sr0290-prod@konet.se"
#$to = drift@vxa.se
$to = "petter.ivarsson@vxa.se"
$subject = "IIS Application Error on " + $env:COMPUTERNAME
$sendmail = "true"; # true/false

$protocoll = "https://";
$suffix = "/swagger"; # "/swagger" OR ""
# CONFIG ##################################


cls
Write-Host "Checking all iis-sites on" $env:COMPUTERNAME

# Get a list of all applications configured on the local IIS 
$applications = Get-ChildItem IIS:\Sites | Where-Object { $_.Name -ne "Default Web Site" } 

$errors = @();

# Loop through each application and test the specified URL 
foreach ($app in $applications) 
{ 
    try 
    {
        # Check url with swagger
        $appUrl = $protocoll + $app.Name + $suffix 
        Write-Host "Testing $appUrl ..." 
        $request = [System.Net.WebRequest]::Create($appUrl); 
        $response = $request.GetResponse();
        $status = [int]$response.StatusCode; 
        if ($status -gt 499 -and $status -ne 404) 
        { 
            $errors += $appUrl + " => HTTP status code is $status." 
        }
        $response.Close();
    } 
    catch [System.Net.WebException] 
    {
        try 
        {
            # Check url without swagger
            $appUrl = $protocoll + $app.Name;
            Write-Host "Testing $appUrl ..."  
            $request = [System.Net.WebRequest]::Create($appUrl); 
            $response = $request.GetResponse();
            $status = [int]$response.StatusCode; 
            if ($status -gt 499 -and $status -ne 404) 
            { 
                $errors += $appUrl + " => HTTP status code is $status." 
            }
            $response.Close();
        } 
        catch [System.Net.WebException] 
        {

            $errors += $appUrl + " => " + $($_.Exception.Message);
        }


        $errors += $appUrl + " => " + $($_.Exception.Message);
    }
}


$uniqueErrors = $errors | Select-Object -Unique
$mailerrors = @();

foreach($myerror in $uniqueErrors)
{
    if ($myerror -notmatch "(404)" -and $myerror -notmatch "(401)" -and $myerror -notmatch $env:COMPUTERNAME) {
        $mailerrors += "`n" + $myerror.Replace($protocoll,'');
    }
}

$body = "`nFound " + ($mailerrors.Count) + " errors";
$body += $mailerrors;

Write-Host $body

if($sendmail -eq 'true' -and ($mailerrors.Count) -gt 0){

    Write-Host "`nTrying to send mail ..."
    try 
    {
        $message = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body;
        $Encoding = [System.Text.Encoding]::UTF8;
        $message.BodyEncoding = $Encoding;
        $message.SubjectEncoding = $Encoding;
        $client = New-Object System.Net.Mail.SmtpClient $smtpServer, $smtpPort; 
        $client.Send($message);
        Write-Host "Mail sent";
    }
    catch
    {
        Write-Host "Mail could not be sent";
        Write-Host $($_.Exception.Message);
    }
}




