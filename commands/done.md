---
description: Mark a task complete in Todoist and remove from calendar
argument-hint: "Task name (e.g., 'dishes' or 'prettify columns')"
---

# Mark Task Complete

You are helping the user mark tasks as done in both Todoist and their calendar.

## Input

The user will provide a task name or description, like:
- "done with Prettify Columns"
- "finished the dishes"
- "completed Netflix application"

## Step 1: Find the Task in Todoist

Search for the task in Todoist using `find-tasks` with the search text.

### If exact match found:
- Note the task ID and details
- Proceed to Step 2

### If no exact match:
- Search more broadly or list today's tasks
- Present the closest matches to the user:
  > "I couldn't find an exact match for '[input]'. Did you mean one of these?"
  > 1. [Task A]
  > 2. [Task B]
  > 3. [Task C]
- Use AskUserQuestion or let them respond
- Once confirmed, proceed to Step 2

## Step 2: Find the Calendar Event

Search for a matching event on the personal calendar (mbgrimshaw@gmail.com, account: "personal") for today.

Use `list-events` or `search-events` to find events with similar names.

### Matching logic:
1. **Exact match**: Event summary matches task name exactly
2. **Partial match**: Event summary contains key words from task name
3. **Fuzzy match**: Similar words (e.g., "Dishes" matches "dishes", "Do the dishes")

### If exact match found:
- Note the event ID
- Proceed to Step 3

### If no exact match but similar events exist:
- Present options to user:
  > "I found these calendar events that might match:"
  > 1. [Event A] at [time]
  > 2. [Event B] at [time]
  > 3. None of these
- Once confirmed, proceed to Step 3

### If no calendar event found:
- That's OK - the task might not have been scheduled
- Inform user: "No calendar event found for this task (that's fine, completing in Todoist only)"
- Proceed to Step 3

## Step 3: Complete the Task

1. **Mark complete in Todoist** using `complete-tasks` with the task ID
2. **Delete calendar event** (if found) using `delete-event` on the personal calendar

## Step 4: Confirm

Report back:
> "Done! Completed '[task name]' in Todoist [and removed from calendar / no calendar event found]."

## Examples

### User says: "done prettify"
- Search Todoist for "prettify"
- Find "Prettify Columns" → match!
- Search calendar for "Prettify"
- Find "Prettify Columns" at 1:00 PM → match!
- Complete in Todoist, delete from calendar
- Report: "Done! Completed 'Prettify Columns' in Todoist and removed from calendar."

### User says: "finished laundry"
- Search Todoist for "laundry"
- Find "Laundry load" → match!
- Search calendar for "laundry"
- Find "Laundry load" at 3:40 PM → match!
- Complete in Todoist, delete from calendar

### User says: "done with the thing for europe"
- Search Todoist for "europe"
- Find "Nudge Europe for Documentation" → likely match
- Confirm with user if unsure
- Complete and remove from calendar

## Calendar Details

- Personal calendar: mbgrimshaw@gmail.com (account: "personal")
- Work calendar: mason@ode.partners (account: "normal") - typically don't delete from here, but can search
- Focus on today's events, but can expand to nearby days if needed

## Handling Multiple Matches

If multiple Todoist tasks match:
> "I found multiple tasks matching '[input]':"
> 1. [Task A] - [Project/Section]
> 2. [Task B] - [Project/Section]
> "Which one did you complete?"

Always confirm before completing if there's any ambiguity.
