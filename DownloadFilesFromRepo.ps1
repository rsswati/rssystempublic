function DownloadFilesFromRepo {
    Param(
            [Parameter(Mandatory=$True)]
            [string]$User,
    
            [Parameter(Mandatory=$True)]
            [string]$Token,
    
            [Parameter(Mandatory=$True)]
            [string]$Owner,
    
            [Parameter(Mandatory=$True)]
            [string]$Repository,
    
            [Parameter(Mandatory=$True)]
            [AllowEmptyString()]
            [string]$Path,
    
            [Parameter(Mandatory=$True)]
            [string]$DestinationPath
        )
    
        # Authentication
        $authPair = "$($User):$($Token)";
        $encAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($authPair));
        $headers = @{ Authorization = "Basic $encAuth" };
        
        # REST Building
        $baseUri = "https://api.github.com";
        $argsUri = "repos/$Owner/$Repository/contents/$Path";
        $wr = Invoke-WebRequest -Uri ("$baseUri/$argsUri") -Headers $headers;
    
        # Data Handler
        $objects = $wr.Content | ConvertFrom-Json
        $files = $objects | where {$_.type -eq "file"} | Select -exp download_url
        $directories = $objects | where {$_.type -eq "dir"}
        
        # Iterate Directory
        $directories | ForEach-Object { 
            DownloadFilesFromRepo -User $User -Token $Token -Owner $Owner -Repository $Repository -Path $_.path -DestinationPath "$($DestinationPath)/$($_.name)"
        }
    
        # Destination Handler
        if (-not (Test-Path $DestinationPath)) {
            try {
                New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop;
            } catch {
                throw "Could not create path '$DestinationPath'!";
            }
        }
    
        # Iterate Files
        foreach ($file in $files) {
            $fileDestination = Join-Path $DestinationPath (Split-Path $file -Leaf)
            $outputFilename = $fileDestination.Replace("%20", " ");
            try {
                Invoke-WebRequest -Uri "$file" -OutFile "$outputFilename" -ErrorAction Stop -Verbose
                "Grabbed '$($file)' to '$outputFilename'";
            } catch {
                throw "Unable to download '$($file)'";
            }
        }
    }