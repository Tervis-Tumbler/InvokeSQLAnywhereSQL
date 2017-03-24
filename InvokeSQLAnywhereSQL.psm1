function Install-InvokeSQLAnywhereSQL {
    choco install sqlanywhereclient -version 12.0.1
}

function ConvertTo-SQLAnywhereConnectionString {
    param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string]$Host,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string]$DatabaseName,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string]$ServerName,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string]$UserName,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string]$Password
    )
    "UID=$UserName;PWD=$Password;Host=$Host;DatabaseName=$DatabaseName;ServerName=$ServerName"
}

$DatabaseEngineClassMap = [PSCustomObject][Ordered]@{
    Name = "SQLAnywhere"
    NameSpace = "iAnywhere.Data.SQLAnywhere"
    Connection = "SAConnection"
    Command = "SACommand"
    Adapter = "SADataAdapter"
    AddTypeScriptBlock = {Add-iAnywhereDataSSQLAnywhereType}
},
[PSCustomObject][Ordered]@{
    Name = "Oracle"
    NameSpace = "Oracle.ManagedDataAccess.Client"
    Connection = "OracleConnection"
    Command = "OracleCommand"
    Adapter = "OracleDataAdapter"
    AddTypeScriptBlock = {Add-OracleManagedDataAccessType}
},
[PSCustomObject][Ordered]@{
    Name = "MSSQL"
    NameSpace = "system.data.sqlclient"
    Connection = "SQLConnection"
    Command = "SQLCommand"
    Adapter = "SQLDataAdapter"
}

function Get-DatabaseEngineClassMap {
    param (
        $Name
    )
    $DatabaseEngineClassMap | where Name -EQ $Name
}

function Add-iAnywhereDataSSQLAnywhereType {
    Add-Type -AssemblyName "iAnywhere.Data.SQLAnywhere, Version=12.0.1.36052, Culture=neutral, PublicKeyToken=f222fc4333e0d400"
}

function Invoke-SQLAnywhereSQL {
    param(
        [Parameter(Mandatory)][string]$ConnectionString,
        [Parameter(Mandatory)][string]$SQLCommand,
        [ValidateSet("SQLAnywhere","Oracle","MSSQL")]$DatabaseEngineClassMapName,
        [Switch]$ConvertFromDataRow
    )
    $ClassMap = Get-DatabaseEngineClassMap -Name $DatabaseEngineClassMapName
    $NameSpace = $ClassMap.NameSpace
    & $ClassMap.AddTypeScriptBlock

    $Connection = New-Object -TypeName "$NameSpace.$($ClassMap.Connection)" $ConnectionString
    $Command = New-Object "$NameSpace.$($ClassMap.Command)" $SQLCommand,$Connection
    $Connection.Open()
    
    $Adapter = New-Object "$NameSpace.$($ClassMap.Adapter)" $Command
    $Dataset = New-Object System.Data.DataSet
    $Adapter.Fill($DataSet) | Out-Null
    
    $Connection.Close()
    
    if ($ConvertFromDataRow) {
        $DataSet.Tables | ConvertFrom-DataRow
    } else {
        $DataSet.Tables
    }
}