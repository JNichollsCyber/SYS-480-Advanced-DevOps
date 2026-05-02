Import-Module ActiveDirectory

New-ADOrganizationalUnit -Name "Blue29" -Path "DC=blue29,DC=local"
New-ADOrganizationalUnit -Name "Accounts" -Path "DC=blue29,DC=local"

New-ADOrganizationalUnit -Name "Groups" -Path "OU=Accounts,OU=Blue29,DC=blue29,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "DC=blue29,DC=local"

New-ADOrganizationalUnit -Name "Servers" -Path "OU=Computers,OU=Blue29,DC=blue29,DC=local"
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Computers,OU=Blue29,DC=blue29,DC=local"
