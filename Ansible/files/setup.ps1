Import-Module activedirectory

#Point to csv file containing users!
$UserFile = Import-csv C:\Windows\Tasks\useraccounts.csv

#Change this to your domain
$Domain = 'MATRIX.local'

foreach ($User in $UserFile)
{
        
    $Username   = $User.username
    $Password   = $User.password
    $Firstname  = $User.firstname
    $Lastname   = $User.lastname
    $OU         = $User.ou
    $Description = $User.description

    #Check user does not exist
    if (Get-ADUser -F {SamAccountName -eq $Username})
    {
         #If user exists...
         Write-Warning "Error! $Username already exists."
    }
    else
    {
        #Otherwise...   
        New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@$Domain" `
            -Name "$Firstname $Lastname" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -DisplayName "$Lastname, $Firstname" `
            -Path $OU `
            -Description $Description `
            -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $False -PasswordNeverExpires $True
    }
}