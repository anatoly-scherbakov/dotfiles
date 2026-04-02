#!/usr/bin/env python3

import configparser
import json
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from base64 import b64encode
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional
import yaml


TODOIST_FILTER = "today"
TOGGL_API_BASE = "https://api.track.toggl.com/api/v9"
TODOIST_API_BASE = "https://api.todoist.com/api/v1"
TOGGL_CONFIG_PATH = Path.home() / ".togglrc"
TODOIST_CONFIG_PATHS = [
    Path.home() / ".config" / "todoist" / "config.json",
    Path.home() / ".todoist.config.json",
]
PROJECT_MAP_PATH = Path(__file__).resolve().with_name("todo_toggl_project_map.yaml")
STATE_PATH = Path.home() / ".cache" / "todo_toggl" / "current.json"
I3BLOCKS_SIGNAL = "12"
CREATED_WITH = "todo_toggl"


@dataclass
class TodoistTask:
    task_id: str
    priority: str
    due: str
    due_datetime: Optional[str]
    project: str
    project_id: str
    duration: str
    content: str
    toggl_project_id: Optional[int] = None

    @property
    def cleaned_content(self) -> str:
        return " ".join(self.content.split())

    @property
    def cleaned_project(self) -> str:
        return self.project or "#Inbox"

    def toggl_description(self) -> str:
        return f"{self.cleaned_content} [todoist:{self.task_id} {self.cleaned_project}]"

    def picker_label(self) -> str:
        due = self.due or "no-date"
        duration = f" {self.duration}" if self.duration else ""
        label = f"{self.priority} {due} {self.cleaned_project}{duration} :: {self.cleaned_content}"
        return truncate(label, 180)

    def sort_key(self):
        if self.due_datetime and "T" in self.due_datetime:
            return (0, self.due_datetime, self.cleaned_project.lower(), self.cleaned_content.lower())
        if self.due_datetime:
            return (1, self.due_datetime, self.cleaned_project.lower(), self.cleaned_content.lower())
        return (2, self.cleaned_project.lower(), self.cleaned_content.lower())


def truncate(value: str, limit: int) -> str:
    if len(value) <= limit:
        return value
    return value[: limit - 3] + "..."


def read_toggl_token() -> str:
    parser = configparser.ConfigParser()
    parser.read(TOGGL_CONFIG_PATH)
    token = parser.get("auth", "api_token", fallback="").strip()
    if not token:
        raise RuntimeError(f"Missing [auth].api_token in {TOGGL_CONFIG_PATH}")
    return token


def read_todoist_token() -> str:
    for path in TODOIST_CONFIG_PATHS:
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        token = (data.get("token") or "").strip()
        if token:
            return token
    raise RuntimeError("Missing Todoist token in known config paths")


def todoist_request(path: str, params: Optional[dict] = None):
    token = read_todoist_token()
    query = ""
    if params:
        query = "?" + urllib.parse.urlencode(params)
    url = urllib.parse.urljoin(TODOIST_API_BASE + "/", path.lstrip("/")) + query
    request = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {token}"},
        method="GET",
    )
    try:
        with urllib.request.urlopen(request) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        message = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Todoist API {exc.code}: {message}") from exc


def todoist_paginated(path: str, params: Optional[dict] = None) -> List[dict]:
    current = dict(params or {})
    results: List[dict] = []
    while True:
        payload = todoist_request(path, current)
        page_results = payload.get("results", [])
        results.extend(page_results)
        cursor = payload.get("next_cursor")
        if not cursor:
            return results
        current["cursor"] = cursor


def normalize_name(value: str) -> str:
    return " ".join(value.casefold().split())


def load_project_map() -> Dict[str, str]:
    if not PROJECT_MAP_PATH.exists():
        return {}
    raw = yaml.safe_load(PROJECT_MAP_PATH.read_text(encoding="utf-8")) or {}
    return {normalize_name(key): value for key, value in raw.items()}


def toggl_request(method: str, path: str, payload: Optional[dict] = None):
    token = read_toggl_token()
    url = urllib.parse.urljoin(TOGGL_API_BASE + "/", path.lstrip("/"))
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    auth = b64encode(f"{token}:api_token".encode("utf-8")).decode("ascii")
    headers["Authorization"] = f"Basic {auth}"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        message = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Toggl API {exc.code}: {message}") from exc
    if not body or body == "null":
        return None
    return json.loads(body)


def get_workspace_id() -> int:
    me = toggl_request("GET", "/me")
    workspace_id = me.get("default_workspace_id")
    if not workspace_id:
        raise RuntimeError("Unable to determine Toggl default workspace")
    return int(workspace_id)


def save_state(state: dict):
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(state), encoding="utf-8")


def load_state() -> Optional[dict]:
    if not STATE_PATH.exists():
        return None
    try:
        return json.loads(STATE_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None


def clear_state():
    if STATE_PATH.exists():
        STATE_PATH.unlink()


def stop_entry(state: Optional[dict]) -> bool:
    if not state:
        return False
    workspace_id = int(state["workspace_id"])
    entry_id = int(state["entry_id"])
    toggl_request(
        "PATCH",
        f"/workspaces/{workspace_id}/time_entries/{entry_id}/stop",
    )
    clear_state()
    notify_i3blocks()
    return True


def start_task(task: TodoistTask):
    state = load_state()
    if state:
        try:
            stop_entry(state)
        except RuntimeError:
            clear_state()
    workspace_id = get_workspace_id()
    now = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
    payload = {
        "created_with": CREATED_WITH,
        "description": task.toggl_description(),
        "duration": -1,
        "start": now,
        "stop": None,
        "workspace_id": workspace_id,
        "tags": ["todoist", f"todoist:{task.task_id}"],
    }
    if task.toggl_project_id:
        payload["project_id"] = task.toggl_project_id
    created = toggl_request("POST", f"/workspaces/{workspace_id}/time_entries", payload)
    save_state(
        {
            "entry_id": int(created["id"]),
            "workspace_id": workspace_id,
            "description": created.get("description") or task.toggl_description(),
            "start": created.get("start") or now,
        }
    )
    notify_i3blocks()


def format_duration(entry: dict) -> str:
    start = entry.get("start")
    if not start:
        return ""
    started_at = datetime.fromisoformat(start.replace("Z", "+00:00"))
    delta = datetime.now(timezone.utc) - started_at
    total_seconds = max(int(delta.total_seconds()), 0)
    hours, remainder = divmod(total_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    if hours:
        return f"{hours}:{minutes:02d}:{seconds:02d}"
    return f"{minutes}:{seconds:02d}"


def strip_todoist_suffix(description: str) -> str:
    marker = " [todoist:"
    if marker in description:
        return description.split(marker, 1)[0]
    return description


def print_current():
    state = load_state()
    if not state:
        return 0
    description = strip_todoist_suffix(state.get("description") or "Tracking")
    print(f"{truncate(description, 80)} [{format_duration(state)}]")
    return 0


def load_tasks() -> List[TodoistTask]:
    tasks_payload = todoist_paginated("/tasks/filter", {"query": TODOIST_FILTER})
    projects_payload = todoist_paginated("/projects")
    project_map = load_project_map()
    projects: Dict[str, dict] = {
        str(project.get("id")): project for project in projects_payload if project.get("id")
    }
    workspace_id = get_workspace_id()
    toggl_projects_payload = toggl_request("GET", f"/workspaces/{workspace_id}/projects") or []
    toggl_projects = {
        normalize_name(project["name"]): int(project["id"])
        for project in toggl_projects_payload
        if project.get("name")
    }
    tasks: List[TodoistTask] = []
    for payload in tasks_payload:
        due = payload.get("due") or {}
        project_id = str(payload.get("project_id") or "")
        project_name = resolve_todoist_project_name(project_id, projects)
        tasks.append(
            TodoistTask(
                task_id=str(payload["id"]).strip(),
                priority=f"p{payload.get('priority', 1)}",
                due=(due.get("string") or due.get("date") or "").strip(),
                due_datetime=(due.get("date") or "").strip() or None,
                project=project_name,
                project_id=project_id,
                duration="",
                content=(payload.get("content") or "").strip(),
                toggl_project_id=resolve_toggl_project_id(project_id, projects, toggl_projects, project_map),
            )
        )
    tasks.sort(key=lambda task: task.sort_key())
    return tasks


def resolve_todoist_project_name(project_id: str, projects: Dict[str, dict]) -> str:
    if not project_id or project_id not in projects:
        return "#Inbox"
    parts = []
    current_id = project_id
    while current_id and current_id in projects:
        project = projects[current_id]
        parts.append(project.get("name", current_id))
        current_id = str(project.get("parent_id") or "")
    return "#" + ":".join(reversed(parts))


def resolve_toggl_project_id(
    project_id: str,
    todoist_projects: Dict[str, dict],
    toggl_projects: Dict[str, int],
    project_map: Dict[str, str],
) -> Optional[int]:
    current_id = project_id
    while current_id and current_id in todoist_projects:
        project = todoist_projects[current_id]
        normalized = normalize_name(project.get("name", ""))
        mapped_name = project_map.get(normalized)
        if mapped_name:
            mapped_normalized = normalize_name(mapped_name)
            if mapped_normalized in toggl_projects:
                return toggl_projects[mapped_normalized]
        if normalized in toggl_projects:
            return toggl_projects[normalized]
        current_id = str(project.get("parent_id") or "")
    return None


def choose_task(tasks: List[TodoistTask]) -> Optional[TodoistTask]:
    if not tasks:
        return None
    menu_input = "\n".join(task.picker_label() for task in tasks) + "\n"
    command = [
        "rofi",
        "-dmenu",
        "-i",
        "-no-custom",
        "-format",
        "i",
        "-l",
        "20",
        "-p",
        "Todoist -> Toggl",
    ]
    result = subprocess.run(command, input=menu_input, text=True, capture_output=True)
    if result.returncode != 0:
        return None
    index = result.stdout.strip()
    if not index:
        return None
    selected = int(index)
    if selected < 0 or selected >= len(tasks):
        return None
    return tasks[selected]


def notify_i3blocks():
    subprocess.run(["pkill", f"-RTMIN+{I3BLOCKS_SIGNAL}", "i3blocks"], check=False)


def usage() -> int:
    print(f"Usage: {Path(sys.argv[0]).name} pick|stop|current", file=sys.stderr)
    return 2


def command_pick() -> int:
    tasks = load_tasks()
    task = choose_task(tasks)
    if task is None:
        return 0
    start_task(task)
    print(f"Started: {task.cleaned_content}")
    return 0


def command_stop() -> int:
    state = load_state()
    if not state:
        print("No timer running")
        return 0
    stopped = stop_entry(state)
    if stopped:
        print("Stopped current timer")
        return 0
    print("No timer running")
    return 0


def main() -> int:
    if len(sys.argv) != 2:
        return usage()
    command = sys.argv[1]
    try:
        if command == "pick":
            return command_pick()
        if command == "stop":
            return command_stop()
        if command == "current":
            return print_current()
    except FileNotFoundError as exc:
        print(f"Missing dependency: {exc.filename}", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr.strip() if exc.stderr else ""
        print(stderr or str(exc), file=sys.stderr)
        return exc.returncode or 1
    except Exception as exc:  # pragma: no cover - defensive path for CLI usage
        print(str(exc), file=sys.stderr)
        return 1
    return usage()


if __name__ == "__main__":
    sys.exit(main())
