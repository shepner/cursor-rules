# Cursor Rules Repository

This repository contains my personal collection of Cursor rules for use across different projects.

## Structure

- All rules are stored in the `rules/` directory and use the `.mdc` extension.
- Rule files are named and grouped by category prefix:
  - `code-*`: General coding standards, organization, documentation, performance, testing, etc.
  - `security-*`: Security standards, privacy, hardening, deception, data handling, etc.
  - `git-*`: Git workflow, best practices, repository sync, etc.
  - `docker-*`: Docker logging, optimization, etc.
  - `cursor-*`: Cursor IDE configuration and models.
  - `cursor-rule-*`: Rules about writing, organizing, and validating Cursor rules.
- Example rule files:
  - `code-organization.mdc`
  - `security-data-privacy.mdc`
  - `git-best-practices.mdc`
  - `docker-logging.mdc`
  - `cursor-models.mdc`
  - `cursor-rule-naming-standards.mdc`
- See each `.mdc` file for detailed documentation and configuration.

## Usage

1. Clone this repository
2. Set environment variables:
   ```bash
   export CURSOR_RULES_REPO="your-username/cursor-rules"
   export CURSOR_RULES_BRANCH="main"
   ```

## Best Practices for Writing Cursor Rules

From https://docs.cursor.com/context/rules


Example MDC rule:

```
---
description: RPC Service boilerplate
globs: 
alwaysApply: false
---

- Use our internal RPC pattern when defining services
- Always use snake_case for service names.

@service-template.ts
```

Good rules are focused, actionable, and scoped. Follow these principles to ensure your rules are effective and maintainable:

- **Keep rules concise.** Aim for under 500 lines per rule.
- **Split large concepts into multiple, composable rules.** This makes each rule easier to understand and reuse.
- **Provide concrete examples or reference files when helpful.** Use `@filename` to include templates or illustrative code.
- **Avoid vague guidance.** Write rules as you would write a clear internal document—be specific and direct.
- **Reuse rules when you find yourself repeating prompts in chat.** Modular, reusable rules save time and ensure consistency.

## License

Copyright (c) 2024. All rights reserved. 