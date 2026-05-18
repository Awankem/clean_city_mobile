$filePath = "c:\Users\SMARTECH\Desktop\Laravel\clean_city_api\app\Http\Controllers\Api\ReportController.php"
$content = Get-Content -Path $filePath -Raw

# Remove the redundant, broken PgSql update block
$oldBlock = @"
                // Bind coordinates to the raw SQL
                if (`$isPgSql) {
                    `$report->where('id', `$report->id)->update([
                        'location' => DB::raw("ST_GeomFromText('POINT(' || {\$request->longitude} || ' ' || {\$request->latitude} || ')', 4326)")
                    ]);
                }
"@

# Replace it with empty string
$content = $content.Replace($oldBlock, "")

Set-Content -Path $filePath -Value $content

cd c:\Users\SMARTECH\Desktop\Laravel\clean_city_api
git add app/Http/Controllers/Api/ReportController.php
git commit -m "Remove redundant and broken PgSql location update block"
git push
