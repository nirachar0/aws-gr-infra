terraform {
    backend "s3" {
        bucket         = "terraform-state-store-956a3a6c"
        key            = "terraform/state/terraform.tfstate"
        region         = "us-east-1"
    }
}