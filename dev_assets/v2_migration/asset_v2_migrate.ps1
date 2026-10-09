$ErrorActionPreference='Stop'
$project='C:\codespace\ai\cay_simulasyonu'
$review=Join-Path $project 'dev_assets\v2_migration'
$rejected=@{
  '14_TEA_TRANSPORT_TRUCK.png'='Cab roof removed.'
  '15_FARMER_MALE.png'='Cream shirt shoulder and sleeve pixels removed.'
  '19_TEA_MERCHANT.png'='Right cream sleeve removed.'
  '21_TEA_FACTORY_SUPERVISOR.png'='Cream sleeves/shoulders removed.'
  '23_VILLAGE_ELDER.png'='Right cream sleeve/shoulder removed.'
  '38_DELIVERY_TRUCK.png'='Cargo box roof removed.'
}
$audit=Get-Content -Raw -Encoding UTF8 (Join-Path $review 'alpha_audit.json') | ConvertFrom-Json
if($audit.Count -ne 28){throw 'Expected all 28 transparent candidates to be reviewed.'}
$decisions=@()
foreach($row in $audit){
  if($row.directMatches -ne 1){throw 'Non-unique filename match.'}
  $name=$row.filename
  $source=Join-Path $review ('transparent\'+$name)
  $destination=Join-Path $project $row.gamePath
  $backup=Join-Path $review ('before\'+$row.gamePath.Substring('assets\images\'.Length))
  if((Get-FileHash -LiteralPath $destination).Hash -ne (Get-FileHash -LiteralPath $backup).Hash){throw ('Game asset changed after baseline: '+$name)}
  if($rejected.ContainsKey($name)){
    Copy-Item -LiteralPath (Join-Path $review ('original\'+$name)) -Destination $destination
    $decisions += [pscustomobject]@{filename=$name; migrated=$false;reason=($rejected[$name]+' V1 also damaged; untouched original master restored.');sha256=(Get-FileHash -LiteralPath $destination).Hash}
  }else{
    if($row.format -ne 'Format32bppArgb' -or $row.zeroAlpha -eq 0){throw ('Missing real transparency: '+$name)}
    Copy-Item -LiteralPath $source -Destination $destination
    if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $destination).Hash){throw 'Copy hash mismatch'}
    $decisions += [pscustomobject]@{filename=$name;migrated=$true;reason='Passed paired checkerboard visual review; exact transparent ZIP bytes.';sha256=(Get-FileHash -LiteralPath $destination).Hash}
  }
}
$decisions | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $review 'decisions.json')
$protected=Get-Content -Raw -Encoding UTF8 (Join-Path $review 'before_hashes.json') | ConvertFrom-Json
foreach($row in $protected){
  $name=Split-Path $row.path -Leaf
  if($name -cmatch '^(0[1-4]|2[5-9]|30|37|40)_'){
    if((Get-FileHash -LiteralPath (Join-Path $project ('assets\images\'+$row.path))).Hash -ne $row.sha256){throw ('Protected asset changed: '+$name)}
  }
}
'Migrated: '+@($decisions | Where-Object migrated).Count
'Rejected: '+@($decisions | Where-Object { !$_.migrated }).Count
'Protected field/sheet files unchanged: 12'
