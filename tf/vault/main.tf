terraform {
  required_version = ">= 1.4.0"
  required_providers {
    vault = "~> 3.25.0"
  }
  backend "s3" {
    bucket = "tfstate"
    key    = "vault.tfstate"
    endpoints = {
      s3 = "http://localhost:9000"
    }
    region = "minio"

    skip_credentials_validation = true
    skip_requesting_account_id = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style = true
  }
}

provider "vault" {
  address = "https://vault.didactik.labs"
}
