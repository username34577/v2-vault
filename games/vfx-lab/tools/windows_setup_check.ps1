# VFX Lab: Windows setup check (READ-ONLY: installs nothing, changes nothing).
#
#   powershell -ExecutionPolicy Bypass -File games\vfx-lab\tools\windows_setup_check.ps1 [-Repo C:\path\to\v2-vault]
#
# Checks what the VFX Lab needs for real Roblox Studio testing:
#   Roblox Studio, its built-in MCP server (mcp.bat), Claude Code and its MCP registration,
#   Rojo (+ Studio plugin), Node.js, Python + numpy/scipy/Pillow, git, Lune, Blender,
#   the roblox-vfx skill, and that the lab project builds with Rojo (to a temp file).
# Prints OK / MISSING / CHECK lines and the next step for each problem.
param([string]$Repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path)

$results = @()
function Report($name, $status, $detail, $fix) {
    $script:results += [pscustomobject]@{ Item = $name; Status = $status; Detail = $detail; Fix = $fix }
}
function Find-Cmd($name) { $c = Get-Command $name -ErrorAction SilentlyContinue; if ($c) { $c.Source } else { $null } }
function Version-Of($exe, $arg = "--version") {
    try { (& $exe $arg 2>&1 | Select-Object -First 1).ToString().Trim() } catch { "?" }
}

# --- Roblox Studio + built-in MCP server ---------------------------------------------
$studio = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Versions\*\RobloxStudioBeta.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($studio) { Report "Roblox Studio" "OK" $studio.FullName "" }
else { Report "Roblox Studio" "MISSING" "no RobloxStudioBeta.exe under %LOCALAPPDATA%\Roblox\Versions" "Install Studio from create.roblox.com" }

$mcpBat = "$env:LOCALAPPDATA\Roblox\mcp.bat"
if (Test-Path $mcpBat) { Report "Studio MCP launcher" "OK" $mcpBat "" }
else { Report "Studio MCP launcher" "MISSING" "$mcpBat not found" "Update Studio, then Assistant > ... > Manage MCP Servers > turn on 'Enable Studio as MCP server'" }

# --- Claude Code + MCP registration ---------------------------------------------------
$claude = Find-Cmd "claude"
if ($claude) {
    Report "Claude Code CLI" "OK" (Version-Of $claude) ""
    $list = (& $claude mcp list 2>&1 | Out-String)
    if ($list -match "Roblox_Studio") {
        $state = if ($list -match "Roblox_Studio[^\r\n]*(Connected|connected)") { "OK" } else { "CHECK" }
        Report "MCP: Roblox_Studio registered" $state (($list -split "`n" | Where-Object { $_ -match "Roblox_Studio" }) -join " ").Trim() "If not connected: open Studio with the MCP server enabled, then restart Claude Code"
    } else {
        Report "MCP: Roblox_Studio registered" "MISSING" "not in 'claude mcp list'" 'claude mcp add --scope user Roblox_Studio -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"   (or Studio: Assistant Settings > MCP Servers > Quick connect > Claude Code)'
    }
} else {
    Report "Claude Code CLI" "MISSING" "claude not on PATH" "Install Claude Code (claude.com/claude-code); the Desktop app also works for the MCP"
}

# --- Rojo ------------------------------------------------------------------------------
$rojo = Find-Cmd "rojo"
if ($rojo) { Report "Rojo" "OK" (Version-Of $rojo) "" }
else { Report "Rojo" "MISSING" "rojo not on PATH" "Install Rokit (github.com/rojo-rbx/rokit), then 'rokit add rojo-rbx/rojo' in the repo; or download rojo.exe from github.com/rojo-rbx/rojo/releases" }
$plugin = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Plugins\*" -Include "*Rojo*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($plugin) { Report "Rojo Studio plugin" "OK" $plugin.FullName "" }
else { Report "Rojo Studio plugin" "MISSING" "no Rojo plugin in %LOCALAPPDATA%\Roblox\Plugins" "rojo plugin install   (then restart Studio)" }

# --- Tool chain for the skill and the lab's checks ------------------------------------
$node = Find-Cmd "node"
if ($node) { Report "Node.js" "OK" (Version-Of $node) "" } else { Report "Node.js" "MISSING" "" "Install Node.js LTS (needed by studio_kit.js and render_previews.js)" }

$py = Find-Cmd "python"; if (-not $py) { $py = Find-Cmd "py" }
if ($py) {
    Report "Python" "OK" (Version-Of $py) ""
    $mods = & $py -c "import importlib.util as u; print(','.join(m for m in ('numpy','scipy','PIL') if u.find_spec(m) is None))" 2>&1
    if ([string]::IsNullOrWhiteSpace($mods)) { Report "numpy / scipy / Pillow" "OK" "" "" }
    else { Report "numpy / scipy / Pillow" "MISSING" "missing: $mods" "pip install numpy scipy pillow" }
} else { Report "Python" "MISSING" "" "Install Python 3.11+ (python.org), tick 'Add to PATH'" }

$git = Find-Cmd "git"
if ($git) { Report "git" "OK" (Version-Of $git) "" } else { Report "git" "MISSING" "" "Install Git for Windows" }

$lune = Find-Cmd "lune"
if ($lune) { Report "Lune" "OK" (Version-Of $lune) "" } else { Report "Lune (optional gates)" "MISSING" "" "rokit add lune-org/lune   (enables the Lune compile/build gates in check.sh)" }

$blender = Find-Cmd "blender"
if (-not $blender) { $b = Get-ChildItem "C:\Program Files\Blender Foundation\Blender 4*\blender.exe" -ErrorAction SilentlyContinue | Select-Object -First 1; if ($b) { $blender = $b.FullName } }
if ($blender) { Report "Blender 4.x (optional, meshes)" "OK" $blender "" } else { Report "Blender 4.x (optional, meshes)" "MISSING" "" "Only needed for kits with meshes: install Blender 4.x" }

# --- roblox-vfx skill ------------------------------------------------------------------
$skill = Join-Path $HOME ".claude\skills\roblox-vfx"
if (Test-Path (Join-Path $skill "SKILL.md")) {
    $local = if (Test-Path (Join-Path $skill "LOCAL.md")) { "LOCAL.md present" } else { "no LOCAL.md yet" }
    $tex = if (Test-Path (Join-Path $skill "sim\textures\lib")) { "texture library built" } else { "textures NOT built" }
    Report "roblox-vfx skill" "OK" "$skill ($local, $tex)" ""
} else { Report "roblox-vfx skill" "MISSING" "" "Copy skills\roblox-vfx from github.com/1nird/roblox-vfx-v2 to $skill" }

# --- The lab project builds ----------------------------------------------------------
$project = Join-Path $Repo "games\vfx-lab\default.project.json"
if (-not (Test-Path $project)) {
    Report "VFX Lab project" "MISSING" $project "Pass -Repo <your v2-vault clone> and 'git pull' first"
} elseif ($rojo) {
    $out = Join-Path $env:TEMP "vfxlab-check.rbxlx"
    $log = (& $rojo build (Split-Path $project) -o $out 2>&1 | Out-String)
    if ($LASTEXITCODE -eq 0 -and (Test-Path $out)) { Report "VFX Lab: rojo build" "OK" "built $out" "" }
    else { Report "VFX Lab: rojo build" "FAILED" $log.Trim() "Read the error; usually an old Rojo (needs 7.x)" }
} else { Report "VFX Lab: rojo build" "SKIPPED" "no rojo" "" }

$results | Format-Table -AutoSize -Wrap
$bad = @($results | Where-Object { $_.Status -in @("MISSING", "FAILED", "CHECK") -and $_.Item -notmatch "optional" })
if ($bad.Count -eq 0) { Write-Host "`nReady for Studio testing: rojo serve games\vfx-lab, connect in Studio, then ask Claude to run the VFX Lab tests." -ForegroundColor Green }
else { Write-Host "`n$($bad.Count) required item(s) need attention (see Fix column)." -ForegroundColor Yellow }
