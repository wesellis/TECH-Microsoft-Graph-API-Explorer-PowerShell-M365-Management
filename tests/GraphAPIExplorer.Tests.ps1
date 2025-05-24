BeforeAll {
    # Set up test environment
    $script:testRoot = $PSScriptRoot
    $script:projectRoot = Split-Path $testRoot -Parent
    $script:scriptsPath = Join-Path $projectRoot "scripts"
    
    # Mock Microsoft Graph cmdlets for testing
    Mock Connect-MgGraph { return $true }
    Mock Get-MgContext { 
        return @{
            TenantId = "test-tenant-id"
            ClientId = "test-client-id"
            Account = "test@domain.com"
            Scopes = @("User.Read.All", "Group.Read.All")
        }
    }
    Mock Disconnect-MgGraph { return $true }
}

Describe "Microsoft Graph API Explorer - Project Structure" {
    Context "Repository Structure Validation" {
        It "Should have required directories" {
            $requiredDirs = @("scripts", "docs", "tests", "examples", "modules", "templates")
            foreach ($dir in $requiredDirs) {
                $dirPath = Join-Path $script:projectRoot $dir
                $dirPath | Should -Exist
            }
        }
        
        It "Should have required documentation files" {
            $requiredFiles = @("README.md", "CONTRIBUTING.md", "CHANGELOG.md", "LICENSE")
            foreach ($file in $requiredFiles) {
                $filePath = Join-Path $script:projectRoot $file
                $filePath | Should -Exist
            }
        }
        
        It "Should have GitHub configuration" {
            $githubPath = Join-Path $script:projectRoot ".github"
            $githubPath | Should -Exist
            
            $workflowsPath = Join-Path $githubPath "workflows"
            $workflowsPath | Should -Exist
            
            $templatesPath = Join-Path $githubPath "ISSUE_TEMPLATE"
            $templatesPath | Should -Exist
        }
    }
}

Describe "PowerShell Script Validation" {
    Context "Script File Structure" {
        It "Should have PowerShell scripts in scripts directory" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            $scriptFiles.Count | Should -BeGreaterThan 0
        }
        
        It "Should have valid PowerShell syntax in all scripts" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            
            foreach ($file in $scriptFiles) {
                { 
                    $null = [System.Management.Automation.PSParser]::Tokenize(
                        (Get-Content $file.FullName -Raw), 
                        [ref]$null
                    )
                } | Should -Not -Throw -Because "Script $($file.Name) should have valid syntax"
            }
        }
    }
}

Describe "Microsoft Graph Integration Tests" {
    Context "Graph Module Requirements" {
        BeforeAll {
            # Mock Get-Module to simulate Graph modules being available
            Mock Get-Module {
                if ($Name -like "*Microsoft.Graph*") {
                    return @{
                        Name = $Name
                        Version = "2.8.0"
                        ModuleType = "Script"
                    }
                }
                return $null
            }
        }
        
        It "Should detect Microsoft Graph modules" {
            $graphModules = Get-Module -Name "Microsoft.Graph*" -ListAvailable
            $graphModules | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle Graph connection state" {
            # Test mocked connection
            $context = Get-MgContext
            $context | Should -Not -BeNullOrEmpty
            $context.TenantId | Should -Be "test-tenant-id"
        }
    }
    
    Context "Graph API Cmdlet Usage Validation" {
        It "Should use proper Graph cmdlet patterns" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            
            foreach ($file in $scriptFiles) {
                $content = Get-Content $file.FullName -Raw
                
                # If script uses Graph cmdlets, it should have proper error handling
                if ($content -match "(Get-Mg|Set-Mg|New-Mg|Remove-Mg|Update-Mg|Invoke-Mg)") {
                    # Should have try/catch or error handling
                    ($content -match "try.*catch|ErrorAction") | Should -Be $true -Because "Graph API scripts should have error handling"
                }
            }
        }
        
        It "Should include authentication validation in Graph scripts" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            
            foreach ($file in $scriptFiles) {
                $content = Get-Content $file.FullName -Raw
                
                # If script uses Graph cmdlets, it should validate authentication
                if ($content -match "(Get-Mg|Set-Mg|New-Mg|Remove-Mg|Update-Mg|Invoke-Mg)") {
                    # Should check connection state
                    ($content -match "Get-MgContext|Connect-MgGraph") | Should -Be $true -Because "Graph API scripts should validate authentication"
                }
            }
        }
    }
}

Describe "Script Parameter Validation" {
    Context "Common Parameter Patterns" {
        It "Should use proper parameter validation attributes" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            
            foreach ($file in $scriptFiles) {
                $content = Get-Content $file.FullName -Raw
                
                # If script has parameters, should use proper validation
                if ($content -match "param\s*\(") {
                    # Should have parameter attributes
                    ($content -match "\[Parameter\(|Mandatory|ValidateNotNullOrEmpty|ValidateSet") | Should -Be $true -Because "Scripts should use parameter validation"
                }
            }
        }
        
        It "Should include help documentation" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            
            foreach ($file in $scriptFiles) {
                $content = Get-Content $file.FullName -Raw
                
                # Should have comment-based help
                ($content -match "\.SYNOPSIS|\.DESCRIPTION|\.PARAMETER|\.EXAMPLE") | Should -Be $true -Because "Scripts should have help documentation"
            }
        }
    }
}

Describe "Security Validation" {
    Context "Credential and Secret Handling" {
        It "Should not contain hardcoded credentials" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            
            foreach ($file in $scriptFiles) {
                $content = Get-Content $file.FullName -Raw
                
                # Check for potential hardcoded credentials
                $securityPatterns = @(
                    'password\s*=\s*["''][^"'']+["'']',
                    'secret\s*=\s*["''][^"'']+["'']',
                    'key\s*=\s*["''][^"'']+["'']',
                    'token\s*=\s*["''][^"'']+["'']'
                )
                
                foreach ($pattern in $securityPatterns) {
                    $content | Should -Not -Match $pattern -Because "Scripts should not contain hardcoded credentials"
                }
            }
        }
        
        It "Should use secure credential handling patterns" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            
            foreach ($file in $scriptFiles) {
                $content = Get-Content $file.FullName -Raw
                
                # If script handles credentials, should use secure methods
                if ($content -match "credential|password|secret") {
                    # Should use SecureString or proper credential objects
                    ($content -match "SecureString|PSCredential|Get-Credential") | Should -Be $true -Because "Scripts should use secure credential handling"
                }
            }
        }
    }
}

Describe "Graph API Permission Documentation" {
    Context "Permission Requirements" {
        It "Should document required Graph API permissions" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            
            foreach ($file in $scriptFiles) {
                $content = Get-Content $file.FullName -Raw
                
                # If script uses Graph cmdlets, should document permissions
                if ($content -match "(Get-Mg|Set-Mg|New-Mg|Remove-Mg|Update-Mg|Invoke-Mg)") {
                    # Should document required permissions in comments
                    ($content -match "Permission|Scope|\.Read\.|\.Write\.|\.All") | Should -Be $true -Because "Graph API scripts should document required permissions"
                }
            }
        }
    }
}

Describe "Output and Formatting Standards" {
    Context "Consistent Output Patterns" {
        It "Should use consistent output methods" {
            $scriptFiles = Get-ChildItem -Path $script:scriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            
            foreach ($file in $scriptFiles) {
                $content = Get-Content $file.FullName -Raw
                
                # Should use proper PowerShell output cmdlets
                if ($content -match "Write-|Output") {
                    # Should use appropriate output cmdlets
                    ($content -match "Write-Output|Write-Host|Write-Verbose|Write-Warning|Write-Error") | Should -Be $true -Because "Scripts should use proper output cmdlets"
                }
            }
        }
    }
}

AfterAll {
    # Clean up any test resources if needed
    Write-Verbose "Test cleanup completed"
}
