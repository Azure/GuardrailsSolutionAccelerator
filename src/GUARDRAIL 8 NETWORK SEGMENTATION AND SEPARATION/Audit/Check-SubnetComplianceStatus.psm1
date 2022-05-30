
function Get-SubnetComplianceInformation {
    param (
        [Parameter(Mandatory=$false)]
        [string]
        $token,
        [Parameter(Mandatory=$true)]
        [string]
        $ControlName,
        [Parameter(Mandatory=$true)]
        [string]
        $WorkSpaceID,
        [Parameter(Mandatory=$true)]
        [string]
        $workspaceKey,
        [Parameter(Mandatory=$false)]
        [string]
        $LogType="GuardrailsCompliance",
        [Parameter(Mandatory=$false)]
        [string]
        $ExcludedSubnets,
        [Parameter(Mandatory=$true)]
        [string]
        $ReportTime
    )
    #module for Tags handling
    #import-module '..\..\GUARDRAIL COMMON\Get-Tags.psm1'
    [PSCustomObject] $SubnetList = New-Object System.Collections.ArrayList
    $reservedSubnetNames=@("GatewaySubnet","AzureFirewallSubnet","AzureBastionSubnet")
    $allexcluded=$ExcludedSubnets+$reservedSubnetNames
    $subs=Get-AzSubscription | Where-Object {$_.State -eq 'Enabled'}
    if ($ExcludedSubnets -ne $null)
    {
        $ExcludedSubnetsList=$ExcludedSubnets.Split(",")
    }
    foreach ($sub in $subs)
    {
        Write-Verbose "Selecting subscription..."
        Select-AzSubscription -SubscriptionObject $sub
        
        $VNets=Get-AzVirtualNetwork
        Write-Debug "Found $($VNets.count) VNets."
        if ($VNets)
        {
            foreach ($VNet in $VNets)
            {
                Write-Debug "Working on $($VNet.Name) VNet..."
                $ev=get-tagValue -tagKey "ExcludeFromCompliance" -object $VNet
                if ($ev -ne "true")
                {
                    #Handles the subnets
                    foreach ($subnet in Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet)
                    {
                        Write-Debug "Working on $($subnet.Name) Subnet..."
                        if ($subnet.Name -notin $allexcluded)
                        {
                            #checks NSGs
                            $ComplianceStatus=$false
                            $Comments="No NSG is present."
                            $MitigationCommands=@"
# https://docs.microsoft.com/en-us/powershell/module/az.network/set-azvirtualnetworksubnetconfig?view=azps-8.0.0#2-add-a-network-security-group-to-a-subnet
#Creates NSG Resource for subnet $($subnet.Name)
Select-azsubscription $($sub.SubscriptionId)
`$nsg=New-AzNetworkSecurityGroup -Name '$($subnet.Name)-nsg' -ResourceGroupName $($vnet.ResourceGroupName) -Location $($VNet.Location)
# Assign NSG to subnet
`$subnet=(Get-AzVirtualNetwork -ResourceGroupName $($vnet.ResourceGroupName) -Name $($vnet.Name)).Subnets | Where-Object Name -eq $($subnet.Name)
`$subnet.NetworkSecurityGroup = `$nsg
Get-AzVirtualNetwork -ResourceGroupName $($vnet.ResourceGroupName) -Name $($vnet.Name) | set-azvirtual-network
"@
                            if ($null -ne $subnet.NetworkSecurityGroup)
                            {
                                Write-Debug "Found $($subnet.NetworkSecurityGroup.Id.Split("/")[8]) NSG"
                                #Add routine to analyze NSG regarding standard rules.
                                $nsg=Get-AzNetworkSecurityGroup -Name $subnet.NetworkSecurityGroup.Id.Split("/")[8] -ResourceGroupName $subnet.NetworkSecurityGroup.Id.Split("/")[4]
                                if ($nsg.SecurityRules.count -ne 0) #NSG has other rules on top of standard rules.
                                {
                                    $LastSecurityRule=($nsg.SecurityRules | Sort-Object Priority -Descending)[0]
                                    if ($LastSecurityRule.DestinationAddressPrefix -eq '*' -and $LastSecurityRule.Access -eq "Deny") # Determine all criteria for good or bad here...
                                    {
                                        $ComplianceStatus=$true
                                        $Comments = "Subnet is compliant."
                                        $MitigationCommands="N/A"
                                    }
                                    else {
                                        $ComplianceStatus=$false
                                        $Comments="NSG is present but not properly configured (Missing Deny all last Rule)."
                                        $MitigationCommands=@"
Select-azsubscription $($sub.SubscriptionId)
`$nsg=Get-AzNetworkSecurityGroup -Name $($subnet.NetworkSecurityGroup.Id.Split("/")[8]) -ResourceGroupName $($subnet.NetworkSecurityGroup.Id.Split("/")[4])
`$RuleParams = @{
    'Name'                     = 'Denyall'
    'NetworkSecurityGroup'     = `$nsg
    'Protocol'                 = '*'
    'Direction'                = 'Inbound'
    'Priority'                 = 4096
    'SourceAddressPrefix'      = '*'
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '*'
    'Access'                   = 'Deny'
    }
Add-AzNetworkSecurityRuleConfig @RuleParams | Set-AzNetworkSecurityGroup
"@
                                    }
                                }
                                else {
                                    #NSG is present but has no custom rules at all.
                                    $ComplianceStatus=$false
                                    $Comments="NSG is present but not properly configured (Missing Custom Rules)."
                                    $MitigationCommands=@"
Select-azsubscription $($sub.SubscriptionId)
`$nsg=Get-AzNetworkSecurityGroup -Name $($subnet.NetworkSecurityGroup.Id.Split("/")[8]) -ResourceGroupName $($subnet.NetworkSecurityGroup.Id.Split("/")[4])
`$RuleParams = @{
    'Name'                     = 'Denyall'
    'NetworkSecurityGroup'     = `$nsg
    'Protocol'                 = '*'
    'Direction'                = 'Inbound'
    'Priority'                 = 4096
    'SourceAddressPrefix'      = '*'
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '*'
    'Access'                   = 'Deny'
    }
Add-AzNetworkSecurityRuleConfig @RuleParams | Set-AzNetworkSecurityGroup
"@
                                }
                            }
                            $SubnetObject = [PSCustomObject]@{ 
                                SubscriptionName  = $sub.Name 
                                SubnetName="$($VNet.Name)\$($subnet.Name)"
                                ComplianceStatus = $ComplianceStatus
                                Comments = $Comments
                                ItemName = "Segmentation"
                                ControlName = $ControlName
                                MitigationCommands=$MitigationCommands
                                ReportTime = $ReportTime
                            }
                            $SubnetList.add($SubnetObject) | Out-Null

                            #Checks Routes
                            if ($subnet.RouteTable)
                            {
                                $UDR=$subnet.RouteTable.Id.Split("/")[8]
                                Write-Debug "Found $UDR UDR"
                                $routeTable=Get-AzRouteTable -ResourceGroupName $subnet.RouteTable.Id.Split("/")[4] -name $UDR
                                $ComplianceStatus=$true
                                $Comments="Subnet is compliant."
                                $MitigationCommands="N/A"
                                foreach ($route in $routeTable.Routes)
                                {
                                    if ($route.NextHopType -ne "VirtualAppliance")
                                    {
                                        $ComplianceStatus=$false
                                        $Comments="Route present but not directed to a Virtual Appliance."
                                        $MitigationCommands="Update the route to point to a virtual appliance"
                                    }
                                }
                            }
                            else {
                                $ComplianceStatus=$false
                                $Comments="No User defined Route configured."
                                $MitigationCommands="Please apply a custom route to this subnet, pointing to a virtual appliance."
                            }

                        }
                        else { #subnet excluded
                            $ComplianceStatus=$true
                            $Comments="Subnet Excluded (manually or reserved name)."
                            $MitigationCommands="N/A"                            
                        }
                        $SubnetObject = [PSCustomObject]@{ 
                            SubscriptionName  = $sub.Name 
                            SubnetName="$($VNet.Name)\$($subnet.Name)"
                            ComplianceStatus = $ComplianceStatus
                            Comments = $Comments
                            ItemName = "Separation"
                            ControlName = $ControlName
                            ReportTime = $ReportTime
                            MitigationCommands=$MitigationCommands
                        }
                        $SubnetList.add($SubnetObject) | Out-Null
                    }
                }
                else {
                    Write-Verbose "Excluding $($VNet.Name) based on tagging."
                }    
            }
        }
    }
    Write-Output "Listing $($SubnetList.Count) List members."
    foreach ($s in $SubnetList)
    {
        Write-Output "Subnet: $($s.SubnetName) - Compliant: $($s.ComplianceStatus) Comments: $($s.Comments)"
    }
    $JSONSubnetList = ConvertTo-Json -inputObject $SubnetList 

    Send-OMSAPIIngestionFile  -customerId $WorkSpaceID `
    -sharedkey $workspaceKey `
    -body $JSONSubnetList `
    -logType $LogType `
    -TimeStampField Get-Date 
}
