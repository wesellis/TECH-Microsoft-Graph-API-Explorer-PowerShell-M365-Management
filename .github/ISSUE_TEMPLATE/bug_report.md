---
name: Bug report
about: Create a report to help us improve Microsoft Graph API Explorer
title: '[BUG] '
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**Script/Functionality Affected**
- Script name: [e.g. get-user-info.ps1]
- Graph API endpoint: [e.g. /users/{id}]
- Operation type: [e.g. GET, POST, PATCH, DELETE]

**To Reproduce**
Steps to reproduce the behavior:
1. Connect to Graph with scopes '...'
2. Run script with parameters '...'
3. Observe error or unexpected behavior

**Expected behavior**
A clear and concise description of what you expected to happen.

**Error Messages**
If applicable, paste the complete error message(s):
```
Paste error messages here
```

**Graph API Response** (if applicable)
If you received an error from the Graph API:
```json
{
  "error": {
    "code": "ErrorCode",
    "message": "Error message"
  }
}
```

**Environment Information**
- **PowerShell Version**: [e.g. 7.3.0] (run `$PSVersionTable.PSVersion`)
- **Microsoft Graph SDK Version**: [e.g. 2.8.0] (run `Get-Module Microsoft.Graph -ListAvailable`)
- **Operating System**: [e.g. Windows 11, Ubuntu 22.04]
- **Microsoft 365 Tenant Type**: [e.g. Commercial, GCC, Education]

**Authentication Details**
- **Authentication Method**: [e.g. Interactive, Service Principal, Certificate]
- **Scopes Used**: [e.g. User.Read.All, Group.Read.All]
- **Tenant Type**: [e.g. Single tenant, Multi-tenant]

**Script Output/Logs**
Please paste relevant script output or log files:
```
Paste console output here
```

**Graph API Context**
- **Graph API Version**: [e.g. v1.0, beta]
- **Resource Type**: [e.g. Users, Groups, Applications]
- **Required Permissions**: [List the permissions your app registration has]

**Additional context**
- Are you running in a production or development environment?
- Is this a new issue or regression from a previous version?
- Any recent changes to your Microsoft 365 tenant?
- Are there any custom policies or conditional access rules that might affect this?

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Attempted Solutions**
What have you tried to fix this issue?
- [ ] Verified Graph API permissions
- [ ] Tested with Graph Explorer
- [ ] Checked Microsoft Graph documentation
- [ ] Ran script with different parameters
- [ ] Tested with different user account
- [ ] Other: ________________

**Impact Assessment**
How is this affecting your work?
- [ ] Blocks critical automation
- [ ] Prevents user management tasks
- [ ] Affects reporting capabilities
- [ ] Minor inconvenience
- [ ] Other: ________________

**Workaround**
If you found a temporary workaround, please describe it here.
