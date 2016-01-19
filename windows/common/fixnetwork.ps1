$ProgressPreference="SilentlyContinue"
$ErrorActionPreference="Stop"

# You cannot enable Windows PowerShell Remoting on network connections that are set to Public
# Spin through all the network locations and if they are set to Public, set them to Private
# using the INetwork interface:
# http://msdn.microsoft.com/en-us/library/windows/desktop/aa370750(v=vs.85).aspx
# For more info, see:
# http://blogs.msdn.com/b/powershell/archive/2009/04/03/setting-network-location-to-private.aspx

# Network location feature was only introduced in Windows Vista - no need to bother with this
# if the operating system is older than Vista
if([environment]::OSVersion.version.Major -lt 6) { return }

# You cannot change the network location if you are joined to a domain, so abort
if(1,3,4,5 -contains (Get-WmiObject win32_computersystem).DomainRole) { return }

# Get network connections

if (Get-Command "Get-NetConnectionProfile" -ErrorAction SilentlyContinue){
    $connections = Get-NetConnectionProfile

    $connections |% {
        $network = $_
        $networkName = $network.Name
        $category = $network.NetworkCategory
        $interfaceIndex = $network.InterfaceIndex
        Write-Host "$networkName category was previously set to $category"

        try{
            Set-NetConnectionProfile -InterfaceIndex $interfaceIndex -NetworkCategory Private
        } catch {
            Get-NetAdapter -InterfaceIndex $interfaceIndex | Disable-NetAdapter
            Set-NetConnectionProfile -InterfaceIndex $interfaceIndex -NetworkCategory Private
            Get-NetAdapter -InterfaceIndex $interfaceIndex | Enable-NetAdapter
        }


        $network = Get-NetConnectionProfile -InterfaceIndex $interfaceIndex
        $networkName = $network.Name
        $category = $network.NetworkCategory

        Write-Host "$networkName changed to category $category"
    }
} else {

    $networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
    $connections = $networkListManager.GetNetworkConnections()

    $connections |% {
        $network = $_.GetNetwork()
        $networkName = $network.GetName()
        $category = $network.GetCategory()
	    Write-Host "$networkName category was previously set to $category"

	    $_.GetNetwork().SetCategory(1)

        $network = $_.GetNetwork()
        $networkName = $network.GetName()
        $category = $network.GetCategory()

	    Write-Host "$networkName changed to category $category"
    }
}