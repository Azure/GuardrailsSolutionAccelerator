# Guardrails Module 8 - Network Segmentation and Separation

## How it works

This module will retrieve the list of subnets in all available VNets (all VNets visible to the managed identity, according to the permissions assigned (Typically, all since permissions are assigned at the Root Management Group level))

For each subnet the following items will be evaluated.

### Regarding Segmentation

- Existence of an NSG attached to the subnet.
- In the said NSG, there must be a rule, set as the last rule in the custom rules, and configured to deny all traffic.

If any of the above rules is not true, the subnet will be considered non compliant

### Regarding Separation

- Existence of an UDR (Route table) assigned to the subnet
- The UDR must have a default route set to a Virtual Appliance

If any of the above rules is not true, the subnet will be considered non compliant