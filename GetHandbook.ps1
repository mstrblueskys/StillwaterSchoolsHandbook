# Define target URL and output path
$baseUrl = "https://lilylake.stillwaterschools.org/our-school/handbooks"
$outputPath = "C:\appDev\LilyLakeHandbookContent.md"

# Initialize output file
"" | Out-File -FilePath $outputPath -Encoding UTF8

# Download HTML content
try {
    $html = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing
} catch {
    Write-Error "Failed to fetch the page: $_"
    exit
}

# Extract all anchor tags
$links = $html.Links | Where-Object { $_.href -like "*handbooks/article*" }

# Deduplicate and resolve full URLs
$uniqueUrls = $links |
    ForEach-Object {
        if ($_.href -notmatch "^https?://") {
            # Convert relative URL to absolute
            [System.Uri]::new($baseUrl, $_.href).AbsoluteUri
        } else {
            $_.href
        }
    } | Sort-Object -Unique

# Loop through each URL
foreach ($entry in $uniqueUrls) {


    try {
        Write-Host "Fetching $entry..."

        # Download raw HTML content
        $response = Invoke-WebRequest -Uri $entry
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
