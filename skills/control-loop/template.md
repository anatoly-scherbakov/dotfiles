---
"@context":
  - urn:control-loop:context
  - "@base": <the loop file's URL on the default branch>

$id: "#loop"
$type: ControlLoop
name: <loop name>
system: <what the loop controls>

goal:
  $type: Goal
  text: <the condition the supervisor wants reached once>

set-point:
  $type: SetPoint
  text: <what the loop holds true on every tick>
  clauses:
    - $id: "#set-point-<clause>"
      $type: SetPoint
      name: <short name>
      text: <one condition, in prose>

clock:
  $type: Clock
  mechanism: <what fires each tick>
  sample-period: PT45M
  window: <optional: the days and UTC hours the clock ticks in, such as Mon-Fri 05:00-16:00 UTC>
  lifetime: <what keeps the clock alive, and what stops it>

sensors:
  - $id: "#sensor-<name>"
    $type: Sensor
    reads: <what it reads>

noise:
  - $type: MeasurementNoise
    text: <how the sensor can report a state that is not the real one>
    mitigation: <how the loop corrects for it>

checks:
  - $type: Check
    covers: ["#set-point-<clause>"]
    verdict: Verified
    command: <the command or query that decides it>

controllers:
  - $type: Controller
    role: <how it picks the next action>

actuators:
  - $id: "#actuator-<name>"
    $type: Actuator
    output: <what it produces>
    gate: <what stands between the output and the system>
    on-gap: Act

flow-control:
  - $type: WorkInProgressLimit
    limit: <what is bounded, and the bound>

state: loop-state.md

memory:
  - <where the loop keeps what it learned between ticks>

supervisor:
  $type: Supervisor
  who: <person or team>
  channel: <how they see the loop and steer it>

disturbances:
  - $type: Disturbance
    text: <a change from outside the loop>

termination:
  $type: Termination
  met-when: <when the goal counts as reached>
  inferred-only: <what happens to a clause that only inferred checks cover>
---

# <loop name>

<What the loop is for, in two or three sentences.>

## Coverage

- <Each clause with no verified check, and each missing part.>
