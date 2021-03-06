# Author: William Lam
# Website: www.virtuallyghetto.com
# Description: PowerCLI script to deploy the required infrastructure for setting up Piovtal Container Service (PKS)

# vCenter Server to deploy PKS Lab
$VIServer = "vcenter.primp-industries.com"
$VIUsername = "primp"
$VIPassword = "-->MySuperDuperSecurePassword<--"

# Full Path to both the Nested ESXi 6.5u1 VA, NSX-T & PKS OVAs
$NestedESXiApplianceOVA = "C:\Users\primp\Desktop\Nested_ESXi6.5u1_Appliance_Template_v1.ova"
$NSXTManagerOVA = "C:\Users\primp\Desktop\nsx-unified-appliance-2.1.0.0.0.7395503.ova"
$NSXTControllerOVA = "C:\Users\primp\Desktop\nsx-controller-2.1.0.0.0.7395493.ova"
$NSXTEdgeOVA = "C:\Users\primp\Desktop\nsx-edge-2.1.0.0.0.7395502.ova"
$PKSOpsMgrOVA = "C:\Users\primp\Desktop\pcf-vsphere-2.1-build.318.ova"

# PKS VMs
$OpsManagerDisplayName = "pks-opsmgr"
$OpsManagerHostname = "pks-opsmgr.primp-industries.com"
$OpsManagerIPAddress = "172.30.51.19"
$OpsManagerNetmask = "255.255.255.0"
$OpsManagerGateway = "172.30.51.1"
$OpsManagerAdminPassword = "VMware1!"

# Nested ESXi VMs to deploy
$NestedESXiHostnameToIPs = @{
"esxi-01" = "172.30.51.10"
"esxi-02" = "172.30.51.11"
"esxi-03" = "172.30.51.12"
}

# Nested ESXi VM Resources
$NestedESXivCPU = "2"
$NestedESXivMEM = "24" #GB
$NestedESXiCachingvDisk = "4" #GB
$NestedESXiCapacityvDisk = "60" #GB

# General Deployment Configuration for Nested ESXi, NSX-T & PKS VMs
$VirtualSwitchType = "VDS" # VSS or VDS
$VMNetwork = "dv-vlan3251"
$VMDatastore = "himalaya-local-SATA-dc3500-3"
$VMNetmask = "255.255.255.0"
$VMGateway = "172.30.51.1"
$VMDNS = "172.30.0.100"
$VMNTP = "pool.ntp.org"
$VMPassword = "VMware1!"
$VMDomain = "primp-industries.com"
$VMSyslog = "172.30.51.170"
# Applicable to Nested ESXi only
$VMSSH = "true"
$VMVMFS = "false"
# Applicable to VC Deployment Target only
$RootDatacenterName = "Production"
$VMCluster = "Primp-Cluster"

# Name of new vSphere Cluster for the Compute ESXi Cluster
$NewVCVSANClusterName = "PKS-Cluster"

# NSX-T Configuration
$DeployNSX = 1
$NSXRootPassword = "VMware1!"
$NSXAdminUsername = "admin"
$NSXAdminPassword = "VMware1!"
$NSXAuditUsername = "audit"
$NSXAuditPassword = "VMware1!"
$NSXSSHEnable = "true"
$NSXEnableRootLogin = "true"
$NSXPrivatePortgroup = "dv-private"
$NSXIntermediateNetworkPortgroup = "dv-vlan3250"

$TunnelEndpointPoolName = "ESXi-VTEP-Pool"
$TunnelEndpointPoolDescription = "Tunnel Endpoint for ESXi Transport Nodes"
$TunnelEndpointPoolIPRangeStart = "192.168.1.10"
$TunnelEndpointPoolIPRangeEnd = "192.168.1.30"
$TunnelEndpointPoolCIDR = "192.168.1.0/24"
$TunnelEndpointPoolGateway = "192.168.1.1"

$LoadBalancerPoolName = "Load-Balancer-Pool"
$LoadBalancerPoolDescription = "Load Balancer IP Pool"
$LoadBalancerPoolIPRangeStart = "10.20.0.10"
$LoadBalancerPoolIPRangeEnd = "10.20.0.50"
$LoadBalancerPoolCIDR = "10.20.0.0/24"

$ipBlockName = "PKS-IP-Block"
$ipBlockNetwork = "172.16.0.0/16"

$OverlayTransportZoneName = "TZ-Overlay"
$OverlayTransportZoneHostSwitchName = "Hostswitch1-OVERLAY"
$VlanTransportZoneName = "TZ-VLAN"
$VlanTransportZoneNameHostSwitchName = "Hostswitch2-VLAN"

$ESXiUplinkProfileName = "ESXi-Uplink-Profile"
$ESXiUplinkProfilePolicy = "FAILOVER_ORDER"
$ESXiUplinkProfileActivepNIC = "vmnic2"
$ESXiUplinkProfileTransportVLAN = "0"
$ESXiUplinkProfileMTU = "1600"

$EdgeUplinkProfileName = "Edge-Uplink-Profile"
$EdgeUplinkProfilePolicy = "FAILOVER_ORDER"
$EdgeUplinkProfileActivepNIC = "uplink-1"
$EdgeUplinkProfileTransportVLAN = "0"
$EdgeUplinkProfileMTU = "1600"
$EdgeUplinkProfileOverlayvNIC = "fp-eth0"
$EdgeUplinkProfileVlanvNIC = "fp-eth1"

$K8SMgmtClusterLogicalSwitchName = "K8S-Mgmt-Cluster-LS"
$K8SMgmtClusterLogicalSwitchReplicationMode = "MTEP"
$UplinkLogicalSwitchName = "Uplink-LS"
$UplinkLogicalSwitchVlan = "0"

$EdgeClusterName = "Edge-Cluster-01"

# T0 Router Configuration
$T0LogicalRouterName = "T0-LR"
$T0LogicalRouterEdgeCluster = $EdgeClusterName
$T0LogicalRouterHAMode = "ACTIVE_STANDBY"
$T0UplinkRouterPortName = "Uplink-1"
$T0UplinkRouterPortLS = $UplinkLogicalSwitchName
$T0UplinkRouterPortSwitchPortName = "Uplink-1-Port"
$T0UplinkRouterPortIP = "172.30.50.2"
$T0UplinkRouterPortIPPrefix = "24"
$T0UplinkRouterStaticRouteNetwork = "0.0.0.0/0"
$T0UplinkRouterStaticRouteNextHop = "172.30.50.1"

# T1 Router Configuration
$T1LogicalRouterName = "T1-K8S-Mgmt-Cluster"
$T1LogicalRouterEdgeCluster = $EdgeClusterName
$T1LogicalRouterHAMode = "ACTIVE_STANDBY"
$T1LogicalRouterFailOverMode = "PREEMPTIVE"
$T1LinkedRouterPortLS = $K8SMgmtClusterLogicalSwitchName
$T1LinkedRouterPortNameOnT0 = "LinkedPort_K8S-Mgmt-Cluster"
$T1LinkedRouterPortNameOnT1 = "LinkedPort_T0-LR"
$T1DownlinkRouterPortSwitchPortName = "Downlink-1-Port"
$T1DownlinkRouterPortNameOnT1 = "Downlink-1"
$T1DownlinkRouterPortIP = "10.10.0.1"
$T1DownlinkRouterPortIPPrefix = "24"

# NSX-T Manager Configurations
$NSXTMgrDeploymentSize = "small"
$NSXTMgrvCPU = "2"
$NSXTMgrvMEM = "8"
$NSXTMgrDisplayName = "nsx-mgr"
$NSXTMgrHostname = "nsx-mgr.primp-industries.com"
$NSXTMgrIPAddress = "172.30.51.13"

# NSX-T Controller Configurations
$NSXTCtrvCPU = "2"
$NSXTCtrvMEM = "6"
$NSXControllerSharedSecret = "s3cR3ctz"
$NSXTControllerHostnameToIPs = @{
"nsx-ctr01" = "172.30.51.14"
"nsx-ctr02" = "172.30.51.15"
"nsx-ctr03" = "172.30.51.16"
}

# NSX-T Edge Configuration
$NSXTEdgevCPU = "8"
$NSXTEdgevMEM = "16"
$NSXTEdgeHostnameToIPs = @{
"nsx-edge01" = "172.30.51.17"
}

# Advanced Configurations
# Set to 1 only if you have DNS (forward/reverse) for ESXi hostnames
$addHostByDnsName = 1

#### DO NOT EDIT BEYOND HERE ####

$debug = $true
$verboseLogFile = "pks-vghetto-lab-deployment.log"
$random_string = -join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})
$VAppName = "vGhetto-Nested-PKS-Lab-$random_string"

$nsxStorageMap = @{
"manager"="160";
"controller"="120";
"edge"="120"
}

$esxiTotalCPU = 0
$nsxTotalCPU = 0
$esxiTotalMemory = 0
$nsxTotalMemory = 0
$esxiTotalStorage = 0
$nsxTotalStorage = 0

$preCheck = 1
$confirmDeployment = 1
$deployNestedESXiVMs = 1
$deployOpsManager = 1
$setupNewVC = 1
$addESXiHostsToVC = 1
$configureVSANDiskGroups = 1
$initialNSXConfig = 1
$postDeployNSXConfig = 1
$moveVMsIntovApp = 1

$StartTime = Get-Date

Function Get-SSLThumbprint256 {
    param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    [Alias('FullName')]
    [String]$URL
    )

add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
            public class IDontCarePolicy : ICertificatePolicy {
            public IDontCarePolicy() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy

    # Need to connect using simple GET operation for this to work
    Invoke-RestMethod -Uri $URL -Method Get | Out-Null

    $ENDPOINT_REQUEST = [System.Net.Webrequest]::Create("$URL")
    $CERT = $ENDPOINT_REQUEST.ServicePoint.Certificate
    # https://stackoverflow.com/a/22251597
    $BYTES = $cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    Set-content -value $BYTES -encoding byte -path $ENV:TMP\cert-temp
    $SSL_THUMBPRINT = (Get-FileHash -Path $ENV:TMP\cert-temp -Algorithm SHA256).Hash
    return $SSL_THUMBPRINT -replace '(..(?!$))','$1:'
}

Function Set-VMKeystrokes {
    <#
        Please see http://www.virtuallyghetto.com/2017/09/automating-vm-keystrokes-using-the-vsphere-api-powercli.html for more details
    #>
        param(
            [Parameter(Mandatory=$true)][String]$VMName,
            [Parameter(Mandatory=$true)][String]$StringInput,
            [Parameter(Mandatory=$false)][Boolean]$ReturnCarriage,
            [Parameter(Mandatory=$false)][Boolean]$DebugOn
        )

        # Map subset of USB HID keyboard scancodes
        # https://gist.github.com/MightyPork/6da26e382a7ad91b5496ee55fdc73db2
        $hidCharacterMap = @{
            "a"="0x04";
            "b"="0x05";
            "c"="0x06";
            "d"="0x07";
            "e"="0x08";
            "f"="0x09";
            "g"="0x0a";
            "h"="0x0b";
            "i"="0x0c";
            "j"="0x0d";
            "k"="0x0e";
            "l"="0x0f";
            "m"="0x10";
            "n"="0x11";
            "o"="0x12";
            "p"="0x13";
            "q"="0x14";
            "r"="0x15";
            "s"="0x16";
            "t"="0x17";
            "u"="0x18";
            "v"="0x19";
            "w"="0x1a";
            "x"="0x1b";
            "y"="0x1c";
            "z"="0x1d";
            "1"="0x1e";
            "2"="0x1f";
            "3"="0x20";
            "4"="0x21";
            "5"="0x22";
            "6"="0x23";
            "7"="0x24";
            "8"="0x25";
            "9"="0x26";
            "0"="0x27";
            "!"="0x1e";
            "@"="0x1f";
            "#"="0x20";
            "$"="0x21";
            "%"="0x22";
            "^"="0x23";
            "&"="0x24";
            "*"="0x25";
            "("="0x26";
            ")"="0x27";
            "_"="0x2d";
            "+"="0x2e";
            "{"="0x2f";
            "}"="0x30";
            "|"="0x31";
            ":"="0x33";
            "`""="0x34";
            "~"="0x35";
            "<"="0x36";
            ">"="0x37";
            "?"="0x38";
            "-"="0x2d";
            "="="0x2e";
            "["="0x2f";
            "]"="0x30";
            "\"="0x31";
            "`;"="0x33";
            "`'"="0x34";
            ","="0x36";
            "."="0x37";
            "/"="0x38";
            " "="0x2c";
        }

        $vm = Get-View -ViewType VirtualMachine -Filter @{"Name"=$VMName}

        # Verify we have a VM or fail
        if(!$vm) {
            Write-host "Unable to find VM $VMName"
            return
        }

        $hidCodesEvents = @()
        foreach($character in $StringInput.ToCharArray()) {
            # Check to see if we've mapped the character to HID code
            if($hidCharacterMap.ContainsKey([string]$character)) {
                $hidCode = $hidCharacterMap[[string]$character]

                $tmp = New-Object VMware.Vim.UsbScanCodeSpecKeyEvent

                # Add leftShift modifer for capital letters and/or special characters
                if( ($character -cmatch "[A-Z]") -or ($character -match "[!|@|#|$|%|^|&|(|)|_|+|{|}|||:|~|<|>|?]") ) {
                    $modifer = New-Object Vmware.Vim.UsbScanCodeSpecModifierType
                    $modifer.LeftShift = $true
                    $tmp.Modifiers = $modifer
                }

                # Convert to expected HID code format
                $hidCodeHexToInt = [Convert]::ToInt64($hidCode,"16")
                $hidCodeValue = ($hidCodeHexToInt -shl 16) -bor 0007

                $tmp.UsbHidCode = $hidCodeValue
                $hidCodesEvents+=$tmp
            } else {
                My-Logger Write-Host "The following character `"$character`" has not been mapped, you will need to manually process this character"
                break
            }
        }

        # Add return carriage to the end of the string input (useful for logins or executing commands)
        if($ReturnCarriage) {
            # Convert return carriage to HID code format
            $hidCodeHexToInt = [Convert]::ToInt64("0x28","16")
            $hidCodeValue = ($hidCodeHexToInt -shl 16) + 7

            $tmp = New-Object VMware.Vim.UsbScanCodeSpecKeyEvent
            $tmp.UsbHidCode = $hidCodeValue
            $hidCodesEvents+=$tmp
        }

        # Call API to send keystrokes to VM
        $spec = New-Object Vmware.Vim.UsbScanCodeSpec
        $spec.KeyEvents = $hidCodesEvents
        $results = $vm.PutUsbScanCodes($spec)
    }

Function My-Logger {
    param(
    [Parameter(Mandatory=$true)]
    [String]$message
    )

    $timeStamp = Get-Date -Format "MM-dd-yyyy_hh:mm:ss"

    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor Green " $message"
    $logMessage = "[$timeStamp] $message"
    $logMessage | Out-File -Append -LiteralPath $verboseLogFile
}

Function URL-Check([string] $url) {
    $isWorking = $true

    try {
        $request = [System.Net.WebRequest]::Create($url)
        $request.Method = "HEAD"
        $request.UseDefaultCredentials = $true

        $response = $request.GetResponse()
        $httpStatus = $response.StatusCode

        $isWorking = ($httpStatus -eq "OK")
    }
    catch {
        $isWorking = $false
    }
    return $isWorking
}

if($preCheck -eq 1) {
    if(!(Test-Path $NestedESXiApplianceOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $NestedESXiApplianceOVA ...`nexiting"
        exit
    }

    if(!(Test-Path $NSXTManagerOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $NSXTManagerOVA ...`nexiting"
        exit
    }

    if(!(Test-Path $NSXTControllerOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $NSXTControllerOVA ...`nexiting"
        exit
    }

    if(!(Test-Path $NSXTEdgeOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $NSXTEdgeOVA ...`nexiting"
        exit
    }
}

if($confirmDeployment -eq 1) {
    Write-Host -ForegroundColor Magenta "`nPlease confirm the following configuration will be deployed:`n"

    Write-Host -ForegroundColor Yellow "---- vGhetto NSX-T Automated Lab Deployment Configuration ---- "
    Write-Host -NoNewline -ForegroundColor Green "Nested ESXi Image Path: "
    Write-Host -ForegroundColor White $NestedESXiApplianceOVA
    Write-Host -NoNewline -ForegroundColor Green "VCSA Image Path: "
    Write-Host -ForegroundColor White $VCSAInstallerPath

    if($DeployNSX -eq 1) {
        Write-Host -NoNewline -ForegroundColor Green "NSX-T Manager Image Path: "
        Write-Host -ForegroundColor White $NSXTManagerOVA
        Write-Host -NoNewline -ForegroundColor Green "NSX-T Controller Image Path: "
        Write-Host -ForegroundColor White $NSXTControllerOVA
        Write-Host -NoNewline -ForegroundColor Green "NSX-T Edge Image Path: "
        Write-Host -ForegroundColor White $NSXTEdgeOVA
    }

    Write-Host -ForegroundColor Yellow "`n---- vCenter Server Deployment Target Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "vCenter Server Address: "
    Write-Host -ForegroundColor White $VIServer
    Write-Host -NoNewline -ForegroundColor Green "VM Network: "
    Write-Host -ForegroundColor White $VMNetwork

    if($DeployNSX -eq 1) {
        Write-Host -NoNewline -ForegroundColor Green "NSX-T Private VM Network: "
        Write-Host -ForegroundColor White $NSXPrivatePortgroup
    }

    Write-Host -NoNewline -ForegroundColor Green "VM Storage: "
    Write-Host -ForegroundColor White $VMDatastore
    Write-Host -NoNewline -ForegroundColor Green "VM Cluster: "
    Write-Host -ForegroundColor White $VMCluster
    Write-Host -NoNewline -ForegroundColor Green "VM vApp: "
    Write-Host -ForegroundColor White $VAppName

    Write-Host -ForegroundColor Yellow "`n---- vESXi Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "# of Nested ESXi VMs: "
    Write-Host -ForegroundColor White $NestedESXiHostnameToIPs.count
    Write-Host -NoNewline -ForegroundColor Green "vCPU: "
    Write-Host -ForegroundColor White $NestedESXivCPU
    Write-Host -NoNewline -ForegroundColor Green "vMEM: "
    Write-Host -ForegroundColor White "$NestedESXivMEM GB"
    Write-Host -NoNewline -ForegroundColor Green "Caching VMDK: "
    Write-Host -ForegroundColor White "$NestedESXiCachingvDisk GB"
    Write-Host -NoNewline -ForegroundColor Green "Capacity VMDK: "
    Write-Host -ForegroundColor White "$NestedESXiCapacityvDisk GB"
    Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
    Write-Host -ForegroundColor White $NestedESXiHostnameToIPs.Values
    Write-Host -NoNewline -ForegroundColor Green "Netmask "
    Write-Host -ForegroundColor White $VMNetmask
    Write-Host -NoNewline -ForegroundColor Green "Gateway: "
    Write-Host -ForegroundColor White $VMGateway
    Write-Host -NoNewline -ForegroundColor Green "DNS: "
    Write-Host -ForegroundColor White $VMDNS
    Write-Host -NoNewline -ForegroundColor Green "NTP: "
    Write-Host -ForegroundColor White $VMNTP
    Write-Host -NoNewline -ForegroundColor Green "Syslog: "
    Write-Host -ForegroundColor White $VMSyslog
    Write-Host -NoNewline -ForegroundColor Green "Enable SSH: "
    Write-Host -ForegroundColor White $VMSSH
    Write-Host -NoNewline -ForegroundColor Green "Create VMFS Volume: "
    Write-Host -ForegroundColor White $VMVMFS
    Write-Host -NoNewline -ForegroundColor Green "Root Password: "
    Write-Host -ForegroundColor White $VMPassword

    if($DeployNSX -eq 1) {
        Write-Host -ForegroundColor Yellow "`n---- NSX-T Configuration ----"
        Write-Host -NoNewline -ForegroundColor Green "NSX Manager Hostname: "
        Write-Host -ForegroundColor White $NSXTMgrHostname
        Write-Host -NoNewline -ForegroundColor Green "NSX Manager IP Address: "
        Write-Host -ForegroundColor White $NSXTMgrIPAddress
        Write-Host -NoNewline -ForegroundColor Green "# of NSX Controller VMs: "
        Write-Host -ForegroundColor White $NSXTControllerHostnameToIPs.count
        Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
        Write-Host -ForegroundColor White $NSXTControllerHostnameToIPs.Values
        Write-Host -NoNewline -ForegroundColor Green "# of NSX Edge VMs: "
        Write-Host -ForegroundColor White $NSXTEdgeHostnameToIPs.count
        Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
        Write-Host -ForegroundColor White $NSXTEdgeHostnameToIPs.Values
        Write-Host -NoNewline -ForegroundColor Green "Netmask: "
        Write-Host -ForegroundColor White $VMNetmask
        Write-Host -NoNewline -ForegroundColor Green "Gateway: "
        Write-Host -ForegroundColor White $VMGateway
        Write-Host -NoNewline -ForegroundColor Green "Enable SSH: "
        Write-Host -ForegroundColor White $NSXSSHEnable
        Write-Host -NoNewline -ForegroundColor Green "Enable Root Login: "
        Write-Host -ForegroundColor White $NSXEnableRootLogin
    }

    $esxiTotalCPU = $NestedESXiHostnameToIPs.count * [int]$NestedESXivCPU
    $esxiTotalMemory = $NestedESXiHostnameToIPs.count * [int]$NestedESXivMEM
    $esxiTotalStorage = ($NestedESXiHostnameToIPs.count * [int]$NestedESXiCachingvDisk) + ($NestedESXiHostnameToIPs.count * [int]$NestedESXiCapacityvDisk)

    Write-Host -ForegroundColor Yellow "`n---- Resource Requirements ----"
    Write-Host -NoNewline -ForegroundColor Green "ESXi VM CPU: "
    Write-Host -NoNewline -ForegroundColor White $esxiTotalCPU
    Write-Host -NoNewline -ForegroundColor Green " ESXi VM Memory: "
    Write-Host -NoNewline -ForegroundColor White $esxiTotalMemory "GB "
    Write-Host -NoNewline -ForegroundColor Green "ESXi VM Storage: "
    Write-Host -ForegroundColor White $esxiTotalStorage "GB"

    if($DeployNSX -eq 1) {
        $nsxTotalCPU += $NSXTControllerHostnameToIPs.count * [int]$NSXTCtrvCPU
        $nsxTotalMemory += $NSXTControllerHostnameToIPs.count * [int]$NSXTCtrvMEM
        $nsxTotalStorage += $NSXTControllerHostnameToIPs.count * [int]$nsxStorageMap["controller"]

        $nsxTotalCPU += [int]$NSXTMgrvCPU
        $nsxTotalMemory += [int]$NSXTMgrvMEM
        $nsxTotalStorage += [int]$nsxStorageMap["manager"]

        $nsxTotalCPU += $NSXTEdgeHostnameToIPs.count * [int]$NSXTEdgevCPU
        $nsxTotalMemory += $NSXTEdgeHostnameToIPs.count * [int]$NSXTEdgevMEM
        $nsxTotalStorage += $NSXTEdgeHostnameToIPs.count * [int]$nsxStorageMap["edge"]

        Write-Host -NoNewline -ForegroundColor Green "NSX VM CPU: "
        Write-Host -NoNewline -ForegroundColor White $nsxTotalCPU
        Write-Host -NoNewline -ForegroundColor Green " NSX VM Memory: "
        Write-Host -NoNewline -ForegroundColor White $nsxTotalMemory "GB "
        Write-Host -NoNewline -ForegroundColor Green " NSX VM Storage: "
        Write-Host -ForegroundColor White $nsxTotalStorage "GB"
    }

    Write-Host -ForegroundColor White "---------------------------------------------"
    Write-Host -NoNewline -ForegroundColor Green "Total CPU: "
    Write-Host -ForegroundColor White ($esxiTotalCPU + $nsxTotalCPU)
    Write-Host -NoNewline -ForegroundColor Green "Total Memory: "
    Write-Host -ForegroundColor White ($esxiTotalMemory + $nsxTotalMemory) "GB"
    Write-Host -NoNewline -ForegroundColor Green "Total Storage: "
    Write-Host -ForegroundColor White ($esxiTotalStorage + $nsxTotalStorage) "GB"

    Write-Host -ForegroundColor Magenta "`nWould you like to proceed with this deployment?`n"
    $answer = Read-Host -Prompt "Do you accept (Y or N)"
    if($answer -ne "Y" -or $answer -ne "y") {
        exit
    }
    Clear-Host
}

My-Logger "Connecting to Management vCenter Server $VIServer ..."
$viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue

$datastore = Get-Datastore -Server $viConnection -Name $VMDatastore | Select -First 1
if($VirtualSwitchType -eq "VSS") {
    $network = Get-VirtualPortGroup -Server $viConnection -Name $VMNetwork | Select -First 1
    if($DeployNSX -eq 1) {
        $privateNetwork = Get-VirtualPortGroup -Server $viConnection -Name $NSXPrivatePortgroup | Select -First 1
        $NSXIntermediateNetwork = Get-VirtualPortgroup -Server $viConnection -Name $NSXIntermediateNetworkPortgroup | Select -First 1
    }
} else {
    $network = Get-VDPortgroup -Server $viConnection -Name $VMNetwork | Select -First 1
    if($DeployNSX -eq 1) {
        $privateNetwork = Get-VDPortgroup -Server $viConnection -Name $NSXPrivatePortgroup | Select -First 1
        $NSXIntermediateNetwork = Get-VDPortgroup -Server $viConnection -Name $NSXIntermediateNetworkPortgroup | Select -First 1
    }
}
$cluster = Get-Cluster -Server $viConnection -Name $VMCluster
$datacenter = $cluster | Get-Datacenter
$vmhost = $cluster | Get-VMHost | Select -First 1

if($datastore.Type -eq "vsan") {
    My-Logger "VSAN Datastore detected, enabling Fake SCSI Reservations ..."
    Get-AdvancedSetting -Entity $vmhost -Name "VSAN.FakeSCSIReservations" | Set-AdvancedSetting -Value 1 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
}

if($deployNestedESXiVMs -eq 1) {
    $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value

        $ovfconfig = Get-OvfConfiguration $NestedESXiApplianceOVA
        $ovfconfig.NetworkMapping.VM_Network.value = $VMNetwork

        $ovfconfig.common.guestinfo.hostname.value = $VMName
        $ovfconfig.common.guestinfo.ipaddress.value = $VMIPAddress
        $ovfconfig.common.guestinfo.netmask.value = $VMNetmask
        $ovfconfig.common.guestinfo.gateway.value = $VMGateway
        $ovfconfig.common.guestinfo.dns.value = $VMDNS
        $ovfconfig.common.guestinfo.domain.value = $VMDomain
        $ovfconfig.common.guestinfo.ntp.value = $VMNTP
        $ovfconfig.common.guestinfo.syslog.value = $VMSyslog
        $ovfconfig.common.guestinfo.password.value = $VMPassword
        if($VMSSH -eq "true") {
            $VMSSHVar = $true
        } else {
            $VMSSHVar = $false
        }
        $ovfconfig.common.guestinfo.ssh.value = $VMSSHVar

        My-Logger "Deploying Nested ESXi VM $VMName ..."
        $vm = Import-VApp -Source $NestedESXiApplianceOVA -OvfConfiguration $ovfconfig -Name $VMName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

        My-Logger "Adding vmnic2/vmnic3 to $NSXPrivatePortgroup ..."
        New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $privateNetwork -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $privateNetwork -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vCPU Count to $NestedESXivCPU & vMEM to $NestedESXivMEM GB ..."
        Set-VM -Server $viConnection -VM $vm -NumCpu $NestedESXivCPU -MemoryGB $NestedESXivMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vSAN Caching VMDK size to $NestedESXiCachingvDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 2" | Set-HardDisk -CapacityGB $NestedESXiCachingvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vSAN Capacity VMDK size to $NestedESXiCapacityvDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 3" | Set-HardDisk -CapacityGB $NestedESXiCapacityvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Powering On $vmname ..."
        $vm | Start-Vm -RunAsync | Out-Null
    }
}

if($deployOpsManager -eq 1) {
    # Deploy Ops Manager
    $opsMgrOvfCOnfig = Get-OvfConfiguration $PKSOpsMgrOVA
    $opsMgrOvfCOnfig.Common.ip0.Value = $OpsManagerIPAddress
    $opsMgrOvfCOnfig.Common.custom_hostname.Value = $OpsManagerHostname
    $opsMgrOvfCOnfig.Common.netmask0.Value = $OpsManagerNetmask
    $opsMgrOvfCOnfig.Common.gateway.Value = $OpsManagerGateway
    $opsMgrOvfCOnfig.Common.ntp_servers.Value = $VMNTP
    $opsMgrOvfCOnfig.Common.DNS.Value = $VMDNS
    $opsMgrOvfCOnfig.Common.admin_password.Value = $OpsManagerAdminPassword
    $opsMgrOvfCOnfig.NetworkMapping.Network_1.Value = $VMNetwork

    My-Logger "Deploying PKS Ops Manager $OpsManagerDisplayName ..."
    $opsmgr_vm = Import-VApp -Source $PKSOpsMgrOVA -OvfConfiguration $opsMgrOvfCOnfig -Name $OpsManagerDisplayName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

    My-Logger "Powering On $OpsManagerDisplayName ..."
    $opsmgr_vm | Start-Vm -RunAsync | Out-Null
}

if($DeployNSX -eq 1) {
    # Deploy NSX Manager
    $nsxMgrOvfConfig = Get-OvfConfiguration $NSXTManagerOVA
    $nsxMgrOvfConfig.DeploymentOption.Value = $NSXTMgrDeploymentSize
    $nsxMgrOvfConfig.NetworkMapping.Network_1.value = $VMNetwork

    $nsxMgrOvfConfig.Common.nsx_role.Value = "nsx-manager"
    $nsxMgrOvfConfig.Common.nsx_hostname.Value = $NSXTMgrHostname
    $nsxMgrOvfConfig.Common.nsx_ip_0.Value = $NSXTMgrIPAddress
    $nsxMgrOvfConfig.Common.nsx_netmask_0.Value = $VMNetmask
    $nsxMgrOvfConfig.Common.nsx_gateway_0.Value = $VMGateway
    $nsxMgrOvfConfig.Common.nsx_dns1_0.Value = $VMDNS
    $nsxMgrOvfConfig.Common.nsx_domain_0.Value = $VMDomain
    $nsxMgrOvfConfig.Common.nsx_ntp_0.Value = $VMNTP

    if($NSXSSHEnable -eq "true") {
        $NSXSSHEnableVar = $true
    } else {
        $NSXSSHEnableVar = $false
    }
    $nsxMgrOvfConfig.Common.nsx_isSSHEnabled.Value = $NSXSSHEnableVar
    if($NSXEnableRootLogin -eq "true") {
        $NSXRootPasswordVar = $true
    } else {
        $NSXRootPasswordVar = $false
    }
    $nsxMgrOvfConfig.Common.nsx_allowSSHRootLogin.Value = $NSXRootPasswordVar

    $nsxMgrOvfConfig.Common.nsx_passwd_0.Value = $NSXRootPassword
    $nsxMgrOvfConfig.Common.nsx_cli_username.Value = $NSXAdminUsername
    $nsxMgrOvfConfig.Common.nsx_cli_passwd_0.Value = $NSXAdminPassword
    $nsxMgrOvfConfig.Common.nsx_cli_audit_username.Value = $NSXAuditUsername
    $nsxMgrOvfConfig.Common.nsx_cli_audit_passwd_0.Value = $NSXAuditPassword

    My-Logger "Deploying NSX Manager VM $NSXTMgrDisplayName ..."
    $nsxmgr_vm = Import-VApp -Source $NSXTManagerOVA -OvfConfiguration $nsxMgrOvfConfig -Name $NSXTMgrDisplayName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

    My-Logger "Updating vCPU Count to $NSXTMgrvCPU & vMEM to $NSXTMgrvMEM GB ..."
    Set-VM -Server $viConnection -VM $nsxmgr_vm -NumCpu $NSXTMgrvCPU -MemoryGB $NSXTMgrvMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Powering On $NSXTMgrDisplayName ..."
    $nsxmgr_vm | Start-Vm -RunAsync | Out-Null

    # Deploy Controllers
    $nsxCtrOvfConfig = Get-OvfConfiguration $NSXTControllerOVA
    $NSXTControllerHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value
        $VMHostname = "$VMName" + "@" + $VMDomain

        $nsxCtrOvfConfig.NetworkMapping.Network_1.value = $VMNetwork
        $nsxCtrOvfConfig.Common.nsx_hostname.Value = $VMHostname
        $nsxCtrOvfConfig.Common.nsx_ip_0.Value = $VMIPAddress
        $nsxCtrOvfConfig.Common.nsx_netmask_0.Value = $VMNetmask
        $nsxCtrOvfConfig.Common.nsx_gateway_0.Value = $VMGateway
        $nsxCtrOvfConfig.Common.nsx_dns1_0.Value = $VMDNS
        $nsxCtrOvfConfig.Common.nsx_domain_0.Value = $VMDomain
        $nsxCtrOvfConfig.Common.nsx_ntp_0.Value = $VMNTP

        if($NSXSSHEnable -eq "true") {
            $NSXSSHEnableVar = $true
        } else {
            $NSXSSHEnableVar = $false
        }
        $nsxCtrOvfConfig.Common.nsx_isSSHEnabled.Value = $NSXSSHEnableVar
        if($NSXEnableRootLogin -eq "true") {
            $NSXRootPasswordVar = $true
        } else {
            $NSXRootPasswordVar = $false
        }
        $nsxCtrOvfConfig.Common.nsx_allowSSHRootLogin.Value = $NSXRootPasswordVar

        $nsxCtrOvfConfig.Common.nsx_passwd_0.Value = $NSXRootPassword
        $nsxCtrOvfConfig.Common.nsx_cli_username.Value = $NSXAdminUsername
        $nsxCtrOvfConfig.Common.nsx_cli_passwd_0.Value = $NSXAdminPassword
        $nsxCtrOvfConfig.Common.nsx_cli_audit_username.Value = $NSXAuditUsername
        $nsxCtrOvfConfig.Common.nsx_cli_audit_passwd_0.Value = $NSXAuditPassword

        My-Logger "Deploying NSX Controller VM $VMName ..."
        $nsxctr_vm = Import-VApp -Source $NSXTControllerOVA -OvfConfiguration $nsxCtrOvfConfig -Name $VMName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

        My-Logger "Updating vCPU Count to $NSXTCtrvCPU & vMEM to $NSXTCtrvMEM GB ..."
        Set-VM -Server $viConnection -VM $nsxctr_vm -NumCpu $NSXTCtrvCPU -MemoryGB $NSXTCtrvMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Powering On $VMName ..."
        $nsxctr_vm | Start-Vm -RunAsync | Out-Null
    }

    # Deploy Edges
    $nsxEdgeOvfConfig = Get-OvfConfiguration $NSXTEdgeOVA
    $NSXTEdgeHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value
        $VMHostname = "$VMName" + "@" + $VMDomain

        $nsxEdgeOvfConfig.DeploymentOption.Value = $NSXTMgrDeploymentSize
        $nsxEdgeOvfConfig.NetworkMapping.Network_0.value = $VMNetwork
        $nsxEdgeOvfConfig.NetworkMapping.Network_1.value = $NSXPrivatePortgroup
        $nsxEdgeOvfConfig.NetworkMapping.Network_2.value = $NSXPrivatePortgroup
        $nsxEdgeOvfConfig.NetworkMapping.Network_3.value = $NSXPrivatePortgroup

        $nsxEdgeOvfConfig.Common.nsx_hostname.Value = $VMHostname
        $nsxEdgeOvfConfig.Common.nsx_ip_0.Value = $VMIPAddress
        $nsxEdgeOvfConfig.Common.nsx_netmask_0.Value = $VMNetmask
        $nsxEdgeOvfConfig.Common.nsx_gateway_0.Value = $VMGateway
        $nsxEdgeOvfConfig.Common.nsx_dns1_0.Value = $VMDNS
        $nsxEdgeOvfConfig.Common.nsx_domain_0.Value = $VMDomain
        $nsxEdgeOvfConfig.Common.nsx_ntp_0.Value = $VMNTP

        if($NSXSSHEnable -eq "true") {
            $NSXSSHEnableVar = $true
        } else {
            $NSXSSHEnableVar = $false
        }
        $nsxEdgeOvfConfig.Common.nsx_isSSHEnabled.Value = $NSXSSHEnableVar
        if($NSXEnableRootLogin -eq "true") {
            $NSXRootPasswordVar = $true
        } else {
            $NSXRootPasswordVar = $false
        }
        $nsxEdgeOvfConfig.Common.nsx_allowSSHRootLogin.Value = $NSXRootPasswordVar

        $nsxEdgeOvfConfig.Common.nsx_passwd_0.Value = $NSXRootPassword
        $nsxEdgeOvfConfig.Common.nsx_cli_username.Value = $NSXAdminUsername
        $nsxEdgeOvfConfig.Common.nsx_cli_passwd_0.Value = $NSXAdminPassword
        $nsxEdgeOvfConfig.Common.nsx_cli_audit_username.Value = $NSXAuditUsername
        $nsxEdgeOvfConfig.Common.nsx_cli_audit_passwd_0.Value = $NSXAuditPassword

        My-Logger "Deploying NSX Edge VM $NSXTEdgeDisplayName ..."
        $nsxedge_vm = Import-VApp -Source $NSXTEdgeOVA -OvfConfiguration $nsxEdgeOvfConfig -Name $VMName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

        My-Logger "Updating vCPU Count to $NSXTEdgevCPU & vMEM to $NSXTEdgevMEM GB ..."
        Set-VM -Server $viConnection -VM $nsxedge_vm -NumCpu $NSXTEdgevCPU -MemoryGB $NSXTEdgevMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Reconfiguring Network Adapter 2 to $privateNetwork ..."
        $nsxedge_vm | Get-NetworkAdapter -Name "Network adapter 2" | Set-NetworkAdapter -Portgroup $privateNetwork -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Reconfiguring Network Adapter 3 to $NSXIntermediateNetwork ..."
        $nsxedge_vm | Get-NetworkAdapter -Name "Network adapter 3" | Set-NetworkAdapter -Portgroup $NSXIntermediateNetwork -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Powering On $NSXTEdgeDisplayName ..."
        $nsxedge_vm | Start-Vm -RunAsync | Out-Null
    }
}

if($moveVMsIntovApp -eq 1) {
    My-Logger "Creating vApp $VAppName ..."
    $VApp = New-VApp -Name $VAppName -Server $viConnection -Location $cluster

    if($deployNestedESXiVMs -eq 1) {
        My-Logger "Moving Nested ESXi VMs into $VAppName vApp ..."
        $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $vm = Get-VM -Name $_.Key -Server $viConnection
            Move-VM -VM $vm -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    if($deployOpsManager -eq 1) {
        My-Logger "Moving Ops Manager VM into $VAppName vApp ..."
        $opsMgrVM = Get-VM -Name $OpsManagerDisplayName -Server $viConnection
        Move-VM -VM $opsMgrVM -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
    }

    if($DeployNSX -eq 1) {
        $nsxMgrVM = Get-VM -Name $NSXTMgrDisplayName -Server $viConnection
        My-Logger "Moving $NSXTMgrDisplayName into $VAppName vApp ..."
        Move-VM -VM $nsxMgrVM -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Moving NSX Controller VMs into $VAppName vApp ..."
        $NSXTControllerHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $nsxCtrVM = Get-VM -Name $_.Key -Server $viConnection
            Move-VM -VM $nsxCtrVM -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        My-Logger "Moving NSX Edge VMs into $VAppName vApp ..."
        $NSXTEdgeHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $nsxEdgeVM = Get-VM -Name $_.Key -Server $viConnection
            Move-VM -VM $nsxEdgeVM -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }
    }
}

My-Logger "Disconnecting from $VIServer ..."
Disconnect-VIServer -Server $viConnection -Confirm:$false

if($setupNewVC -eq 1) {
    My-Logger "Connecting to Management vCenter Server $VIServer ..."
    $viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue

    My-Logger "Creating new VSAN Cluster $NewVCVSANClusterName ..."
    New-Cluster -Server $viConnection -Name $NewVCVSANClusterName -Location (Get-Datacenter -Name $RootDatacenterName -Server $viConnection) -DrsEnabled -VsanEnabled -VsanDiskClaimMode 'Manual' | Out-File -Append -LiteralPath $verboseLogFile

    if($addESXiHostsToVC -eq 1) {
        $NestedESXiHostnameToIPs.GetEnumerator() | sort -Property Value | Foreach-Object {
            $VMName = $_.Key
            $VMIPAddress = $_.Value

            $targetVMHost = $VMIPAddress
            if($addHostByDnsName -eq 1) {
                $targetVMHost = $VMName
            }
            My-Logger "Adding ESXi host $targetVMHost to Cluster ..."
            Add-VMHost -Server $viConnection -Location (Get-Cluster -Name $NewVCVSANClusterName) -User "root" -Password $VMPassword -Name $targetVMHost -Force | Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    if($configureVSANDiskGroups -eq 1) {
        My-Logger "Enabling VSAN & disabling VSAN Health Check ..."
        Get-VsanClusterConfiguration -Server $viConnection -Cluster $NewVCVSANClusterName | Set-VsanClusterConfiguration -HealthCheckIntervalMinutes 0 | Out-File -Append -LiteralPath $verboseLogFile


        foreach ($vmhost in Get-Cluster -Server $viConnection -Name $NewVCVSANClusterName | Get-VMHost) {
            $luns = $vmhost | Get-ScsiLun | select CanonicalName, CapacityGB

            My-Logger "Querying ESXi host disks to create VSAN Diskgroups ..."
            foreach ($lun in $luns) {
                if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiCachingvDisk") {
                    $vsanCacheDisk = $lun.CanonicalName
                }
                if(([int]($lun.CapacityGB)).toString() -eq "$NestedESXiCapacityvDisk") {
                    $vsanCapacityDisk = $lun.CanonicalName
                }
            }
            My-Logger "Creating VSAN DiskGroup for $vmhost ..."
            New-VsanDiskGroup -Server $viConnection -VMHost $vmhost -SsdCanonicalName $vsanCacheDisk -DataDiskCanonicalName $vsanCapacityDisk | Out-File -Append -LiteralPath $verboseLogFile
          }
    }

    # Exit maintanence mode in case patching was done earlier
    foreach ($vmhost in Get-Cluster -Server $viConnection -Name $NewVCVSANClusterName | Get-VMHost) {
        if($vmhost.ConnectionState -eq "Maintenance") {
            Set-VMHost -VMhost $vmhost -State Connected -RunAsync -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    My-Logger "Disconnecting from management vCenter Server ..."
    Disconnect-VIServer -Server $viConnection -Confirm:$false
}

if($initialNSXConfig -eq 1) {
    if(!(Connect-NsxtServer -Server $NSXTMgrHostname -Username $NSXAdminUsername -Password $NSXAdminPassword -WarningAction SilentlyContinue)) {
        Write-Host -ForegroundColor Red "Unable to connect to NSX Manager, please check the deployment"
        exit
    } else {
        My-Logger "Successfully logged into NSX Manager $NSXTMgrHostname  ..."
    }

    My-Logger "Connecting back to Management vCenter Server $VIServer ..."
    Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue | Out-Null

    # Retrieve NSX Manager Thumbprint which will be needed later
    My-Logger "Retrieving NSX Manager Thumbprint ..."
    $nsxMgrID = (Get-NsxtService -Name "com.vmware.nsx.cluster.nodes").list().results.id
    $nsxMgrCertThumbprint = (Get-NsxtService -Name "com.vmware.nsx.cluster.nodes").get($nsxMgrID).manager_role.api_listen_addr.certificate_sha256_thumbprint

    ### Setup NSX Controllers
    $ctrCount=0
    $firstNSXController = ""
    $nsxControllerCertThumbprint  = ""
    $NSXTControllerHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $nsxCtrName = $_.name
        $nsxCtrIp = $_.value

        if($ctrCount -eq 0) {
            My-Logger "Configuring NSX Controller $nsxCtrName as control-cluster master ..."
            # Store the first NSX Controller for later use
            $firstNSXController = $nsxCtrName

            # Login by passing in admin username <enter>
            if($debug) { My-Logger "Sending admin username ..." }
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $NSXAdminUsername -ReturnCarriage $true
            Start-Sleep 2

            # Login by passing in admin password <enter>
            if($debug) { My-Logger "Sending admin password ..." }
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $NSXAdminPassword -ReturnCarriage $true
            Start-Sleep 5

            # Join Controller to NSX Manager
            if($debug) { My-Logger "Sending join management plane command ..." }
            $joinMgmtCmd1 = "join management-plane $NSXTMgrIPAddress username $NSXAdminUsername thumbprint $nsxMgrCertThumbprint"
            $joinMgmtCmd2 = "$NSXAdminPassword"
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $joinMgmtCmd1 -ReturnCarriage $true
            Start-Sleep 5
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $joinMgmtCmd2 -ReturnCarriage $true
            Start-Sleep 25

            # Setup shared secret
            if($debug) { My-Logger "Sending shared secret command ..." }
            $sharedSecretCmd = "set control-cluster security-model shared-secret secret $NSXControllerSharedSecret"
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $sharedSecretCmd -ReturnCarriage $true
            Start-Sleep  5

            # Initialize NSX Controller Cluster
            if($debug) { My-Logger "Sending control cluster init command ..." }
            $initCmd = "initialize control-cluster"
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $initCmd -ReturnCarriage $true
            Start-Sleep 25
        } else {
            My-Logger "Configuring additional NSX Controller $nsxCtrName ..."

            # Login by passing in admin username <enter>
            if($debug) { My-Logger "Sending admin username ..." }
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $NSXAdminUsername -ReturnCarriage $true
            Start-Sleep 2

            # Login by passing in admin password <enter>
            if($debug) { My-Logger "Sending admin password ..." }
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $NSXAdminPassword -ReturnCarriage $true
            Start-Sleep 5

            # Join Controller to NSX Manager
            if($debug) { My-Logger "Sending join management plane command ..." }
            $joinMgmtCmd1 = "join management-plane $NSXTMgrIPAddress username $NSXAdminUsername thumbprint $nsxMgrCertThumbprint"
            $joinMgmtCmd2 = "$NSXAdminPassword"
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $joinMgmtCmd1 -ReturnCarriage $true
            Start-Sleep 5
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $joinMgmtCmd2 -ReturnCarriage $true
            Start-Sleep 25

            # Setup shared secret
            if($debug) { My-Logger "Sending shared secret command ..." }
            $sharedSecretCmd = "set control-cluster security-model shared-secret secret $NSXControllerSharedSecret"
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $sharedSecretCmd -ReturnCarriage $true
            Start-Sleep 5

            ### --- (stupid hack because we don't have an API) --- ###
                # Exit from nsxcli
                if($debug) { My-Logger "Sending exit command ..." }
                Set-VMKeystrokes -VMName $nsxCtrName -StringInput "exit" -ReturnCarriage $true
                Start-Sleep 10

                # Login using root
                if($debug) { My-Logger "Sending root username ..." }
                Set-VMKeystrokes -VMName $nsxCtrName -StringInput "root" -ReturnCarriage $true
                Start-Sleep 2

                # Login by passing in root password <enter>
                if($debug) { My-Logger "Sending root password ..." }
                Set-VMKeystrokes -VMName $nsxCtrName -StringInput $NSXRootPassword -ReturnCarriage $true
                Start-Sleep 10

                # Retrieve Control Cluster Thumbprint by running nsxcli in the shell and
                # storing the thumbprint to a file which we will download later
                if($debug) { My-Logger "Sending get control cluster cert ..." }
                $ctrClusterThumbprintCmd = "nsxcli -c `"get control-cluster certificate thumbprint`" > /tmp/controller-thumbprint"
                Set-VMKeystrokes -VMName $nsxCtrName -StringInput $ctrClusterThumbprintCmd -ReturnCarriage $true
                Start-Sleep 25

                if($debug) { My-Logger "Processing certificate thumbprint ..." }
                Copy-VMGuestFile -vm (Get-VM -Name $nsxCtrName) -GuestToLocal -GuestUser "root" -GuestPassword $NSXRootPassword -Source /tmp/controller-thumbprint -Destination $ENV:TMP\controller-thumbprint | Out-Null
                $nsxControllerCertThumbprint = Get-Content -Path $ENV:TMP\controller-thumbprint | ? {$_.trim() -ne "" }

                # Exit from shell
                if($debug) { My-Logger "Sending exit command ..." }
                Set-VMKeystrokes -VMName $nsxCtrName -StringInput "exit" -ReturnCarriage $true
                Start-Sleep 10
            ### --- (stupid hack because we don't have an API) --- ###

            # Login by passing in admin username <enter>
            if($debug) { My-Logger "Sending admin username ..." }
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $NSXAdminUsername -ReturnCarriage $true
            Start-Sleep 2

            # Login by passing in admin password <enter>
            if($debug) { My-Logger "Sending admin password ..." }
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $NSXAdminPassword -ReturnCarriage $true
            Start-Sleep 5

            # Join NSX Controller to NSX Controller Cluster
            if($debug) { My-Logger "Sending join control cluster command ..." }
            $joinCtrCmd = "join control-cluster $nsxCtrIp thumbprint $nsxControllerCertThumbprint"
            Set-VMKeystrokes -VMName $firstNSXController -StringInput $joinCtrCmd -ReturnCarriage $true
            Start-Sleep 30

            # Activate NSX Controller
            if($debug) { My-Logger "Sending control cluster activate command ..." }
            $initCmd = "activate control-cluster"
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput $initCmd -ReturnCarriage $true
            Start-Sleep 30

            # Exit Console
            if($debug) { My-Logger "Sending final exit ..." }
            Set-VMKeystrokes -VMName $nsxCtrName -StringInput "exit" -ReturnCarriage $true
        }
        $ctrCount++
    }

    ### Setup NSX Edges
    $NSXTEdgeHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $nsxEdgeName = $_.name
        $nsxEdgeIp = $_.value

        My-Logger "Configuring NSX Edge $nsxEdgeName ..."

        # Login by passing in admin username <enter>
        if($debug) { My-Logger "Sending admin username ..." }
        Set-VMKeystrokes -VMName $nsxEdgeName -StringInput $NSXAdminUsername -ReturnCarriage $true
        Start-Sleep 2

        # Login by passing in admin password <enter>
        if($debug) { My-Logger "Sending admin password ..." }
        Set-VMKeystrokes -VMName $nsxEdgeName -StringInput $NSXAdminPassword -ReturnCarriage $true
        Start-Sleep 5

        # Join NSX Edge to NSX Manager
        if($debug) { My-Logger "Sending join management plane command ..." }
        $joinMgmtCmd1 = "join management-plane $NSXTMgrIPAddress username $NSXAdminUsername thumbprint $nsxMgrCertThumbprint"
        $joinMgmtCmd2 = "$NSXAdminPassword"
        Set-VMKeystrokes -VMName $nsxEdgeName -StringInput $joinMgmtCmd1 -ReturnCarriage $true
        Start-Sleep 5
        Set-VMKeystrokes -VMName $nsxEdgeName -StringInput $joinMgmtCmd2 -ReturnCarriage $true
        Start-Sleep 20

        # Exit Console
        if($debug) { My-Logger "Sending final exit ..." }
        Set-VMKeystrokes -VMName $nsxEdgeName -StringInput "exit" -ReturnCarriage $true
    }

    # Exit Console for first NSX Controller
    if($debug) { My-Logger "Sending final exit to initial Controller ..." }
    Set-VMKeystrokes -VMName $firstNSXController -StringInput "exit" -ReturnCarriage $true

    My-Logger "Disconnecting from NSX Manager ..."
    Disconnect-NsxtServer -Confirm:$false

    My-Logger "Disconnecting from Management vCenter ..."
    Disconnect-VIServer * -Confirm:$false
}

if($postDeployNSXConfig -eq 1) {
    if(!(Connect-NsxtServer -Server $NSXTMgrHostname -Username $NSXAdminUsername -Password $NSXAdminPassword -WarningAction SilentlyContinue)) {
        Write-Host -ForegroundColor Red "Unable to connect to NSX Manager, please check the deployment"
        exit
    } else {
        My-Logger "Successfully logged into NSX Manager $NSXTMgrHostname  ..."
    }

    $runHealth=$true
    $runEULA=$true
    $runIPPool=$true
    $runIPBlock=$true
    $runTransportZone=$true
    $runAddVC=$true
    $runLogicalSwitch=$true
    $runHostPrep=$true
    $runUplinkProfile=$true
    $runAddESXiTransportNode=$true
    $runAddEdgeTransportNode=$true
    $runAddEdgeCluster=$true
    $runT0Router = $true
    $runT0RouterPort = $true
    $runT0StaticRoute = $true
    $runT1Router = $true
    $runT1RouterPort = $true
    $runT1RouterAdvertisement = $true

    ### Verify Health for all Nodes
    if($runHealth) {
        My-Logger "Verifying health of all NSX Manager/Controller Nodes ..."
        $clusterNodeService = Get-NsxtService -Name "com.vmware.nsx.cluster.nodes"
        $clusterNodeStatusService = Get-NsxtService -Name "com.vmware.nsx.cluster.nodes.status"
        $nodes = $clusterNodeService.list().results
        $mgmtNodes = $nodes | where { $_.controller_role -eq $null }
        $controllerNodes = $nodes | where { $_.manager_role -eq $null }

        foreach ($mgmtNode in $mgmtNodes) {
            $mgmtNodeId = $mgmtNode.id
            $mgmtNodeName = $mgmtNode.appliance_mgmt_listen_addr

            if($debug) { My-Logger "Check health status of Mgmt Node $mgmtNodeName ..." }
            while ( $clusterNodeStatusService.get($mgmtNodeId).mgmt_cluster_status.mgmt_cluster_status -ne "CONNECTED") {
                if($debug) { My-Logger "$mgmtNodeName is not ready, sleeping 20 seconds ..." }
                Start-Sleep 20
            }
        }

        foreach ($controllerNode in $controllerNodes) {
            $controllerNodeId = $controllerNode.id
            $controllerNodeName = $controllerNode.controller_role.control_plane_listen_addr.ip_address

            if($debug) { My-Logger "Checking health of Ctrl Node $controllerNodeName ..." }
            while ( $clusterNodeStatusService.get($controllerNodeId).control_cluster_status.control_cluster_status -ne "CONNECTED") {
                if($debug) { My-Logger "$controllerNodeName is not ready, sleeping 20 seconds ..." }
                Start-Sleep 20
            }
        }
    }

    if($runEULA) {
        My-Logger "Accepting NSX Manager EULA ..."
        $eulaService = Get-NsxtService -Name "com.vmware.nsx.eula.accept"
        $eulaService.create()
    }

    if($runIPPool) {
        My-Logger "Creating Tunnel Endpoint IP Pool for ESXi ..."
        $ipPoolService = Get-NsxtService -Name "com.vmware.nsx.pools.ip_pools"
        $ipPoolSpec = $ipPoolService.help.create.ip_pool.Create()
        $subNetSpec = $ipPoolService.help.create.ip_pool.subnets.Element.Create()
        $allocationRangeSpec = $ipPoolService.help.create.ip_pool.subnets.Element.allocation_ranges.Element.Create()

        $allocationRangeSpec.start = $TunnelEndpointPoolIPRangeStart
        $allocationRangeSpec.end = $TunnelEndpointPoolIPRangeEnd
        $addResult = $subNetSpec.allocation_ranges.Add($allocationRangeSpec)
        $subNetSpec.cidr = $TunnelEndpointPoolCIDR
        $subNetSpec.gateway_ip = $TunnelEndpointPoolGateway
        $ipPoolSpec.display_name = $TunnelEndpointPoolName
        $ipPoolSpec.description = $TunnelEndpointPoolDescription
        $addResult = $ipPoolSpec.subnets.Add($subNetSpec)
        $ipPool = $ipPoolService.create($ipPoolSpec)

        My-Logger "Load Balancer IP Pool for K8S ..."
        $ipPoolService = Get-NsxtService -Name "com.vmware.nsx.pools.ip_pools"
        $ipPoolSpec = $ipPoolService.help.create.ip_pool.Create()
        $subNetSpec = $ipPoolService.help.create.ip_pool.subnets.Element.Create()
        $allocationRangeSpec = $ipPoolService.help.create.ip_pool.subnets.Element.allocation_ranges.Element.Create()

        $allocationRangeSpec.start = $LoadBalancerPoolIPRangeStart
        $allocationRangeSpec.end = $LoadBalancerPoolIPRangeEnd
        $addResult = $subNetSpec.allocation_ranges.Add($allocationRangeSpec)
        $subNetSpec.cidr = $LoadBalancerPoolCIDR
        $ipPoolSpec.display_name = $LoadBalancerPoolName
        $ipPoolSpec.description = $LoadBalancerPoolDescription
        $addResult = $ipPoolSpec.subnets.Add($subNetSpec)
        $ipPool = $ipPoolService.create($ipPoolSpec)
    }

    if($runIPBlock) {
        My-Logger "Creating PKS IP Block ..."
        $ipBlockService = Get-NsxtService -Name "com.vmware.nsx.pools.ip_blocks"
        $ipBlockSpec = $ipBlockService.Help.create.ip_block.Create()
        $ipBlockSpec.display_name = $ipBlockName
        $ipBlockSpec.cidr = $ipBlockNetwork
        $ipBlockAdd = $ipBlockService.create($ipBlockSpec)
    }

    if($runTransportZone) {
        My-Logger "Creating Overlay & VLAN Transport Zones ..."
        $transportZoneService = Get-NsxtService -Name "com.vmware.nsx.transport_zones"
        $overlayTZSpec = $transportZoneService.help.create.transport_zone.Create()
        $overlayTZSpec.display_name = $OverlayTransportZoneName
        $overlayTZSpec.host_switch_name = $OverlayTransportZoneHostSwitchName
        $overlayTZSpec.transport_type = "OVERLAY"
        $overlayTZ = $transportZoneService.create($overlayTZSpec)

        $vlanTZSpec = $transportZoneService.help.create.transport_zone.Create()
        $vlanTZSpec.display_name = $VLANTransportZoneName
        $vlanTZSpec.host_switch_name = $VlanTransportZoneNameHostSwitchName
        $vlanTZSpec.transport_type = "VLAN"
        $vlanTZ = $transportZoneService.create($vlanTZSpec)
    }

    if($runAddVC) {
        My-Logger "Adding vCenter Server Compute Manager ..."
        $computeManagerSerivce = Get-NsxtService -Name "com.vmware.nsx.fabric.compute_managers"
        $computeManagerStatusService = Get-NsxtService -Name "com.vmware.nsx.fabric.compute_managers.status"

        $computeManagerSpec = $computeManagerSerivce.help.create.compute_manager.Create()
        $credentialSpec = $computeManagerSerivce.help.create.compute_manager.credential.username_password_login_credential.Create()
        $VCURL = "https://" + $VIServer + ":443"
        $VCThumbprint = Get-SSLThumbprint256 -URL $VCURL
        $credentialSpec.username = $VIUsername
        $credentialSpec.password = $VIPassword
        $credentialSpec.thumbprint = $VCThumbprint
        $computeManagerSpec.server = $VIServer
        $computeManagerSpec.origin_type = "vCenter"
        $computeManagerSpec.display_name = $VIServer
        $computeManagerSpec.credential = $credentialSpec
        $computeManagerResult = $computeManagerSerivce.create($computeManagerSpec)

        if($debug) { My-Logger "Waiting for VC registration to complete ..." }
            while ( $computeManagerStatusService.get($computeManagerResult.id).registration_status -ne "REGISTERED") {
                if($debug) { My-Logger "$VIServer is not ready, sleeping 30 seconds ..." }
                Start-Sleep 30
        }
    }

    if($runLogicalSwitch) {
        $transportZoneService = Get-NsxtService -Name "com.vmware.nsx.transport_zones"
        $overlayTZ = $transportZoneService.list().results | where { $_.display_name -eq $OverlayTransportZoneName }
        $vlanTZ = $transportZoneService.list().results | where { $_.display_name -eq $VlanTransportZoneName }

        My-Logger "Adding Logical Switch for K8S Management Cluster ..."
        $logicalSwitchService = Get-NsxtService -Name "com.vmware.nsx.logical_switches"
        $logicalSwitchSpec = $logicalSwitchService.help.create.logical_switch.Create()
        $logicalSwitchSpec.display_name = $K8SMgmtClusterLogicalSwitchName
        $logicalSwitchSpec.admin_state = "UP"
        $logicalSwitchSpec.replication_mode = $K8SMgmtClusterLogicalSwitchReplicationMode
        $logicalSwitchSpec.transport_zone_id = $overlayTZ.id
        $uplinkLogicalSwitch = $logicalSwitchService.create($logicalSwitchSpec)

        My-Logger "Adding Logical Switch for Uplink ..."
        $logicalSwitchService = Get-NsxtService -Name "com.vmware.nsx.logical_switches"
        $logicalSwitchSpec = $logicalSwitchService.help.create.logical_switch.Create()
        $logicalSwitchSpec.display_name = $UplinkLogicalSwitchName
        $logicalSwitchSpec.admin_state = "UP"
        $logicalSwitchSpec.vlan = $UplinkLogicalSwitchVlan
        $logicalSwitchSpec.transport_zone_id = $vlanTZ.id
        $uplinkLogicalSwitch = $logicalSwitchService.create($logicalSwitchSpec)
    }

    if($runHostPrep) {
        My-Logger "Preparing ESXi hosts & Installing NSX VIBs ..."
        $computeCollectionService = Get-NsxtService -Name "com.vmware.nsx.fabric.compute_collections"
        $computeId = $computeCollectionService.list().results[0].external_id

        $computeCollectionFabricTemplateService = Get-NsxtService -Name "com.vmware.nsx.fabric.compute_collection_fabric_templates"
        $computeFabricTemplateSpec = $computeCollectionFabricTemplateService.help.create.compute_collection_fabric_template.Create()
        $computeFabricTemplateSpec.auto_install_nsx = $true
        $computeFabricTemplateSpec.compute_collection_id = $computeId
        $computeCollectionFabric = $computeCollectionFabricTemplateService.create($computeFabricTemplateSpec)

        My-Logger "Waiting for ESXi hosts to finish host prep ..."
        $fabricNodes = (Get-NsxtService -Name "com.vmware.nsx.fabric.nodes").list().results | where { $_.resource_type -eq "HostNode" }
        foreach ($fabricNode in $fabricNodes) {
            $fabricNodeName = $fabricNode.display_name
            while ((Get-NsxtService -Name "com.vmware.nsx.fabric.nodes.status").get($fabricNode.external_id).host_node_deployment_status -ne "INSTALL_SUCCESSFUL") {
                if($debug) { My-Logger "ESXi hosts are still being prepped, sleeping for 30 seconds ..." }
                Start-Sleep 30
            }
        }
    }

    if($runUplinkProfile) {
        $hostSwitchProfileService = Get-NsxtService -Name "com.vmware.nsx.host_switch_profiles"

        My-Logger "Creating ESXi Uplink Profile ..."
        $ESXiUplinkProfileSpec = $hostSwitchProfileService.help.create.base_host_switch_profile.uplink_host_switch_profile.Create()
        $activeUplinkSpec = $hostSwitchProfileService.help.create.base_host_switch_profile.uplink_host_switch_profile.teaming.active_list.Element.Create()
        $activeUplinkSpec.uplink_name = $ESXiUplinkProfileActivepNIC
        $activeUplinkSpec.uplink_type = "PNIC"
        $ESXiUplinkProfileSpec.display_name = $ESXiUplinkProfileName
        $ESXiUplinkProfileSpec.mtu = $ESXiUplinkProfileMTU
        $ESXiUplinkProfileSpec.transport_vlan = $ESXiUplinkProfileTransportVLAN
        $addActiveUplink = $ESXiUplinkProfileSpec.teaming.active_list.Add($activeUplinkSpec)
        $ESXiUplinkProfileSpec.teaming.policy = $ESXiUplinkProfilePolicy
        $ESXiUplinkProfile = $hostSwitchProfileService.create($ESXiUplinkProfileSpec)

        My-Logger "Creating Edge Uplink Profile ..."
        $EdgeUplinkProfileSpec = $hostSwitchProfileService.help.create.base_host_switch_profile.uplink_host_switch_profile.Create()
        $activeUplinkSpec = $hostSwitchProfileService.help.create.base_host_switch_profile.uplink_host_switch_profile.teaming.active_list.Element.Create()
        $activeUplinkSpec.uplink_name = $EdgeUplinkProfileActivepNIC
        $activeUplinkSpec.uplink_type = "PNIC"
        $EdgeUplinkProfileSpec.display_name = $EdgeUplinkProfileName
        $EdgeUplinkProfileSpec.mtu = $EdgeUplinkProfileMTU
        $EdgeUplinkProfileSpec.transport_vlan = $EdgeUplinkProfileTransportVLAN
        $addActiveUplink = $EdgeUplinkProfileSpec.teaming.active_list.Add($activeUplinkSpec)
        $EdgeUplinkProfileSpec.teaming.policy = $EdgeUplinkProfilePolicy
        $EdgeUplinkProfile = $hostSwitchProfileService.create($EdgeUplinkProfileSpec)
    }

    if($runAddESXiTransportNode) {
        $transportNodeService = Get-NsxtService -Name "com.vmware.nsx.transport_nodes"
        $transportNodeStateService = Get-NsxtService -Name "com.vmware.nsx.transport_nodes.state"

        # Retrieve all ESXi Host Nodes
        $hostNodes = (Get-NsxtService -Name "com.vmware.nsx.fabric.nodes").list().results | where { $_.resource_type -eq "HostNode" }
        $ESXiUplinkProfile = (Get-NsxtService -Name "com.vmware.nsx.host_switch_profiles").list().results | where { $_.display_name -eq $ESXiUplinkProfileName}
        $ipPool = (Get-NsxtService -Name "com.vmware.nsx.pools.ip_pools").list().results | where { $_.display_name -eq $TunnelEndpointPoolName }
        $overlayTransportZone = (Get-NsxtService -Name "com.vmware.nsx.transport_zones").list().results | where { $_.transport_type -eq "OVERLAY" }

        foreach ($hostNode in $hostNodes) {
            $hostNodeName = $hostNode.display_name
            My-Logger "Adding $hostNodeName Transport Node ..."

            # Create all required empty specs
            $transportNodeSpec = $transportNodeService.help.create.transport_node.Create()
            $hostSwitchSpec = $transportNodeService.help.create.transport_node.host_switches.Element.Create()
            $hostSwitchProfileSpec = $transportNodeService.help.create.transport_node.host_switches.Element.host_switch_profile_ids.Element.Create()
            $pnicSpec = $transportNodeService.help.create.transport_node.host_switches.Element.pnics.Element.Create()
            $transportZoneEPSpec = $transportNodeService.help.create.transport_node.transport_zone_endpoints.Element.Create()

            $transportNodeSpec.display_name = $hostNodeName
            $hostSwitchSpec.host_switch_name = $OverlayTransportZoneHostSwitchName
            $hostSwitchProfileSpec.key = "UplinkHostSwitchProfile"
            $hostSwitchProfileSpec.value = $ESXiUplinkProfile.id
            $pnicSpec.device_name = $ESXiUplinkProfileActivepNIC
            $pnicSpec.uplink_name = $ESXiUplinkProfileActivepNIC
            $hostSwitchSpec.static_ip_pool_id = $ipPool.id
            $pnicAddResult = $hostSwitchSpec.pnics.Add($pnicSpec)
            $switchProfileAddResult = $hostSwitchSpec.host_switch_profile_ids.Add($hostSwitchProfileSpec)
            $switchAddResult = $transportNodeSpec.host_switches.Add($hostSwitchSpec)
            $transportZoneEPSpec.transport_zone_id = $overlayTransportZone.id
            $transportZoneAddResult = $transportNodeSpec.transport_zone_endpoints.Add($transportZoneEPSpec)
            $transportNodeSpec.node_id = $hostNode.id
            $transportNode = $transportNodeService.create($transportNodeSpec)

            My-Logger "Waiting for transport node configurations to complete ..."
            while ($transportNodeStateService.get($transportNode.id).state -ne "success") {
                if($debug) { My-Logger "ESXi transport node still being configured, sleeping for 30 seconds ..." }
                Start-Sleep 30
            }
        }
    }

    if($runAddEdgeTransportNode) {
        $transportNodeService = Get-NsxtService -Name "com.vmware.nsx.transport_nodes"
        $transportNodeStateService = Get-NsxtService -Name "com.vmware.nsx.transport_nodes.state"

        # Retrieve all Edge Host Nodes
        $edgeNodes = (Get-NsxtService -Name "com.vmware.nsx.fabric.nodes").list().results | where { $_.resource_type -eq "EdgeNode" }
        $EdgeUplinkProfile = (Get-NsxtService -Name "com.vmware.nsx.host_switch_profiles").list().results | where { $_.display_name -eq $EdgeUplinkProfileName}
        $ipPool = (Get-NsxtService -Name "com.vmware.nsx.pools.ip_pools").list().results | where { $_.display_name -eq $TunnelEndpointPoolName }
        $overlayTransportZone = (Get-NsxtService -Name "com.vmware.nsx.transport_zones").list().results | where { $_.transport_type -eq "OVERLAY" }
        $vlanTransportZone = (Get-NsxtService -Name "com.vmware.nsx.transport_zones").list().results | where { $_.transport_type -eq "VLAN" }

        foreach ($edgeNode in $edgeNodes) {
            $edgeNodeName = $edgeNode.display_name
            My-Logger "Adding $edgeNodeName Edge Transport Node ..."

            # Create all required empty specs
            $transportNodeSpec = $transportNodeService.help.create.transport_node.Create()
            $hostSwitchOverlaySpec = $transportNodeService.help.create.transport_node.host_switches.Element.Create()
            $hostSwitchVlanSpec = $transportNodeService.help.create.transport_node.host_switches.Element.Create()
            $hostSwitchProfileSpec = $transportNodeService.help.create.transport_node.host_switches.Element.host_switch_profile_ids.Element.Create()
            $pnicOverlaySpec = $transportNodeService.help.create.transport_node.host_switches.Element.pnics.Element.Create()
            $pnicVlanSpec = $transportNodeService.help.create.transport_node.host_switches.Element.pnics.Element.Create()
            $transportZoneEPOverlaySpec = $transportNodeService.help.create.transport_node.transport_zone_endpoints.Element.Create()
            $transportZoneEPVlanSpec = $transportNodeService.help.create.transport_node.transport_zone_endpoints.Element.Create()

            $transportNodeSpec.display_name = $edgeNodeName

            $hostSwitchOverlaySpec.host_switch_name = $OverlayTransportZoneHostSwitchName
            $hostSwitchProfileSpec.key = "UplinkHostSwitchProfile"
            $hostSwitchProfileSpec.value = $EdgeUplinkProfile.id
            $pnicOverlaySpec.device_name = $EdgeUplinkProfileOverlayvNIC
            $pnicOverlaySpec.uplink_name = $EdgeUplinkProfileActivepNIC
            $hostSwitchOverlaySpec.static_ip_pool_id = $ipPool.id
            $pnicAddResult = $hostSwitchOverlaySpec.pnics.Add($pnicOverlaySpec)
            $switchProfileAddResult = $hostSwitchOverlaySpec.host_switch_profile_ids.Add($hostSwitchProfileSpec)
            $switchAddResult = $transportNodeSpec.host_switches.Add($hostSwitchOverlaySpec)

            $hostSwitchVlanSpec.host_switch_name = $VlanTransportZoneNameHostSwitchName
            $hostSwitchProfileSpec.key = "UplinkHostSwitchProfile"
            $hostSwitchProfileSpec.value = $EdgeUplinkProfile.id
            $pnicVlanSpec.device_name = $EdgeUplinkProfileVlanvNIC
            $pnicVlanSpec.uplink_name = $EdgeUplinkProfileActivepNIC
            $pnicAddResult = $hostSwitchVlanSpec.pnics.Add($pnicVlanSpec)
            $switchProfileAddResult = $hostSwitchVlanSpec.host_switch_profile_ids.Add($hostSwitchProfileSpec)
            $switchAddResult = $transportNodeSpec.host_switches.Add($hostSwitchVlanSpec)

            $transportZoneEPOverlaySpec.transport_zone_id = $overlayTransportZone.id
            $transportZoneAddResult = $transportNodeSpec.transport_zone_endpoints.Add($transportZoneEPOverlaySpec)

            $transportZoneEPVlanSpec.transport_zone_id = $vlanTransportZone.id
            $transportZoneAddResult = $transportNodeSpec.transport_zone_endpoints.Add($transportZoneEPVlanSpec)

            $transportNodeSpec.node_id = $edgeNode.id
            $transportNode = $transportNodeService.create($transportNodeSpec)

            My-Logger "Waiting for transport node configurations to complete ..."
            while ($transportNodeStateService.get($transportNode.id).state -ne "success") {
                if($debug) { My-Logger "ESXi transport node still being configured, sleeping for 30 seconds ..." }
                Start-Sleep 30
            }
        }
    }

    if($runAddEdgeCluster) {
        $edgeNodes = (Get-NsxtService -Name "com.vmware.nsx.fabric.nodes").list().results | where { $_.resource_type -eq "EdgeNode" }
        $edgeClusterService = Get-NsxtService -Name "com.vmware.nsx.edge_clusters"
        $edgeNodeMembersSpec = $edgeClusterService.help.create.edge_cluster.members.Create()

        My-Logger "Creating Edge Cluster $EdgeClusterName and adding Edge Hosts ..."

        foreach ($edgeNode in $edgeNodes) {
            $edgeNodeName = $edgeNode.display_name
            $edgeNodeMemberSpec = $edgeClusterService.help.create.edge_cluster.members.Element.Create()
            $edgeNodeMemberSpec.transport_node_id = $edgeNode.id
            $edgeNodeMemberAddResult = $edgeNodeMembersSpec.Add($edgeNodeMemberSpec)
        }

        $edgeClusterSpec = $edgeClusterService.help.create.edge_cluster.Create()
        $edgeClusterSpec.display_name = $EdgeClusterName
        $edgeClusterSpec.members = $edgeNodeMembersSpec
        $edgeCluster = $edgeClusterService.Create($edgeClusterSpec)
    }

    if($runT0Router) {
        My-Logger "Creating T0 Router $T0LogicalRouterName ..."
        # T0-LR
        $edgeClusterService = Get-NsxtService -Name "com.vmware.nsx.edge_clusters"
        $edgeCluster = $edgeClusterService.list().results | where { $_.display_name -eq $EdgeClusterName }
        $logicalRouterService = Get-NsxtService -Name "com.vmware.nsx.logical_routers"
        $lrSpec = $logicalRouterService.Help.create.logical_router.Create()
        $lrSpec.display_name = $T0LogicalRouterName
        $lrSpec.router_type = "TIER0"
        $lrSpec.high_availability_mode = $T0LogicalRouterHAMode
        $lrSpec.edge_cluster_id = $edgeCluster.id
        $lrAdd = $logicalRouterService.create($lrSpec)
    }

    if($runT0RouterPort) {
        $logicalRouterService = Get-NsxtService -Name "com.vmware.nsx.logical_routers"
        $lr = $logicalRouterService.list().results | where { $_.display_name -eq $T0LogicalRouterName }
        $logicalSwitchService = Get-NsxtService -Name "com.vmware.nsx.logical_switches"
        $ls = $logicalSwitchService.list().results | where { $_.display_name -eq $UplinkLogicalSwitchName}

        # Must add Logical Switch Port before adding Logical Router Port (gah)
        My-Logger "Creating Logical Switch Port $T0UplinkRouterPortSwitchPortName ..."
        # Uplink-1-Port
        $logicalPortSerivce = Get-NsxtService -Name "com.vmware.nsx.logical_ports"
        $portSpec = $logicalPortSerivce.Help.create.logical_port.Create()
        $portSpec.display_name = $T0UplinkRouterPortSwitchPortName
        $portSpec.admin_state = "UP"
        $portSpec.logical_switch_id = $ls.id
        $logicalSwitchPort = $logicalPortSerivce.create($portSpec)

        My-Logger "Creating Logical Router Port $T0UplinkRouterPortName ..."
        # Uplink-1
        $logicalRouterPortSerivce = Get-NsxtService -Name "com.vmware.nsx.logical_router_ports"
        $lrPortSpec = $logicalRouterPortSerivce.help.create.logical_router_port.logical_router_up_link_port.Create()
        $subnetSpec = $logicalRouterPortSerivce.help.create.logical_router_port.logical_router_up_link_port.subnets.Element.Create()
        $memberIndex = $logicalRouterPortSerivce.help.create.logical_router_port.logical_router_up_link_port.edge_cluster_member_index.Element.Create()
        $subnetAdd = $subnetSpec.ip_addresses.Add($T0UplinkRouterPortIP)
        $subNetSpec.prefix_length = $T0UplinkRouterPortIPPrefix
        $lrPortSpec.display_name = $T0UplinkRouterPortName
        $lrPortSpec.linked_logical_switch_port_id.target_id = $logicalSwitchPort.id
        $lrPortSpec.linked_logical_switch_port_id.target_type = "LogicalPort"
        $subnetAdd = $lrPortSpec.subnets.Add($subNetSpec)
        $memberIndex = @(0)
        $lrPortSpec.edge_cluster_member_index = $memberIndex
        $lrPortSpec.logical_router_id = $lr.id
        $logicalRouterPortAdd = $logicalRouterPortSerivce.create($lrPortSpec)
    }

    if($runT0StaticRoute) {
        My-Logger "Creating Static Route on $T0LogicalRouterName from $T0UplinkRouterStaticRouteNetwork to $T0UplinkRouterstaticRouteNextHop ..."
        $logicalRouterService = Get-NsxtService -Name "com.vmware.nsx.logical_routers"
        $lr = $logicalRouterService.list().results | where { $_.display_name -eq $T0LogicalRouterName }

        $staticRouteSerivce = Get-NsxtService -Name "com.vmware.nsx.logical_routers.routing.static_routes"
        $staticRouteSpec = $staticRouteSerivce.Help.create.static_route.Create()
        $nextHopeSpec = $staticRouteSerivce.Help.create.static_route.next_hops.Element.Create()
        $staticRouteSpec.network = $T0UplinkRouterStaticRouteNetwork
        $nextHopeSpec.ip_address = $T0UplinkRouterstaticRouteNextHop
        $nextHopAdd = $staticRouteSpec.next_hops.Add($nextHopeSpec)
        $staticRouteAdd = $staticRouteSerivce.create($lr.id, $staticRouteSpec)
    }

    if($runT1Router) {
        My-Logger "Creating T1 Router $T1LogicalRouterName ..."
        # T1-K8S-Mgmt-Cluster
        $edgeClusterService = Get-NsxtService -Name "com.vmware.nsx.edge_clusters"
        $edgeCluster = $edgeClusterService.list().results | where { $_.display_name -eq $EdgeClusterName }
        $logicalRouterService = Get-NsxtService -Name "com.vmware.nsx.logical_routers"
        $lrSpec = $logicalRouterService.Help.create.logical_router.Create()
        $lrSpec.display_name = $T1LogicalRouterName
        $lrSpec.router_type = "TIER1"
        $lrSpec.high_availability_mode = $T1LogicalRouterHAMode
        $lrSpec.failover_mode = $T1LogicalRouterFailOverMode
        $lrSpec.edge_cluster_id = $edgeCluster.id
        $lrAdd = $logicalRouterService.create($lrSpec)
    }

    if($runT1RouterPort) {
        $logicalRouterService = Get-NsxtService -Name "com.vmware.nsx.logical_routers"
        $t0lr = $logicalRouterService.list().results | where { $_.display_name -eq $T0LogicalRouterName }
        $t1lr = $logicalRouterService.list().results | where { $_.display_name -eq $T1LogicalRouterName }

        $logicalSwitchService = Get-NsxtService -Name "com.vmware.nsx.logical_switches"
        $ls = $logicalSwitchService.list().results | where { $_.display_name -eq $K8SMgmtClusterLogicalSwitchName}

        $logicalRouterPortSerivce = Get-NsxtService -Name "com.vmware.nsx.logical_router_ports"
        $portOnT0 = $logicalRouterPortSerivce.help.create.logical_router_port.logical_router_link_port_on_TIE_r0.Create()
        $portOnT1 = $logicalRouterPortSerivce.Help.create.logical_router_port.logical_router_link_port_on_TIE_r1.Create()
        $downlinkPortOnT1 = $logicalRouterPortSerivce.Help.create.logical_router_port.logical_router_down_link_port.Create()
        $subnetSpec = $logicalRouterPortSerivce.help.create.logical_router_port.logical_router_down_link_port.subnets.Element.Create()
        $memberIndex = $logicalRouterPortSerivce.Help.create.logical_router_port.logical_router_link_port_on_TIE_r1.edge_cluster_member_index.Create()

        My-Logger "Creating T0 Logical Router Port $T1LinkedRouterPortNameOnT0 ..."
        # LinkedPort_K8S-Mgmt-Cluster
        $portOnT0.display_name = $T1LinkedRouterPortNameOnT0
        $portOnT0.logical_router_id = $t0lr.id
        $portOnT0Add = $logicalRouterPortSerivce.create($portOnT0)

        My-Logger "Creating T1 Logical Router Port $T1LinkedRouterPortNameOnT1 ..."
        # LinkedPort_T0-LR
        $portOnT1.display_name = $T1LinkedRouterPortNameOnT1
        $portOnT1.logical_router_id = $t1lr.id
        $portOnT1.linked_logical_router_port_id.target_type = "LogicalRouterLinkPortOnTIER0"
        $portOnT1.linked_logical_router_port_id.target_id = $portOnT0Add.id
        $memberIndex = @(0)
        $portOnT1.edge_cluster_member_index = $memberIndex
        $portOnT1Add = $logicalRouterPortSerivce.create($portOnT1)

        My-Logger "Creating T1 Logical Downlink Router Switch Port $T1DownlinkRouterPortSwitchPortName"
        # Downlink-1-Port
        $logicalPortSerivce = Get-NsxtService -Name "com.vmware.nsx.logical_ports"
        $portSpec = $logicalPortSerivce.Help.create.logical_port.Create()
        $portSpec.display_name = $T1DownlinkRouterPortSwitchPortName
        $portSpec.admin_state = "UP"
        $portSpec.logical_switch_id = $ls.id
        $logicalSwitchPort = $logicalPortSerivce.create($portSpec)

        My-Logger "Creating T1 Logical Downlink Router Port $T1DownlinkRouterPortNameOnT1 ..."
        # Downlink-1
        $subnetAdd = $subnetSpec.ip_addresses.Add($T1DownlinkRouterPortIP)
        $subNetSpec.prefix_length = $T1DownlinkRouterPortIPPrefix     
        $subnetAdd = $downlinkPortOnT1.subnets.Add($subNetSpec)
        $downlinkPortOnT1.display_name = $T1DownlinkRouterPortNameOnT1
        $downlinkPortOnT1.linked_logical_switch_port_id.target_type = "LogicalPort"
        $downlinkPortOnT1.linked_logical_switch_port_id.target_id = $logicalSwitchPort.id
        $downlinkPortOnT1.logical_router_id =  $t1lr.id
        $downlinkRouterPortAdd = $logicalRouterPortSerivce.create($downlinkPortOnT1)
    }

    if($runT1RouterAdvertisement) {
        $routingAdvertisementSerivce = Get-NsxtService -Name "com.vmware.nsx.logical_routers.routing.advertisement"

        $logicalRouterSerivce = Get-NsxtService -Name "com.vmware.nsx.logical_routers"
        $lr = $logicalRouterSerivce.list().results | where { $_.display_name -eq $T1LogicalRouterName }
        $currentRevision = [int]$routingAdvertisementSerivce.get($lr.id).toString()

        My-Logger "Updating T1 Route Advertisement on $T1LogicalRouterName ..."
        $advertisementSpec = $routingAdvertisementSerivce.Help.update.advertisement_config.Create()
        $advertisementSpec.enabled = $true
        $advertisementSpec.advertise_nsx_connected_routes = $true
        $advertisementSpec.advertise_nat_routes = $true
        $advertisementSpec.revision = $currentRevision
        $routeAdvUpdate = $routingAdvertisementSerivce.update($lr.id,$advertisementSpec)
    }

    My-Logger "Disconnecting from NSX Manager ..."
    Disconnect-NsxtServer * -Confirm:$false
}

$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)

My-Logger "PKS 1.0 Lab Deployment Complete!"
My-Logger "StartTime: $StartTime"
My-Logger "  EndTime: $EndTime"
My-Logger " Duration: $duration minutes"