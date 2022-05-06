$CLASSES_DIR = '.\classes'
$SLOTS_DIR   = '.\slots'
$TODO_DIR    = '.\todo'
$LOG         = '.\log.txt'

$classList = (Get-Item -Path $CLASSES_DIR\*)
foreach ($class in $classList) {
	if (-not ($class -like '*\_*.ps1')) {
		Remove-Item $class -Force | Out-Null
	}
}
Remove-Item $SLOTS_DIR -Recurse -Force | Out-Null
Remove-Item $LOG -Force | Out-Null
$todoList = (Get-Item -Path $TODO_DIR\*)
foreach ($todo in $todoList) {
	if ($todo -like '* _auto') {
		Remove-Item $todo -Force | Out-Null
	}
}