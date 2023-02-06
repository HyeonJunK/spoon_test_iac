terraform {
  backend "s3" {
    bucket = "spoon-test-tf"
    key    = "terraform/spoon-test.tfstate"
    region = "ap-northeast-2"
  }
}
