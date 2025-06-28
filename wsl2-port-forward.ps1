# WSL2 Port Forward Script for Multiple Port Ranges
# Run this as Administrator
# This script persists across system restarts by creating a scheduled task

param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Run
)

# Define port ranges
$portRanges = @(
    @{ Start = 8881; End = 8888 },
    @{ Start = 9991; End = 9999 }
)

$taskName = "WSL2-PortForward-Persistent"
$scriptPath = $MyInvocation.MyCommand.Path

# Function to setup port forwarding for a single port
function Setup-PortForward {
    param($port, $wsl2IP)
    
    # Remove existing port forwarding rule if it exists (suppress errors)
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0 >$null 2>&1
    
    # Add new port forwarding rule
    Write-Host "Setting up port forwarding from Windows:$port to WSL2:$port"
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wsl2IP
}

# Function to setup firewall rule for a port range
function Setup-FirewallRule {
    param($startPort, $endPort)
    
    $firewallRule = "WSL2 Port Range $startPort-$endPort"
    $existingRule = netsh advfirewall firewall show rule name="$firewallRule" 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Adding firewall rule for ports $startPort-$endPort"
        netsh advfirewall firewall add rule name="$firewallRule" dir=in action=allow protocol=TCP localport="$startPort-$endPort"
    } else {
        Write-Host "Firewall rule for ports $startPort-$endPort already exists"
    }
}

# Function to perform the actual port forwarding setup
function Setup-AllPortForwarding {
    # Get WSL2 IP address
    $wsl2IP = $null
    $attempts = 0
    $maxAttempts = 10
    
    while ($wsl2IP -eq $null -and $attempts -lt $maxAttempts) {
        try {
            $wsl2IPRaw = (wsl hostname -I 2>$null).Trim()
            if (-not [string]::IsNullOrEmpty($wsl2IPRaw)) {
                # Take only the first IP address if multiple are returned
                $wsl2IP = ($wsl2IPRaw -split '\s+')[0]
            } else {
                $wsl2IP = $null
            }
        } catch {
            $wsl2IP = $null
        }
        
        if ($wsl2IP -eq $null) {
            $attempts++
            Write-Host "Waiting for WSL2 to be ready... (attempt $attempts/$maxAttempts)"
            Start-Sleep -Seconds 5
        }
    }
    
    if ($wsl2IP -eq $null) {
        Write-Host "Failed to get WSL2 IP address after $maxAttempts attempts"
        return
    }
    
    Write-Host "WSL2 IP: $wsl2IP"
    
    # Process each port range
    foreach ($range in $portRanges) {
        Write-Host "`nProcessing port range $($range.Start)-$($range.End)..."
        
        # Setup port forwarding for each port in the range
        for ($port = $range.Start; $port -le $range.End; $port++) {
            Setup-PortForward -port $port -wsl2IP $wsl2IP
        }
        
        # Setup firewall rule for the entire range (only needs to be done once)
        Setup-FirewallRule -startPort $range.Start -endPort $range.End
    }
    
    Write-Host "`nPort forwarding setup complete!"
}

# Install scheduled task
if ($Install) {
    Write-Host "Installing persistent WSL2 port forwarding..."
    
    # Remove existing task if it exists
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Create action to run this script with -Run parameter
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -Run"
    
    # Create trigger for system startup
    $trigger = New-ScheduledTaskTrigger -AtStartup
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Create principal to run as SYSTEM with highest privileges
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register the task
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Persistent WSL2 port forwarding for development ports"
    
    Write-Host "Scheduled task '$taskName' created successfully!"
    Write-Host "Port forwarding will persist across system restarts."
    Write-Host "Run the script now with: PowerShell -ExecutionPolicy Bypass -File `"$scriptPath`" -Run"
    return
}

# Uninstall scheduled task
if ($Uninstall) {
    Write-Host "Removing persistent WSL2 port forwarding..."
    
    # Remove scheduled task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Remove port forwarding rules
    foreach ($range in $portRanges) {
        for ($port = $range.Start; $port -le $range.End; $port++) {
            netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0 2>$null
        }
        
        # Remove firewall rules
        $firewallRule = "WSL2 Port Range $($range.Start)-$($range.End)"
        netsh advfirewall firewall delete rule name="$firewallRule" 2>$null
    }
    
    Write-Host "WSL2 port forwarding removed successfully!"
    return
}

# Run the port forwarding setup
if ($Run) {
    Setup-AllPortForwarding
    return
}

# Default behavior - setup port forwarding and show instructions
Write-Host "WSL2 Persistent Port Forward Script"
Write-Host "===================================="
Write-Host ""
Write-Host "Usage:"
Write-Host "  -Install    : Install persistent port forwarding (survives reboots)"
Write-Host "  -Uninstall  : Remove persistent port forwarding"
Write-Host "  -Run        : Run port forwarding setup once"
Write-Host ""
Write-Host "To make port forwarding persistent across reboots:"
Write-Host "  PowerShell -ExecutionPolicy Bypass -File `"$scriptPath`" -Install"
Write-Host ""

# If no parameters, run setup once
Setup-AllPortForwarding

# Show current port forwarding rules
Write-Host "`nCurrent port forwarding rules:"
netsh interface portproxy show v4tov4

# Get network IP for display
$networkIP = (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.InterfaceAlias -notlike "*WSL*" } | Select-Object -First 1).IPAddress

Write-Host "`nYour applications should be accessible at:"
Write-Host "- Local: http://localhost:[PORT]"
if ($networkIP) {
    Write-Host "- Network: http://${networkIP}:[PORT]"
}
Write-Host "`nWhere [PORT] is any port in the ranges: 8881-8888, 9991-9999"