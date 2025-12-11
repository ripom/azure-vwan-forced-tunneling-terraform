# Azure Virtual WAN with Force Tunneling - Terraform Deployment

> [!IMPORTANT]
> **⚠️ POST-DEPLOYMENT STEP REQUIRED ⚠️**
> 
> This deployment requires a **mandatory post-deployment configuration step** using Azure CLI after running `terraform apply`. 
> 
> **Without this step, force tunneling will NOT work correctly.**
> 
> See [Step 6: Post-Deployment Configuration](#6-️-important-post-deployment-configuration-required) for details.

This Terraform configuration deploys an Azure Virtual WAN environment with force tunneling through Azure Firewall, demonstrating hub-spoke topology with custom firewall policies.

## Architecture

```
                                 ┌─────────────────────────────────────────┐
                                 │      Internet (0.0.0.0/0)              │
                                 └────────────────▲────────────────────────┘
                                                  │
                                                  │ Direct Internet Access
                                                  │
                                      ┌───────────┴───────────┐
                                      │   DMZ VNet            │
                                      │  10.0.0.0/16          │
                                      │                       │
                                      │  ┌─────────────────┐  │
                             ┌────────┤  │    fw-dmz       │  │
                             │        │  │   (AZFW VNet)   │  │
                             │        │  │   HTTP Only     │  │
                             │        │  └─────────────────┘  │
                             │        │   10.0.1.0/24         │
                             │        └───────────────────────┘
                             │
                             │ Static Route: 0.0.0.0/0
                             │ Force Tunnel via fw-dmz
                             │
                  ┌──────────┴─────────────────────┐
                  │   Virtual WAN Hub              │
                  │   10.1.0.0/16                  │
                  │                                │
                  │  ┌──────────────────────────┐  │
                  │  │       fw-hub             │  │
                  │  │     (AZFW Hub)           │  │
                  │  │     HTTP Only            │  │
                  │  │                          │  │
                  │  │   Routing Intent for     │  │
                  │  │   Private Traffic        │  │
                  │  └──────────────────────────┘  │
                  └────────────┬───────────────────┘
                               │
                               │ Hub Connection
                               │ Internet Security Enabled
                               │
                    ┌──────────▼─────────────┐
                    │   Spoke VNet           │
                    │   hub-spoke            │
                    │   10.2.0.0/16          │
                    │                        │
                    │  ┌──────────────────┐  │
                    │  │    vm-spoke      │  │
                    │  │    (Ubuntu)      │  │
                    │  └──────────────────┘  │
                    │   10.2.0.0/24          │
                    └────────────────────────┘

Traffic Flow (Force Tunneling):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Spoke VM → Internet: 
  vm-spoke → fw-hub (private traffic) → fw-dmz (0.0.0.0/0 static route) → Internet
  
• DMZ VNet → Internet: 
  Direct via fw-dmz (allows HTTP only)
  
• Inter-VNet Traffic: 
  Routed through fw-hub via routing intent (private traffic inspection)
  
• Force Tunneling: 
  All internet traffic from Hub/Spoke is forced through DMZ firewall (fw-dmz)
  Static route 0.0.0.0/0 points to fw-dmz private IP
```

The deployment creates:

### DMZ Virtual Network (10.0.0.0/16)
- **vnet-dmz** with Azure Firewall for inspection
  - `AzureFirewallSubnet` (10.0.1.0/24) - Azure Firewall subnet
- **Azure Firewall (fw-dmz)** - VNet-based firewall with custom policies:
  - Allows HTTP traffic (port 80)
- **Route Table** - Routes internet traffic (0.0.0.0/0) directly to Internet

### Virtual WAN Hub (10.1.0.0/16)
- **Azure Virtual WAN** - Regional network hub
- **Virtual Hub (vhub)** - Central routing point
- **Azure Firewall (fw-hub)** - Hub-based firewall with policies:
  - Allows HTTP traffic (port 80)
- **Routing Intent** - Routes private traffic through hub firewall

### Spoke Virtual Network (10.2.0.0/16)
- **hub-spoke** VNet with workload VM
  - `subnet-spoke` (10.2.0.0/24) - Workload subnet
- **vm-spoke** - Ubuntu 22.04 test VM

### Hub Connections
- DMZ VNet connected with static route (0.0.0.0/0) to DMZ firewall
- Spoke VNet connected with internet security enabled

## File Structure

The configuration is organized into multiple files:
- `main.tf` - Provider and resource group configuration
- `variables.tf` - Variable definitions
- `dmz.tf` - DMZ VNet and firewall resources
- `vwan.tf` - Virtual WAN, hub, and connections
- `spoke.tf` - Spoke VNet and VM resources
- `outputs.tf` - Output values
- `terraform.tfvars` - Variable values (customize this)

## Prerequisites

- Azure subscription
- Terraform >= 1.0
- Azure CLI installed and authenticated

## Deployment Steps

### 1. Authenticate to Azure

```powershell
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Configure Variables

Copy the example variables file and update with your values:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your values:

```hcl
subscription_id     = "your-subscription-id"
resource_group_name = "rg-example-demo"
location            = "eastus"
admin_username      = "adminuser"
admin_password      = "YourSecurePassword123!"
vm_size             = "Standard_B2s"
```

### 3. Initialize Terraform

```powershell
terraform init
```

### 4. Review the Plan

```powershell
terraform plan
```

### 5. Deploy

```powershell
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### 6. ⚠️ IMPORTANT: Post-Deployment Configuration (Required)

**This step is MANDATORY to enable force tunneling for internet traffic.**

After Terraform completes, you must manually add `0.0.0.0/0` to the Virtual Hub Routing Intent's Private Traffic prefixes using Azure CLI. This configuration is not yet supported by the Terraform provider.

**Why this is needed:**
- Terraform can only configure routing intent with predefined destinations ("PrivateTraffic" or "Internet")
- To achieve force tunneling, we need to add `0.0.0.0/0` as a custom prefix to the Private Traffic policy
- This routes internet-bound traffic through the hub firewall, which then forwards it to the DMZ firewall via the static route

**Run this after `terraform apply` completes:**

**RECOMMENDED: Manual Configuration via Azure Portal**

The Azure REST API does not currently support adding custom prefixes to Private Traffic through automation. Use the Portal method:

1. Navigate to **Azure Portal** → **Virtual WAN** → Your Virtual Hub (**vhub**)
2. Go to **"Routing Intent and Routing Policies"**
3. Click on **"Private Traffic"** → **"Edit Private Traffic Prefixes"**
4. In the text box, add: `0.0.0.0/0`
5. Click **"Save"**
6. Wait for the configuration to complete (may take a few minutes)

**Why this manual step is required:**
- Azure Portal supports adding custom IP prefixes to the Private Traffic definition
- This feature is not yet exposed in the Terraform azurerm provider
- The Azure REST API does not accept custom prefix properties (`privateTrafficPrefixes`, `destinationAddressPrefixes`, etc.)
- Adding `0.0.0.0/0` tells the routing intent to treat internet traffic as "private traffic"
- This causes internet-bound traffic to route through fw-hub, which then follows the static route to fw-dmz

**What happens after configuration:**
- Traffic from spoke VNets to internet (0.0.0.0/0) will be classified as "private traffic"
- Routing intent sends this traffic through fw-hub
- The DMZ VNet connection has a static route (0.0.0.0/0 → fw-dmz)
- fw-hub forwards the traffic to fw-dmz, achieving force tunneling
- fw-dmz applies HTTP-only rules before sending to internet

**⚠️ Without this step, force tunneling will NOT work correctly and internet traffic from spoke VNets will bypass the DMZ firewall.**

## Firewall Policies

### DMZ Firewall Rules
1. **Network Rule** (Priority 100) - Allow HTTP
   - Allows TCP port 80 to all destinations

### Hub Firewall Rules
1. **Network Rule** (Priority 100) - Allow HTTP
   - Allows TCP port 80 to all destinations
   - No Google blocking

## Testing

### Test HTTP Traffic from Spoke VM
1. Connect to `vm-spoke` using Azure Bastion or serial console
2. Test HTTP traffic: `curl -I http://example.com`
3. Traffic routes through fw-hub → fw-dmz → Internet

### Test Force Tunneling
- All internet traffic from spoke VNet passes through both firewalls
- Only HTTP (port 80) is allowed
- HTTPS and other protocols will be blocked

## Resource Naming

All resources follow Azure naming conventions:
- Resource Group: Configurable via variable
- DMZ VNet: `vnet-dmz`
- Spoke VNet: `hub-spoke`
- DMZ Firewall: `fw-dmz`
- Hub Firewall: `fw-hub`
- Virtual WAN: `vwan`
- Virtual Hub: `vhub`

## Cleanup

To remove all resources:

```powershell
terraform destroy
```

Type `yes` when prompted to confirm deletion.

## Cost Considerations

This deployment includes:
- Azure Virtual WAN Hub (charged per hour)
- 2 Azure Firewalls - Standard tier (VNet and Hub-based)
- 1 Standard_B2s VM (can be changed via `vm_size` variable)
- Public IPs for firewalls

These resources incur significant costs. Consider destroying the environment when not in use.

## References

- [Azure Virtual WAN Documentation](https://learn.microsoft.com/en-us/azure/virtual-wan/)
- [Azure Firewall Policy Documentation](https://learn.microsoft.com/en-us/azure/firewall/policy-rule-sets)
- [Virtual WAN Routing Intent](https://learn.microsoft.com/en-us/azure/virtual-wan/how-to-routing-policies)

