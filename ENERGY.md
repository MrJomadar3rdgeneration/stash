# Stash 0.2.0 — energy observations

Measured on this Mac on 2026-09-18. This is a short process-resource observation, not a battery-life benchmark.

## Measured

After closing the history window, with three small clips in history, `top -l 7 -s 5` observed the installed Stash process for approximately 31 seconds:

- All six post-baseline samples displayed **0.0% CPU** at the tool's displayed precision.
- Memory remained approximately **35 MB** (`top` MEM).
- Cumulative CPU time advanced from **3.58 to 3.60 seconds** during the observation.
- The process stayed running after the history window closed.

These values are specific to this small idle history. They do not imply literally zero power use, predict a large history's memory use, or measure the cost of continuous copying. System-wide CPU and disk counters are not Stash-only measurements and were not attributed to Stash.

## Changes to reduce work

- Normal clipboard check every 0.5 seconds; 1 second in Low Power Mode.
- Timer tolerance of 20% lets macOS coalesce wake-ups.
- Invalidate the polling timer when manually paused, during system/display sleep, or while the login session is inactive.
- Restart after wake/session activation, skipping changes made during suspension.
- No sleep-prevention assertion, network client, analytics, indexing service, or update daemon.
- Replace continuously ticking age labels with relative labels refreshed on normal UI updates/reopening.
- Avoid UI refreshes when periodic retention cleanup has no changes.
- Avoid folding every clip's text when the search query is empty.

## What battery drain should I expect?

The idle sample suggests a small background CPU cost, but there is no defensible battery-per-hour percentage from this measurement. Battery cost depends on copy frequency, image size, history size, the Mac, screen use, background apps, and macOS scheduling. Frequent large image copies cost more than occasional short text.

To estimate a real battery-life difference, compare matched unplugged sessions with Stash running versus fully quit, under the same workload and screen brightness, and repeat long enough to reduce noise. Activity Monitor's Energy pane can help observe relative impact. Pause stops polling; Quit stops the whole app. Neither operation deletes history.

## Other costs and limits

- History is held decoded in RAM; large image histories can consume substantially more memory than this 35 MB observation.
- The default unpinned history has a 250 MB payload budget, but encrypted JSON/base64 overhead means disk usage can be higher. Pinned clips are exempt.
- A copy larger than 20 MB is skipped. Moved/deleted file references may stop working.
- Clipboard contents can include secrets; exclusions and concealed markers reduce but do not eliminate that risk.
- Capture is suspended when the display sleeps; background clipboard changes in that period are deliberately not captured. No monitoring occurs before login.
- Polling can miss rapid overwrites or be delayed by App Nap.

Apple references: [Timer tolerance](https://developer.apple.com/documentation/foundation/timer/tolerance) and [App Nap](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/AppNap.html).
