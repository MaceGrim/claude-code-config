---
description: Plan your day - fetch todos, check calendars, prioritize, and schedule
---

# Day Preparation Assistant

You are helping the user plan their day. Follow these steps:

## Step 1: Gather Context

1. **Get current time** using the Google Calendar MCP tool
2. **Fetch today's calendar events** from BOTH accounts:
   - Work calendar (mason@ode.partners) - account: "normal"
   - Personal calendar (mbgrimshaw@gmail.com) - account: "personal"
3. **Fetch today's Todoist tasks** including overdue items

## Step 2: Ask for New Todos

Ask the user:
> "Do you have any new todos to add for today? If so, list them with the project/section they belong to. Otherwise, say 'none'."

If they provide new todos, add them to Todoist in the appropriate projects/sections.

## Step 3: Review & Prioritize

Present the user with:
1. **Fixed calendar events** (meetings, appointments they must attend)
2. **All todos for today** organized by project, with time estimates if available

Then ask:
> "Which tasks are HIGH priority (must do today)? Which are MEDIUM (should do if time allows)? Which are LOW (can push to tomorrow)?"

Use the AskUserQuestion tool with options for each task or let them respond in text.

## Step 4: Get Time Estimates

For any tasks without duration estimates, ask the user:
> "These tasks need time estimates: [list]. Please provide estimates like '1: 30m, 2: 1h, ...'"

Update the tasks in Todoist with the durations.

## Step 5: Generate Schedule

Create a schedule following these **constraints**:

### Hard Constraints
- **Respect all calendar events** - don't double-book
- **Family dinner: 5:00 PM - 6:30 PM** - block this time, no work tasks
- **Work cutoff: 5:00 PM** - no work tasks (Ode, Consulting, IndigiGenius) after this
- **Housework exception**: Personal/House tasks CAN be scheduled after 6:30 PM

### Soft Constraints
- **Lunch break**: Try to keep 12:00 PM - 12:30 PM or 12:30 PM - 1:00 PM free (flexible based on meetings)
- **High priority first**: Schedule high-priority tasks in the morning when possible
- **Buffer time**: Leave 5-10 min gaps between focus tasks when possible
- **Batch similar work**: Group tasks from the same project together when it makes sense

### Task Scheduling Order
1. HIGH priority tasks - fit these first
2. MEDIUM priority tasks - fill remaining gaps
3. LOW priority tasks - only if time remains, otherwise suggest moving to tomorrow

## Step 6: Present & Confirm

Show the proposed schedule in a clear table format:

| Time | Task | Project | Duration |
|------|------|---------|----------|
| ... | ... | ... | ... |

Include:
- Existing calendar events (marked as fixed)
- Lunch break
- Family dinner block
- End-of-day summary

If any LOW priority tasks don't fit, list them separately:
> "These tasks may need to move to tomorrow: [list]"

Ask: "Does this schedule work? Any adjustments needed?"

## Step 7: Create Calendar Events

Once approved:
1. Create all task events on the **personal calendar** (mbgrimshaw@gmail.com, account: "personal")
2. Confirm creation with a final summary

## Project Structure Reference

The user's Todoist is organized as:
```
├── Ode (work)
│   ├── BuildEngine
│   ├── Ocean Central
│   ├── TD
│   ├── TRACE
│   └── Misc
├── Consulting (work)
│   ├── SCC
│   └── eFinery
├── IndigiGenius (work)
│   ├── LAICC
│   ├── Ocelot
│   └── Governance
├── Personal
│   ├── Health
│   ├── House
│   └── Admin
```

Work categories: Ode, Consulting, IndigiGenius
Personal categories: Personal (Health, House, Admin)
