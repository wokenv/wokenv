# Contributing to Wokenv

Thank you for your interest in contributing to Wokenv! We welcome contributions from the community.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/wokenv.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit with clear messages: `git commit -m "Add feature: description"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Open a Pull Request

## Development Guidelines

### Code Style

- Use clear, descriptive variable names
- Follow existing code patterns
- Add comments for complex logic
- Keep shell scripts POSIX-compatible where possible

### Testing

Before submitting a PR, please test:

1. **Installation script**: Test the curl installer
2. **Makefile commands**: Verify all make targets work
3. **Docker images**: Test both standard and patched variants
4. **Different environments**: Test on Linux and macOS if possible

### Documentation

- Update README.md if you change functionality
- Add inline comments for complex code
- Update examples if needed

## Pull Request Process

1. **Clear description**: Explain what your PR does and why
2. **Reference issues**: Link related issues if applicable
3. **Test results**: Share how you tested your changes
4. **Breaking changes**: Clearly mark any breaking changes

## Reporting Issues

When reporting issues, please include:

- Operating system and version
- Docker version
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs or error messages

## Questions?

Feel free to open an issue for questions or discussion.

## License

By contributing, you agree that your contributions will be licensed under GPL-3.0-or-later.
