terraform {
    backend "s3" {
        bucket         = "terraform-state-store-d43f36f3"
        key            = "terraform/state/terraform.tfstate"
        region         = "us-east-1"
    }
}