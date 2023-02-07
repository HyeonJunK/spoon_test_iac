terraform {
  backend "s3" {
    bucket = ${{ secrets.AWS_S3 }}
    key    = ${{ secrets.AWS_S3_KEY }}
    region = ${{ secrets.AWS_REGION }}
  }
}
