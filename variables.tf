variable "cors" {
  description = "Cross Origin Resource Sharing"
  type        = any
  default     = null
}

variable "enable_transfer_acceleration" {
  description = "Enable S3 Transfer Acceleration"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Lifecycle rules"
  type        = any
  default     = null
}

variable "logging" {
  description = "Logging"
  type        = any
  default     = null
}

variable "name" {
  description = "The name of the bucket"
  type        = string
  default     = ""
}

variable "object_lock" {
  description = "Object Lock"
  type        = any
  default     = null
}

variable "policy" {
  description = "Policy"
  type        = any
  default     = null
}

variable "public" {
  description = "Public Settings"
  type        = any
  default     = null
}

variable "public_access_block" {
  description = "Public Access Block configuration"
  type        = any
  default     = null
}

variable "requester_pays" {
  description = "Enable Requester Pays"
  type        = bool
  default     = false
}

variable "s3_bucket_additional_tags" {
  description = "S3Bucket - Additional Tags"
  type        = map
  default     = {}
}

variable "server_side_encryption" {
  description = "Server-Side Encryption"
  type        = any
  default     = null
}

variable "used_for_s3_logs" {
  description = "Used for S3 Logs"
  type        = bool
  default     = false
}

variable "versioning" {
  description = "Versioning options"
  type        = any
  default     = null
}

variable "website" {
  description = "Website Configuration"
  type        = any
  default     = null
}
