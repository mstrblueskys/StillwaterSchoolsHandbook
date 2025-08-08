################################################################
#
#  Parse and extract the handbook for Stillwater MN Schools
#          Created 8/8/2025, Updated []
#               Matt Peterson
#
#  I couldn't handle the site's UX so this builds a text only version
#
################################################################

# Define target URL and output path
# Replace the URL in the quotes if you want to try with a different school
$baseUrl = "https://lilylake.stillwaterschools.org/our-school/handbooks"
$outputPath = "C:\appDev\LilyLakeHandbookContent.md"

$today = Get-Date -Format "MM-dd-yyyy" # Ugh, fine, this format works

# Initialize output file - add the disclaimer at the beginning.
$IntroURL = "Below is the list of sites linked at the Lilly Lake Handbook site: " + $baseUrl
$InrtoDate = "This was pulled on " + "" + $today + ". My guess would be this handbook will be updated overtime so please take note of the date. Thank you."

# I wish I was smart enough to not do it like this... ick.
$allIntro = $IntroURL + "

" + $InrtoDate


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

        # Basic HTML cleanup (optional: improve with full HTML-to-Markdown conversion) - I am keeping some because it's nice.
        $cleanContent = $fsBodyHtml <#-replace "<[^>]+>", ""#> -replace "&nbsp;", " " -replace "&amp;", "&" -replace "\s{2,}", "`n"

        # Write to Markdown file
        Add-Content -Path $outputPath -Value "`n# $title`n"
        Add-Content -Path $outputPath -Value "$cleanContent`n"
    } catch {
        Write-Warning "Failed to process $url $_"
    }
}

Write-Host "All content saved to $outputPath"


