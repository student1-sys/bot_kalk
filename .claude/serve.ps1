param([int]$Port = 8765)
# Minimal static file server for the bot prototype (index.html).
# Serves the project folder (parent of .claude) on http://localhost:$Port/
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$Port/"
$types = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.js'='application/javascript; charset=utf-8'; '.json'='application/json; charset=utf-8'; '.png'='image/png'; '.svg'='image/svg+xml'; '.ico'='image/x-icon' }
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
  if ($rel -eq '') { $rel = 'index.html' }
  $path = [IO.Path]::GetFullPath((Join-Path $root $rel))
  $res = $ctx.Response
  if ($path.StartsWith($root) -and (Test-Path $path -PathType Leaf)) {
    $bytes = [IO.File]::ReadAllBytes($path)
    $ext = [IO.Path]::GetExtension($path).ToLower()
    $res.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' }
    $res.ContentLength64 = $bytes.Length
    if ($ctx.Request.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($bytes, 0, $bytes.Length) }
    Write-Host "200 /$rel"
  } else {
    $res.StatusCode = 404
    Write-Host "404 /$rel"
  }
  $res.Close()
}
