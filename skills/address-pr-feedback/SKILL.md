---
name: address-pr-feedback
description: Investigate and address GitHub pull request feedback from a local checkout, including top-level review comments, inline review comments, CI feedback when relevant, pushing fixes, and resolving fixed inline review threads.
---

# Address PR Feedback

Use this skill when the user asks to look into, fix, address, or respond to feedback on an existing GitHub pull request.

## Workflow

1. Resolve the PR and branch.
   - Run `git status --short --branch`.
   - Use the current branch's PR when the user does not provide a PR number: `gh pr view --json number,url,headRefName,baseRefName,state`.
   - Do not proceed from the default branch unless the user explicitly asks.
   - If the worktree has unrelated changes, pause and ask how to handle them.

2. Fetch all feedback, including inline comments.
   - Fetch top-level PR details with `gh pr view --json number,url,title,state,reviewDecision,comments,reviews,latestReviews`.
   - Always fetch inline review comments separately; `gh pr view` is not enough:
     `gh api repos/{owner}/{repo}/pulls/{number}/comments`.
   - For thread resolution, fetch review thread IDs with GraphQL:

     ```graphql
     query($owner: String!, $repo: String!, $number: Int!) {
       repository(owner: $owner, name: $repo) {
         pullRequest(number: $number) {
           reviewThreads(first: 100) {
             nodes {
               id
               isResolved
               isOutdated
               path
               line
               comments(first: 20) {
                 nodes {
                   id
                   body
                   author { login }
                   url
                 }
               }
             }
           }
         }
       }
     }
     ```

   - Ignore bot noise such as coverage comments unless it reports an actionable failure.
   - Include unresolved inline threads, top-level review comments, and failing checks in the working feedback list.

3. Plan and implement narrowly.
   - Map each actionable comment to the affected file, symbol, or behavior.
   - Read the current code around each inline comment; comments may move after new commits.
   - Fix comments with the smallest coherent change that matches project conventions.
   - If a comment is ambiguous or should not be accepted, leave it unresolved and summarize the reason.

4. Validate.
   - Run the most specific local checks that cover the changes.
   - If `gh pr checks --json conclusion` is unsupported, use supported fields such as `bucket`, `state`, `link`, timestamps, and `workflow`.
   - For CI failures, inspect failing run details before changing code.

5. Commit and push when updating the PR.
   - If the user asked to fix PR feedback, commit the fixes using the commit workflow conventions for the repository.
   - Prefer one file per commit when the repository guidance or commit skill says so.
   - Push the PR branch after committing.

6. Resolve fixed inline review threads.
   - Only resolve a thread after the fix is committed and pushed, or after confirming no code change is needed and explaining why.
   - Resolve review threads with GraphQL:

     ```graphql
     mutation($threadId: ID!) {
       resolveReviewThread(input: {threadId: $threadId}) {
         thread { id isResolved }
       }
     }
     ```

   - Resolve only the threads addressed by the changes. Do not resolve unrelated, ambiguous, outdated-but-unfixed, or still-disputed threads.
   - If resolution fails because the comment ID is not a thread ID, refetch `reviewThreads` and match by comment URL, path, line, or comment body.

7. Re-check and report.
   - Re-fetch inline review threads and PR review state.
   - Re-check PR checks; if they are still pending, report the pending checks rather than waiting indefinitely.
   - Summarize fixed feedback, resolved thread count, commits pushed, validation commands, PR URL, and any remaining unresolved comments or risks.

## GitHub CLI Notes

- Use elevated network access for `gh` and `git push` commands when required by the sandbox.
- Prefer `gh api graphql` for review thread resolution; REST pull review comments are not sufficient to resolve threads.
- Do not mark a thread resolved just because it is inconvenient; resolution means the feedback has been addressed or explicitly answered.

## Output Expectations

- For investigation-only requests, list actionable comments and a proposed fix plan.
- For fix requests, implement the fixes, validate locally, push, resolve addressed inline threads, and report final PR/check status.
