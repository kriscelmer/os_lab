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

echo "---> Creating m1.tiny flavor"
openstack flavor create --ram 256 --disk 1 --vcpus 1 m1.tiny
echo "<---"

echo "---> Creating m1.small flavor"
openstack flavor create --ram 512 --disk 5 --vcpus 1 m1.small
echo "<---"

echo "---> Creating m1.standard flavor"
openstack flavor create --ram 1024 --disk 10 --vcpus 1 m1.standard
echo "<---"

echo "---> Creating a public image public-cirros"
wget https://download.cirros-cloud.net/0.6.3/cirros-0.6.3-x86_64-disk.img
openstack image create --public --file cirros-0.6.3-x86_64-disk.img --disk-format qcow2 --container-format bare public-cirros
echo "<---"

echo "---> Creating project demo-project, user demo with role member in demo-project"
openstack project create --enable demo-project
openstack user create --project demo-project --password openstack --ignore-password-expiry demo
openstack role add --user demo --project demo-project member
echo "<---"

echo "---> Creating openrc file for user demo"
cat << EOF > ~/.demo-openrc.sh
export OS_PROJECT_DOMAIN_NAME='Default'
export OS_USER_DOMAIN_NAME='Default'
export OS_PROJECT_NAME='demo-project'
export OS_TENANT_NAME='demo-project'
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

echo "---> Sharing example.test. zone with demo-project project"
PROJECT_PROJECT_ID=$(openstack project show -f value -c id demo-project)
openstack zone share create example.test. $PROJECT_PROJECT_ID
echo "<---"

echo "---> Switching CLI credentials to user demo in demo-project project"
source ~/.demo-openrc.sh
echo "<---"

echo "---> Creating demo-net network and demo-router in project demo-project"
openstack network create demo-net
openstack subnet create --network demo-net --subnet-range 10.10.10.0/24 demo-subnet
openstack router create demo-router
openstack router set demo-router --external-gateway provider-net
openstack router add subnet demo-router demo-subnet
echo "<---"

echo "---> Creating private cirros image"
openstack image create --file cirros-0.6.3-x86_64-disk.img --disk-format qcow2 --container-format bare demo-cirros
echo "<---"

echo "---> Creating security group allowing ingres of ICMP (ping) and SSH traffic"
openstack security group create --description 'Allows ssh and ping from any host' ssh-icmp
openstack security group rule create --ethertype IPv4 --protocol icmp --remote-ip 0.0.0.0/0 ssh-icmp
openstack security group rule create --ethertype IPv4 --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0 ssh-icmp
echo "<---"

echo "---> Switching CLI credentials to user admin"
source /etc/kolla/admin-openrc.sh
echo "<---"

echo "---> Creating project/tenant lab1-tenant, user lab1 with role member in lab1-tenant"
openstack project create --enable lab1-tenant
openstack user create --project lab1-tenant --password openstack --ignore-password-expiry lab1
openstack role add --user lab1 --project lab1-tenant member
echo "<---"

echo "---> Creating openrc file for user lab1"
cat << EOF > ~/.lab1-openrc.sh
export OS_PROJECT_DOMAIN_NAME='Default'
export OS_USER_DOMAIN_NAME='Default'
export OS_PROJECT_NAME='lab1-tenant'
export OS_TENANT_NAME='lab1-tenant'
export OS_USERNAME='lab1'
export OS_PASSWORD='openstack'
export OS_AUTH_URL='http://10.0.0.11:5000'
export OS_INTERFACE='internal'
export OS_ENDPOINT_TYPE='internalURL'
export OS_IDENTITY_API_VERSION='3'
export OS_REGION_NAME='RegionOne'
export OS_AUTH_PLUGIN='password'
EOF
echo "<---"

echo "---> Sharing example.test. zone with lab1-tenant project"
PROJECT_TENANT_ID=$(openstack project show -f value -c id lab1-tenant)
openstack zone share create example.test. $PROJECT_TENANT_ID
echo "<---"

echo "---> Switching CLI credentials to user lab1 in lab1-tenant project"
source ~/.lab1-openrc.sh
echo "<---"

echo "---> Creating lab1-net network and lab1-router in project lab1-tenant"
openstack network create lab1-net
openstack subnet create --network lab1-net --subnet-range 10.10.20.0/24 lab1-subnet
openstack router create lab1-router
openstack router set lab1-router --external-gateway provider-net
openstack router add subnet lab1-router lab1-subnet
echo "<---"

echo "---> Creating cirros image"
openstack image create --file cirros-0.6.3-x86_64-disk.img --disk-format qcow2 --container-format bare lab1-cirros
echo "<---"

echo "---> Creating security group allowing ingres of ICMP (ping) and SSH traffic"
openstack security group create --description 'Allows ssh and ping from any host' ssh-icmp
openstack security group rule create --ethertype IPv4 --protocol icmp --remote-ip 0.0.0.0/0 ssh-icmp
openstack security group rule create --ethertype IPv4 --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0 ssh-icmp
echo "<---"

echo "---> Creating an instance lab1-inst"
openstack server create --flavor m1.tiny --image lab1-cirros --network lab1-net --security-group default --security-group ssh-icmp --wait lab1-inst
echo "<---"

echo "---> Creating a new, empty volume lab1-vol and attach to lab1-inst"
openstack volume create --size 1 lab1-vol
openstack server add volume lab1-inst lab1-vol
echo "<---"

echo "---> Stopping the lab1-inst"
openstack server stop lab1-inst
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