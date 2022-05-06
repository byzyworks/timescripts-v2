[string] $DATETIME_FORMAT   = '%Y/%m/%d %H:%M:%S'
[string] $ADD               = '.\add.ps1'
[string] $LOG               = '.\log.txt'
[string] $TODO_DIR          = '.\todo'
[string] $SOUNDS_DIR        = '.\sounds'
[string] $WALLPAPERS_DIR    = '.\wallpapers'
[string] $NO_REPEATERS      = 'NeverRepeat'
[string] $NO_STOP           = 'RepeatForever'
[string] $NO_WEEKDAY        = 'AnyWeekday'
[string] $NO_EXPIRE         = 'NeverExpire'
[string] $EXPIRE_NEXT       = 'NextRepeat'
[string] $NO_MESSAGE        = 'NoMessage'
[string] $DEFAULT_SOUND     = '<Class>'
[string] $DEFAULT_WALLPAPER = '<Class>'
[int]    $URG_HIDDEN        = 0
[int]    $URG_LOW           = 1
[int]    $URG_MEDIUM        = 2
[int]    $URG_HIGH          = 3
[int]    $PRI_NO_PERSIST    = -1
[int]    $PRI_LOG_ONLY      = 0
[int]    $TODO_ONCE         = 0
[int]    $TODO_DECREMENT    = 1
[int]    $TODO_INCREMENT    = 2

[string]      $currentDatetime = ''
[int]         $currentId       = 0
[string]      $slotDatetime    = ''
[hashtable[]] $repeaterPairs   = @()
[string[]]    $nextEpochs      = @()
[string]      $nextDatetime    = ''
[int]         $nextId          = 0
[string]      $stopDatetime    = ''
[int]         $stopId          = 0
[string]      $weekday         = ''
[double]      $random          = 0.0
[int]         $expirationId    = 0
[string]      $fullMessage     = ''
[string]      $soundFile       = ''
[string]      $wallpaperFile   = ''

$currentDatetime = (Get-Date -UFormat "$DATETIME_FORMAT")
$currentId       = (Get-Date $currentDatetime -UFormat '%s' -Millisecond 0)

for ($i = 0; $i -lt $Epochs.length; $i++) {
	$Epochs[$i] = (Get-Date $Epochs[$i] -UFormat $DATETIME_FORMAT)
}
$slotDatetime = $Epochs[($Epochs.length - 1)]

if ($Repeaters[0] -ne $NO_REPEATERS) {
	foreach ($repeater in $Repeaters) {
		$repeaterSplit = $repeater -split ','
		$repeaterPairs += @{ 'Wait' = $repeaterSplit[0]; `
							 'Stop' = $repeaterSplit[1]  }
	}

	$nextEpochs = $Epochs.Clone()
	for ($i = $Epochs.length; $i -lt $repeaterPairs.length; $i++) {
		$nextEpochs += $Epochs[($Epochs.length - 1)]
	}

	for ($i = ($nextEpochs.length - 1); $i -ge 0; $i--) {
		$nextDatetime = (Invoke-Expression "Get-Date (Get-Date `"$($nextEpochs[$i])`").$($repeaterPairs[$i]['Wait']) -UFormat `"$DATETIME_FORMAT`"")
		$nextId       = (Get-Date $nextDatetime -UFormat '%s' -Millisecond 0)
		if ($repeaterPairs[$i]['Stop'] -ne $NO_STOP) {
			if ($i -eq 0) {
				$repeaterPairs[0]['Stop'] = (Get-Date $repeaterPairs[0]['Stop'] -UFormat $DATETIME_FORMAT)
				$stopDatetime = $repeaterPairs[0]['Stop']
			} else {
				$stopDatetime = (Invoke-Expression "Get-Date (Get-Date `"$($nextEpochs[($i - 1)])`").$($repeaterPairs[$i]['Stop']) -UFormat `"$DATETIME_FORMAT`"")
			}
			$stopId = (Get-Date $stopDatetime -UFormat '%s' -Millisecond 0)
			if ($nextId -ge $stopId) {
				continue
			}
		}
		for ($j = $i; $j -lt $nextEpochs.length; $j++) {
			$nextEpochs[$j] = "$nextDatetime"
		}
		& $ADD -Epochs $nextEpochs -Class $Class -ArgumentOverride $ArgumentOverride
		break
	}
}

if (-not ($Enabled)) {
	exit
}

if ($RequiredWeekdays[0] -ne $NO_WEEKDAY) {
	$weekday = (Get-Date $slotDatetime -UFormat '%A')
	$pass    = $false
	foreach ($requiredWeekday in $RequiredWeekdays) {
		if ($weekday -eq $requiredWeekday) {
			$pass = $true
			break
		}
	}
	if (-not ($pass)) {
		exit
	}
}

if ($RandomMaximum -gt 1) {
	$random = (Get-Random -Minimum 0 -Maximum $RandomMaximum)
	if ($random -lt $RandomThreshold) {
		exit
	}
}

if ($ExpirationDatetime -ne $NO_EXPIRE) {
	if ($ExpirationDatetime -eq $EXPIRE_NEXT) {
		$ExpirationDatetime = $repeaterPairs[($repeaterPairs.length - 1)]['Wait']
	}
	if ($ExpirationEpoch -eq 0) {
		$ExpirationDatetime = (Get-Date $ExpirationDatetime -UFormat $DATETIME_FORMAT)
	} else {
		if ($ExpirationEpoch -eq -1) {
			$ExpirationEpoch = $Epochs.length
		}
		$ExpirationDatetime = (Invoke-Expression "Get-Date (Get-Date `"$($Epochs[($ExpirationEpoch - 1)])`").$ExpirationDatetime -UFormat `"$DATETIME_FORMAT`"")
	}
	$expirationId = (Get-Date $ExpirationDatetime -UFormat '%s' -Millisecond 0)
	if ($currentId -ge $expirationId) {
		exit
	}
}

if ($Sound -ne $DEFAULT_SOUND) {
	$soundFile = "$SOUNDS_DIR\$Sound.mp3"
} else {
	$soundFile = "$SOUNDS_DIR\$Class.mp3"
}
if (Test-Path $soundFile) {
	& 'C:\Program Files\VideoLAN\VLC\vlc.exe' -I null --play-and-exit --no-repeat $soundFile
}

if ($Wallpaper -ne $DEFAULT_WALLPAPER) {
	$wallpaperFile = "$WALLPAPERS_DIR\$Wallpaper.jpg"
} else {
	$wallpaperFile = "$WALLPAPERS_DIR\$Class.jpg"
}
if (Test-Path $wallpaperFile) {
	& 'C:\Users\jellisv\SetWallpaper.exe' $wallpaperFile | Out-Null
}

if ($Message -ne $NO_MESSAGE) {
	$fullMessage = "Sent     @ $slotDatetime | $Message`r`nReceived @ $currentDatetime |`r`n-------------------------------+"

	if ($Urgency -ge $URG_LOW) {
		Write-Host $fullMessage
		if ($Urgency -ge $URG_MEDIUM) {
			Add-Type -AssemblyName System.Windows.Forms
			$script:balloon = New-Object System.Windows.Forms.NotifyIcon
			$path = (Get-Process -id $pid).Path
			$balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
			$balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::None
			$balloon.BalloonTipText = $Message
			$balloon.BalloonTipTitle = 'Time Manager'
			$balloon.Visible = $true
			$balloon.ShowBalloonTip(5000)
			$script:balloon.Dispose()
			if ($Urgency -ge $URG_HIGH) {
				[System.Windows.Forms.MessageBox]::Show("$Message", 'Time Manager', 'OK', 'None') | Out-Null
			}
		}
	}

	if ($Priority -gt $PRI_NO_PERSIST) {
		Add-Content $LOG -Value $fullMessage -Encoding 'UTF8'
		if ($Priority -gt $PRI_LOG_ONLY) {
			if ($TodoRepeating -eq $TODO_ONCE) {
				if (-not (Test-Path "$TODO_DIR\($Priority) $Message _auto")) {
					Out-File "$TODO_DIR\($Priority) $Message _auto" | Out-Null
				}
			} elseif ($TodoRepeating -eq $TODO_DECREMENT) {
				$new = $true
				for ($i = $Priority; $i -gt 0; $i--) {
					if (Test-Path "$TODO_DIR\($i) $Message _auto") {
						if ($i -gt 1) {
							Rename-Item "$TODO_DIR\($i) $Message _auto" "($($i - 1)) $Message _auto"
						}
						$new = $false
						break
					}
				}
				if ($new) {
					Out-File "$TODO_DIR\($Priority) $Message _auto" | Out-Null
				}
			} elseif ($TodoRepeating -eq $TODO_INCREMENT) {
				$delays = 1
				while (Test-Path "$TODO_DIR\($Priority) $Message ($delays) _auto") {
					$delays++
				}
				Out-File "$TODO_DIR\($Priority) $Message ($delays) _auto" | Out-Null
			}
		}
	}
}