# Paramètres
$ftpServer = "10.10.121.32"
$ftpUsername = "cyber"
$ftpPassword = "P@ssw0rd"
$remoteFilePath = "/test.tar.gz"
$localFilePath = "C:\\FTP\\archive.tar.gz"
$smtpServer = "smtp.example.com"
$smtpPort = 587
$smtpUsername = "admin@example.com"
$smtpPassword = "password"
$emailRecipient = "admin@example.com"
$emailSubject = "Erreur de téléchargement FTP"

# Fonction d'envoi de mail
function Send-ErrorEmail {
    param (
        [string]$errorMessage
    )

    $emailBody = "Une erreur est survenue lors du téléchargement depuis le serveur FTP :`n`n$errorMessage"

    try {
        Send-MailMessage -From $smtpUsername -To $emailRecipient -Subject $emailSubject -Body $emailBody -SmtpServer $smtpServer -Port $smtpPort -Credential (New-Object PSCredential($smtpUsername, (ConvertTo-SecureString $smtpPassword -AsPlainText -Force))) -UseSsl
    } catch {
        Write-Error "Échec de l'envoi du mail : $_"
    }
}

# Téléchargement de l'archive
try {
    # Création de la session FTP
    $ftpRequest = [System.Net.FtpWebRequest]::Create("ftp://$ftpServer$remoteFilePath")
    $ftpRequest.Credentials = New-Object System.Net.NetworkCredential($ftpUsername, $ftpPassword)
    $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile

    # Téléchargement
    $response = $ftpRequest.GetResponse()
    $responseStream = $response.GetResponseStream()
    $fileStream = New-Object IO.FileStream($localFilePath, [IO.FileMode]::Create)

    [byte[]]$buffer = New-Object byte[] 4096
    while (($readBytes = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $fileStream.Write($buffer, 0, $readBytes)
    }

    $fileStream.Close()
    $responseStream.Close()
    $response.Close()

    Write-Host "Téléchargement terminé avec succès."
} catch {
    $errorMessage = "$_"
    Write-Error "Erreur : $errorMessage"
    Send-ErrorEmail -errorMessage $errorMessage
}
