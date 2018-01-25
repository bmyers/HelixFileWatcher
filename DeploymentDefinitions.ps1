$global:FileWatchActions = @{}
function Get-ProjectRoot{
	param(
		[string]$Path
	)
	if ($path -eq [string]::Empty){
		return [string]::Empty
	}
	if (-Not (Test-Path $Path)){
		return Get-ProjectRoot -Path (split-Path $Path)
	}
	$PathItem = Get-Item -Path $Path
	if (-Not ($PathItem -is [System.IO.DirectoryInfo])){
		return Get-ProjectRoot -Path (Split-Path $Path)
	}
	if ((resolve-path "$Path\*.csproj").Count -gt 0){
		return $Path
	}elseif($PathItem.Parent -ne $null){
		return Get-ProjectRoot -Path $PathItem.Parent.FullName
	}
	return ""
}
function Copy-ItemToWebroot{
	param(
		$Path,
		$OldPath,
		$Delete,
		$Index,
		$IntermediatePath
	)
	if ($Index -lt 0){
		return
	}
	
	$TargetPath = $DeployTargetWebPath + $IntermediatePath + $Path.Substring($Index)
	if ($Delete -and (Test-Path $TargetPath)){
		write-host "Removing file $TargetPath" -ForegroundColor Red
		Remove-Item $TargetPath -Force -Recurse
	}elseif (-Not (Test-Path $Path) -and (Test-Path $TargetPath)){
		write-host "Removing file $TargetPath" -ForegroundColor Red
		Remove-Item $TargetPath -Force -Recurse
	}elseif(Test-Path $Path){
		if ($OldPath -ne ""){
			$OldTargetPath = $DeployTargetWebPath + $IntermediatePath + $OldPath.Substring($Index)
			if ((Test-Path $OldTargetPath) -and ((Split-Path $Path) -eq (Split-Path $OldPath) )){
				$newName = Split-Path $Path -Leaf -Resolve
				write-host "Renaming Item" -ForegroundColor Yellow
				write-host "    $OldTargetPath" -ForegroundColor Yellow
				write-host "    =>$TargetPath" -ForegroundColor Yellow
				Rename-Item $OldTargetPath $newName -Force
				return
			}
		}
		if (-Not (Test-Path $TargetPath) -or (Compare-Object (ls $Path) (ls $TargetPath) -Property Name, Length, LastWriteTime)){
			write-host "Copying Item" -ForegroundColor Green
			write-host "    $Path" -ForegroundColor Green
			write-host "    =>$TargetPath" -ForegroundColor Green
			New-Item -Path "$(Split-Path $TargetPath)" -ItemType Directory -Force
			Copy-Item -Path $Path -Destination $TargetPath -Recurse -Force
		}
	}
}

#Add watcher action configurations
#Based on extension define how to process the files that are changed
$global:FileWatchActions.Add(".cshtml", {
	param(
		$Path,
		$OldPath,
		$Delete
	)
	$index = $Path.IndexOf("\Views", 5)
	Copy-ItemToWebroot -Path $Path -OldPath $OldPath -Delete $Delete -Index $index -IntermediatePath "\Areas\Demo"
} )

$global:FileWatchActions.Add(".config", {
	param(
		$Path,
		$OldPath,
		$Delete
	)
	$index = $Path.IndexOf("\App_Config\Include", 5)
	Copy-ItemToWebroot -Path $Path -OldPath $OldPath -Delete $Delete -Index $index
	if ($index -eq -1){
		$fileName = Split-Path $Path -Leaf
		$FileDirectory = Get-ProjectRoot -Path $Path
		if ($fileName.StartsWith("web", "CurrentCultureIgnoreCase")){
			Copy-ItemToWebroot -Path $Path -OldPath $OldPath -Delete $Delete -Index $FileDirectory.Length -IntermediatePath "\Areas\Demo"		
		}
	}
} )

$global:FileWatchActions.Add(".dll", {
	param(
		$Path,
		$OldPath,
		$Delete
	)
	$index = $Path.IndexOf("\bin", 5)
	Copy-ItemToWebroot -Path $Path -OldPath $OldPath -Delete $Delete -Index $index	
} )

$global:FileWatchActions.Add("folder", {
	param(
		$Path,
		$OldPath,
		$Delete
	)
	if (-Not( $delete -or $OldPath -ne [string]::Empty)){
		return
	}
	$index = $Path.IndexOf("\Views", 5)
	if ($index -ne -1){
		Copy-ItemToWebroot -Path $Path -OldPath $OldPath -Delete $Delete -Index $index -IntermediatePath "\Areas\Demo"
		return		
	}
	$index = $Path.IndexOf("\App_Config\Include", 5)
	if ($index -ne -1){
		Copy-ItemToWebroot -Path $Path -OldPath $OldPath -Delete $Delete -Index $index -IntermediatePath "\App_Config\Include"
		return		
	}
})
