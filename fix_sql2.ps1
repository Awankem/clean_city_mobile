$filePath = "c:\Users\SMARTECH\Desktop\Laravel\clean_city_api\app\Http\Controllers\Api\ReportController.php"
$content = Get-Content -Path $filePath -Raw
$content = $content.Replace(
    "? ""ST_GeomFromText('POINT(' || ? || ' ' || ? || ')', 4326)""",
    "? ""ST_GeomFromText('POINT({`$request->longitude} {`$request->latitude})', 4326)"""
)
$content = $content.Replace(
    ": ""ST_GeomFromText(CONCAT('POINT(', ?, ' ', ?, ')'), 4326)""",
    ": ""ST_GeomFromText('POINT({`$request->longitude} {`$request->latitude})', 4326)"""
)
Set-Content -Path $filePath -Value $content

cd c:\Users\SMARTECH\Desktop\Laravel\clean_city_api
git add app/Http/Controllers/Api/ReportController.php
git commit -m "Fix raw SQL bindings for location properly"
git push
