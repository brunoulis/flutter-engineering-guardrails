# Performance: Flutter Web, desktop and reactive UI

Goal: **optimize where a problem exists**, not turn every widget into a micro-optimization. Official guide: https://docs.flutter.dev/perf/best-practices.

## Mandatory method for improvement claims

1. **Reproduce:** use case, device/browser and data profile, appropriate version/release mode.
2. **Measure a baseline:** Flutter DevTools Performance/Memory, frame time, CPU timeline, rebuilds, requests, memory snapshots; pick the metric that measures the problem.
3. **Form a hypothesis:** for example, an eager list builds thousands of elements, or `notifyListeners` triggers unnecessary work.
4. **Change the minimum:** one rebuild region, a memo/cache with invalidation, one query, one list builder.
5. **Compare A/B:** same machine, data, scenario and mode; report real results or **not measured**.
6. **Assess the cost:** latency/CPU/RAM/complexity and resources freed.

## Technical rules

- `build()` can run frequently; do not block it with large parsing, I/O or repeated expensive computations.
- Use `ListView.builder`/`SliverList` or other lazy builders for many rows; do not use `Column(children: thousands)`.
- Keep reactive state localized in the consuming subtree. `Consumer`/`Selector`/equivalents help when profiling shows excessive rebuilds, not as an obligation.
- Keep `Future`/stream objects and controllers tied to the lifecycle, avoiding new requests on rebuilds without reason.
- `const` improves expressiveness and can avoid work, but it does not replace design or profiling.
- Be careful with `Opacity`, clipping, `saveLayer`, intrinsic layout, shadows or filters in animations; check whether they are the real cause.
- Choose stable keys in lists whose items change order.
- Avoid caches without bounds or invalidation, even when they reduce CPU: they can raise RAM and show stale data.
- Measure the real situation before using isolates; serialization and startup cost can exceed the savings.

## Flutter Web / admin panels

- URL state, refresh/back/forward, filters and deep links must work with the real router.
- Test layouts with zoom, keyboard navigation, window sizes and text scaling.
- Measure the render cost of large tables, virtualized lists, downloads, images and JSON parsing.
- Avoid heavy computation on the UI thread; do not promise lower RAM by moving operations to another layer if they still live in the same process.
- Do not use a full-screen `MediaQuery.sizeOf(context).width` when what matters is the width of a panel constrained by its parent.
- On desktop: test resize, focus, mouse support, shortcuts and DPI scaling.

## Evidence the agent must return

```text
Hypothesis: Widget X rebuilds 400 rows per filter change.
Baseline: [real measurement; otherwise, not measured].
Change: lazy builder + localized state.
After: [real measurement].
Risks: scroll, selection, accessibility, ordering.
Tests: widget test 0/1/many rows + interaction.
```

Never claim "30% faster" from static reading or from a reduced line count.

## Operational performance (not only benchmarks)

- **High-frequency events** (pointer moves, frames, socket/stream messages, progress ticks): never log or notify one-per-event. Sample, coalesce or rate-limit, and give the limit a number in code.
- **Never block the event loop:** no synchronous file/process I/O, big `jsonDecode`, or CPU loops on the UI isolate or in an async server path; move to `Isolate.run`/`compute` or an async API.
- **Bound everything that grows:** log files, in-memory queues, retry counters, caches. State the cap.
- Record these as limits in the change description; verify with a counter or profile, not by reading the code.
