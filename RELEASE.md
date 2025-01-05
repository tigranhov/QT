# AI Release Process Instructions

These are my (AI assistant) steps for creating a new release of the QT addon.

## Step 1: Analyze Current State

1. Read and analyze key files:
   - Check VERSION file for current version
   - Read CHANGELOG.md for recent changes
   - Review qt.toc for current metadata
   - Find last release tag to determine changes since then

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
   - Compare changes between last release tag and current state:
     - Read all commit messages since last tag
     - Review actual code changes in each commit
     - Look for patterns and themes in changes
     - Note any breaking changes or API modifications
     - Check for dependency updates
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

1. Verify create-release.ps1 will:
   - Exclude development files (.git, .gitignore, GUIDELINES.md, create-release.ps1)
   - Package all required files
   - Create QT.zip with correct structure

2. Release Tags:
   - Wait until after CHANGELOG.md is updated and committed
   - Tag format should be "v{X.Y.Z}" (e.g., v1.1.0)
   - Tag message should include version, date, and full changelog entry for this version
   - Ensure tag matches VERSION file exactly

Note: As an AI, I should always:
- Be explicit about version changes
- Provide clear reasoning for version number choices
- List all significant changes found in code analysis
- Alert user to any potential compatibility issues 