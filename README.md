# Microsoft Graph API Explorer PowerShell Toolkit

[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-5391FE?style=flat-square&logo=powershell&logoColor=white)](https://docs.microsoft.com/powershell/)
[![Graph API](https://img.shields.io/badge/Graph_API-v1.0-00BCF2?style=flat-square&logo=microsoft&logoColor=white)](https://graph.microsoft.com)
[![M365](https://img.shields.io/badge/M365-All_Services-FF6900?style=flat-square&logo=microsoft-office&logoColor=white)](https://www.microsoft.com/microsoft-365)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/wesellis/TECH-Microsoft-Graph-API-Explorer-PowerShell-M365-Management?style=flat-square)](https://github.com/wesellis/TECH-Microsoft-Graph-API-Explorer-PowerShell-M365-Management/stargazers)
[![Last Commit](https://img.shields.io/github/last-commit/wesellis/TECH-Microsoft-Graph-API-Explorer-PowerShell-M365-Management?style=flat-square)](https://github.com/wesellis/TECH-Microsoft-Graph-API-Explorer-PowerShell-M365-Management/commits)

## Overview

PowerShell toolkit for exploring and managing Microsoft 365 services through the Microsoft Graph API. This collection provides ready-to-use scripts for common administrative tasks and helps simplify complex API operations.

## Features

- **Graph API Explorer** - Test and explore Graph API endpoints
- **User Management** - Manage users across Azure AD and M365
- **Automated Reports** - Generate compliance and auditing reports
- **Bulk Operations** - Handle large-scale operations on mailboxes, groups, and teams
- **Data Export** - Export data in multiple formats
- **API Testing** - Test API calls before implementation

## Common Use Cases

### User Management

```powershell
# Get all users with specific license
Get-GraphUsers -Filter "assignedLicenses/any(x:x/skuId eq 'SPE_E5')"

# Bulk create users from CSV
Import-Csv users.csv | New-GraphUser -SendWelcomeEmail

# Find inactive users
Get-InactiveUsers -Days 90 | Export-Csv inactive_users.csv
```

### Email & Calendar

```powershell
# Search emails across organization
Search-GraphMail -Query "invoice" -From "2024-01-01"

# Export calendar events
Get-GraphCalendarEvents -User "user@domain.com" -Days 30

# Set out-of-office for multiple users
Set-BulkOutOfOffice -UserList $users -Message "On vacation"
```

### Teams Management

```powershell
# Create team from template
New-GraphTeam -Template "ProjectTeam" -Name "Q1 Project"

# Audit team membership
Get-TeamMembershipReport -IncludeGuests | Export-Excel

# Archive inactive teams
Get-InactiveTeams -Days 180 | Set-TeamArchiveStatus -Archive
```

## Quick Start

```powershell
# Install module
Install-Module Microsoft.Graph
Install-Module GraphExplorerToolkit

# Connect to Graph
Connect-GraphExplorer -TenantId "your-tenant"

# Run your first query
Get-GraphData -Resource "users" -Top 10
```

## Key Scripts Included

### Reports

- `Get-LicenseReport.ps1` - License usage and costs
- `Get-SecurityReport.ps1` - Security compliance status
- `Get-MailboxSizeReport.ps1` - Storage utilization
- `Get-GuestUserReport.ps1` - External user audit
- `Get-GroupMembershipReport.ps1` - Group memberships

### Automation

- `Sync-ADtoGraph.ps1` - Sync on-prem AD to Azure AD
- `Process-JoinersLeavers.ps1` - Onboarding/offboarding
- `Update-UserProperties.ps1` - Bulk property updates
- `Migrate-DistributionLists.ps1` - DL to M365 Groups
- `Backup-TeamsConfig.ps1` - Teams configuration backup

### Utilities

- `Test-GraphPermissions.ps1` - Verify API permissions
- `Convert-GraphData.ps1` - Transform API responses
- `Export-GraphSchema.ps1` - Document API schema
- `Monitor-GraphThrottling.ps1` - Track API limits
- `Invoke-GraphBatch.ps1` - Batch API requests

## Advanced Features

### Smart Query Builder

```powershell
# Build complex queries easily
$query = New-GraphQuery -Resource "users" `
    -Select "displayName,mail,department" `
    -Filter "department eq 'IT'" `
    -OrderBy "displayName" `
    -Top 100

Invoke-GraphQuery $query
```

### Batch Operations

```powershell
# Process in batches to avoid throttling
$users | Invoke-GraphBatch -BatchSize 20 -Operation {
    param($user)
    Update-GraphUser -Id $user.id -Department "NewDept"
}
```

### Error Handling

```powershell
# Automatic retry with exponential backoff
Invoke-GraphRequest -Uri $uri -RetryCount 3 -RetryDelay 2
```

### Custom Cmdlets

Create your own Graph cmdlets:

```powershell
function Get-CompanyPhones {
    Get-GraphData -Resource "users" `
        -Select "displayName,mobilePhone,businessPhones" `
        -Filter "companyName eq 'Contoso'"
}
```

### Pipeline Support

```powershell
# Chain operations
Get-GraphUsers |
    Where-Object { $_.accountEnabled -eq $false } |
    Set-GraphUserStatus -Enabled $true |
    Send-GraphMail -Template "AccountReactivated"
```

### Parallel Processing

```powershell
# Speed up bulk operations
$users | ForEach-Object -Parallel {
    Get-GraphUserDetails -Id $_.id
} -ThrottleLimit 10
```

## Export Options

- **CSV** - For Excel analysis
- **JSON** - For further processing
- **HTML** - For reports
- **XML** - For integration
- **SQLite** - For local database

## Security

- **Certificate Authentication** supported
- **Managed Identity** for Azure resources
- **Least Privilege** permission model
- **Audit Logging** of all operations
- **Secure Credential** storage

## Troubleshooting

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| Permission denied | Check app registration permissions |
| Throttling (429) | Use batch operations and delays |
| Token expired | Refresh with Connect-GraphExplorer |
| No data returned | Verify filter syntax and permissions |

## Documentation

- [Getting Started Guide](docs/getting-started.md)
- [Common Scenarios](docs/scenarios.md)
- [API Reference](docs/api-reference.md)
- [Best Practices](docs/best-practices.md)

## Requirements

- PowerShell 7.0 or higher
- Microsoft.Graph PowerShell module
- Azure AD app registration with appropriate permissions
- M365 tenant access

## Contributing

Contributions are welcome. Please follow PowerShell best practices and include appropriate documentation for new scripts.

## License

MIT License - See LICENSE file for details.

---

**Note**: These scripts require appropriate Microsoft Graph API permissions. Always test in a non-production environment first and follow your organization's change management procedures.

---

## Project Status & Roadmap

**[45% Complete]** - Core user/group management functional, key reports implemented

### What's Implemented (1,000+ lines of production code)
- ✅ **User Management** (5 scripts): Get info, list, create, update, delete users
- ✅ **Group Management** (6 scripts): Create, list, get members, add/remove users, delete groups
- ✅ **License Reporting**: Comprehensive license usage and cost analysis
- ✅ **Permission Testing**: Validate Graph API permissions before running scripts
- ✅ **Error Handling**: Proper try/catch, connection validation, parameter validation
- ✅ **Help Documentation**: Comment-based help with examples for all scripts
- ✅ **Pipeline Support**: ValueFromPipeline for batch operations

### What's NOT Done Yet (55%)
- ⏳ **Advanced Reports**: Guest user report, inactive users, mailbox sizes, security compliance
- ⏳ **Automation Scripts**: AD sync, joiners/leavers processing, bulk property updates
- ⏳ **Utility Scripts**: Batch operations, data conversion, schema export, throttling monitoring
- ⏳ **Teams Management**: Team creation, archiving, membership management
- ⏳ **Email/Calendar**: Mail search, calendar exports, out-of-office automation

### Current Status
Core user and group management scripts are production-ready and fully tested.
All scripts follow PowerShell best practices with proper error handling,
parameter validation, and comprehensive help documentation.

**Next Steps**: Implement remaining reporting, automation, and Teams management scripts.
