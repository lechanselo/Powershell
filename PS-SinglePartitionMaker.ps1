# Détection de la langue du système
$culture = (Get-Culture).Name
$isFrench = $culture -like "fr*"

# Fonction de traduction
function T($fr, $en) {
    if ($isFrench) { return $fr } else { return $en }
}

# Affichage des disques
Write-Host (T "Disques disponibles :" "Available disks:") -ForegroundColor Cyan
Get-Disk | Format-Table -AutoSize

# Demande du numéro de disque
$diskNumber = Read-Host (T "Entrez le numéro du disque à réinitialiser (ex: 1)" "Enter the disk number to reset (e.g., 1)")

# Vérification de l'existence du disque
$disk = Get-Disk -Number $diskNumber -ErrorAction SilentlyContinue
if (-not $disk) {
    Write-Host (T "❌ Disque introuvable. Script interrompu." "❌ Disk not found. Script aborted.") -ForegroundColor Red
    exit
}

# Affichage des partitions
Write-Host (T "`nPartitions actuelles du disque $diskNumber :" "`nCurrent partitions on disk $diskNumber:") -ForegroundColor Yellow
Get-Partition -DiskNumber $diskNumber | Format-Table -AutoSize

# Première confirmation
$confirm1 = Read-Host (T "⚠️ Toutes les partitions, y compris OEM, seront supprimées. Tapez OUI pour continuer." "⚠️ All partitions, including OEM, will be deleted. Type YES to continue.")
if ($confirm1 -ne (T "OUI" "YES")) {
    Write-Host (T "Opération annulée." "Operation cancelled.") -ForegroundColor Magenta
    exit
}

# Deuxième confirmation
$confirm2 = Read-Host (T "Confirmez une seconde fois en tapant SUPPRIMER." "Confirm again by typing DELETE.")
if ($confirm2 -ne (T "SUPPRIMER" "DELETE")) {
    Write-Host (T "Sécurité activée. Aucune action effectuée." "Safety triggered. No action performed.") -ForegroundColor Magenta
    exit
}

# Demande du nom du volume
$volumeLabel = Read-Host (T "Entrez le nom que vous souhaitez donner au disque (ex: Données)" "Enter the name you want to give to the disk (e.g., Data)")

# Nettoyage du disque (inclut OEM)
Clear-Disk -Number $diskNumber -RemoveData -RemoveOEM -Confirm:$false
Write-Host (T "✅ Disque nettoyé." "✅ Disk cleaned.") -ForegroundColor Green

# Initialisation du disque
Initialize-Disk -Number $diskNumber -PartitionStyle GPT
Write-Host (T "✅ Disque initialisé en GPT." "✅ Disk initialized as GPT.") -ForegroundColor Green

# Création de la partition
$newPartition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter
Write-Host (T "✅ Nouvelle partition créée." "✅ New partition created.") -ForegroundColor Green

# Formatage avec nom personnalisé
Format-Volume -Partition $newPartition -FileSystem NTFS -NewFileSystemLabel $volumeLabel
Write-Host (T "✅ Partition formatée en NTFS avec le nom '$volumeLabel'." "✅ Partition formatted as NTFS with label '$volumeLabel'.") -ForegroundColor Green

# Fin
Write-Host (T "`n🎉 Opération terminée avec succès !" "`n🎉 Operation completed successfully!") -ForegroundColor Cyan
