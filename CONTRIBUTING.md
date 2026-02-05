# Contributing to swiftcn

Thank you for your interest in contributing to swiftcn!

## Before You Start

1. Check [existing issues](https://github.com/Dicky019/swiftcn/issues) to avoid duplicates
2. For new features, open a discussion first to align with project scope
3. Review the [Code of Conduct](CODE_OF_CONDUCT.md)

## How to Contribute

### 1. Fork and Clone

```bash
git clone https://github.com/Dicky019/swiftcn.git
cd swiftcn
```

### 2. Create a Branch

```bash
git checkout -b your-username/feature-name
```

### 3. Make Changes

- Follow existing code style and patterns
- Components use the `CN` prefix
- Include tests for new functionality
- Run tests before committing: `swift test`

### 4. Commit

Use clear commit messages:

```bash
git commit -m "feat(component): add CNToast component"
git commit -m "fix(button): correct disabled state opacity"
git commit -m "docs: update README with new examples"
```

### 5. Push and Create PR

```bash
git push origin your-username/feature-name
```

Open a pull request against the `main` branch.

## Component Guidelines

New components should:

1. **Be self-contained** - No external dependencies beyond SwiftUI
2. **Use the CN prefix** - e.g., `CNToast`, `CNAlert`
3. **Include variants** - Use enums for size/variant options
4. **Support theming** - Use `@Environment(\.theme)` for colors
5. **Include previews** - Add `#Preview` for all variants

## Questions?

Open an issue or start a discussion. We're happy to help!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
