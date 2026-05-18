$filePath = "c:\Users\SMARTECH\Desktop\Laravel\clean_city_api\app\Http\Controllers\Api\ReportController.php"
$content = Get-Content -Path $filePath -Raw

# We will search for 'updatePriorityScore(Report $report)' and replace the pointFunc line inside it.
# We will use regex to find '$pointFunc = ...;' inside 'updatePriorityScore' and replace it with the correct placeholders one.

$pattern = '(?s)(protected\s+function\s+updatePriorityScore\s*\(\s*Report\s+\$report\s*\)\s*\{.*?\$pointFunc\s*=\s*)[^\n;]+(\s*;)'
$replacement = '$1$isPgSql ? "ST_GeomFromText(''POINT('' || ? || '' '' || ? || '')'', 4326)" : "ST_GeomFromText(CONCAT(''POINT('', ?, '' '', ?, '')''), 4326)"$2'

$newContent = [regex]::Replace($content, $pattern, $replacement)

Set-Content -Path $filePath -Value $newContent

cd c:\Users\SMARTECH\Desktop\Laravel\clean_city_api
git add app/Http/Controllers/Api/ReportController.php
git commit -m "Fix SQL bindings in priority score calculation properly using regex"
git push
