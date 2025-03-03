#! /bin/bash

# To run this script in freshly installed Ubuntu 24.04:
# $ wget "https://raw.githubusercontent.com/kriscelmer/os_lab/refs/heads/main/2024.2%20(Dalmatian)/lab-config.sh"
# $ bash lab-config.sh
# Follow on screen instructions when script finishes

echo "---> Setting user CLI credentials to user admin"
source /etc/kolla/admin-openrc.sh
echo "<---"

echo "---> Activate openstack-venv to enable openstack CLI command"
source ~/openstack-venv/bin/activate
echo "<---"

echo "---> Creating provider network"
openstack network create --share --external --dns-domain example.test. --provider-network-type flat --provider-physical-network physnet1 provider-net
VM_NAT_net_prefix=$(sudo ip -4 -o a show ens32 | awk '{print $4}' | cut -d '.' -f 1,2,3)
openstack subnet create --network provider-net --allocation-pool start=$VM_NAT_net_prefix.100,end=$VM_NAT_net_prefix.127 --gateway $VM_NAT_net_prefix.2 --subnet-range $VM_NAT_net_prefix.0/24 provider-net-subnet
echo "<---"

echo "---> Creating project/tenant demo-tenant, user demo with role member in demo-tenant"
openstack project create --enable demo-tenant
openstack user create --project demo-tenant --password openstack --ignore-password-expiry demo
openstack role add --user demo --project demo-tenant member
echo "<---"

echo "---> Creating openrc file for user demo"
cat << EOF > ~/.demo-openrc.sh
export OS_PROJECT_DOMAIN_NAME='Default'
export OS_USER_DOMAIN_NAME='Default'
export OS_PROJECT_NAME='demo-tenant'
export OS_TENANT_NAME='demo-tenant'
export OS_USERNAME='demo'
export OS_PASSWORD='openstack'
export OS_AUTH_URL='http://10.0.0.11:5000'
export OS_INTERFACE='internal'
export OS_ENDPOINT_TYPE='internalURL'
export OS_IDENTITY_API_VERSION='3'
export OS_REGION_NAME='RegionOne'
export OS_AUTH_PLUGIN='password'
EOF
echo "<---"

echo "---> Creating m1.tiny flavor"
openstack flavor create --ram 256 --disk 1 --vcpus 1 m1.tiny
echo "<---"

echo "---> Sharing example.test. zone with demo-tenant project"
PROJECT_TENANT_ID=$(openstack project show -f value -c id demo-tenant)
openstack zone share create example.test. $PROJECT_TENANT_ID
echo "<---"

echo "---> Switching CLI credentials to user demo in demo-tenant project"
source ~/.demo-openrc.sh
echo "<---"

echo "---> Creating demo-net network and demo-router in project demo-tenant"
openstack network create demo-net
openstack subnet create --network demo-net --subnet-range 10.10.10.0/24 demo-subnet
openstack router create demo-router
openstack router set demo-router --external-gateway provider-net
openstack router add subnet demo-router demo-subnet
echo "<---"

echo "---> Creating cirros image"
wget https://download.cirros-cloud.net/0.6.3/cirros-0.6.3-x86_64-disk.img
openstack image create --file cirros-0.6.3-x86_64-disk.img --disk-format qcow2 --container-format bare cirros
echo "<---"

echo "---> Creating security group allowing ingres of ICMP (ping) and SSH traffic"
openstack security group create --description 'Allows ssh and ping from any host' ssh-icmp
openstack security group rule create --ethertype IPv4 --protocol icmp --remote-ip 0.0.0.0/0 ssh-icmp
openstack security group rule create --ethertype IPv4 --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0 ssh-icmp
echo "<---"

cat << EOF

OpenStack All-in-One Lab is configured now.

Horizon GUI Console is available from Windows browser at http://10.0.0.11
Skyline modern console is available from Windows browser at http://10.0.0.11:9999

User 'admin' password gets retrieved by running:

grep OS_PASSWORD /etc/kolla/admin-openrc.sh

Admin credentials for OpenStack CLI client are set by running:

source /etc/kolla/admin-openrc.sh

User demo credentials for OpenStack CLI are set by running:

source ~/.demo-openrc.sh

OpenSearch console can get accessed from Windows browser at 10.0.1.11:5601
Default username is opensearch and password is retrieved by running:

grep opensearch_dashboards_password /etc/kolla/passwords.yml

Enjoy!
EOF