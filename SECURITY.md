# Security Policy - Microsoft Graph API Explorer

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| Previous| :white_check_mark: |
| Older   | :x:                |

## Security Features

### Microsoft Graph Integration Security
- **Secure Authentication** - Service principal and certificate-based authentication
- **Least Privilege Access** - Granular permission scope validation
- **Token Management** - Secure handling of Azure AD tokens and refresh tokens
- **Graph API Compliance** - Microsoft security standards adherence
- **Audit Logging** - Complete activity tracking and security event logging

### PowerShell Script Security
- **Input Validation** - Parameter validation and sanitization
- **Execution Policy** - Signed script enforcement recommendations
- **Credential Protection** - Secure credential storage patterns
- **Error Handling** - Security-aware error responses
- **Code Signing** - Digital signature verification support

### Enterprise Data Protection
- **Data Encryption** - Microsoft 365 data encryption at rest and in transit
- **API Security** - HTTPS-only Microsoft Graph API communications
- **Access Controls** - Azure AD conditional access integration
- **Audit Trails** - Microsoft 365 audit log integration
- **Data Residency** - Geographic compliance for enterprise data

### Infrastructure Security
- **Azure AD Integration** - Native Microsoft identity platform security
- **Multi-tenant Isolation** - Tenant boundary enforcement
- **Rate Limiting** - Microsoft Graph API throttling compliance
- **DDoS Protection** - Azure infrastructure security benefits
- **Regular Updates** - PowerShell and Graph SDK security patches

## Microsoft Graph Specific Vulnerabilities

### High-Risk Scenarios
- **Overprivileged Applications** - Service principals with excessive permissions
- **Token Exposure** - Access tokens in logs or insecure storage
- **Permission Escalation** - Unintended administrative access through scripts
- **Data Exfiltration** - Bulk export of sensitive Microsoft 365 data
- **Tenant Compromise** - Malicious automation with administrative permissions

### Authentication Vulnerabilities
- **Client Secret Exposure** - Hardcoded secrets in scripts or repositories
- **Certificate Compromise** - Stolen or improperly secured authentication certificates
- **Consent Phishing** - Malicious applications requesting excessive permissions
- **Session Hijacking** - Intercepted or reused authentication tokens
- **Replay Attacks** - Reused authentication requests or tokens

## Reporting a Vulnerability

**DO NOT** create a public GitHub issue for security vulnerabilities affecting Microsoft Graph integration.

### How to Report
Email: **security@wesellis.com**
- **Microsoft Graph Issues**: Report through Microsoft Security Response Center (MSRC)
- **Script Vulnerabilities**: Report directly to this project
- **PowerShell Issues**: Report to PowerShell Security Team

### Information to Include
- **Description**: Detailed vulnerability description and potential impact
- **Graph API Scope**: Affected Microsoft Graph endpoints or permissions
- **Authentication Method**: Which authentication flow is affected
- **Steps to Reproduce**: Complete reproduction steps with sample data
- **Affected Versions**: PowerShell versions and Microsoft Graph SDK versions
- **Tenant Impact**: Multi-tenant vs single-tenant vulnerability scope
- **Suggested Fixes**: Proposed remediation approaches

### Response Timeline
- **Acknowledgment**: Within 24 hours
- **Initial Assessment**: Within 72 hours
- **Security Coordination**: With Microsoft MSRC for Graph API issues
- **Status Updates**: Weekly until resolved
- **Fix Development**: 1-14 days (severity dependent)
- **Security Release**: Coordinated with Microsoft for Graph API fixes

## Severity Classification

### Critical (CVSS 9.0-10.0)
- **Tenant Takeover** - Complete administrative access to Microsoft 365 tenant
- **Mass Data Exfiltration** - Bulk export of all organizational data
- **Authentication Bypass** - Circumventing Azure AD authentication entirely
- **Service Disruption** - Scripts that can disable entire Microsoft 365 services

**Response**: 24-48 hours with immediate Microsoft coordination

### High (CVSS 7.0-8.9)
- **Privilege Escalation** - Elevation to Global Administrator or similar roles
- **Significant Data Exposure** - Access to sensitive user or organizational data
- **Authentication Weaknesses** - Token theft or authentication manipulation
- **Cross-tenant Access** - Unintended access to other organizations' data

**Response**: 3-7 days with Microsoft security team coordination

### Medium (CVSS 4.0-6.9)
- **Limited Data Exposure** - Access to non-sensitive organizational information
- **Service Availability** - Performance impact or limited service disruption
- **Information Disclosure** - Metadata or configuration information exposure
- **Audit Evasion** - Ability to avoid detection in audit logs

**Response**: 7-14 days

### Low (CVSS 0.1-3.9)
- **Minor Information Leakage** - Limited metadata exposure
- **Security Hardening** - Opportunities to improve security posture
- **Configuration Issues** - Non-optimal security configurations

**Response**: 14-30 days

## Security Best Practices

### For Microsoft 365 Administrators
- **Application Permissions Review** - Regular audit of Graph API permissions
- **Conditional Access Policies** - Enforce MFA for administrative automation
- **Privileged Access Management** - Time-bound elevation for sensitive operations
- **Security Monitoring** - Monitor Graph API usage and anomalies
- **Tenant Security Defaults** - Enable Azure AD security defaults
- **Regular Access Reviews** - Audit service principal and user permissions

### For PowerShell Developers
- **Secure Credential Storage** - Use Azure Key Vault or Windows Credential Manager
- **Input Validation** - Validate all parameters against expected formats
- **Error Handling** - Avoid exposing sensitive information in error messages
- **Code Signing** - Sign PowerShell scripts for production environments
- **Permission Validation** - Check required permissions before script execution
- **Audit Logging** - Log all administrative actions with proper context

### For Script Users
- **Execution Policy** - Use signed script execution policies
- **Credential Management** - Never store credentials in plain text
- **Permission Awareness** - Understand what permissions scripts require
- **Regular Updates** - Keep PowerShell and Graph SDK modules updated
- **Testing Environment** - Test scripts in non-production tenants first
- **Backup Strategies** - Maintain configuration backups before automation

### For Security Teams
- **Graph API Monitoring** - Monitor unusual Graph API activity patterns
- **Application Audit** - Regular review of registered applications and permissions
- **Token Lifecycle Management** - Monitor and rotate authentication tokens
- **Threat Detection** - Implement Microsoft 365 security center monitoring
- **Incident Response** - Establish procedures for Graph API security incidents

## Microsoft Graph API Security Guidelines

### Authentication Security
```powershell
# Secure service principal authentication
$ClientSecretSecure = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($ClientId, $ClientSecretSecure)
Connect-MgGraph -TenantId $TenantId -Credential $Credential
```

### Permission Validation
```powershell
# Validate required permissions before execution
$RequiredScopes = @("User.Read.All", "Group.Read.All")
$CurrentScopes = (Get-MgContext).Scopes
foreach ($Scope in $RequiredScopes) {
    if ($Scope -notin $CurrentScopes) {
        throw "Missing required permission: $Scope"
    }
}
```

### Secure Data Handling
```powershell
# Secure data export with encryption
$ExportData = Get-MgUser -All
$ExportData | Export-Csv -Path $SecurePath -NoTypeInformation
# Implement encryption for sensitive exports
```

## Security Contact

- **Primary**: security@wesellis.com
- **Microsoft Graph Issues**: Microsoft Security Response Center (MSRC)
- **Response Time**: 24 hours maximum for critical issues
- **PGP Key**: Available upon request
- **Security Advisory**: GitHub Security Advisories for this repository

## Compliance and Legal

### Microsoft 365 Compliance
- **Data Protection** - GDPR, CCPA, and regional privacy law compliance
- **Industry Standards** - SOC 2, ISO 27001, HIPAA compatibility
- **Audit Requirements** - Microsoft 365 audit log integration
- **Data Residency** - Geographic data location compliance
- **Retention Policies** - Data lifecycle management compliance

### Safe Harbor for Security Research
We commit to not pursuing legal action against security researchers who:
- **Follow Responsible Disclosure** - Report vulnerabilities privately first
- **Avoid Data Access** - Do not access or modify production data
- **Respect Tenant Boundaries** - Test only in dedicated research tenants
- **Report Through Proper Channels** - Use designated security contact methods
- **Coordinate with Microsoft** - For Microsoft Graph API vulnerabilities

### Scope of Security Policy
This policy applies to:
- **PowerShell Scripts** - All automation scripts in this repository
- **Microsoft Graph Integration** - Graph API usage and authentication
- **Documentation and Examples** - Sample code and configuration guidance
- **Testing Framework** - Pester tests and validation scripts

### Out of Scope
- **Microsoft Graph API Platform** - Report to Microsoft MSRC
- **Azure Active Directory Platform** - Report to Microsoft MSRC
- **PowerShell Platform** - Report to PowerShell Security Team
- **Third-party Modules** - Report to respective module maintainers
- **User-generated Configurations** - Custom scripts based on this toolkit

## Acknowledgments

We appreciate security researchers and Microsoft 365 community members who responsibly disclose vulnerabilities and help improve enterprise security for all organizations using Microsoft Graph automation.

---

**Security is a shared responsibility between Microsoft, this project, and the organizations implementing these automation scripts.**