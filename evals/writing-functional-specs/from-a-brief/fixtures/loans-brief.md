# Tool library: loans — product brief (validated 2026-09-12)

The neighbourhood tool library lends tools to its members. This brief covers loans: borrowing a tool, returning it, extending a loan, and what happens when a tool comes back late. Membership sign-up and the tool catalogue are handled by the membership and catalogue teams; payments are not part of the library at all.

## Rules

- A loan lasts 7 days from the moment the member picks the tool up.
- A member holds at most 3 loans at a time.
- A member may extend a loan once, by 7 days, and only during the last 48 hours of the loan. A tool another member has reserved cannot be extended.
- A member with an overdue loan cannot borrow anything until every overdue tool is back.
- The day after a loan's due date, the member receives a reminder by email.
- A tool marked "damaged" on return is withdrawn from lending until a volunteer marks it repaired.

## Technical notes (from the dev team)

- Loans are stored in the `loans` Postgres table, one row per loan, with a `due_at` timestamp column.
- A nightly cron job at 02:00 scans the `loans` table and sends reminders through SendGrid.
- The `LoanService.extend()` method checks the 48-hour window; the mobile app calls `POST /api/loans/{id}/extend`.
- The 3-loan limit is enforced by a database trigger on insert.

## Acceptance examples

Given a member with 3 active loans
When they try to borrow a fourth tool
Then the loan is refused

Given a loan due in 30 hours
When the member asks to extend it
Then the due date moves 7 days later

Given a member with one overdue loan
When they try to borrow a tool
Then the loan is refused until the overdue tool is returned

## Glossary

- **Member**: a person registered with the library.
- **Loan**: a tool lent to a member, from pick-up to return.
- **Due date**: the end of a loan.
- **Extension**: pushing a loan's due date back.
