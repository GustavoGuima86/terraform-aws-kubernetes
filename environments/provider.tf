provider "aws" {
  region = var.targetRegion
  default_tags {
    tags = {
      Environment = "Test"
      Owner       = "Gustavo"
      Project     = "Calculation"
    }
  }
  alias = "this"
}