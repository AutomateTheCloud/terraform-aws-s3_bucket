# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-04

Initial release.

### Added

- An S3 bucket with secure defaults: public access blocked, HTTPS required, SSE-S3 encryption, and ACLs off.
- Versioning, lifecycle rules, server access logging, and default encryption with SSE-S3 or KMS.
- A bucket policy with read and write access for other AWS accounts and AWS Organizations, public read, and your own statements through `policy.source_policy_documents`.
- Static website hosting, CORS, Object Lock, Transfer Acceleration, and Requester Pays.
- `region`, to create the bucket in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for a basic bucket, a static website, a log bucket, and most options together.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-s3_bucket/releases/tag/v1.0.0
