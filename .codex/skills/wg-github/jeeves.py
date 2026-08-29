"""Report JSON-LD Working Group pull requests needing attention."""

from __future__ import annotations

import json
import subprocess
from concurrent.futures import ThreadPoolExecutor
from typing import Any


ORGANIZATIONS = ("w3c", "json-ld")
YAML_LD_REPOSITORY = "w3c/yaml-ld"


def _github(*arguments: str) -> Any:
    """Run gh and decode its JSON output."""
    result = subprocess.run(
        ("gh", *arguments),
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def _repositories(organization: str) -> dict[str, str]:
    """Return covered non-fork repositories and their default branches."""
    pages = _github(
        "api",
        "--paginate",
        "--slurp",
        f"orgs/{organization}/repos?per_page=100&type=all",
    )
    repositories = (
        repository
        for page in pages
        for repository in page
        if not repository["fork"]
        and (
            repository["full_name"] == YAML_LD_REPOSITORY
            or repository["name"].startswith("json-ld")
        )
    )
    return {
        repository["full_name"]: repository["default_branch"]
        for repository in repositories
    }


def _pull_requests(repository: str) -> list[dict[str, Any]]:
    """Return the open pull requests for one covered repository."""
    pull_requests = _github(
        "pr",
        "list",
        "--repo",
        repository,
        "--state",
        "open",
        "--limit",
        "100",
        "--json",
        "url,number,title,updatedAt,baseRefName,isDraft,reviewDecision,author,reviews",
    )
    for pull_request in pull_requests:
        pull_request["repository"] = repository
        pull_request["approvals"] = sum(
            review["state"] == "APPROVED"
            for review in pull_request["reviews"]
        )
    return pull_requests


def _change_request_status(pull_request: dict[str, Any]) -> str:
    """Classify whether a change-request decision still has active threads."""
    owner, _, name = pull_request["repository"].partition("/")
    result = _github(
        "api",
        "graphql",
        "-F",
        "owner=" + owner,
        "-F",
        "name=" + name,
        "-F",
        "number=" + str(pull_request["number"]),
        "-f",
        "query="
        "query($owner: String!, $name: String!, $number: Int!) { "
        "repository(owner: $owner, name: $name) { "
        "pullRequest(number: $number) { "
        "reviewThreads(first: 100) { totalCount nodes { isResolved isOutdated } } "
        "} } }",
    )
    threads = result["data"]["repository"]["pullRequest"]["reviewThreads"]
    nodes = threads["nodes"]
    if (
        nodes
        and threads["totalCount"] == len(nodes)
        and all(thread["isResolved"] or thread["isOutdated"] for thread in nodes)
    ):
        return "awaiting re-review"
    return "changes requested"


def _covered_repositories() -> dict[str, str]:
    """Return covered repositories and their configured default branches."""
    with ThreadPoolExecutor(max_workers=len(ORGANIZATIONS)) as executor:
        repository_groups = executor.map(_repositories, ORGANIZATIONS)
    repositories = {
        repository: default_branch
        for group in repository_groups
        for repository, default_branch in group.items()
    }
    return dict(sorted(repositories.items()))


def _all_pull_requests(repositories: list[str]) -> list[dict[str, Any]]:
    """Fetch each repository concurrently, then order by last update."""
    with ThreadPoolExecutor(max_workers=min(8, len(repositories))) as executor:
        pull_request_groups = executor.map(_pull_requests, repositories)
    pull_requests = [
        pull_request for group in pull_request_groups for pull_request in group
    ]
    changes_requested = [
        pull_request
        for pull_request in pull_requests
        if pull_request["reviewDecision"] == "CHANGES_REQUESTED"
    ]
    with ThreadPoolExecutor(max_workers=min(8, len(changes_requested) or 1)) as executor:
        statuses = executor.map(_change_request_status, changes_requested)
        for pull_request, status in zip(changes_requested, statuses, strict=True):
            pull_request["changeRequestStatus"] = status
    return sorted(
        pull_requests,
        key=lambda pull_request: pull_request["updatedAt"],
        reverse=True,
    )


def _requires_attention(pull_request: dict[str, Any]) -> bool:
    """Return whether a non-draft PR needs review or follow-up."""
    return (
        not pull_request["isDraft"]
        and (
            pull_request["approvals"] == 0
            or pull_request["reviewDecision"] == "CHANGES_REQUESTED"
        )
    )


def _status(pull_request: dict[str, Any]) -> str:
    if pull_request["reviewDecision"] == "CHANGES_REQUESTED":
        return pull_request["changeRequestStatus"]
    return "awaiting approval"


def _print_pull_requests(pull_requests: list[dict[str, Any]]) -> None:
    if not pull_requests:
        print("None")
        return

    for pull_request in pull_requests:
        print(
            f'{pull_request["updatedAt"]}  '
            f'{pull_request["repository"]}#{pull_request["number"]}  '
            f'[{_status(pull_request)}] {pull_request["title"]}'
        )
        print(f'  {pull_request["url"]}')


def report() -> None:
    """List JSON-LD WG pull requests that need review or follow-up."""
    username = _github("api", "user")["login"]
    repositories = _covered_repositories()
    pull_requests = _all_pull_requests(list(repositories))
    pull_requests = [
        pull_request
        for pull_request in pull_requests
        if pull_request["baseRefName"] == repositories[pull_request["repository"]]
    ]

    own_pull_requests = [
        pull_request
        for pull_request in pull_requests
        if pull_request["author"]["login"] == username
        and _requires_attention(pull_request)
    ]
    other_pull_requests = [
        pull_request
        for pull_request in pull_requests
        if pull_request["author"]["login"] != username
        and _requires_attention(pull_request)
    ]

    print(f"Your open PRs awaiting approval or changes ({username})\n")
    _print_pull_requests(own_pull_requests)
    print("\nOther open PRs targeting default branches that need review or follow-up\n")
    _print_pull_requests(other_pull_requests)
