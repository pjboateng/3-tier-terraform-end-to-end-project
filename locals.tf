locals {
  project_tags = {
    contact      = "devops@apci.com"
    application  = "jupiter"
    project      = "apci"
    environment  = "${terraform.workspace}" # refers to your current workspace (dev, prod, etc)
    creationTime = timestamp()
  }
}