terraform {
  backend "remote" {
    organization = "davidkelly"

    workspaces {
      name = "tf_aws_artifactory_server"
    }
  }
}
