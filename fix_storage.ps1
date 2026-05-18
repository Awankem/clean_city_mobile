$filePath = "c:\Users\SMARTECH\Desktop\Laravel\clean_city_api\app\Http\Controllers\Api\ReportController.php"
$content = Get-Content -Path $filePath -Raw

# Replace saveOptimizedImage to ensure the directory exists before copy
$oldOptimized = @"
    protected function saveOptimizedImage(`$sourcePath, `$destinationPath)
    {
        // Simple copy for now or image manipulation
        copy(`$sourcePath, `$destinationPath);
    }
"@

$newOptimized = @"
    protected function saveOptimizedImage(`$sourcePath, `$destinationPath)
    {
        `$dir = dirname(`$destinationPath);
        if (!file_exists(`$dir)) {
            mkdir(`$dir, 0755, true);
        }
        copy(`$sourcePath, `$destinationPath);
    }
"@

$content = $content.Replace($oldOptimized, $newOptimized)

Set-Content -Path $filePath -Value $content

cd c:\Users\SMARTECH\Desktop\Laravel\clean_city_api
git add app/Http/Controllers/Api/ReportController.php
git commit -m "Ensure local storage fallback directory exists"
git push
