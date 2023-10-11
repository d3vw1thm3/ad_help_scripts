# Load the necessary modules
Import-Module DhcpServer
Import-Module ActiveDirectory

# Specify the DHCP Server (adjust this value to your needs)
$dhcpServer = "srv.domain.ltd"

# Get all scopes from the specified DHCP Server
$scopes = Get-DhcpServerv4Scope -ComputerName $dhcpServer

# Iterate over each scope and get reservations
foreach ($scope in $scopes) {
    Write-Output "Processing reservations in scope $($scope.ScopeId)"
    $reservations = Get-DhcpServerv4Reservation -ComputerName $dhcpServer -ScopeId $scope.ScopeId

    # Check each reservation
    foreach ($reservation in $reservations) {
        # Try to ping the reserved IP
        $active = Test-Connection -ComputerName $reservation.IPAddress -Count 2 -Quiet
        $status = if ($active) { "active" } else { "inactive" }
        
        # Attempt to resolve IP to hostname
        try {
            $dnsInfo = Resolve-DnsName -Name $reservation.IPAddress -ErrorAction Stop
            $resolvedHostname = $dnsInfo.NameHost
        } catch {
            $resolvedHostname = "Unresolvable"
        }

        # Check if the resolved hostname matches the reservation name
        $nameMatch = if ($resolvedHostname -eq $reservation.Name) { "match" } else { "do not match" }

        # Check Active Directory for a computer with the same name and if it's enabled
        try {
            $adComputer = Get-ADComputer -Filter {Name -eq $reservation.Name} -Properties Enabled -ErrorAction Stop
            $adStatus = if ($adComputer.Enabled -eq $true) { "enabled" } else { "disabled" }
        } catch {
            $adStatus = "not found in AD"
        }

        # Output the results
        Write-Output "Reservation for IP $($reservation.IPAddress) in scope $($scope.ScopeId) is $status. Resolved Hostname: $resolvedHostname. Reservation Name: $($reservation.Name). The names $nameMatch. AD Status: $adStatus."
    }
}
