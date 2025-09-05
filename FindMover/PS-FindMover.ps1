# Détection de la langue de l'OS
$culture = (Get-Culture).TwoLetterISOLanguageName
$Lang = if ($culture -eq 'fr') { 'FR' } else { 'EN' }

# Messages multilingues
$Messages = @{
    'FR' = @{
        StartTitle = "=== Déplacement de fichiers/répertoires ==="
        EnterNames = "Entrez les noms à rechercher (fichier ou dossier)."
        QuitInfo   = "Tapez 'Q' ou 'q' pour terminer la saisie.`n"
        PromptName = "Nom à rechercher"
        Searching  = "Recherche de"
        SimSummary = "=== Simulation ==="
        FilesFound = "Fichiers trouvés"
        DirsFound  = "Répertoires trouvés"
        TotalSize  = "Taille totale"
        UnitBytes  = "octets"
        Confirm    = "Souhaitez-vous effectuer le déplacement ? (O/N)"
        Moved      = "Déplacé"
        Done       = "=== Opération terminée ==="
        ResultIn   = "Les éléments trouvés ont été déplacés dans"
        CannotMove = "Impossible de déplacer"
        DestFolder = "Resultat_Deplacement"
    }
    'EN' = @{
        StartTitle = "=== Moving files/directories ==="
        EnterNames = "Enter the names to search for (file or folder)."
        QuitInfo   = "Type 'Q' or 'q' to finish input.`n"
        PromptName = "Name to search"
        Searching  = "Searching for"
        SimSummary = "=== Simulation ==="
        FilesFound = "Files found"
        DirsFound  = "Directories found"
        TotalSize  = "Total size"
        UnitBytes  = "bytes"
        Confirm    = "Do you want to proceed with the move? (Y/N)"
        Moved      = "Moved"
        Done       = "=== Operation completed ==="
        ResultIn   = "The found items have been moved to"
        CannotMove = "Unable to move"
        DestFolder = "Move_Result"
    }
}

# Définir le répertoire racine (là où se trouve le script)
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DestinationRoot = Join-Path $ScriptRoot $Messages[$Lang].DestFolder

# Créer le dossier de destination s'il n'existe pas
if (-not (Test-Path $DestinationRoot)) {
    New-Item -Path $DestinationRoot -ItemType Directory | Out-Null
}

# Liste pour stocker les noms à rechercher
$SearchNames = @()

Write-Host $Messages[$Lang].StartTitle
Write-Host $Messages[$Lang].EnterNames
Write-Host $Messages[$Lang].QuitInfo

# Boucle de saisie
while ($true) {
    $inputName = Read-Host $Messages[$Lang].PromptName
    if ($inputName -match '^[Qq]$') { break }
    if (-not [string]::IsNullOrWhiteSpace($inputName)) {
        $SearchNames += $inputName
    }
}

# Simulation : collecte des éléments
$AllItems = @()

foreach ($name in $SearchNames) {
    Write-Host "`n$($Messages[$Lang].Searching) : $name"
    
    $found = Get-ChildItem -Path $ScriptRoot -Recurse -Force -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -ieq $name }

    $AllItems += $found
}

# Calculs de simulation
$FileCount = ($AllItems | Where-Object { -not $_.PSIsContainer }).Count
$DirCount  = ($AllItems | Where-Object { $_.PSIsContainer }).Count
$TotalSize = ($AllItems | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum

# Affichage simulation
Write-Host "`n$($Messages[$Lang].SimSummary)"
Write-Host "$($Messages[$Lang].FilesFound) : $FileCount"
Write-Host "$($Messages[$Lang].DirsFound) : $DirCount"
Write-Host ("{0} : {1:N0} {2}" -f $Messages[$Lang].TotalSize, $TotalSize, $Messages[$Lang].UnitBytes)

# Confirmation utilisateur
$confirm = Read-Host "`n$($Messages[$Lang].Confirm)"
if (($Lang -eq 'FR' -and $confirm -notmatch '^[Oo]$') -or ($Lang -eq 'EN' -and $confirm -notmatch '^[Yy]$')) {
    Write-Host "`nOpération annulée."
    return
}

# Déplacement réel
foreach ($item in $AllItems) {
    $relativePath = $item.FullName.Substring($ScriptRoot.Length).TrimStart('\')
    $destPath = Join-Path $DestinationRoot $relativePath
    $destDir = Split-Path $destPath -Parent

    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }

    try {
        Move-Item -Path $item.FullName -Destination $destPath -Force
        Write-Host "$($Messages[$Lang].Moved) : $relativePath"
    }
    catch {
        Write-Warning "$($Messages[$Lang].CannotMove) : $($item.FullName) — $_"
    }
}

Write-Host "`n$($Messages[$Lang].Done)"
Write-Host "$($Messages[$Lang].ResultIn) : $DestinationRoot"
