# Contributing to GAS Project

Thank you for your interest in contributing to the GAS (GitHub Actions Staging) project! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome diverse perspectives
- Focus on constructive feedback
- Help others learn and grow

## Getting Started

### Prerequisites

- Node.js 18 or higher
- npm 9 or higher
- Docker and Docker Compose
- Git
- Azure CLI (for Azure deployments)

### Local Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd gas-project

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Start development server
npm run dev

# In another terminal, start monitoring stack
docker-compose up -d
```

### Verify Setup

```bash
# Run tests
npm test

# Run linting
npm run lint

# Check health endpoint
curl http://localhost:3000/health
```

## Development Workflow

### 1. Create a Feature Branch

```bash
# Create branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description

# Or for hotfixes
git checkout -b hotfix/critical-issue
```

### 2. Make Changes

```bash
# Edit files
# Test locally
npm test
npm run lint

# Commit with meaningful message
git add .
git commit -m "feat: Add new feature description"
```

### Commit Message Format

Follow conventional commits:

```
feat: Add new feature
fix: Fix bug
docs: Update documentation
style: Format code
refactor: Refactor code
test: Add tests
chore: Update dependencies
```

### 3. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create pull request on GitHub
# - Describe what you changed
# - Link related issues
# - Request reviewers
```

### 4. Code Review

- Address feedback from reviewers
- Update your branch with latest changes
- Re-request review when ready

### 5. Merge

Once approved:

```bash
# Merge to develop (for features)
# Merge to main (for releases)
# Delete feature branch
```

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test tests/unit/health.test.js

# Run with coverage
npm run test:coverage

# Run unit tests only
npm run test:unit

# Run integration tests only
npm run test:integration
```

### Writing Tests

Tests should be:
- **Clear** - Easy to understand what's being tested
- **Isolated** - Don't depend on other tests
- **Fast** - Run quickly
- **Comprehensive** - Cover happy path and error cases

## Code Style

### Linting

```bash
# Check code style
npm run lint

# Auto-fix style issues
npm run lint:fix
```

### Style Guide

- Follow Airbnb JavaScript style guide
- Use 2-space indentation
- Use semicolons
- Use single quotes for strings
- Use const/let (not var)

## Documentation

### Update Documentation When

- Adding new features
- Changing API endpoints
- Modifying configuration
- Updating deployment procedures

### Documentation Files

- **README.md** - Project overview
- **docs/system-overview.md** - Architecture and components
- **docs/ci-cd-architecture.md** - CI/CD pipelines
- **docs/blue-green-guide.md** - Blue-green deployment
- **docs/canary-guide.md** - Canary deployment
- **docs/rollback-guide.md** - Rollback procedures
- **docs/observability-guide.md** - Monitoring and logging

## Deployment

### Staging Deployment

```bash
# Push to develop branch
git push origin develop

# GitHub Actions automatically deploys to staging
```

### Production Deployment

```bash
# Create pull request to main
# Get code review
# Merge to main

# GitHub Actions automatically deploys to production
```

## Reporting Issues

### Bug Reports

Include:
- Description of the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment (OS, Node version, etc.)

### Feature Requests

Include:
- Description of the feature
- Why it's needed
- How it should work

## Security

### Security Issues

**Do not** open a public issue for security vulnerabilities.

Instead:
1. Email security details to maintainers
2. Include steps to reproduce
3. Allow time for fix before disclosure

### Security Best Practices

- Never commit secrets or credentials
- Use environment variables for sensitive data
- Keep dependencies updated
- Run security scans: `npm audit`

## Getting Help

### Resources

- **Documentation** - See `docs/` directory
- **Issues** - Search existing issues
- **Discussions** - Ask questions in discussions

### Common Issues

**Tests failing locally?**
```bash
npm install
npm test
```

**Linting errors?**
```bash
npm run lint:fix
```

**Docker issues?**
```bash
docker-compose down
docker-compose up -d
```

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Acknowledgments

Thank you for contributing to make this project better!

---

**Last Updated:** 2025-11-20
**Version:** 1.0.0
