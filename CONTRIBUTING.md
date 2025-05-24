# Contributing to Microsoft Graph API Explorer

Thank you for your interest in contributing to the Microsoft Graph API Explorer! This project helps Microsoft 365 administrators and developers automate and manage their organizations through PowerShell and the Microsoft Graph API.

## 🌟 Ways to Contribute

### 💻 **Code Contributions**
- **New PowerShell scripts** for Graph API automation
- **Enhanced authentication methods** and security improvements
- **Bug fixes** and performance optimizations
- **Utility functions** and helper modules
- **Test coverage** with PowerShell Pester tests

### 📖 **Documentation**
- **Usage examples** and real-world scenarios
- **API integration guides** and best practices
- **Security documentation** for authentication and permissions
- **Troubleshooting guides** and FAQs
- **Tutorial content** for learning Graph API concepts

### 🧪 **Quality Assurance**
- **Testing scripts** across different Microsoft 365 environments
- **Permission validation** and security reviews
- **Performance testing** with large datasets
- **Cross-platform compatibility** (Windows, Linux, macOS)

## 🚀 Getting Started

### Prerequisites

- **PowerShell 5.1+** or **PowerShell Core 6.0+**
- **Microsoft Graph PowerShell SDK** (`Install-Module Microsoft.Graph`)
- **Azure AD App Registration** for testing
- **Microsoft 365 tenant** (dev tenant recommended)
- **Git** for version control
- **Visual Studio Code** with PowerShell extension (recommended)

### Development Environment Setup

1. **Fork and clone the repository**
   ```powershell
   git clone https://github.com/YOUR-USERNAME/Microsoft-Graph-API-Explorer.git
   cd Microsoft-Graph-API-Explorer
   ```

2. **Install required PowerShell modules**
   ```powershell
   # Microsoft Graph SDK
   Install-Module Microsoft.Graph -Force -AllowClobber
   Install-Module Microsoft.Graph.Authentication -Force
   Install-Module Microsoft.Graph.Users -Force
   Install-Module Microsoft.Graph.Groups -Force
   Install-Module Microsoft.Graph.Security -Force
   Install-Module Microsoft.Graph.Reports -Force
   
   # Development tools
   Install-Module Pester -Force
   Install-Module PSScriptAnalyzer -Force
   Install-Module platyPS -Force
   ```

3. **Set up test environment**
   ```powershell
   # Connect to your development tenant
   Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Directory.Read.All"
   
   # Verify connection
   Get-MgContext
   ```

4. **Create a feature branch**
   ```powershell
   git checkout -b feature/your-feature-name
   ```

## 📝 Development Guidelines

### PowerShell Script Standards

#### **Script Structure Template**
```powershell
<#
.SYNOPSIS
    Brief description of what the script does

.DESCRIPTION
    Detailed description of the script's functionality, use cases, and any important notes.
    Include information about required Graph API permissions and scopes.

.PARAMETER ParameterName
    Description of the parameter, including type, required/optional status, and expected values

.EXAMPLE
    PS> .\script-name.ps1 -Parameter "value"
    Description of what this example demonstrates

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0
    Requires: Microsoft.Graph.Users module
    Graph API Permissions: User.Read.All, Group.Read.All

.LINK
    https://docs.microsoft.com/graph/api/user-get
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Description of parameter")]
    [ValidateNotNullOrEmpty()]
    [string]$ParameterName,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Option1", "Option2", "Option3")]
    [string]$OptionalParameter = "Option1"
)

# Import required modules with error handling
try {
    Import-Module Microsoft.Graph.Users -ErrorAction Stop
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
}
catch {
    Write-Error "Failed to import required modules: $($_.Exception.Message)"
    exit 1
}

# Verify Graph connection
try {
    $context = Get-MgContext
    if (-not $context) {
        Write-Error "Not connected to Microsoft Graph. Run Connect-MgGraph first."
        exit 1
    }
}
catch {
    Write-Error "Failed to verify Graph connection: $($_.Exception.Message)"
    exit 1
}

# Main script logic here
```

#### **Coding Standards**

- **Use approved PowerShell verbs** (`Get-Verb` for reference)
- **Include comprehensive error handling** with try/catch blocks
- **Add parameter validation** with appropriate attributes
- **Use meaningful variable names** that describe their purpose
- **Include progress indicators** for long-running operations
- **Add verbose output** for debugging (`Write-Verbose`)
- **Follow PowerShell naming conventions** (PascalCase for functions)
- **Include Graph API permission requirements** in documentation

#### **Microsoft Graph Best Practices**

- **Permission Scope Validation** - Check required permissions before execution
- **Error Handling** - Handle Graph API throttling and transient errors
- **Pagination** - Properly handle paginated results for large datasets
- **Batch Operations** - Use batch requests for multiple operations
- **Rate Limiting** - Implement appropriate delays for large operations
- **Resource Validation** - Verify resources exist before operations

### Security Requirements

#### **Authentication Security**
```powershell
# Example secure authentication pattern
function Connect-SecureGraph {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Scopes = @("User.Read.All")
    )
    
    try {
        # Prefer certificate-based authentication for production
        if ($env:GRAPH_CLIENT_CERTIFICATE_PATH) {
            $cert = Get-ChildItem -Path $env:GRAPH_CLIENT_CERTIFICATE_PATH
            Connect-MgGraph -TenantId $TenantId -ClientId $env:GRAPH_CLIENT_ID -Certificate $cert
        }
        else {
            # Interactive authentication for development
            Connect-MgGraph -TenantId $TenantId -Scopes $Scopes
        }
        
        Write-Verbose "Successfully connected to Microsoft Graph"
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        throw
    }
}
```

#### **Data Security Guidelines**
- **No Hardcoded Secrets** - Use environment variables or secure storage
- **Minimal Data Exposure** - Only request necessary user properties
- **Secure Output** - Encrypt sensitive data in output files
- **Audit Logging** - Log all operations for security auditing
- **Input Sanitization** - Validate and sanitize all user inputs

## 🧪 Testing Requirements

### Unit Testing with Pester

Create comprehensive tests for all new functionality:

```powershell
BeforeAll {
    # Import the script being tested
    . "$PSScriptRoot\..\scripts\your-script.ps1"
    
    # Mock Graph API calls for testing
    Mock Connect-MgGraph { return $true }
    Mock Get-MgUser { 
        return @{
            Id = "test-user-id"
            DisplayName = "Test User"
            UserPrincipalName = "test@domain.com"
        }
    }
}

Describe "Your-Script Function Tests" {
    Context "Parameter Validation" {
        It "Should require mandatory parameters" {
            { Your-Function } | Should -Throw
        }
        
        It "Should validate parameter values" {
            { Your-Function -Parameter "InvalidValue" } | Should -Throw
        }
    }
    
    Context "Graph API Integration" {
        It "Should handle Graph API responses correctly" {
            $result = Your-Function -Parameter "ValidValue"
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle Graph API errors gracefully" {
            Mock Get-MgUser { throw "Graph API Error" }
            { Your-Function -Parameter "ValidValue" } | Should -Throw
        }
    }
    
    Context "Output Validation" {
        It "Should return expected object structure" {
            $result = Your-Function -Parameter "ValidValue"
            $result | Should -HaveProperty "Id"
            $result | Should -HaveProperty "DisplayName"
        }
    }
}
```

### Integration Testing

Test with real Microsoft Graph API:

```powershell
Describe "Integration Tests" -Tag "Integration" {
    BeforeAll {
        # Connect to test tenant
        $testTenantId = $env:TEST_TENANT_ID
        if (-not $testTenantId) {
            throw "TEST_TENANT_ID environment variable not set"
        }
        
        Connect-MgGraph -TenantId $testTenantId -Scopes "User.Read.All"
    }
    
    Context "Real Graph API Operations" {
        It "Should retrieve user information from Graph API" {
            $users = Get-MgUser -Top 1
            $users | Should -Not -BeNullOrEmpty
        }
    }
    
    AfterAll {
        Disconnect-MgGraph
    }
}
```

### Required Test Coverage

- **Parameter validation** and input sanitization
- **Graph API integration** with mocked responses
- **Error handling** for various failure scenarios
- **Permission validation** for required scopes
- **Output format validation** and data integrity
- **Integration tests** with real Graph API (optional)

## 📋 Submission Process

### Before Submitting

1. **Run PowerShell Script Analyzer**
   ```powershell
   Invoke-ScriptAnalyzer -Path .\scripts\your-script.ps1 -Severity Error,Warning
   ```

2. **Execute Pester tests**
   ```powershell
   Invoke-Pester -Path .\tests\ -CodeCoverage .\scripts\*.ps1
   ```

3. **Test with real Graph API** (if applicable)

4. **Update documentation** and help content

5. **Verify Graph API permissions** are documented

### Pull Request Guidelines

#### **PR Title Format**
- `feat: add user license management script`
- `fix: resolve pagination issue in group listing`
- `docs: improve authentication setup guide`
- `test: add integration tests for user operations`

#### **PR Description Template**
```markdown
## Description
Brief description of changes and the Microsoft Graph API functionality added/improved

## Type of Change
- [ ] New Graph API script or functionality
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] Enhancement to existing script
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Security improvement

## Graph API Details
- **Endpoints Used**: /users, /groups, etc.
- **Required Permissions**: User.Read.All, Group.Read.All
- **API Version**: v1.0 or beta
- **Pagination Handled**: Yes/No

## Testing Performed
- [ ] PowerShell Script Analyzer validation passed
- [ ] Pester unit tests pass
- [ ] Integration tests with Graph API completed
- [ ] Tested with test tenant
- [ ] Permission requirements validated
- [ ] Error scenarios tested

## Security Considerations
- [ ] No hardcoded credentials or secrets
- [ ] Appropriate permission scopes requested
- [ ] Input validation implemented
- [ ] Error messages don't expose sensitive information
- [ ] Audit logging included where appropriate

## Documentation Updates
- [ ] Script help documentation updated
- [ ] README.md updated if needed
- [ ] Examples provided
- [ ] Permission requirements documented

## Checklist
- [ ] Code follows project coding standards
- [ ] Self-review completed
- [ ] No breaking changes introduced
- [ ] Graph API best practices followed
```

## 🔍 Code Review Process

### What Reviewers Look For

- **Graph API Integration** - Correct API usage and error handling
- **Security** - Proper authentication and permission handling
- **Performance** - Efficient API calls and data processing
- **Maintainability** - Clear code structure and documentation
- **Testing** - Adequate test coverage and validation
- **Best Practices** - Following Microsoft Graph and PowerShell standards

### Review Timeline

- **Initial review** within 3-5 business days
- **Follow-up reviews** within 2 business days
- **Approval and merge** after all checks pass

## 🎯 Priority Areas

### High-Priority Contributions

- **Modern Authentication** - Advanced authentication scenarios
- **Security & Compliance** - Advanced security operations and auditing
- **Reporting & Analytics** - Enhanced reporting with data visualization
- **Bulk Operations** - Large-scale user and group management
- **Integration Examples** - Real-world automation scenarios

### Beginner-Friendly Tasks

- **Documentation improvements** - Fix typos, add examples
- **Test coverage** - Add Pester tests for existing scripts
- **Error message enhancement** - Improve user-friendly error messages
- **Parameter validation** - Add better input validation
- **Help documentation** - Improve comment-based help

## 📞 Getting Help

### Development Resources

- **[Microsoft Graph Documentation](https://docs.microsoft.com/graph/)** - Official API documentation
- **[Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)** - Interactive API testing
- **[PowerShell SDK Documentation](https://docs.microsoft.com/powershell/microsoftgraph/)** - PowerShell module documentation
- **[Graph API Permissions](https://docs.microsoft.com/graph/permissions-reference)** - Complete permissions reference

### Support Channels

- **💬 GitHub Discussions** - [Ask questions and discuss ideas](https://github.com/wesellis/Microsoft-Graph-API-Explorer/discussions)
- **🐛 GitHub Issues** - [Report bugs or request features](https://github.com/wesellis/Microsoft-Graph-API-Explorer/issues)
- **📧 Direct Contact** - Check repository for maintainer contact information

## 🏆 Recognition

Contributors are recognized through:
- **README.md** acknowledgments section
- **Release notes** credit for contributions
- **Special recognition** for significant contributions
- **Collaborator access** for ongoing contributors

## 📜 Code of Conduct

This project follows the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). By participating, you agree to abide by its terms.

### Our Standards

- **Be respectful** and inclusive in all interactions
- **Provide constructive feedback** and suggestions
- **Focus on Microsoft Graph** and PowerShell best practices
- **Help create a welcoming environment** for all skill levels

## 🔒 Security Policy

### Reporting Security Issues

If you discover a security vulnerability:
1. **Do not** open a public issue
2. **Email** the maintainer directly (check repository for contact)
3. **Include** detailed information about the vulnerability
4. **Wait** for confirmation before public disclosure

### Security Guidelines

- **No credential exposure** - Never include real credentials in code or documentation
- **Safe API operations** - Validate all operations before execution
- **Input sanitization** - Sanitize all user inputs and parameters
- **Audit compliance** - Ensure operations are auditable and trackable

---

Thank you for contributing to Microsoft Graph API Explorer! Your efforts help the Microsoft 365 community automate and manage their environments more effectively. 🚀✨
