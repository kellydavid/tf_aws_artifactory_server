output artifactory_private_ip_address {
  value = "${module.artifactory_server.private_ip}"
}
