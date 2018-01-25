$global:LastEvent = ((Get-Date).AddSeconds(2).ToString('HH:mm:ss.fff'))
function global:Send-ChangesToWebroot{
	param(
	[string]$Path = "",
	[string]$OldPath = "",
	[bool]$Delete = $false
	)
	$extension = [IO.Path]::GetExtension($Path)
	$IsDirectory = $false
	if (Test-Path $Path){
		$IsDirectory= (Get-Item -Path $Path) -is [System.IO.DirectoryInfo]
	}elseif ($Delete -and $extension -eq [string]::Empty){
		$IsDirectory = $true;
	}
	try{
		if (-Not $IsDirectory -and $global:FileWatchActions.ContainsKey($extension)){
			$global:LastEvent = ((Get-Date).AddSeconds(2).ToString('HH:mm:ss.fff'))
			$global:FileWatchActions.Get_Item($extension).Invoke($Path, $OldPath, $Delete)
		}elseif ($IsDirectory){
			$global:LastEvent = ((Get-Date).AddSeconds(2).ToString('HH:mm:ss.fff'))
			$global:FileWatchActions.Get_Item("folder").Invoke($Path, $OldPath, $Delete)
		}
	}catch [System.Exception]{
		Write-Host "An error has occurred while attempting to run the processor for $extension" -ForegroundColor Red
		Write-Host "Path: $Path" -ForegroundColor Red
		Write-Host "OldPath: $OldPath" -ForegroundColor Red
		Write-Host $_.Exception.ToString() -ForegroundColor Red
	}
}
function Add-Watcher{
	param(
		$Directory
	)
	$Watcher = New-Object IO.FileSystemWatcher $Directory, "*" -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, DirectoryName, LastWrite, Size'}
	
	Register-ObjectEvent $Watcher Changed -SourceIdentifier "$Directory FileChanged" -Action {Send-ChangesToWebroot -Path $Event.SourceEventArgs.FullPath}
	
	Register-ObjectEvent $Watcher Renamed -SourceIdentifier "$Directory FileRenamed" -Action {Send-ChangesToWebroot -Path $Event.SourceEventArgs.FullPath -OldPath $Event.SourceEventArgs.OldFullPath}
	
	Register-ObjectEvent $Watcher Deleted -SourceIdentifier "$Directory FileDeleted" -Action {Send-ChangesToWebroot -Path $Event.SourceEventArgs.FullPath -Delete $true}
	
	Register-ObjectEvent $Watcher Created -SourceIdentifier "$Directory FileCreated" -Action {Send-ChangesToWebroot -Path $Event.SourceEventArgs.FullPath}
	
	$Watcher.EnableRaisingEvents = $true
}
Resolve-Path "$SourceDirectory/*/App_Config/Include" | ForEach-Object{
	Write-Host "Adding watch location: $_" -ForegroundColor Yellow
	Add-Watcher $_ | Out-Null
}

Resolve-Path "$SourceDirectory/*/Views" | ForEach-Object{
	Write-Host "Adding watch location: $_" -ForegroundColor Yellow	
	Add-Watcher $_ | Out-Null
}

Resolve-Path "$SourceDirectory/*/bin" | ForEach-Object{
	Write-Host "Adding watch location: $_" -ForegroundColor Yellow
	Add-Watcher $_ | Out-Null
}

Resolve-Path "$SourceDirectory/*/Assets" | ForEach-Object {
	Write-Host "Adding watch location: $_" -ForegroundColor Yellow
	Add-Watcher $_ | Out-Null
}

Write-Host ""
Write-Host "Now watching for changes made in the repo." -ForegroundColor Yellow
Write-Host "Any changes made will be delivered to the Webroot automatically" -ForegroundColor Yellow
Write-Host "***************************************************************" -ForegroundColor Yellow
while($true){
	#sleep more quickly when changes are happening
	if ($global:LastEvent -gt ((Get-Date).ToString('HH:mm:ss.fff'))){
		Start-Sleep -m 5
	}else{
		Start-Sleep 1
	}
}
