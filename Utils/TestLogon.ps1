


# username: "adservice@perficientads.com"
# password: "P3rficient"

Import-Module ActiveDirectory
$session = New-PSSession -ConnectionUri "https://PerficientAD.perficientads.com:6666" -Credential (Get-Credential)

Import-PSSession -Session $session -module ActiveDirectory

Pause