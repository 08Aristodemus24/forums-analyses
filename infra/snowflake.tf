provider "snowflake" {
    username = "terraform"
    account  = "xxx"
    private_key_path       = "../rsa_key.p8"
    role                   = "xxxx"
}