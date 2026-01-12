# Security Policy

## Supported Versions

We actively support the latest version of Wokenv. Security updates will be provided for:

| Version | Supported          |
|---------|--------------------|
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within Wokenv, please send an email to the maintainers at [security@example.com](mailto:security@example.com). All security vulnerabilities will be promptly addressed.

**Please do not report security vulnerabilities through public GitHub issues.**

### What to Include

When reporting a vulnerability, please include:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response Timeline

- We will acknowledge receipt of your vulnerability report within 48 hours
- We will send you regular updates about our progress
- If the vulnerability is accepted, we will release a patch as soon as possible
- Once the security issue is resolved, we will publicly disclose the vulnerability

## Security Best Practices

When using Wokenv:

1. **Keep Docker Updated**: Always use the latest version of Docker
2. **Use Official Images**: Pull images from official Docker Hub repository
3. **Review .env Files**: Never commit sensitive data to version control
4. **Limited Exposure**: Don't expose WordPress ports to public networks in production
5. **Regular Updates**: Keep Wokenv and dependencies updated

## Known Security Considerations

- Wokenv uses Docker-in-Docker which requires mounting the Docker socket. This grants significant privileges to the container.
- The environment is intended for development only, not production use.
- Default WordPress credentials (admin/password) should be changed if exposing to any network.

## Disclosure Policy

When we receive a security report, we will:

1. Confirm the problem and determine affected versions
2. Audit code to find similar problems
3. Prepare fixes for all supported versions
4. Release new versions and announce the vulnerability

Thank you for helping keep Wokenv and its users safe!
