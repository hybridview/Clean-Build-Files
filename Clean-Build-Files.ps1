#
# NOTE: Might need to open an adminstrative ps prompt to clean files if VS solution was opened as ADMIN.
#
# VERSION: 20150220




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
    $targetFolder = (Get-Location -PSProvider FileSystem).ProviderPath
    $viewOnly=0

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
            -help {
                Clean-Build-Files-Show-Help
                exit
            }
        }
    }

    $ExcludeList = Get-Content -Path $excludeListFilePath | Select-Object
    #. $excludeListFilePath

    #
    # Display configuration options.
    #

    $CurrentPath = $targetFolder

    Write-Host
    Write-Host 'Exclusion List ('$ExcludeList.Count' found):' -foregroundcolor gray
    foreach($exclude in $ExcludeList){
		Write-Host '   ' $exclude -foregroundcolor gray
    }
    Write-Host

    Write-Host 'Removing files...' -foregroundcolor white
    #$_ -notmatch '_tools' -and $_ -notmatch '_build'
    # recursively get all folders matching given includes, except ignored folders

    $FoldersToRemove = Get-ChildItem $CurrentPath -include bin,obj -Recurse  | where {$_ -notmatch (
        '(' + [string]::Join(')|(', $ExcludeList) + ')') } | foreach {$_.fullname}


    # Some script code below based on: https://github.com/doblak/ps-clean/blob/master/DeleteObjBinFolders.ps1

    # recursively get all folders matching given includes
    $AllFolders = Get-ChildItem $CurrentPath -include bin,obj -Recurse | foreach {$_.fullname}

    # subtract arrays to calculate ignored ones
    $IgnoredFolders = $AllFolders | where {$FoldersToRemove -notcontains $_} 

    $ItemsRemovedCount = 0

    # remove folders and print to output
    if($FoldersToRemove -ne $null)
    {			
        Write-Host 
	    foreach ($item in $FoldersToRemove) 
	    { 
            Try
            {
                Write-Host "Removing: ." $item.replace($CurrentPath, "")  -nonewline; 
                if ($viewOnly -eq 0) {
                    remove-item $item -Force -Recurse -ea stop; # Instructs PS to generate terminating error if error occurs here. That way, we can use the try catch.
                }
                Write-Host " [Removed]" -foregroundcolor green;
                $ItemsRemovedCount++
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
		    Write-Host "Ignored: . " -foregroundcolor yellow -nonewline; 
		    Write-Host $item.replace($CurrentPath, ""); 
	    } 
	
	    Write-Host 
	    Write-Host $IgnoredFolders.count "folders ignored" -foregroundcolor yellow
    }

    # print summary of the operation
    Write-Host 
    if($FoldersToRemove -ne $null)
    {
	    Write-Host $ItemsRemovedCount "folders removed" -foregroundcolor green
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

