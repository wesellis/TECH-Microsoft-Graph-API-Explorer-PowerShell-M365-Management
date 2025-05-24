# Microsoft Graph API Explorer 🔗

[![PowerShell Gallery](https://img.shields.io/badge/PowerShell%20Gallery-Available-blue.svg)](https://www.powershellgallery.com/)
[![Graph API](https://img.shields.io/badge/Microsoft%20Graph-v1.0-brightgreen.svg)](https://docs.microsoft.com/graph/)
[![Linting](https://github.com/wesellis/Microsoft-Graph-API-Explorer/actions/workflows/powershell-lint.yml/badge.svg)](https://github.com/wesellis/Microsoft-Graph-API-Explorer/actions/workflows/powershell-lint.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Azure AD](https://img.shields.io/badge/Azure%20AD-Compatible-0078d4.svg)](https://azure.microsoft.com/services/active-directory/)

> **Comprehensive collection of PowerShell scripts for Microsoft Graph API automation, enabling seamless Microsoft 365 administration and user management.**

Streamline your Microsoft 365 operations with battle-tested PowerShell scripts that leverage the Microsoft Graph API for user management, group administration, security operations, and organizational automation.

## 🎯 Key Features

- **👥 User Management** - Create, update, delete, and query users across your organization
- **🏢 Group Administration** - Manage groups, memberships, and permissions at scale
- **🔐 Security Operations** - Monitor sign-ins, manage app registrations, and audit activities
- **📊 Reporting & Analytics** - Generate comprehensive reports and usage statistics
- **🔄 Automation Ready** - Production-ready scripts with error handling and logging
- **🛡️ Secure Authentication** - Multiple authentication methods including service principals
- **📚 Educational** - Well-documented examples for learning Graph API concepts
- **⚡ Performance Optimized** - Efficient batch operations and pagination handling

## 🚀 Quick Start

### Prerequisites

- **PowerShell 5.1+** or **PowerShell Core 6.0+**
- **Microsoft.Graph PowerShell SDK** (automatically installed)
- **Azure AD App Registration** with appropriate permissions
- **Microsoft 365 tenant** with administrative access

### Installation

```powershell
# Clone the repository
git clone https://github.com/wesellis/Microsoft-Graph-API-Explorer.git
cd Microsoft-Graph-API-Explorer

# Install required modules
Install-Module Microsoft.Graph -Force -AllowClobber
Install-Module Microsoft.Graph.Authentication -Force
Install-Module Microsoft.Graph.Users -Force
Install-Module Microsoft.Graph.Groups -Force

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"
```

### Basic Usage

```powershell
# Get user information
.\scripts\get-user-info.ps1 -UserId "user@domain.com"

# List all users in the organization
.\scripts\list-users.ps1 -OutputPath "./reports/users.csv"

# Create a new user
.\scripts\create-user.ps1 -DisplayName "John Doe" -UserPrincipalName "john@domain.com"

# Manage group memberships
.\scripts\add-user-to-group.ps1 -UserId "user@domain.com" -GroupId "group-id"
```

## 📁 Project Structure

```
Microsoft-Graph-API-Explorer/
├── 📁 scripts/                 # PowerShell automation scripts
│   ├── 👥 User Management
│   ├── 🏢 Group Administration
│   ├── 🔐 Security Operations
│   ├── 📊 Reporting & Analytics
│   └── 🔧 Utility Functions
├── 📁 templates/               # JSON templates and configurations
├── 📁 docs/                   # Documentation and guides
├── 📁 examples/               # Usage examples and tutorials
├── 📁 tests/                  # PowerShell Pester tests
└── 📁 modules/                # Custom PowerShell modules
```

## 🔧 Available Scripts

### 👥 **User Management**

| Script | Description | Key Parameters |
|--------|-------------|----------------|
| `get-user-info.ps1` | Retrieve detailed user information | `-UserId`, `-Properties` |
| `list-users.ps1` | List all users with filtering options | `-Filter`, `-OutputPath`, `-Format` |
| `create-user.ps1` | Create new user accounts | `-DisplayName`, `-UserPrincipalName`, `-Department` |
| `update-user.ps1` | Update existing user properties | `-UserId`, `-Properties`, `-Values` |
| `delete-user.ps1` | Remove user accounts safely | `-UserId`, `-Force`, `-BackupPath` |
| `bulk-user-operations.ps1` | Batch user operations from CSV | `-CsvPath`, `-Operation`, `-WhatIf` |

### 🏢 **Group Management**

| Script | Description | Key Parameters |
|--------|-------------|----------------|
| `list-groups.ps1` | List all groups with details | `-Filter`, `-Type`, `-OutputPath` |
| `create-group.ps1` | Create security or distribution groups | `-DisplayName`, `-Type`, `-Description` |
| `delete-group.ps1` | Remove groups with member backup | `-GroupId`, `-BackupMembers`, `-Force` |
| `get-group-members.ps1` | Retrieve group membership | `-GroupId`, `-Recursive`, `-OutputPath` |
| `add-user-to-group.ps1` | Add users to groups | `-UserId`, `-GroupId`, `-ValidateUser` |
| `remove-user-from-group.ps1` | Remove users from groups | `-UserId`, `-GroupId`, `-Confirm` |
| `sync-group-membership.ps1` | Synchronize group memberships | `-SourceGroup`, `-TargetGroup`, `-Mode` |

### 🔐 **Security & Compliance**

| Script | Description | Key Parameters |
|--------|-------------|----------------|
| `get-sign-in-logs.ps1` | Retrieve sign-in activity | `-UserId`, `-DateRange`, `-OutputPath` |
| `audit-app-permissions.ps1` | Audit application permissions | `-AppId`, `-OutputPath`, `-Detailed` |
| `get-security-alerts.ps1` | Retrieve security alerts | `-Severity`, `-Status`, `-DateRange` |
| `manage-conditional-access.ps1` | Manage conditional access policies | `-PolicyId`, `-Action`, `-Parameters` |
| `get-privileged-users.ps1` | Identify privileged role assignments | `-RoleFilter`, `-OutputPath`, `-IncludeGuests` |

### 📊 **Reporting & Analytics**

| Script | Description | Key Parameters |
|--------|-------------|----------------|
| `generate-user-report.ps1` | Comprehensive user analytics | `-OutputPath`, `-IncludeUsage`, `-Format` |
| `get-license-usage.ps1` | License allocation and usage | `-LicenseType`, `-OutputPath`, `-Summary` |
| `analyze-group-structure.ps1` | Group hierarchy and membership analysis | `-OutputPath`, `-IncludeNested`, `-Visualize` |
| `get-app-usage-stats.ps1` | Application usage statistics | `-AppId`, `-DateRange`, `-OutputPath` |
| `tenant-health-report.ps1` | Overall tenant health assessment | `-OutputPath`, `-IncludeRecommendations` |

### 🔧 **Utility & Configuration**

| Script | Description | Key Parameters |
|--------|-------------|----------------|
| `connect-graph.ps1` | Enhanced Graph connection with retry | `-TenantId`, `-Scopes`, `-Interactive` |
| `test-graph-permissions.ps1` | Validate required permissions | `-Scopes`, `-OutputPath`, `-Detailed` |
| `backup-configuration.ps1` | Backup tenant configuration | `-OutputPath`, `-IncludeUsers`, `-IncludeGroups` |
| `restore-configuration.ps1` | Restore from backup | `-BackupPath`, `-WhatIf`, `-Selective` |

## 🎨 Templates & Examples

### Authentication Templates
- **Service Principal Authentication** - Automated authentication for production
- **Interactive Authentication** - User-based authentication for development
- **Certificate-based Authentication** - High-security scenarios
- **Managed Identity** - Azure-hosted automation

### JSON Configuration Templates
- **User Creation Template** - Standardized user provisioning
- **Group Configuration** - Group creation with policies
- **App Registration** - Service principal setup
- **Conditional Access** - Security policy templates

## 📚 Documentation

- **[🚀 Getting Started Guide](docs/getting-started.md)** - Complete setup and first steps
- **[🔧 Script Reference](docs/script-reference.md)** - Detailed parameter documentation  
- **[🏗️ Architecture Guide](docs/architecture.md)** - Graph API integration patterns
- **[🔐 Security Best Practices](docs/security.md)** - Authentication and authorization
- **[📊 Reporting Guide](docs/reporting.md)** - Data export and visualization
- **[🔍 Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[🎓 Tutorials](docs/tutorials.md)** - Step-by-step learning guides

## 🎯 Use Cases

### **Enterprise User Management**
- Bulk user provisioning from HR systems
- Automated user lifecycle management
- Department-based access control
- Guest user management and cleanup

### **Group & Team Operations**
- Dynamic group membership based on user attributes
- Microsoft Teams provisioning and management
- Distribution list automation
- Security group access reviews

### **Security & Compliance**
- Privileged access monitoring
- Sign-in anomaly detection
- Application permission auditing
- Conditional access policy management

### **Reporting & Analytics**
- Executive dashboards and KPIs
- License optimization reports
- User activity and adoption metrics
- Security posture assessments

## 🔐 Authentication Methods

### Service Principal (Recommended for Automation)
```powershell
# Using client secret
Connect-MgGraph -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret

# Using certificate
Connect-MgGraph -TenantId $tenantId -ClientId $clientId -Certificate $cert
```

### Interactive Authentication (Development)
```powershell
# Browser-based authentication
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"

# Device code flow
Connect-MgGraph -UseDeviceAuthentication
```

### Managed Identity (Azure-hosted)
```powershell
# System-assigned managed identity
Connect-MgGraph -Identity

# User-assigned managed identity
Connect-MgGraph -Identity -ClientId $managedIdentityClientId
```

## 🛡️ Security Best Practices

### Permission Management
- **Principle of Least Privilege** - Request only required permissions
- **Scope Validation** - Verify permissions before script execution
- **Regular Audits** - Monitor and review granted permissions
- **Time-bound Access** - Use temporary elevated permissions when possible

### Credential Security
- **No Hardcoded Secrets** - Use secure credential storage
- **Certificate Authentication** - Prefer certificates over client secrets
- **Credential Rotation** - Regular secret and certificate updates
- **Audit Logging** - Track all authentication events

### Data Protection
- **Encryption in Transit** - HTTPS for all API communications
- **Secure Storage** - Encrypted storage for sensitive outputs
- **Data Minimization** - Collect only necessary user data
- **Retention Policies** - Automated cleanup of temporary data

## 🧪 Testing Framework

### Pester Test Coverage
```powershell
# Run all tests
Invoke-Pester -Path .\tests\ -CodeCoverage .\scripts\*.ps1

# Test specific functionality
Invoke-Pester -Path .\tests\UserManagement.Tests.ps1 -Verbose

# Integration tests with test tenant
Invoke-Pester -Path .\tests\Integration.Tests.ps1 -Tag "Integration"
```

### Test Categories
- **Unit Tests** - Individual script validation
- **Integration Tests** - End-to-end workflow testing
- **Permission Tests** - Required scope validation
- **Security Tests** - Authentication and authorization validation

## 🤝 Contributing

We welcome contributions from the Microsoft 365 and PowerShell communities! Whether you're fixing bugs, adding new scripts, or improving documentation, your help makes this toolkit better for everyone.

**[📋 Contributing Guidelines →](CONTRIBUTING.md)**

### Quick Contribution Steps
1. **🍴 Fork** the repository
2. **🌿 Create** a feature branch (`git checkout -b feature/new-graph-script`)
3. **📝 Commit** your changes (`git commit -m 'Add new user reporting script'`)
4. **📤 Push** to the branch (`git push origin feature/new-graph-script`)
5. **🔄 Create** a Pull Request

### Areas We Need Help With
- **🆕 New Scripts** - Additional Graph API automation
- **🧪 Testing** - Pester test coverage expansion
- **📖 Documentation** - Usage examples and tutorials
- **🐛 Bug Fixes** - Issue resolution and improvements
- **🔒 Security** - Authentication and permission optimization

## 📊 Project Stats

- **25+** PowerShell scripts covering major Graph API scenarios
- **🔄** Automated testing with Pester framework
- **🔍** PowerShell linting and security validation
- **📖** Comprehensive documentation and examples
- **🤝** Community-driven development and contributions
- **🔐** Production-ready security and error handling

## 🌐 Microsoft Graph Integration

### Supported Graph API Versions
- **Microsoft Graph v1.0** - Production workloads (recommended)
- **Microsoft Graph beta** - Preview features (development only)

### Covered Graph API Endpoints
- **Users** - `/users`, `/me`, `/users/{id}/memberOf`
- **Groups** - `/groups`, `/groups/{id}/members`, `/groups/{id}/owners`
- **Applications** - `/applications`, `/servicePrincipals`
- **Directory** - `/directoryRoles`, `/directoryObjects`
- **Security** - `/security/alerts`, `/auditLogs/signIns`
- **Reports** - `/reports/getEmailActivityUserDetail`

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the file for details.

## 🆘 Support

- **🐛 Bug Reports** - [Create an issue](https://github.com/wesellis/Microsoft-Graph-API-Explorer/issues/new?template=bug_report.md)
- **💡 Feature Requests** - [Suggest improvements](https://github.com/wesellis/Microsoft-Graph-API-Explorer/issues/new?template=feature_request.md)
- **❓ Questions** - [Start a discussion](https://github.com/wesellis/Microsoft-Graph-API-Explorer/discussions)
- **📖 Documentation** - Check our [docs folder](docs/) for comprehensive guides

## 🙏 Acknowledgments

- **Microsoft Graph Team** - For the comprehensive API and excellent documentation
- **PowerShell Community** - For tools, modules, and best practices
- **Microsoft 365 Community** - For feedback, testing, and real-world scenarios
- **Contributors** - For making this toolkit better with code, documentation, and ideas

## 🔗 Related Resources

- **[Microsoft Graph Documentation](https://docs.microsoft.com/graph/)** - Official API documentation
- **[Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)** - Interactive API testing
- **[Microsoft Graph PowerShell SDK](https://github.com/microsoftgraph/msgraph-sdk-powershell)** - Official PowerShell module
- **[Graph API Permissions Reference](https://docs.microsoft.com/graph/permissions-reference)** - Complete permissions documentation

---

<div align="center">

**⭐ Star this repo if it helps your Microsoft 365 automation! ⭐**

Made with ❤️ for Microsoft 365 administrators and developers

[🚀 Get Started](docs/getting-started.md) • [📖 Documentation](docs/) • [🤝 Contribute](CONTRIBUTING.md) • [💬 Discussions](https://github.com/wesellis/Microsoft-Graph-API-Explorer/discussions)

</div>
