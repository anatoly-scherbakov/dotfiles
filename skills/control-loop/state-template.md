---
"@context":
  - https://control-loop.md/context
  - "@base": <the loop file's URL on the default branch>

$id: "#state"
$type: State
loop: "#loop"

observations:
  - $type: Observation
    sensor: "#sensor-<name>"
    time: 2026-01-01T00:00:00Z
    result: <the latest value the sensor saw, or its finding>
    owner: <task id while an agent sensor runs; omit otherwise>

gaps:
  - $type: Gap
    text: <the gap, in one sentence>
    breaks: ["#set-point-<clause>"]
    actuation:
      $type: Actuation
      actuator: "#actuator-<name>"
      on-gap: Act
      owner: <agent task id or pull request URL; empty while a person decides>
      time: 2026-01-01T00:00:00Z
      status: <running, waiting for review, proposed, done>

reported:
  - <time> <one line the supervisor was told>
---

# Loop state

Written by the `control-loop` skill's `start` mode every cycle. Not committed.
