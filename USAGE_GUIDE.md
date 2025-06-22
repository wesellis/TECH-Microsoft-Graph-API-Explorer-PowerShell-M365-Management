# Microsoft Graph API Explorer - Developer Usage Guide

## Quick Reference

**Getting started with Microsoft Graph automation in your enterprise environment.**

### Prerequisites Checklist
- ✅ PowerShell 5.1+ or PowerShell Core 6.0+
- ✅ Microsoft.Graph PowerShell SDK installed
- ✅ Azure AD App Registration with appropriate permissions
- ✅ Microsoft 365 tenant with administrative access
- ✅ Understanding of Graph API permission scopes

### 5-Minute Setup
```powershell
# 1. Install required modules
Install-Module Microsoft.Graph -Force -AllowClobber
Install-Module Microsoft.Graph.Authentication -Force

# 2. Connect with interactive authentication (first time)
Connect-MgGraph -Scopes \"User.Read.All\", \"Group.Read.All\"

# 3. Test connection
Get-MgUser -Top 5 | Select DisplayName, UserPrincipalName

# 4. Run your first automation
.\\scripts\\list-users.ps1 -OutputPath \"./my-users.csv\"
```

## Common Usage Patterns

### Daily User Management
```powershell
# Get user information
.\\scripts\\get-user-info.ps1 -UserId \"john.doe@company.com\"

# Create new user from template
.\\scripts\\create-user.ps1 -DisplayName \"Jane Smith\" -UserPrincipalName \"jane.smith@company.com\" -Department \"Marketing\"

# Bulk user operations from CSV
.\\scripts\\bulk-user-operations.ps1 -CsvPath \"./new-employees.csv\" -Operation \"Create\" -WhatIf
```

### Group Administration
```powershell
# List all security groups
.\\scripts\\list-groups.ps1 -Type \"Security\" -OutputPath \"./security-groups.csv\"

# Add user to multiple groups
.\\scripts\\add-user-to-group.ps1 -UserId \"john.doe@company.com\" -GroupId \"group-id-1\"
.\\scripts\\add-user-to-group.ps1 -UserId \"john.doe@company.com\" -GroupId \"group-id-2\"

# Synchronize group memberships
.\\scripts\\sync-group-membership.ps1 -SourceGroup \"sales-team\" -TargetGroup \"sales-access\" -Mode \"Mirror\"
```

### Security Operations
```powershell
# Monitor recent sign-ins for suspicious activity
.\\scripts\\get-sign-in-logs.ps1 -DateRange \"Last7Days\" -OutputPath \"./sign-ins.csv\"

# Audit application permissions
.\\scripts\\audit-app-permissions.ps1 -OutputPath \"./app-permissions-audit.csv\" -Detailed

# Generate security report
.\\scripts\\get-privileged-users.ps1 -OutputPath \"./privileged-users.csv\" -IncludeGuests
```

### Reporting and Analytics
```powershell
# Generate comprehensive user report
.\\scripts\\generate-user-report.ps1 -OutputPath \"./monthly-user-report.xlsx\" -IncludeUsage -Format \"Excel\"

# License usage analysis
.\\scripts\\get-license-usage.ps1 -OutputPath \"./license-analysis.csv\" -Summary

# Tenant health assessment
.\\scripts\\tenant-health-report.ps1 -OutputPath \"./tenant-health.html\" -IncludeRecommendations
```

## Authentication Scenarios

### Interactive Development
**Best for:** Testing, development, one-time operations
```powershell
# Browser-based authentication
Connect-MgGraph -Scopes \"User.Read.All\", \"Group.ReadWrite.All\"

# Device code flow (for servers without browser)
Connect-MgGraph -UseDeviceAuthentication -Scopes \"User.Read.All\"
```

### Service Principal Automation
**Best for:** Production automation, scheduled tasks
```powershell
# Using client secret (less secure)
$TenantId = \"your-tenant-id\"
$ClientId = \"your-app-client-id\"
$ClientSecret = \"your-client-secret\"

Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -ClientSecret (ConvertTo-SecureString $ClientSecret -AsPlainText -Force)

# Using certificate (recommended)
$Certificate = Get-ChildItem -Path \"Cert:\\CurrentUser\\My\\\" | Where-Object {$_.Subject -eq \"CN=GraphAppCert\"}
Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -Certificate $Certificate
```

### Managed Identity (Azure)
**Best for:** Azure-hosted automation (VMs, Functions, etc.)
```powershell
# System-assigned managed identity
Connect-MgGraph -Identity

# User-assigned managed identity
Connect-MgGraph -Identity -ClientId \"managed-identity-client-id\"
```

## Permission Scopes Guide

### Essential Scopes for Common Operations

| Operation | Required Scope | Reason |
|-----------|----------------|--------|
| Read user information | `User.Read.All` | Access user profile data |
| Create/modify users | `User.ReadWrite.All` | User lifecycle management |
| Read group information | `Group.Read.All` | Access group and membership data |
| Modify group memberships | `Group.ReadWrite.All` | Group administration |
| Read audit logs | `AuditLog.Read.All` | Security monitoring |
| Read application data | `Application.Read.All` | App permission auditing |
| Read directory data | `Directory.Read.All` | Organizational structure |

### Permission Validation
```powershell
# Always validate permissions before operations
.\\scripts\\test-graph-permissions.ps1 -Scopes @(\"User.Read.All\", \"Group.Read.All\") -Detailed
```

## Script Configuration Patterns

### Environment-specific Configuration
```powershell
# Development configuration
$Config = @{
    TenantId = \"dev-tenant-id\"
    OutputPath = \"./dev-reports/\"
    WhatIf = $true
    Verbose = $true
}

# Production configuration
$Config = @{
    TenantId = \"prod-tenant-id\"
    OutputPath = \"./production-reports/\"
    WhatIf = $false
    Verbose = $false
    BackupPath = \"./backups/\"
}
```

### Batch Processing
```powershell
# Process multiple operations efficiently
$Users = Import-Csv \"./user-data.csv\"
foreach ($User in $Users) {
    .\\scripts\\create-user.ps1 -DisplayName $User.DisplayName -UserPrincipalName $User.UPN -Department $User.Department
    Start-Sleep -Seconds 1  # Rate limiting
}
```

## Error Handling and Troubleshooting

### Common Issues and Solutions

#### Authentication Failures
```powershell
# Issue: Token expired
# Solution: Reconnect to Graph
Disconnect-MgGraph
Connect-MgGraph -Scopes \"User.Read.All\", \"Group.Read.All\"

# Issue: Insufficient permissions
# Solution: Request additional scopes
Connect-MgGraph -Scopes \"User.ReadWrite.All\", \"Group.ReadWrite.All\"
```

#### Rate Limiting
```powershell
# Issue: Too many requests
# Solution: Implement retry logic with exponential backoff
try {
    $Result = .\\scripts\\get-user-info.ps1 -UserId $UserId
} catch {
    if ($_.Exception.Message -like \"*throttled*\") {
        Start-Sleep -Seconds 60
        $Result = .\\scripts\\get-user-info.ps1 -UserId $UserId
    }
}
```

#### Large Dataset Handling
```powershell
# Issue: Memory usage with large user lists
# Solution: Use pagination and streaming
.\\scripts\\list-users.ps1 -OutputPath \"./users.csv\" -PageSize 100 -StreamOutput
```

### Debug Mode
```powershell
# Enable verbose logging for troubleshooting
$DebugPreference = \"Continue\"
$VerbosePreference = \"Continue\"

.\\scripts\\your-script.ps1 -Debug -Verbose
```

## Production Deployment Patterns

### Scheduled Automation
```powershell
# Windows Task Scheduler PowerShell command
PowerShell.exe -ExecutionPolicy Bypass -File \"C:\\Scripts\\daily-user-report.ps1\"

# Parameters file for consistent configuration
$ConfigPath = \"C:\\Scripts\\production-config.json\"
$Config = Get-Content $ConfigPath | ConvertFrom-Json
.\\scripts\\generate-user-report.ps1 @Config
```

### Azure Automation
```powershell
# Azure Automation Runbook example
param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputStorageAccount
)

# Connect using managed identity
Connect-MgGraph -Identity

# Run automation
.\\scripts\\tenant-health-report.ps1 -OutputPath \"./reports/health-$(Get-Date -Format 'yyyyMMdd').html\"

# Upload to Azure Storage
# ... storage upload logic
```

### CI/CD Integration
```yaml
# Azure DevOps Pipeline example
- task: PowerShell@2
  inputs:
    targetType: 'inline'
    script: |
      Install-Module Microsoft.Graph -Force
      Connect-MgGraph -Identity
      .\\scripts\\backup-configuration.ps1 -OutputPath \"$(Build.ArtifactStagingDirectory)\"
```

## Performance Optimization

### Efficient Batch Operations
```powershell
# Process users in batches to avoid timeouts
$AllUsers = .\\scripts\\list-users.ps1 -Filter \"accountEnabled eq true\"
$BatchSize = 50
for ($i = 0; $i -lt $AllUsers.Count; $i += $BatchSize) {
    $Batch = $AllUsers[$i..([Math]::Min($i + $BatchSize - 1, $AllUsers.Count - 1))]
    # Process batch
    foreach ($User in $Batch) {
        # Process individual user
    }
    Start-Sleep -Milliseconds 500  # Rate limiting
}
```

### Selective Property Retrieval
```powershell
# Only request needed properties to improve performance
.\\scripts\\list-users.ps1 -Properties @(\"DisplayName\", \"UserPrincipalName\", \"Department\")
```

### Caching Strategies
```powershell
# Cache group information for multiple operations
$Groups = .\\scripts\\list-groups.ps1 -CacheResults -CachePath \"./cache/groups.json\"
# Subsequent operations use cached data
```

## Security Best Practices for Developers

### Credential Management
```powershell
# Store credentials securely
$SecurePassword = Read-Host -AsSecureString \"Enter client secret\"
$Credential = New-Object System.Management.Automation.PSCredential($ClientId, $SecurePassword)

# Use Windows Credential Manager
cmdkey /add:GraphAPI /user:$ClientId /pass:$ClientSecret
$StoredCred = Get-StoredCredential -Target \"GraphAPI\"
```

### Input Validation
```powershell
# Always validate user inputs
function Validate-UserPrincipalName {
    param([string]$UPN)
    if ($UPN -notmatch \"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$\") {
        throw \"Invalid UPN format: $UPN\"
    }
}
```

### Audit Logging
```powershell
# Log all administrative actions
function Write-AuditLog {
    param([string]$Action, [string]$Target, [string]$Result)
    $LogEntry = @{
        Timestamp = Get-Date -Format \"yyyy-MM-dd HH:mm:ss\"
        User = (Get-MgContext).Account
        Action = $Action
        Target = $Target
        Result = $Result
    }
    $LogEntry | ConvertTo-Json | Add-Content -Path \"./audit.log\"
}

Write-AuditLog -Action \"CreateUser\" -Target $UserPrincipalName -Result \"Success\"
```

## Integration Examples

### HR System Integration
```powershell
# Sync from HR database
$HRData = Invoke-Sqlcmd -Query \"SELECT * FROM Employees WHERE Status = 'Active'\"
foreach ($Employee in $HRData) {
    $UserParams = @{
        DisplayName = \"$($Employee.FirstName) $($Employee.LastName)\"
        UserPrincipalName = \"$($Employee.Email)\"
        Department = $Employee.Department
        JobTitle = $Employee.JobTitle
    }
    .\\scripts\\create-user.ps1 @UserParams
}
```

### Slack/Teams Integration
```powershell
# Send report to Teams channel
$Report = .\\scripts\\generate-user-report.ps1 -Format \"Summary\"
$TeamsMessage = @{
    text = \"Daily User Report: $Report\"
}
Invoke-RestMethod -Uri $TeamsWebhookUrl -Method Post -Body ($TeamsMessage | ConvertTo-Json) -ContentType \"application/json\"
```

### ITSM Integration (ServiceNow)
```powershell
# Create ServiceNow ticket for new user
function New-ServiceNowTicket {
    param([string]$UserName, [string]$Department)
    
    $Ticket = @{
        short_description = \"New user account created: $UserName\"
        description = \"User $UserName has been created in department $Department\"
        category = \"Account Management\"
    }
    
    Invoke-RestMethod -Uri \"$ServiceNowURL/api/now/table/incident\" -Method Post -Body ($Ticket | ConvertTo-Json) -Headers $Headers
}
```

## Advanced Scenarios

### Custom Report Generation
```powershell
# Generate executive dashboard data
$DashboardData = @{
    TotalUsers = (.\\scripts\\list-users.ps1).Count
    ActiveUsers = (.\\scripts\\list-users.ps1 -Filter \"accountEnabled eq true\").Count
    GroupCount = (.\\scripts\\list-groups.ps1).Count
    LastSignInSummary = .\\scripts\\get-sign-in-logs.ps1 -DateRange \"Last30Days\" | Group-Object Date | Select Count, Name
}

$DashboardData | ConvertTo-Json | Out-File \"./dashboard-data.json\"
```

### Multi-tenant Management
```powershell
# Manage multiple tenants
$Tenants = @(
    @{Name=\"Production\"; TenantId=\"prod-tenant-id\"; ClientId=\"prod-client-id\"},
    @{Name=\"Development\"; TenantId=\"dev-tenant-id\"; ClientId=\"dev-client-id\"}
)

foreach ($Tenant in $Tenants) {
    Write-Host \"Processing tenant: $($Tenant.Name)\"
    Connect-MgGraph -TenantId $Tenant.TenantId -ClientId $Tenant.ClientId
    
    $Report = .\\scripts\\generate-user-report.ps1 -OutputPath \"./reports/$($Tenant.Name)-users.csv\"
    
    Disconnect-MgGraph
}
```

## Getting Help

### Script-specific Help
```powershell
# Get detailed help for any script
Get-Help .\\scripts\\create-user.ps1 -Detailed
Get-Help .\\scripts\\create-user.ps1 -Examples
```

### Community Resources
- **GitHub Issues** - Bug reports and feature requests
- **Discussions** - Community Q&A and best practices
- **Documentation** - Comprehensive guides in `/docs` folder
- **Microsoft Graph Documentation** - Official API reference

### Support Channels
- **Bug Reports** - [GitHub Issues](https://github.com/wesellis/Microsoft-Graph-API-Explorer/issues)
- **Feature Requests** - [GitHub Discussions](https://github.com/wesellis/Microsoft-Graph-API-Explorer/discussions)
- **Security Issues** - security@wesellis.com
- **General Questions** - [Community Discussions](https://github.com/wesellis/Microsoft-Graph-API-Explorer/discussions)

---

**Happy automating with Microsoft Graph! 🚀**