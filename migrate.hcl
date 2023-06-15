storage_source "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

storage_destination "raft" {
  path    = "./data/vault/"
  node_id = "node_1"
}

cluster_addr = "https://127.0.0.1:8201"
