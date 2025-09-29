# ======================= deploy-task2.ps1 =========================
# VM: Ubuntu 22.04 LTS (Canonical jammy), B1s, Standard security
# Region: UK South. VM спочатку без Public IP, далі Public IP + DNS, NSG 22/8080
# Скрипт:
#  - валідую/нормалізую DNS label
#  - створюю ресурси ідемпотентно
#  - пробую створити Basic/Dynamic Public IP; якщо в регіоні/квоті заборонено —
#    gracefully fallback на Standard/Static, але DNS лишається тим самим
#  - прив’язую PIP до NIC за Id (стабільно між версіями Az)
# ==================================================================

# 0) Налаштування (зміни за потреби)
$AdminUser     = "azureuser"
$SshPubKeyPath = "$HOME/.ssh/id_rsa.pub"
$DnsLabel      = "max-task2-uks"    # тільки a-z0-9-, унікально в UK South

# 1) Імена/локація
$Location   = "UK South"
$TaskRg     = "mate-azure-task-2"
$VmName     = "matevm-uk2"
$VnetName   = "$VmName-vnet"
$SubnetName = "$VmName-subnet"
$NsgName    = "$VmName-nsg"
$NicName    = "$VmName-nic"
$PipName    = "$VmName-pip"

# 2) Образ Ubuntu 22.04 (jammy)
$Publisher = "Canonical"
$Offer     = "0001-com-ubuntu-server-jammy"
$Sku       = "22_04-lts"
$Version   = "latest"

# --- Валідація/нормалізація DNS label
$DnsLabel = $DnsLabel.ToLower()
if ($DnsLabel -notmatch '^[a-z0-9-]+$') {
  throw "DnsLabel '$DnsLabel' is invalid. Use only a-z, 0-9 and '-'."
}

# 3) Перевірки
if (-not (Test-Path $SshPubKeyPath)) {
  throw "Немає SSH public key: $SshPubKeyPath. Згенеруй: ssh-keygen -t rsa -b 4096"
}
$sshKey = Get-Content -Raw $SshPubKeyPath

# 4) RG
New-AzResourceGroup -Name $TaskRg -Location $Location -ErrorAction SilentlyContinue | Out-Null

# 5) NSG
$nsg = Get-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $TaskRg -ErrorAction SilentlyContinue
if (-not $nsg) {
  $nsg = New-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $TaskRg -Location $Location
}

# 6) VNet + Subnet
$vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $TaskRg -ErrorAction SilentlyContinue
if (-not $vnet) {
  $vnet = New-AzVirtualNetwork -Name $VnetName -ResourceGroupName $TaskRg -Location $Location -AddressPrefix "10.42.0.0/16"
  Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet -AddressPrefix "10.42.1.0/24" -NetworkSecurityGroup $nsg | Out-Null
  $vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet
}
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet

# 7) NIC (без Public IP)
$nic = Get-AzNetworkInterface -Name $NicName -ResourceGroupName $TaskRg -ErrorAction SilentlyContinue
if (-not $nic) {
  $nic = New-AzNetworkInterface -Name $NicName -ResourceGroupName $TaskRg -Location $Location -SubnetId $subnet.Id -NetworkSecurityGroupId $nsg.Id
}

# 8) VM конфіг
$vm = New-AzVMConfig -VMName $VmName -VMSize "Standard_B1s" -SecurityType "Standard"

# Пояснення: Set-AzVMOperatingSystem вимагає PSCredential, навіть якщо ми
# відключаємо паролі (-DisablePasswordAuthentication). Передаємо "placeholder"
# пароль; логін дозволений лише по SSH-ключу.
$vm = Set-AzVMOperatingSystem -VM $vm -Linux -ComputerName $VmName `
      -Credential (New-Object System.Management.Automation.PSCredential($AdminUser,(ConvertTo-SecureString "placeholder" -AsPlainText -Force))) `
      -DisablePasswordAuthentication

$vm = Add-AzVMSshPublicKey -VM $vm -KeyData $sshKey -Path "/home/$AdminUser/.ssh/authorized_keys"
$vm = Set-AzVMSourceImage -VM $vm -PublisherName $Publisher -Offer $Offer -Skus $Sku -Version $Version
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id -Primary

# 9) Створити VM (якщо ще немає)
if (-not (Get-AzVM -Name $VmName -ResourceGroupName $TaskRg -ErrorAction SilentlyContinue)) {
  New-AzVM -ResourceGroupName $TaskRg -Location $Location -VM $vm -ErrorAction Stop | Out-Null
}

# 10) Public IP + DNS (спроба Basic/Dynamic, fallback на Standard/Static)
$pip = Get-AzPublicIpAddress -Name $PipName -ResourceGroupName $TaskRg -ErrorAction SilentlyContinue
$fallbackUsed = $false

if (-not $pip) {
  try {
    $pip = New-AzPublicIpAddress -Name $PipName -ResourceGroupName $TaskRg -Location $Location `
           -AllocationMethod Dynamic -Sku Basic -DomainNameLabel $DnsLabel -ErrorAction Stop
  } catch {
    # На деяких підписках/регіонах Basic IPv4 заборонений → робимо Standard/Static
    $pip = New-AzPublicIpAddress -Name $PipName -ResourceGroupName $TaskRg -Location $Location `
           -AllocationMethod Static -Sku Standard -DomainNameLabel $DnsLabel
    $fallbackUsed = $true
  }
}

# Прив’язка PIP до NIC по Id (стабільніше, ніж передавати весь об’єкт)
$nic = Get-AzNetworkInterface -Name $NicName -ResourceGroupName $TaskRg
$ipconfName = $nic.IpConfigurations[0].Name
Set-AzNetworkInterfaceIpConfig -NetworkInterface $nic -Name $ipconfName -PublicIpAddressId $pip.Id | Out-Null
$nic | Set-AzNetworkInterface | Out-Null

$pip = Get-AzPublicIpAddress -Name $PipName -ResourceGroupName $TaskRg
$fqdn = $pip.DnsSettings.Fqdn

# 11) NSG правила 22 і 8080 (окремі правила з різними пріоритетами)
$nsg = Get-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $TaskRg
if (-not ($nsg.SecurityRules | Where-Object Name -eq "allow-ssh-22")) {
  $nsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name "allow-ssh-22" -Description "Allow SSH" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 22
}
if (-not ($nsg.SecurityRules | Where-Object Name -eq "allow-web-8080")) {
  $nsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name "allow-web-8080" -Description "Allow web 8080" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1010 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 8080
}
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg | Out-Null

# 12) Вивід
"===== SUCCESS ====="
"RG:   $TaskRg"
"VM:   $VmName (B1s, Ubuntu 22.04, SecurityType=Standard)"
"DNS:  $fqdn"
if ($fallbackUsed) { "PIP:  Standard/Static (fallback, Basic/Dynamic недоступний у регіоні/квоті)" } else { "PIP:  Basic/Dynamic" }
"SSH:  ssh $AdminUser@$fqdn"
"WEB:  http://$fqdn`:8080"
# =================================================================
