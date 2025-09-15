# 🔍 Microsoft Graph API Explorer PowerShell Toolkit
### M365 Management and Automation Scripts

[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-5391FE?style=for-the-badge&logo=powershell)](https://docs.microsoft.com/powershell/)
[![Graph API](https://img.shields.io/badge/Graph_API-v1.0-00BCF2?style=for-the-badge&logo=microsoft)](https://graph.microsoft.com)
[![M365](https://img.shields.io/badge/M365-All_Services-FF6900?style=for-the-badge&logo=microsoft-office)](https://www.microsoft.com/microsoft-365)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

## 🎯 Overview

PowerShell toolkit for exploring and managing Microsoft 365 services through Graph API. Simplifies complex API calls, provides ready-to-use scripts for common tasks, and helps IT admins manage M365 environments efficiently.

### 📊 What It Does

- **Explore Graph API** without writing complex code
- **Manage Users** across Azure AD and M365
- **Automate Reports** for compliance and auditing
- **Handle Bulk Operations** on mailboxes, groups, teams
- **Export Data** in multiple formats
- **Test API Calls** before implementation

## 💡 Common Use Cases

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

## ⚡ Quick Start

```powershell
# Install module
Install-Module Microsoft.Graph
Install-Module GraphExplorerToolkit

# Connect to Graph
Connect-GraphExplorer -TenantId "your-tenant"

# Run your first query
Get-GraphData -Resource "users" -Top 10
```

## 🛠️ Key Scripts Included

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

## 📈 Features

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

## 🔧 Advanced Features

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

## 📊 Export Options

- **CSV** - For Excel analysis
- **JSON** - For further processing
- **HTML** - For reports
- **XML** - For integration
- **SQLite** - For local database

## 🔒 Security

- **Certificate Authentication** supported
- **Managed Identity** for Azure resources
- **Least Privilege** permission model
- **Audit Logging** of all operations
- **Secure Credential** storage

## 🐛 Troubleshooting

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| Permission denied | Check app registration permissions |
| Throttling (429) | Use batch operations and delays |
| Token expired | Refresh with Connect-GraphExplorer |
| No data returned | Verify filter syntax and permissions |

## 📚 Documentation

- [Getting Started Guide](docs/getting-started.md)
- [Common Scenarios](docs/scenarios.md)
- [API Reference](docs/api-reference.md)
- [Best Practices](docs/best-practices.md)

## 🤝 Contributing

Contributions welcome! Share your useful Graph API scripts.

## 📜 License

MIT License - Free for all use

---

<div align="center">

**Simplify Microsoft Graph API Management**

[![Download](https://img.shields.io/badge/Download-Latest-brightgreen?style=for-the-badge)](https://github.com/yourusername/graph-explorer-toolkit/releases)

*Free • Open Source • Community Driven*

</div>