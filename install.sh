wget https://releases.hashicorp.com/consul/0.9.3/consul_0.9.3_linux_amd64.zip
wget https://releases.hashicorp.com/vault/0.10.2/vault_0.10.2_linux_amd64.zip
wget https://releases.hashicorp.com/vault/1.13.2/vault_1.13.2_linux_amd64.zip

sudo apt install unzip
unzip consul_0.9.3_linux_amd64.zip
unzip vault_0.10.2_linux_amd64.zip
sudo mv vault /usr/bin/vault_old
sudo mv consul /usr/bin

unzip vault_1.13.2_linux_amd64.zip
sudo mv vault /usr/bin/vault_new

rm consul_*
rm vault_*
