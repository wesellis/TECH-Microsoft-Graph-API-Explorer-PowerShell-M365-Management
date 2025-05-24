# Getting Started with Microsoft Graph API Explorer

This guide will help you get started with the Microsoft Graph API Explorer, a comprehensive collection of PowerShell scripts for Microsoft 365 automation and management.

## 🎯 Prerequisites

### Software Requirements
- **PowerShell 5.1** or **PowerShell Core 6.0+** (PowerShell 7.x recommended)
- **Microsoft Graph PowerShell SDK** (automatically installed)
- **Git** for cloning the repository
- **Visual Studio Code** (recommended) with PowerShell extension

### Microsoft 365 Requirements
- **Microsoft 365 tenant** with appropriate licensing
- **Azure AD App Registration** with required permissions
- **Administrative access** to the tenant for setup
- **Appropriate role assignments** for your user account

### Required Knowledge
- Basic PowerShell scripting concepts
- Understanding of Microsoft 365 user and group management
- Familiarity with Azure AD concepts (users, groups, roles)
- Basic understanding of REST APIs and authentication

## 🚀 Installation and Setup

### Step 1: Clone the Repository

```powershell
# Clone the repository
git clone https://github.com/wesellis/Microsoft-Graph-API-Explorer.git
cd Microsoft-Graph-API-Explorer
```

### Step 2: Install Required PowerShell Modules

```powershell
# Install Microsoft Graph PowerShell SDK
Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser

# Install specific Graph modules for different functionality
Install-Module Microsoft.Graph.Authentication -Force -Scope CurrentUser
Install-Module Microsoft.Graph.Users -Force -Scope CurrentUser
Install-Module Microsoft.Graph.Groups -Force -Scope CurrentUser
Install-Module Microsoft.Graph.Security -Force -Scope CurrentUser
Install-Module Microsoft.Graph.Reports -Force -Scope CurrentUser
Install-Module Microsoft.Graph.Applications -Force -Scope CurrentUser

# Verify installation
Get-Module Microsoft.Graph* -ListAvailable
```

### Step 3: Azure AD App Registration Setup

#### Option A: Interactive Authentication (Recommended for Getting Started)

For initial testing and development, you can use interactive authentication:

```powershell
# Connect with interactive authentication
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Directory.Read.All"

# Verify connection
Get-MgContext
```

#### Option B: App Registration for Production (Recommended for Automation)

1. **Create App Registration in Azure Portal:**
   - Navigate to Azure Portal → Azure Active Directory → App registrations
   - Click "New registration"
   - Name: "Microsoft Graph API Explorer"
   - Supported account types: "Accounts in this organizational directory only"
   - Redirect URI: Leave blank for now
   - Click "Register"

2. **Configure API Permissions:**
   ```
   Microsoft Graph (Application permissions):
   - User.Read.All
   - Group.Read.All
   - Directory.Read.All
   - AuditLog.Read.All
   - Reports.Read.All
   
   Microsoft Graph (Delegated permissions):
   - User.ReadWrite.All
   - Group.ReadWrite.All
   - Directory.ReadWrite.All
   ```

3. **Grant Admin Consent:**
   - In the app registration, go to "API permissions"
   - Click "Grant admin consent for [Your Organization]"

4. **Create Client Secret:**
   - Go to "Certificates & secrets"
   - Click "New client secret"
   - Add description and expiration
   - Copy the secret value (you won't see it again!)

### Step 4: Authentication Configuration

#### Service Principal Authentication

```powershell
# Store credentials securely (do this once)
$tenantId = "your-tenant-id"
$clientId = "your-app-registration-client-id"
$clientSecret = "your-client-secret" | ConvertTo-SecureString -AsPlainText -Force

# Connect using service principal
$credential = New-Object System.Management.Automation.PSCredential($clientId, $clientSecret)
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $credential
```

#### Certificate-Based Authentication (Most Secure)

```powershell
# Create self-signed certificate (for testing)
$cert = New-SelfSignedCertificate -Subject "CN=GraphAPIExplorer" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature

# Export certificate for app registration
Export-Certificate -Cert $cert -FilePath "GraphAPIExplorer.cer"

# Connect using certificate
Connect-MgGraph -TenantId $tenantId -ClientId $clientId -Certificate $cert
```

## 🧪 Testing Your Setup

### Verify Connection and Permissions

```powershell
# Test basic connectivity
Get-MgContext

# Test user access
Get-MgUser -Top 5 | Select-Object DisplayName, UserPrincipalName

# Test group access
Get-MgGroup -Top 5 | Select-Object DisplayName, GroupTypes

# Check your permissions
Get-MgContext | Select-Object Scopes
```

### Run Your First Script

```powershell
# Get information about a specific user
.\scripts\get-user-info.ps1 -UserId "user@yourdomain.com"

# List all users in your organization
.\scripts\list-users.ps1 -OutputPath "./my-users.csv"

# Get group membership for a user
.\scripts\get-user-groups.ps1 -UserId "user@yourdomain.com"
```

## 📚 Understanding the Scripts

### Script Categories

#### 👥 User Management Scripts
- **get-user-info.ps1** - Retrieve detailed user information
- **list-users.ps1** - List all users with filtering options
- **create-user.ps1** - Create new user accounts
- **update-user.ps1** - Update user properties
- **delete-user.ps1** - Remove user accounts safely

#### 🏢 Group Management Scripts
- **list-groups.ps1** - List all groups with details
- **create-group.ps1** - Create security or distribution groups
- **get-group-members.ps1** - Retrieve group membership
- **add-user-to-group.ps1** - Add users to groups
- **remove-user-from-group.ps1** - Remove users from groups

### Common Parameters

Most scripts support these common parameters:

```powershell
# Output options
-OutputPath "C:\Reports\output.csv"    # Export results to file
-Format "CSV" | "JSON" | "Console"     # Output format

# Filtering options
-Filter "department eq 'IT'"           # OData filter
-Top 100                               # Limit results

# What-if support
-WhatIf                                # Preview changes without executing
-Confirm                               # Prompt for confirmation

# Verbose output
-Verbose                               # Detailed operation logging
```

## 🎯 Common Use Cases

### User Lifecycle Management

```powershell
# Onboard new employee
.\scripts\create-user.ps1 -DisplayName "John Doe" -UserPrincipalName "john.doe@company.com" -Department "IT"

# Add to appropriate groups
.\scripts\add-user-to-group.ps1 -UserId "john.doe@company.com" -GroupName "IT Department"

# Offboard employee
.\scripts\delete-user.ps1 -UserId "john.doe@company.com" -BackupPath "./backups/"
```

### Group Management

```powershell
# Create department group
.\scripts\create-group.ps1 -DisplayName "Marketing Team" -Description "Marketing Department"

# Add multiple users to group
$users = @("user1@company.com", "user2@company.com", "user3@company.com")
foreach ($user in $users) {
    .\scripts\add-user-to-group.ps1 -UserId $user -GroupName "Marketing Team"
}

# Generate group membership report
.\scripts\get-group-members.ps1 -GroupName "Marketing Team" -OutputPath "./reports/marketing-members.csv"
```

### Reporting and Analytics

```powershell
# Generate comprehensive user report
.\scripts\generate-user-report.ps1 -OutputPath "./reports/" -IncludeGroups -IncludeLicenses

# Audit group memberships
.\scripts\audit-group-memberships.ps1 -OutputPath "./audits/"

# Get inactive users
.\scripts\get-inactive-users.ps1 -DaysInactive 90 -OutputPath "./reports/inactive-users.csv"
```

## 🔐 Security Best Practices

### Authentication Security
1. **Use Certificate Authentication** for production automation
2. **Rotate Secrets Regularly** if using client secrets
3. **Apply Least Privilege** - only request necessary permissions
4. **Monitor Authentication** - track sign-ins and API usage

### Data Protection
1. **Encrypt Sensitive Outputs** when exporting user data
2. **Use Secure Storage** for credentials and configuration
3. **Implement Audit Logging** for all operations
4. **Regular Permission Reviews** of app registrations

### Operational Security
```powershell
# Always verify context before operations
$context = Get-MgContext
if (-not $context) {
    Write-Error "Not connected to Microsoft Graph"
    exit 1
}

# Use -WhatIf for testing
.\scripts\update-user.ps1 -UserId "user@company.com" -Department "HR" -WhatIf

# Implement proper error handling
try {
    Get-MgUser -UserId "user@company.com"
}
catch {
    Write-Error "Failed to get user: $($_.Exception.Message)"
}
```

## 🛠️ Troubleshooting Common Issues

### Authentication Issues

**Problem**: "Insufficient privileges to complete the operation"
```powershell
# Solution: Check and add required permissions
Get-MgContext | Select-Object Scopes
# Add missing scopes and reconnect
```

**Problem**: "The tenant for tenant guid does not exist"
```powershell
# Solution: Verify tenant ID
$tenantId = (Get-MgContext).TenantId
Write-Host "Current Tenant ID: $tenantId"
```

### Permission Issues

**Problem**: Scripts fail with permission errors
1. Verify app registration has required permissions
2. Ensure admin consent has been granted
3. Check if Conditional Access policies block the app

### Script Execution Issues

**Problem**: "Execution policy restriction"
```powershell
# Solution: Update execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Problem**: Module import errors
```powershell
# Solution: Reinstall Graph modules
Uninstall-Module Microsoft.Graph -AllVersions -Force
Install-Module Microsoft.Graph -Force -AllowClobber
```

## 📈 Next Steps

### Beginner Level
1. **Master Basic Scripts** - Start with get-user-info.ps1 and list-users.ps1
2. **Understand Authentication** - Practice with interactive authentication
3. **Learn Filtering** - Use OData filters to refine results
4. **Practice Safely** - Always use -WhatIf first

### Intermediate Level
1. **Automation Setup** - Configure service principal authentication
2. **Custom Scripts** - Modify existing scripts for your needs
3. **Bulk Operations** - Process large datasets efficiently
4. **Error Handling** - Implement robust error handling

### Advanced Level
1. **Production Deployment** - Set up automated workflows
2. **Integration** - Connect with other systems and tools
3. **Custom Modules** - Create reusable PowerShell modules
4. **Monitoring** - Implement logging and alerting

## 📖 Additional Resources

### Microsoft Documentation
- [Microsoft Graph API Reference](https://docs.microsoft.com/graph/api/overview)
- [Microsoft Graph PowerShell SDK](https://docs.microsoft.com/powershell/microsoftgraph/)
- [App Registration Guide](https://docs.microsoft.com/azure/active-directory/develop/quickstart-register-app)
- [Graph Permissions Reference](https://docs.microsoft.com/graph/permissions-reference)

### Learning Resources
- [Microsoft Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)
- [Graph API Quick Start](https://docs.microsoft.com/graph/quick-start)
- [PowerShell for Microsoft 365](https://docs.microsoft.com/microsoft-365/enterprise/manage-microsoft-365-with-microsoft-365-powershell)

### Community Resources
- [Microsoft Graph Blog](https://developer.microsoft.com/graph/blogs/)
- [PowerShell Community](https://docs.microsoft.com/powershell/scripting/community/community-support)
- [Microsoft 365 Tech Community](https://techcommunity.microsoft.com/t5/microsoft-365/ct-p/microsoft365)

Happy automating with Microsoft Graph! 🚀
