$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root='C:\codespace\ai\cay_simulasyonu\dev_assets\v2_migration'
$names=@('14_TEA_TRANSPORT_TRUCK.png','15_FARMER_MALE.png','19_TEA_MERCHANT.png','21_TEA_FACTORY_SUPERVISOR.png','23_VILLAGE_ELDER.png','38_DELIVERY_TRUCK.png')
$font=New-Object Drawing.Font('Arial',13)
$brush=New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(61,104,91))
for($page=0;$page -lt 3;$page++){
  $sheet=New-Object Drawing.Bitmap(1200,900);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::White)
  for($row=0;$row -lt 2;$row++){
    $name=$names[$page*2+$row];$y=$row*450
    $g.DrawString($name,$font,[Drawing.Brushes]::Black,5,$y+4)
    for($col=0;$col -lt 3;$col++){
      $kind=@('original','before','transparent')[$col];$x=$col*400
      $g.DrawString($kind,$font,[Drawing.Brushes]::Black,$x+5,$y+25)
      $g.FillRectangle($brush,$x,$y+50,400,400)
      $file=Get-ChildItem -LiteralPath (Join-Path $root $kind) -Recurse -Filter $name
      $img=[Drawing.Image]::FromFile($file.FullName)
      $scale=[Math]::Min(395.0/$img.Width,395.0/$img.Height);$w=[int]($img.Width*$scale);$h=[int]($img.Height*$scale)
      $g.DrawImage($img,[int]($x+(400-$w)/2),[int]($y+50+(400-$h)/2),$w,$h);$img.Dispose()
    }
  }
  $g.Dispose();$sheet.Save((Join-Path $root ('rejected_'+($page+1)+'.png')),[Drawing.Imaging.ImageFormat]::Png);$sheet.Dispose()
}
$brush.Dispose();$font.Dispose()
