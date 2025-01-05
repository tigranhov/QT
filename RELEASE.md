# AI Release Process Instructions

These are my (AI assistant) steps for creating a new release of the QT addon.

## Step 1: Analyze Current State

1. Read and analyze key files:
   - Check VERSION file for current version
   - Read CHANGELOG.md for recent changes
   - Review qt.toc for current metadata
   - Find latest release tag using `git describe --tags --abbrev=0`

2. Version determination:
   - Based on changes since last release, determine if this should be:
     - MAJOR: Breaking changes
     - MINOR: New features
     - PATCH: Bug fixes
   - Follow semantic versioning (X.Y.Z)

## Step 2: Update Files

1. Update version numbers:
   - Modify VERSION file with new version
   - Update version in qt.toc
   
2. Update CHANGELOG.md:
   - Compare changes between latest release tag and current branch:
     - Get latest release tag: `git describe --tags --abbrev=0`
     - View all commits: `git log <latest_tag>..HEAD --pretty=format:"%h - %s (%an)"` 
     - Review code changes: `git diff <latest_tag>..HEAD`
     - Analyze commit messages for themes and patterns
     - Check modified files: `git diff --name-status <latest_tag>..HEAD`
     - Review pull requests merged since last release
     - Identify breaking changes through code analysis
     - Note dependency updates from commit history
   - Add new version section at top
   - Write comprehensive changelog entries based on analysis:
     - Added: New features with clear descriptions of functionality
     - Changed: Updates to existing features, including rationale
     - Fixed: Bug fixes with root cause and solution
     - Breaking: Any backwards-incompatible changes
     - Dependencies: Third-party library updates
   - Include today's date
   - Write clear, user-focused descriptions that explain the impact
   - Have another developer review the changelog
   - Commit changelog update with descriptive message

## Step 3: Verification

1. Code analysis:
   - Search codebase for any TODOs or unfinished features
   - Verify all imports and dependencies are properly listed
   - Check for any debug code that should be removed

2. Documentation check:
   - Ensure README.md matches current features
   - Verify all command documentation is current
   - Check that all new features are documented

## Step 4: Release Creation

1. Create release package:
   - Open PowerShell in the addon directory
   - Run `.\create-release.ps1` to generate QT.zip
   - Verify QT.zip was created successfully
   - Check contents of QT.zip to ensure all required files are included
   - Verify excluded files are not in the package (.git, .gitignore, GUIDELINES.md, create-release.ps1)

2. Release Tags:
   - Wait until after CHANGELOG.md is updated and committed
   - Tag format should be "v{X.Y.Z}" (e.g., v1.1.0)
   - Create tag: `git tag -a v{X.Y.Z} -m "Version {X.Y.Z} - <changelog entry>"`
   - Push the new tag: `git push origin v{X.Y.Z}`
   - Push all tags: `git push --tags`
   - Verify tags are visible in the repository

Note: As an AI, I should always:
- Be explicit about version changes
- Provide clear reasoning for version number choices
- List all significant changes found in code analysis
- Alert user to any potential compatibility issues 