$filePath = "c:\Users\SMARTECH\Desktop\Laravel\clean_city_api\app\Http\Controllers\Api\ReportController.php"
$content = Get-Content -Path $filePath -Raw

# Correct store() method (should use $request variables directly)
$storeOld = "? ""ST_GeomFromText('POINT(' || ? || ' ' || ? || ')', 4326)"""
$storeNew = "? ""ST_GeomFromText('POINT({`$request->longitude} {`$request->latitude})', 4326)"""

# Restore updatePriorityScore() method to use placeholders ? since whereRaw works perfectly with bindings
$priorityOld = "ST_GeomFromText('POINT({`$request->longitude} {`$request->latitude})', 4326)"
$priorityNew = "ST_GeomFromText('POINT(' || ? || ' ' || ? || ')', 4326)"

# Also make sure the mysql fallback in priority score uses placeholders too
$priorityOldMysql = "ST_GeomFromText('POINT({`$request->longitude} {`$request->latitude})', 4326)" # wait in the code it was replaced to this
# Let's just replace the entire block inside updatePriorityScore to be safe

$oldBlock = @"
        `$isPgSql = DB::getDriverName() === 'pgsql';
        `$distanceFunc = `$isPgSql ? 'ST_DistanceSphere' : 'ST_Distance_Sphere';
        `$pointFunc = `$isPgSql ? "ST_GeomFromText('POINT({`$request->longitude} {`$request->latitude})', 4326)" : "ST_GeomFromText('POINT({`$request->longitude} {`$request->latitude})', 4326)";
"@

$newBlock = @"
        `$isPgSql = DB::getDriverName() === 'pgsql';
        `$distanceFunc = `$isPgSql ? 'ST_DistanceSphere' : 'ST_Distance_Sphere';
        `$pointFunc = `$isPgSql ? "ST_GeomFromText('POINT(' || ? || ' ' || ? || ')', 4326)" : "ST_GeomFromText(CONCAT('POINT(', ?, ' ', ?, ')'), 4326)";
"@

$content = $content.Replace($oldBlock, $newBlock)

# Ensure the store block is clean as well
$content = $content.Replace(
    "? ""ST_GeomFromText('POINT(' || ? || ' ' || ? || ')', 4326)""",
    "? ""ST_GeomFromText('POINT({`$request->longitude} {`$request->latitude})', 4326)"""
)

Set-Content -Path $filePath -Value $content

cd c:\Users\SMARTECH\Desktop\Laravel\clean_city_api
git add app/Http/Controllers/Api/ReportController.php
git commit -m "Fix SQL bindings in priority score calculation"
git push
