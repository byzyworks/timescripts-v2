param (
	[string[]]         $Epochs            ,
	[string]           $ParentClass       ,
	[string]           $Class             ,
	[Nullable[bool]]   $Enabled           ,
	[string[]]         $Repeaters         ,
	[string[]]         $RequiredWeekdays  ,
	[Nullable[double]] $RandomMaximum     ,
	[Nullable[double]] $RandomThreshold   ,
	[string]           $ExpirationDatetime,
	[Nullable[int]]    $ExpirationEpoch   ,
	[string]           $Message           ,
	[Nullable[int]]    $Urgency           ,
	[Nullable[int]]    $Priority          ,
	[Nullable[int]]    $TodoRepeating     ,
	[string]           $Sound             ,
	[string]           $Wallpaper         ,
	[string[]]         $Commands          ,
	[string]           $ArgumentOverride
)

[string] $DATETIME_FORMAT = '%Y-%m-%d_%H-%M-%S'
[string] $MASTER          = '.\act.ps1'
[string] $CLASSES_DIR     = '.\classes'
[string] $SLOTS_DIR       = '.\slots'
[string] $DEFAULT_CLASS   = '_default'
[string] $EMPTY_OVERRIDE  = 'Empty'

[string] $parentClassScript        = ''
[string] $classScript              = ''
[string] $slotDatetime             = ''
[int]    $slotId                   = 0
[string] $slotScript               = ''
[string] $varContent               = ''
[string] $extContent               = ''
[string] $classContent             = ''
[string] $slotContent              = ''
[bool]   $classMode                = $false

if ($Epochs -eq $null) {
	$classMode = $true
}
if ($ParentClass -eq '') {
	$ParentClass = $DEFAULT_CLASS
}
if ($Class -eq '') {
	$Class = $DEFAULT_CLASS
}
if ($ArgumentOverride -eq '') {
	if ($Enabled -ne $null) {
		$varContent += "[bool] `$global:Enabled = `$$Enabled`r`n"
	}
	if ($Repeaters -ne $null) {
		$varContent += "[string[]] `$global:Repeaters = '$($Repeaters -join ''',''')'`r`n"
	}
	if ($RequiredWeekdays -ne $null) {
		$varContent += "[string[]] `$global:RequiredWeekdays = '$($RequiredWeekdays -join ''',''')'`r`n"
	}
	if ($RandomMaximum -ne $null) {
		$varContent += "[float] `$global:RandomMaximum = $RandomMaximum`r`n"
	}
	if ($RandomThreshold -ne $null) {
		$varContent += "[float] `$global:RandomThreshold = $RandomThreshold`r`n"
	}
	if ($ExpirationDatetime -ne '') {
		$varContent += "[string] `$global:ExpirationDatetime = '$ExpirationDatetime'`r`n"
	}
	if ($ExpirationEpoch -ne $null) {
		$varContent += "[int] `$global:ExpirationEpoch = $ExpirationEpoch`r`n"
	}
	if ($Message -ne '') {
		$varContent += "[string] `$global:Message = '$Message'`r`n"
	}
	if ($Urgency -ne $null) {
		$varContent += "[int] `$global:Urgency = $Urgency`r`n"
	}
	if ($Priority -ne $null) {
		$varContent += "[int] `$global:Priority = $Priority`r`n"
	}
	if ($TodoRepeating -ne $null) {
		$varContent += "[int] `$global:TodoRepeating = $TodoRepeating`r`n"
	}
	if ($Sound -ne '') {
		$varContent += "[string] `$global:Sound = '$Sound'`r`n"
	}
	if ($Wallpaper -ne '') {
		$varContent += "[string] `$global:Wallpaper = '$Wallpaper'`r`n"
	}
	if ($Commands -ne $null) {
		for ($i = 0; $i -lt $Commands.length; $i++) {
			$extContent += "$($Commands[$i])`r`n"
		}
	}
}

$parentClassScript = "$CLASSES_DIR\$ParentClass.ps1"
$classScript       = "$CLASSES_DIR\$Class.ps1"
if ($classMode) {
	if (-not (Test-Path $classScript)) {
		$classContent += "& $parentClassScript`r`n"
		if ($ArgumentOverride -eq '') {
			$classContent += $varContent
			$classContent += $extContent
		} else {
			$classContent += $ArgumentOverride
		}
		Set-Content $classScript -Value $classContent -Encoding 'UTF8' -NoNewLine
	}
} else {
	$slotContent += "& $classScript`r`n"
	$slotContent += "[string[]] `$global:Epochs = '$($Epochs -join ''',''')'`r`n"
	$slotContent += "[string] `$global:Class = '$Class'`r`n"
	if ($ArgumentOverride -eq '') {
		$slotContent += $varContent
		$slotContent += $extContent
		if (($varContent -ne '') -or ($extContent -ne '')) {
			$slotContent += "[string] `$global:ArgumentOverride = @'`r`n$varContent$extContent`r`n'@`r`n"
		} else {
			$slotContent += "[string] `$global:ArgumentOverride = @'`r`n$EMPTY_OVERRIDE`r`n'@`r`n"
		}
	} else {
		if ($ArgumentOverride -ne $EMPTY_OVERRIDE) {
			$slotContent += $ArgumentOverride
		}
		$slotContent += "[string] `$global:ArgumentOverride = @'`r`n$ArgumentOverride`r`n'@`r`n"
	}
	$slotContent += "& $MASTER`r`n"
	$slotId       = (Get-Date $Epochs[($Epochs.length - 1)] -UFormat '%s' -Millisecond 0)
	$slotDatetime = (Get-Date $Epochs[($Epochs.length - 1)] -UFormat $DATETIME_FORMAT)
	$slotScript   = "$SLOTS_DIR\$slotId $slotDatetime.ps1"
	Add-Content $slotScript -Value $slotContent -Encoding 'UTF8' -NoNewLine
}