$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing
$project = 'C:\codespace\ai\cay_simulasyonu'
$review = Join-Path $project 'dev_assets\v2_migration'
New-Item -ItemType Directory -Force -Path $review | Out-Null
$before = Join-Path $review 'before'
$current = Get-ChildItem -LiteralPath (Join-Path $project 'assets\images') -Recurse -Filter '*.png'
if (!(Test-Path -LiteralPath $before)) {
New-Item -ItemType Directory -Path $before | Out-Null
$hashes = @()
foreach ($file in $current) {
  $relative = $file.FullName.Substring((Join-Path $project 'assets\images').Length + 1)
  $destination = Join-Path $before $relative
  New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
  Copy-Item -LiteralPath $file.FullName -Destination $destination
  $hashes += [pscustomobject]@{ path=$relative; sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
}
$hashes | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $review 'before_hashes.json')
Get-ChildItem -LiteralPath (Join-Path $project 'lib') -Recurse -Filter '*.dart' | ForEach-Object {
  [pscustomobject]@{ path=$_.FullName.Substring($project.Length+1); sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
} | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $review 'code_before_hashes.json')
}
$archive = [IO.Compression.ZipFile]::OpenRead('C:\Users\Mehmet Demircioglu\Downloads\CAY_SIMULASYON_GAME_READY_V2.zip')
foreach ($entry in $archive.Entries) {
  if ($entry.FullName -cmatch '/(original|transparent)/([0-9]{2}_[A-Z0-9_]+\.png)$') {
    $folder = Join-Path $review $Matches[1]
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $target = Join-Path $folder $Matches[2]
    if (!(Test-Path -LiteralPath $target)) { [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $false) }
  } elseif ($entry.Name -eq 'README.txt') {
    $reader = New-Object IO.StreamReader($entry.Open())
    $reader.ReadToEnd() | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $review 'archive_readme.txt')
    $reader.Dispose()
  }
}
$archive.Dispose()
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
public class AlphaAudit {
  public static string Measure(string filename, string original) {
    using(var b=new Bitmap(filename)) using(var o=new Bitmap(original)) {
      long zero=0, partial=0, border=0, opaqueBorder=0, dark=0, removedDark=0;
      int minX=b.Width,minY=b.Height,maxX=-1,maxY=-1;
      for(int y=0;y<b.Height;y++) for(int x=0;x<b.Width;x++) {
        var c=b.GetPixel(x,y);
        if(c.A==0)zero++; else {if(c.A<255)partial++;minX=Math.Min(minX,x);minY=Math.Min(minY,y);maxX=Math.Max(maxX,x);maxY=Math.Max(maxY,y);}
        if(x==0||y==0||x==b.Width-1||y==b.Height-1){border++;if(c.A>0)opaqueBorder++;}
        if(o.Width==b.Width && o.Height==b.Height){var p=o.GetPixel(x,y);if(p.A>0&&Math.Max(p.R,Math.Max(p.G,p.B))<160){dark++;if(c.A==0)removedDark++;}}
      }
      return string.Join("|",b.Width,b.Height,b.PixelFormat,zero,partial,border,opaqueBorder,minX,minY,maxX,maxY,dark,removedDark);
    }
  }
}
'@
$transparent = Get-ChildItem -LiteralPath (Join-Path $review 'transparent') -Filter '*.png' | Sort-Object Name
$rows = @()
foreach ($file in $transparent) {
  $match = @($current | Where-Object Name -eq $file.Name)
  $stats = [AlphaAudit]::Measure($file.FullName,(Join-Path $review ('original\'+$file.Name))).Split('|')
  $rows += [pscustomobject]@{ filename=$file.Name; directMatches=$match.Count; gamePath=($match.FullName -replace [regex]::Escape($project+'\'),''); width=[int]$stats[0];height=[int]$stats[1];format=$stats[2];zeroAlpha=[long]$stats[3];partialAlpha=[long]$stats[4];borderPixels=[long]$stats[5];nonzeroBorder=[long]$stats[6];bounds=@([int]$stats[7],[int]$stats[8],[int]$stats[9],[int]$stats[10]);originalDark=[long]$stats[11];removedDark=[long]$stats[12]; identicalToCurrent=($match.Count -eq 1 -and (Get-FileHash $file.FullName).Hash -eq (Get-FileHash $match[0].FullName).Hash) }
}
$rows | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $review 'alpha_audit.json')
$font = New-Object Drawing.Font('Arial',12)
$dark = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(83,116,95))
$light = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(125,153,127))
for($page=0;$page -lt [Math]::Ceiling($transparent.Count/4.0);$page++) {
  $sheet = New-Object Drawing.Bitmap(1200,700)
  $g = [Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::White)
  $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  for($slot=0;$slot -lt 4;$slot++) {
    $index=$page*4+$slot;if($index -ge $transparent.Count){break}
    $file=$transparent[$index];$ox=($slot%2)*600;$oy=[Math]::Floor($slot/2)*350
    $g.DrawString($file.Name,$font,[Drawing.Brushes]::Black,$ox+6,$oy+4)
    foreach($kind in @('original','transparent')) {
      $dx=$ox;if($kind -eq 'transparent'){$dx+=300}
      $g.DrawString($kind,$font,[Drawing.Brushes]::Black,$dx+6,$oy+26)
      for($yy=0;$yy -lt 280;$yy+=20){for($xx=0;$xx -lt 290;$xx+=20){$brush=$dark;if((($xx+$yy)/20)%2 -eq 0){$brush=$light};$g.FillRectangle($brush,$dx+$xx,$oy+54+$yy,20,20)}}
      $img=[Drawing.Image]::FromFile((Join-Path $review ($kind+'\'+$file.Name)))
      $scale=[Math]::Min(290.0/$img.Width,280.0/$img.Height)
      $w=[int]($img.Width*$scale);$h=[int]($img.Height*$scale)
      $g.DrawImage($img,[int]($dx+(290-$w)/2),[int]($oy+54+(280-$h)/2),$w,$h);$img.Dispose()
    }
  }
  $g.Dispose();$sheet.Save((Join-Path $review ('review_'+($page+1)+'.png')),[Drawing.Imaging.ImageFormat]::Png);$sheet.Dispose()
}
$font.Dispose();$dark.Dispose();$light.Dispose()
$rows | Format-Table filename,directMatches,width,height,zeroAlpha,nonzeroBorder,removedDark,identicalToCurrent -AutoSize
