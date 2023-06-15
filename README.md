# Backend Migration

In this lab we will, migrate an old Vault instance running version `v0.10.2` and using the Consul backend on version `v0.9.3` to Vault version `v1.13.2` with the Integrated Storage (RAFT) backend. Portions of this guide have been taken from the [official HashiCorp guide](https://developer.hashicorp.com/vault/tutorials/raft/raft-migration)

## Installation

```bash
./install.sh
```

## Consul

Update the `YOUR_PRIVATE_IP_ADDRESS` Consul Config's in the file `consul.json` with yours. You can get it by running:

```bash
ip addr
```

and look for the IP under `eth0`

```hcl
{
  "datacenter": "dc1",
  "data_dir": "./data/consul",
  "log_level": "INFO",
  "bootstrap_expect": 1,
  "node_name": "node1",
  "server": true,
  "advertise_addr": "YOUR_PRIVATE_IP_ADDRESS"
}
```

Start Consul:

```bash
nohup consul agent -server -config-file=consul.json > consul.log &
```

## Vault

Vault Config in the file `vault_config_consul_backend.hcl`:

```hcl
disable_mlock = true
ui            = true
cluster_addr = "http://127.0.0.1:8201"
api_addr = "http://127.0.0.1:8200"

storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
```


```bash
nohup vault_old server -config=vault_config_consul_backend.hcl > vault.log &
```

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault_old operator init -key-shares=1 -key-threshold=1
vault_old operator unseal
export VAULT_TOKEN=
```

### Create a Vault Secret

Let's create a kv secret.

```bash
vault_old secrets enable kv
vault_old kv put kv/test foo=bar
```

Read back the secret

```bash
vault_old kv get kv/test
```

## Migrate to Raft Backend

0. Take a Consul snapshot

It's always a good idea to take a backup snapshot before proceeding.

```bash
consul snapshot save backup.snap
```

1. New Vault config file `vault_config_raft_backend.hcl`:

```hcl
disable_mlock = true
ui            = true
cluster_addr  = "http://127.0.0.1:8201"
api_addr      = "http://127.0.0.1:8200"

storage "raft" {
  path    = "./data/vault/"
  node_id = "node_1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
```

2. Create a migration config file: `migrate.hcl`

```hcl
storage_source "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

storage_destination "raft" {
  path    = "./data/vault/"
  node_id = "node_1"
}

cluster_addr = "https://127.0.0.1:8201"
```

3. Stop the Vault server by killing the vault process

4. Run the migration command with the new vault binary:

```bash
mkdir -p ./data/vault
nohup vault_new operator migrate -config=migrate.hcl > migrate.log &
```

5. Run vault with the new RAFT database

```bash
nohup vault_new server -config=vault_config_raft_backend.hcl > vault.log &
```

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault_new operator unseal
export VAULT_TOKEN=
```

6. Check the Secret stored

```bash
vault_new kv get kv/test
```

7. Take a raft snapshot

```bash
vault_new operator raft snapshot save backup_raft.snap
```