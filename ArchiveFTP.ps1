# Paramètres
$ftpServer = "10.10.121.32"
$ftpUsername = "cyber"
$ftpPassword = "P@ssw0rd"
$remoteFilePath = "/test.tar.gz"
$localFilePath = "C:\FTP\archive.tar.gz"
$localDirectory = [System.IO.Path]::GetDirectoryName($localFilePath)
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

# Vérification de l'existence du répertoire local
try {
    if (-Not (Test-Path -Path $localDirectory -PathType Container)) {
        # Création du répertoire s'il n'existe pas
        New-Item -ItemType Directory -Path $localDirectory -Force | Out-Null
        Write-Host "Le répertoire $localDirectory a été créé."
    } else {
        Write-Host "Le répertoire $localDirectory existe déjà."
    }
} catch {
    $errorMessage = "Erreur lors de la vérification ou de la création du répertoire local : $_"
    Write-Error $errorMessage
    Send-ErrorEmail -errorMessage $errorMessage
    exit 1
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
    $errorMessage = "Erreur lors du téléchargement de l'archive : $_"
    Write-Error $errorMessage
    Send-ErrorEmail -errorMessage $errorMessage
}
