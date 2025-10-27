param(
    [string]$JsonFile,
    [string]$FieldName
)

try {
    # Read JSON from file
    $obj = Get-Content $JsonFile -Raw | ConvertFrom-Json
    
    switch ($FieldName) {
        "file_path" {
            if ($obj.file_path) {
                Write-Output $obj.file_path
            } else {
                Write-Output "NO_FILE_PATH"
            }
        }
        "workspace_roots" {
            if ($obj.workspace_roots -and $obj.workspace_roots.Count -gt 0) {
                Write-Output $obj.workspace_roots[0]
            } else {
                Write-Output "NO_WORKSPACE_ROOT"
            }
        }
        default {
            Write-Output "UNKNOWN_FIELD"
        }
    }
} catch {
    Write-Output "JSON_PARSE_ERROR: $($_.Exception.Message)"
}
