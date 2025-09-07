if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host (T "❌ Ce script doit être exécuté en tant qu'administrateur." "❌ This script must be run as administrator.") -ForegroundColor Red
    exit
}

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
do{
    $input = Read-Host (T "Entrez le numéro du disque à réinitialiser (ex: 1)" "Enter the disk number to reset (e.g., 1)")
} while (-not [int]::TryParse($input, [ref]$diskNumber))

# Vérification de l'existence du disque
$disk = Get-Disk -Number $diskNumber -ErrorAction SilentlyContinue
if (-not $disk) {
    Write-Error (T "❌ Disque introuvable. Script interrompu." "❌ Disk not found. Script aborted.") -ForegroundColor Red
    exit
}

if ($disk.IsBoot -or $disk.IsSystem) {
    Write-Error (T "❌ Impossible de réinitialiser le disque système." "❌ Cannot reset system disk.") -ForegroundColor Red
    exit
}

# Affichage des partitions
Write-Host (T "`nPartitions actuelles du disque $diskNumber :" "`nCurrent partitions on disk ${diskNumber}:") -ForegroundColor Yellow
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
try {
    Clear-Disk -Number $diskNumber -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
} catch {
    Write-Error (T "❌ Échec du nettoyage du disque : $_" "❌ Failed to clean disk: $_") -ForegroundColor Red
    exit
}
Write-Host (T "✅ Disque nettoyé." "✅ Disk cleaned.") -ForegroundColor Green

# Initialisation du disque
try {
    Initialize-Disk -Number $diskNumber -PartitionStyle GPT
} catch {
    Write-Error (T "❌ Échec de l'initialisation du disque : $_" "❌ Failed to initialize disk: $_") -ForegroundColor Red
    exit
}
Write-Host (T "✅ Disque initialisé en GPT." "✅ Disk initialized as GPT.") -ForegroundColor Green

# Création de la partition
try {
    $newPartition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter
} catch {
    Write-Error (T "❌ Échec de la création de la partition : $_" "❌ Failed to create partition: $_") -ForegroundColor Red
    exit
}
Write-Host (T "✅ Nouvelle partition créée." "✅ New partition created.") -ForegroundColor Green

# Formatage avec nom personnalisé
try {
    Format-Volume -Partition $newPartition -FileSystem NTFS -NewFileSystemLabel $volumeLabel
} catch {
    Write-Error (T "❌ Échec du formation NTFS de la partition : $_" "❌ Failed to format partition as NTFS $_") -ForegroundColor Red
    exit
}
Write-Host (T "✅ Partition formatée en NTFS avec le nom '$volumeLabel'." "✅ Partition formatted as NTFS with label '$volumeLabel'.") -ForegroundColor Green

# Vérifier que le volume est bien monté après formatage
$volume = Get-Volume -FileSystemLabel $volumeLabel
if (-not $volume) {
    Write-Host (T "⚠️ Le volume n'a pas été monté correctement." "⚠️ Volume was not mounted correctly.") -ForegroundColor Yellow
}

# Fin
Write-Host (T "`n🎉 Opération terminée avec succès !" "`n🎉 Operation completed successfully!") -ForegroundColor Cyan
Read-Host "Appuyez sur Entrée pour quitter"
