---
name: Script Request
about: Request a new PowerShell script for Microsoft Graph API automation
title: '[SCRIPT] '
labels: script-request
assignees: ''

---

**Script Purpose**
Describe what this script should accomplish:

**Microsoft Graph API Requirements**
- **Primary Endpoint(s)**: [e.g. /users, /groups/{id}/members]
- **HTTP Method(s)**: [e.g. GET, POST, PATCH, DELETE]
- **API Version**: [e.g. v1.0, beta]
- **Required Permissions**: [e.g. User.Read.All, Group.ReadWrite.All]

**Functional Category**
- [ ] User Management (create, update, delete users)
- [ ] Group Management (groups, memberships, permissions)
- [ ] Security & Compliance (alerts, audit logs, policies)
- [ ] Reporting & Analytics (usage reports, statistics)
- [ ] Application Management (app registrations, service principals)
- [ ] Directory Management (organizational units, roles)
- [ ] Device Management (devices, compliance policies)
- [ ] Mail & Calendar (mailboxes, calendars, contacts)
- [ ] Teams & SharePoint (teams, sites, files)
- [ ] Other: ______

**Detailed Requirements**
List the specific functionality needed:
- [ ] 
- [ ] 
- [ ] 

**Input Parameters**
What parameters should the script accept?
- **Required Parameters**:
  - Parameter name: [Type] - Description
  - Parameter name: [Type] - Description
- **Optional Parameters**:
  - Parameter name: [Type] - Description
  - Parameter name: [Type] - Description

**Expected Outputs**
- [ ] Console output with formatting
- [ ] CSV file export
- [ ] JSON data export
- [ ] HTML report
- [ ] PowerShell objects for pipeline processing
- [ ] Log file generation
- [ ] Email notifications
- [ ] Other: ______

**Business Justification**
Why is this script needed?
- **Current manual process takes**: ______ hours/days
- **Frequency of execution**: ______ (daily/weekly/monthly)
- **Number of objects affected**: ______ (users/groups/devices)
- **Business impact**: ______
- **Compliance requirement**: ______

**Example Scenario**
Provide a specific example of how this script would be used:

```powershell
# Example usage:
.\your-script.ps1 -TenantId "tenant-id" -Parameter "value" -OutputPath "./reports/"
```

**Expected Workflow**
1. Step 1: [e.g. Connect to Graph API with required scopes]
2. Step 2: [e.g. Retrieve list of users from specific department]
3. Step 3: [e.g. Process each user and update properties]
4. Step 4: [e.g. Generate report of changes made]

**Authentication Requirements**
- [ ] Interactive authentication acceptable
- [ ] Service principal authentication required
- [ ] Certificate-based authentication needed
- [ ] Managed identity support required
- [ ] Multi-tenant support needed

**Error Handling Requirements**
- [ ] Graceful handling of missing permissions
- [ ] Retry logic for transient failures
- [ ] Detailed error messages and logging
- [ ] Rollback capability for failed operations
- [ ] Validation of prerequisites
- [ ] Support for -WhatIf parameter

**Performance Considerations**
- [ ] Handle small datasets (< 100 items)
- [ ] Handle medium datasets (100-1000 items)  
- [ ] Handle large datasets (1000+ items)
- [ ] Implement pagination for large results
- [ ] Use batch operations where possible
- [ ] Include progress indicators

**Security Requirements**
- [ ] Handle sensitive data securely
- [ ] Support for secure credential storage
- [ ] Audit logging of all actions
- [ ] Follow principle of least privilege
- [ ] No hardcoded credentials or secrets
- [ ] Data encryption for sensitive outputs

**Output Format Preferences**
```
# Example desired output format:
User: john.doe@contoso.com
  - Status: Active
  - Last Sign-in: 2025-01-15
  - Groups: Marketing, All Users
  - Licenses: Office 365 E3
```

**Integration Requirements**
- [ ] Azure Automation runbook compatibility
- [ ] PowerShell ISE/VS Code debugging support
- [ ] CI/CD pipeline integration
- [ ] Scheduled task compatibility
- [ ] Integration with existing monitoring tools
- [ ] Export to external systems

**Testing Requirements**
- [ ] Unit tests with Pester
- [ ] Integration testing with test tenant
- [ ] Mock testing for Graph API responses
- [ ] Performance testing with large datasets
- [ ] Security validation testing
- [ ] Cross-platform compatibility testing

**Documentation Needs**
- [ ] Comment-based help with examples
- [ ] Parameter documentation with validation
- [ ] Prerequisites and setup instructions
- [ ] Permission configuration guide
- [ ] Troubleshooting section
- [ ] Best practices and usage tips

**Similar Existing Solutions**
Are there existing scripts or tools that do something similar?
- [ ] Microsoft Graph PowerShell SDK cmdlets
- [ ] Azure AD PowerShell module scripts
- [ ] Third-party tools or scripts
- [ ] Custom scripts you've seen elsewhere
- [ ] Nothing similar exists (this is unique)

**Priority Level**
- [ ] Urgent (needed within 2 weeks)
- [ ] High (needed within 1 month)
- [ ] Medium (needed within 3 months)
- [ ] Low (nice to have, no timeline)

**Resources Available**
- [ ] I can provide test environment
- [ ] I can help with testing and validation
- [ ] I can provide sample data
- [ ] I can review and provide feedback
- [ ] I have existing code that can be adapted
- [ ] I can help with documentation

**Compliance/Regulatory Requirements**
- [ ] GDPR compliance required
- [ ] HIPAA compliance required
- [ ] SOX compliance required
- [ ] Industry-specific regulations
- [ ] Internal corporate policies
- [ ] No specific compliance requirements
- [ ] Other: ______

**Graph API Complexity**
- [ ] Simple single API call
- [ ] Multiple related API calls
- [ ] Complex multi-step operations
- [ ] Requires error handling and retry logic
- [ ] Needs batch operations
- [ ] Requires pagination handling

**Additional Context**
Any other information that would help in creating this script:

**Related Documentation**
Link to any relevant Microsoft Graph API documentation:
- Microsoft Graph API reference: 
- PowerShell SDK documentation:
- Other relevant resources:

**Success Criteria**
How will you know this script is successful?
- [ ] Reduces manual effort by X hours/week
- [ ] Eliminates human error in process
- [ ] Provides consistent results
- [ ] Integrates smoothly with existing workflows
- [ ] Meets performance requirements
- [ ] Passes security and compliance review
- [ ] Other: ______
