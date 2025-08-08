# Define paths
$csvPath = "C:\appDev\handbookURLs.csv"
$outputPath = "C:\appDev\handbookContent.md"

# Load URLs from CSV
$urls = Import-Csv -Path $csvPath

# Initialize output file
"" | Out-File -FilePath $outputPath -Encoding UTF8

# Loop through each URL
foreach ($entry in $urls) {
    $url = $entry.URL  

    try {
        Write-Host "Fetching $url..."

        # Download raw HTML content
        $response = Invoke-WebRequest -Uri $url
        $html = $response.Content

        # Extract title using regex
        $titleMatch = [regex]::Match($html, "<title>(.*?)</title>", "IgnoreCase")
        $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "Untitled" }

        # Extract fsBody content using regex
        $fsBodyMatch = [regex]::Match($html, '<div class="fsBody">(.*?)</div>', 'Singleline, IgnoreCase')
        $fsBodyHtml = if ($fsBodyMatch.Success) { $fsBodyMatch.Groups[1].Value } else { "No content found." }

        # Basic HTML cleanup (optional: improve with full HTML-to-Markdown conversion)
        $cleanContent = $fsBodyHtml -replace "<[^>]+>", "" -replace "&nbsp;", " " -replace "&amp;", "&" -replace "\s{2,}", "`n"

        # Write to Markdown file
        Add-Content -Path $outputPath -Value "`n# $title`n"
        Add-Content -Path $outputPath -Value "$cleanContent`n"
    } catch {
        Write-Warning "Failed to process $url $_"
    }
}

Write-Host "All content saved to $outputPath"
