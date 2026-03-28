# Commit Guidelines

Best practices for making commits in this repository.

## Guidelines

- Make focused commits: Each commit should address a single concern or feature
- Commit at the file level: Group related changes together rather than committing everything at once
- Write descriptive commit messages that explain the "why" behind the changes
- Keep commits small and reviewable (aim for less than 300 lines changed per commit)
- Use the imperative mood in commit messages (e.g., "Add user authentication" not "Added user authentication")
- Separate the subject from the body with a blank line when providing detailed explanations
- Reference issue numbers when applicable (e.g., "Fix bug in workout timer #123")
- Verify your changes before committing by reviewing the diff
- Commit frequently during development to create checkpoints, then squash/rebase before pushing to main
- Include tests alongside code changes in the same commit when possible