#
# NOTE: Might need to open an adminstrative ps prompt to clean files if VS solution was opened as ADMIN.
#
# VERSION: 20170221
#
# TODO: 
#   + Why was the 0 file get written to this directory before???
#   + IMPORTANT: Address issue as mentioned at this article! https://www.simple-talk.com/dotnet/net-framework/practical-powershell-pruning-file-trees-and-extending-cmdlets/
#   + When no args passed, prompt user for options. We still get quick launch when launching with args.
#   + Allow to customize folders via command arg as well as file.
#   + Still some strange errors for some folders about "length" cannot be found when using Measure-object, even after I test 
#     for it. Not sure how the error is possible. Doesn't seem to affect results, so will look later.

#. GetChildItemExtension.ps1



# PowerShell script that recursively deletes all 'bin' and 'obj' (or any other specified) folders inside current folder
function Clean-Build-Files($Values = $args)
{
    <#
    .SYNOPSIS
          This function cleans build files recusively starting from target path specified by user. To run without any 
          arguments, just place this script and the exclude list in the target directory you want to clean and run it.
    .OUTPUTS
          N/A
    .NOTES
        This should be made into a cmdlet...?
    .EXAMPLE
        powershell.exe D:\BTSync\!Projects\Common\Powershell\CleanBuildFiles\Clean-Build-Files.ps1 '-excludelistpath=D:\BTSync\!Projects\Common\Powershell\CleanBuildFiles\exclude-list.txt' '-targetfolder=D:\OssDevRoot\CleanBuildFiles_Testing'
    
        powershell.exe D:\BTSync\!Projects\Common\Powershell\CleanBuildFiles\Clean-Build-Files.ps1 '-excludelistpath=D:\BTSync\!Projects\Common\Powershell\CleanBuildFiles\exclude-list.txt' '-targetfolder=D:\OssDevRoot\hybridview\HomeGenie' -viewonly
   
    #>
	
    # Defaults in case user passes no args.
    $excludeListFilePath = "exclude-list.txt"
	$includeListFilePath = "include-list.txt"
    $targetFolder = (Get-Location -PSProvider FileSystem).ProviderPath
    $viewOnly=1

	#$includeFolderNameList = "bin,obj,node_modules"
	
    foreach($value in $Values){
		Write-Host $value
        $arrTmp = $value.Split("=")
        switch ($arrTmp[0].ToLower()) {
			-excludelistpath {
                $excludeListFilePath = $arrTmp[1]
            }
            -targetfolder {
                $targetFolder = $arrTmp[1]
            }
            -viewonly {
                $viewOnly=1
            }
			-includelistpath {
                $includeListFilePath = $arrTmp[1]
            }
            -help {
                Clean-Build-Files-Show-Help
                exit
            }
        }
    }
	
	if ($viewOnly -eq 1) {
       Write-Host ' ! Running in VIEW ONLY mode. No files will be deleted!' -foregroundcolor yellow
    }
				
	if (Test-Path $includeListFilePath) 
	{
		$IncludeList = Get-Content -Path $includeListFilePath | Select-Object
	} else {
		$IncludeList = @("bin","obj")
		Write-Host "No include list file located. Using defaults."
	}
	
	if (Test-Path $excludeListFilePath) 
	{
		$ExcludeList = Get-Content -Path $excludeListFilePath | Select-Object
	} else {
		$ExcludeList = @()
		Write-Host "No exclude list file located. Using defaults."
	}
	
    
	
    #
    # Display configuration options.
    #

    $CurrentPath = $targetFolder

	Write-Host
    Write-Host 'Inclusion List ('$IncludeList.Count' found):' -foregroundcolor gray
    foreach($include in $IncludeList){
		Write-Host '   ' $include -foregroundcolor green
    }

    Write-Host 'Exclusion List ('$ExcludeList.Count' found):' -foregroundcolor gray
    foreach($exclude in $ExcludeList){
		Write-Host '   ' $exclude -foregroundcolor gray
    }
    Write-Host
	Write-Host
	
    Write-Host 'Removing files...' -foregroundcolor white
    #$_ -notmatch '_tools' -and $_ -notmatch '_build'
    # recursively get all folders matching given includes, except ignored folders
	$ObjFoldersToRemove = Get-ChildItem $CurrentPath -include $IncludeList -Recurse
	if ($ExcludeList.Count -gt 0) 
	{
		$ObjFoldersToRemove = $ObjFoldersToRemove | where {$_ -notmatch (
			'(' + [string]::Join(')|(', $ExcludeList) + ')') }
	}
	#$ObjFoldersToRemove = Get-ChildItem $CurrentPath -include "$includeFolderNameList" -Recurse | where {$_ -notmatch (
    #    '(' + [string]::Join(')|(', $ExcludeList) + ')') }
	
    $FoldersToRemove = $ObjFoldersToRemove | foreach {$_.fullname}


    # Some script code below based on: https://github.com/doblak/ps-clean/blob/master/DeleteObjBinFolders.ps1

    # recursively get all folders matching given includes
    $AllFoldersObj = Get-ChildItem $CurrentPath -include $IncludeList -Recurse 
	$AllFolders = $AllFoldersObj | foreach {$_.fullname}
    # subtract arrays to calculate ignored ones
    $IgnoredFolders = $AllFolders | where {$FoldersToRemove -notcontains $_} 

    $ItemsRemovedCount = 0
	$TotalSpaceKbCleared = 0
	#$TotalSpaceMbCleared = ($AllFoldersObj | Measure-Object -Sum length)
	

	if($ObjFoldersToRemove -ne $null)
    {			
        Write-Host 
	    foreach ($objitem in $ObjFoldersToRemove) 
	    { 
            Try
            {
				$item = $objitem.fullname
				$temp = Get-ChildItem $item -Recurse -Force
				
				$sizeBytes = 0
				#$hasProp = [bool]($temp.PSobject.Properties.name -match "length")
				$hasProp = [bool]($temp.PSobject.Properties.Name -contains "length")
				if ($hasProp) #$temp -ne $null)
				{
					if ($temp.length -ne $null) {
						$sizeObj = $temp | Measure-Object -property length -sum
						$sizeBytes = $sizeObj.Sum
					}
				}
				
				$sizeKBytes = [math]::Round($sizeBytes / 1024)
				
                Write-Host "Removing: " $item.replace($CurrentPath, "") -nonewline; 
				
                if ($viewOnly -eq 0) {
                    remove-item $item -Force -Recurse -ea stop; # Instructs PS to generate terminating error if error occurs here. That way, we can use the try catch.
                }
                Write-Host " [Removed $sizeKBytes KB]" -foregroundcolor green;
				#Write-Host $sizeKBytes -foregroundcolor green -nonewline; 
				#Write-Host " KB]" -foregroundcolor green;
				 
                $ItemsRemovedCount++
				$TotalSpaceKbCleared += $sizeKBytes
				
				#$directory | Get-ChildItem |
				#  Measure-Object -Sum Length | Select-Object `
				#	@{Name=”Path”; Expression={$directory.FullName}},
				#	@{Name=”Files”; Expression={$_.Count}},
				#	@{Name=”Size”; Expression={$_.Sum}}
            }
            Catch [system.exception]
            {
                write-host 'ERROR:' $_.Exception.Message -foregroundcolor red
            }
            Finally
            {
                #"end of action"
            }
		    #Write-Host $item.replace($CurrentPath, ""); 
	    } 
    }

	
    # print ignored folders	to output
    if($IgnoredFolders -ne $null)
    {
        Write-Host 
	    foreach ($item in $IgnoredFolders) 
	    { 
		    Write-Host "Ignored: " -foregroundcolor yellow -nonewline; 
		    Write-Host $item.replace($CurrentPath, ""); 
	    } 
	
	    Write-Host 
	    Write-Host $IgnoredFolders.count "folders ignored" -foregroundcolor yellow
    }

    # print summary of the operation
    Write-Host 
    if($FoldersToRemove -ne $null)
    {
	    Write-Host $ItemsRemovedCount "folders removed ($TotalSpaceKbCleared KB)" -foregroundcolor green
	    #Write-Host $FoldersToRemove.count-$ItemsRemovedCount "folders removed" -foregroundcolor green
    }
    else { 	Write-Host "No folders to remove" -foregroundcolor green }	

    Write-Host 

    # prevent closing the window immediately
    $dummy = Read-Host "Completed, press enter to continue."
}



function Clean-Build-Files-Show-Help()
{
    Write-Host
    Write-Host "Clean-Build-Files HELP" -foregroundcolor white
    Write-Host "Cleans build files recusively starting from target path specified by user. To run without any arguments, just place this script and the exclude list in the target directory you want to clean and run it." -foregroundcolor white
	Write-Host
    Write-Host "NOTE: Exclusion list file entries should be seperated by line break (1 on each line)." -foregroundcolor white
    Write-Host
    Write-Host "EXAMPLE" -foregroundcolor white
    Write-Host " powershell.exe Clean-Build-Files.ps1 '-excludelistpath=<PathToExcludeListFile>' '-targetfolder=<FolderToClean>'" -foregroundcolor yellow
    Write-Host


}


# Run the function.
Clean-Build-Files $args


# Original ABM code below for old examples.
# This will delete all BIN folders.
# Get-ChildItem .\ -include bin,obj -Recurse | foreach ($_) { remove-item $_.fullname -Force -Recurse }
# get-childitem -rec | where {($_.PSIsContainer -eq $true) -and ($_.name -like "bin*")} | foreach ($_) {remove-item $_.fullname -recurse -force }

