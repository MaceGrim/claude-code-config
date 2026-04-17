# Rundown - Comprehensive Repository Analysis

Generate a thorough analysis of the current repository for someone with fresh eyes.

## Arguments

**$ARGUMENTS** - Optional focus area (e.g., "Focus on the authentication system" or "Focus on the API layer"). If empty, provide equal coverage across all areas.

## Instructions

You are analyzing a codebase for someone who has never seen it before. Your goal is to provide a comprehensive understanding of what this repository does, how it's organized, and where the important functionality lives.

### Phase 1: Exploration

Launch multiple Explore agents in parallel to investigate different aspects of the codebase. Use "very thorough" for each agent. The agents should cover:

1. **Project Overview Agent** - Understand the high-level purpose
   - Read README, package.json/pyproject.toml/Cargo.toml, and any documentation
   - Identify the tech stack (languages, frameworks, major dependencies)
   - Determine if this is a monorepo, library, application, CLI tool, etc.

2. **Architecture Agent** - Map the structure
   - Identify major directories and their purposes
   - Find entry points (main files, index files, API routes)
   - Trace how different parts connect to each other
   - Identify the data flow through the system

3. **Core Functionality Agent** - Find the important code
   - Locate the "meat" of the application - where the real work happens
   - Identify key algorithms, business logic, or processing pipelines
   - Find configuration files and understand what's configurable

4. **External Interfaces Agent** - Map boundaries
   - Find API endpoints, CLI commands, or UI entry points
   - Identify external service integrations (databases, APIs, cloud services)
   - Locate authentication/authorization logic if present

5. **Development & Operations Agent** - Understand the workflow
   - Find test files and understand testing approach
   - Identify CI/CD configuration
   - Locate build scripts, Dockerfiles, deployment configs
   - Find environment variable requirements

If **$ARGUMENTS** contains a focus area, add a 6th agent specifically to deep-dive on that topic.

### Phase 2: Synthesis

After all agents complete, synthesize their findings into a structured report with these sections:

---

## Output Format

Present the report directly in the terminal using this structure:

```
## What This Repo Does

[2-4 sentences explaining the purpose and value of this project. What problem does it solve? Who is it for?]

## Tech Stack

- **Language(s):** [e.g., Python 3.11, TypeScript]
- **Framework(s):** [e.g., FastAPI, Next.js]
- **Database:** [if applicable]
- **Key Dependencies:** [list the 3-5 most important ones with brief explanations]

## Project Structure

[Describe the top-level organization. For monorepos, explain each package/service. Use a tree-like format for clarity:]

```
repo/
├── src/           # [purpose]
│   ├── api/       # [purpose]
│   └── core/      # [purpose]
├── tests/         # [purpose]
└── config/        # [purpose]
```

## Key Files & Entry Points

| File | Purpose |
|------|---------|
| `path/to/file` | [what it does and why it matters] |
| ... | ... |

[List 10-20 of the most important files. These are files someone MUST understand to work on this codebase.]

## Core Functionality

### [Feature/System 1]
[Explain what it does, where the code lives, and how it works at a high level]

### [Feature/System 2]
[Continue for each major piece of functionality]

## Data Flow

[Explain how data moves through the system. For a web app: request → handler → service → database → response. For a CLI: input → parser → processor → output. Use arrows and file references.]

## External Interfaces

### APIs / Endpoints
[List key endpoints or CLI commands with brief descriptions]

### Integrations
[List external services, databases, or APIs this connects to]

## Configuration & Environment

[List required environment variables, config files, and their purposes]

## Development Workflow

- **How to run:** [command to start the application]
- **How to test:** [command to run tests]
- **How to build:** [command to build/compile if applicable]

## Architecture Decisions & Patterns

[Note any notable patterns, conventions, or architectural decisions. Examples: "Uses repository pattern for data access", "Event-driven architecture with message queues", "Follows hexagonal architecture"]

---

[If $ARGUMENTS specified a focus area, add a dedicated section:]

## Deep Dive: [Focus Area]

[Provide detailed analysis of the requested focus area, including specific files, functions, and how they interconnect]

```

### Guidelines

- **Be specific** - Reference actual file paths and function names
- **Explain the "why"** - Don't just list things, explain their purpose
- **Prioritize** - In each section, put the most important items first
- **Use examples** - When explaining data flow or functionality, use concrete examples
- **Stay factual** - Only report what you find; don't speculate about intent unless it's documented
- **Fresh eyes** - Write as if the reader has zero context about this project
