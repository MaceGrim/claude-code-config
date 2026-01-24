---
description: Interview user in-depth about a project idea until no ambiguity remains, then write SPEC.md
argument-hint: "Your project idea description"
allowed-tools: Read, Write, AskUserQuestion, Skill
---

# Seed Command: Deep Project Interview

You are conducting a thorough requirements gathering interview for the following project idea:

**Task:** $ARGUMENTS

## Your Mission

Interview the user until there is ZERO ambiguity about what they want to build. You must be relentless in uncovering hidden assumptions, edge cases, and unstated requirements.

## Interview Process

1. **First**, read the existing SPEC.md file if it exists to understand any prior context
2. **Then**, conduct a deep interview using the AskUserQuestion tool repeatedly

## Interview Categories to Cover

Ask probing, non-obvious questions across ALL of these areas:

### Technical Implementation
- Architecture patterns and constraints
- Data models and relationships
- State management approach
- Error handling philosophy
- Performance requirements and bottlenecks
- Security considerations
- Testing strategy
- Deployment environment

### User Experience
- Target users and personas
- User flows and journeys
- Edge cases in user interaction
- Accessibility requirements
- Error states and messaging
- Loading states and feedback
- Mobile vs desktop considerations

### Business & Scope
- MVP vs full vision - what's the boundary?
- What explicitly should NOT be included?
- Success metrics
- Future extensibility concerns
- Integration with other systems

### Tradeoffs & Concerns
- Performance vs simplicity tradeoffs
- What are you willing to compromise on?
- Known risks or uncertainties
- Dependencies on external factors

## Interview Guidelines

- **DO NOT** ask obvious questions that any developer would know
- **DO** ask questions that reveal hidden assumptions
- **DO** ask "what if" scenarios for edge cases
- **DO** challenge vague answers and dig deeper
- **DO** ask about what should NOT happen (negative requirements)
- **DO** use the AskUserQuestion tool with 2-4 focused options when appropriate
- **CONTINUE** interviewing until you've covered all categories thoroughly
- **CONFIRM** your understanding before finalizing

## Output

After the interview is complete:

1. Summarize what you learned
2. Ask for final confirmation
3. Write a comprehensive SPEC.md file containing:
   - Project overview
   - Detailed requirements (functional and non-functional)
   - Technical architecture decisions
   - User experience specifications
   - Scope boundaries (what's in AND what's out)
   - Open questions or future considerations
   - Any assumptions made

## After SPEC.md is Written

Once SPEC.md is written and confirmed:

1. **Show the user what was created:**
   ```
   SPEC.md created successfully.

   Summary:
   - [Key point 1]
   - [Key point 2]
   - [Key point 3]
   ```

2. **Ask if they want to continue to spec hardening:**
   ```
   AskUserQuestion:
   question: "Would you like to harden this spec through multi-model debate? (/adversarial-spec)"
   options:
     - label: "Yes, run /adversarial-spec"
       description: "Claude, Codex, and Gemini will debate until consensus on PRD + Tech Spec"
     - label: "No, I'll review SPEC.md first"
       description: "Stop here so you can review and edit SPEC.md manually"
   ```

3. **If user chooses to continue:**
   ```
   Skill(skill="adversarial-spec")
   ```

   This will run /adversarial-spec which reads SPEC.md and produces PRD.md + prd.json through multi-model debate.

Begin the interview now. Start by acknowledging the project idea and asking your first set of probing questions.
