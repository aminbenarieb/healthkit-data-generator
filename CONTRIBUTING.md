# Contributing to Health Generator App

Thank you for your interest in contributing to the Health Generator App! This document provides guidelines and instructions for contributing to this project.

## Getting Started

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.10 or later
- Tuist (for iOS app development)
- Python 3.8+ (for icon generation scripts)

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/health-generator-app.git
   cd health-generator-app
   ```

2. **Set up the iOS app**
   ```bash
   cd HealthGeneratorApp
   tuist generate
   open HealthGeneratorApp.xcworkspace
   ```

3. **Set up the Swift Package**
   ```bash
   cd AppleHealthGenerator
   swift build
   swift test
   ```

## Project Structure

- `AppleHealthGenerator/` - Swift Package for health data generation
- `HealthGeneratorApp/` - SwiftUI iOS app that uses the package
- `.github/workflows/` - CI/CD workflows
- `HealthGeneratorApp/create_*.py` - Python scripts for icon generation

## Development Workflow

### Branching Strategy

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature branches
- `hotfix/*` - Critical bug fixes
- `release/*` - Release preparation branches

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the coding standards (see below)
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Test Swift Package
   cd AppleHealthGenerator
   swift test
   
   # Test iOS App
   cd HealthGeneratorApp
   tuist generate
   # Run tests in Xcode or via xcodebuild
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new health data type support"
   ```

5. **Push and create a pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### Swift Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting (configuration in `.swiftlint.yml`)
- Prefer `async/await` over completion handlers
- Use proper access control (private, internal, public)
- Document public APIs with Swift documentation comments

### Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

Examples:
```
feat: add sleep data generation support
fix: resolve crash when cleaning health data
docs: update README with new installation steps
```

### Code Quality

- All public APIs must be documented
- New features must include unit tests
- Maintain test coverage above 80%
- Follow SOLID principles
- Use dependency injection where appropriate

## Testing

### Swift Package Tests

```bash
cd AppleHealthGenerator
swift test
```

### iOS App Tests

```bash
cd HealthGeneratorApp
tuist generate
xcodebuild -workspace HealthGeneratorApp.xcworkspace \
  -scheme HealthGeneratorApp \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  test
```

### Manual Testing

1. Test on real devices when possible
2. Verify HealthKit permissions work correctly
3. Test data generation and cleanup functionality
4. Ensure UI works across different screen sizes

## Documentation

- Update README.md for user-facing changes
- Update inline code documentation for API changes
- Add examples for new features
- Update this CONTRIBUTING.md if the development process changes

## Submitting Pull Requests

### Before Submitting

- [ ] Code follows project style guidelines
- [ ] Self-review of code completed
- [ ] Tests added for new functionality
- [ ] All tests pass
- [ ] Documentation updated
- [ ] No SwiftLint warnings
- [ ] Commit messages follow convention

### Pull Request Process

1. **Fill out the PR template** with detailed description
2. **Request review** from maintainers
3. **Address feedback** promptly and thoroughly
4. **Ensure CI passes** before requesting final review
5. **Squash commits** if requested by maintainers

### PR Title Format

Use the same format as commit messages:
```
feat: add heart rate variability data generation
fix: resolve memory leak in data cleanup
```

## Release Process

Releases are automated through GitHub Actions:

1. **Version Bump**: Update version numbers in relevant files
2. **Create Tag**: `git tag -a v1.2.0 -m "Release v1.2.0"`
3. **Push Tag**: `git push origin v1.2.0`
4. **GitHub Actions** will automatically create a release

## Issue Reporting

### Bug Reports

Include:
- iOS version and device model
- Xcode version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/videos if applicable
- Console logs if relevant

### Feature Requests

Include:
- Clear description of the feature
- Use case and motivation
- Proposed implementation approach
- Any alternative solutions considered

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers get started
- Maintain professional communication

## Getting Help

- Check existing issues and documentation first
- Create a GitHub issue for bugs or feature requests
- Use GitHub Discussions for questions and ideas

## License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project.

## Recognition

Contributors will be acknowledged in the project's README and release notes.

Thank you for contributing! 🎉
