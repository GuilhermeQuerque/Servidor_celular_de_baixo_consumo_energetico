# Roadmap

**Status:** Constitution v3 — normative (revised 2026-11-16: the peer
workstation replaces the previous transfer peer, the repetitions are n = 100 /
n = 50, the payloads are split into text and image families, the cloud is
anchored on the providers' published data, and the device characterization
opens Phase 0). Scope and method are fixed in [`mission.md`](mission.md);
instrumentation is fixed in [`techstack.md`](techstack.md). This file fixes
only the **order** of the work.

---

## 1. How to read this

The project is four phases in sequence. Each phase has a single goal, a set of
tasks, deliverables that can be checked, and an **exit criterion** — a
statement that is either true or false. A phase is not "done" because the work
felt complete; it is done because its exit criterion holds.

```
Phase 0  Setup & instrumentation validation   ← detailed below (the small phase)
Phase 1  Measurement campaigns
Phase 2  Analysis & cost model
Phase 3  Report & conclusions
```

**Phase 0 is the small phase.** It is the only phase broken down into
individual, ordered, checkable tasks, because it is the phase where a mistake
is cheapest to make and most expensive to discover later — a collector that
miscalibrates against a mock will miscalibrate against hardware for the entire
campaign, and the error will look like a finding.

| Phase | Goal | Exit criterion |
|-------|------|----------------|
| 0 | The harness is proven before it touches real hardware | `make check` passes, the mock-source validation is within its error budget, and the phone's measurement route is chosen |
| 1 | Real measurements exist for every cell of the matrix | Every cell has n = 100 valid repetitions (n = 50 for the idle baselines), or a recorded, explained gap |
| 2 | The numbers are computed from assumptions, not from hard-coded values | The cost model reproduces from CLI parameters alone, with no constant edited in source |
| 3 | The study answers RQ1–RQ4 and states its limits | Every claim in the report resolves to a raw file, and the limitations are stated in full |

---

## 2. Phase 0 — Setup & instrumentation validation

### Goal

Build and prove the measurement harness on a machine where nothing can be
silently wrong, so that the first real campaign produces numbers that can be
trusted.

### Why this phase is the small one

Every later phase consumes its output. If the collector's sampling window, its
warm-up handling or its energy integration is wrong, that defect propagates
into every scenario, every comparison, and the final report — where it will
look like a property of the phone rather than a bug in the harness. The
defect is caught here, for the cost of one afternoon, against a source whose
correct answer is known by construction.

### Entry criteria

- The phone: an old Android handset, factory state, with **Termux installed
  from F-Droid** (the tutorial's route) and enough **internal** free space for
  the campaign's peak (§0.16).
- The peer workstation: the Linux machine that runs the collector, the client
  paths and the analysis — reachable from the phone over the LAN, with free
  disk space for the largest volume.
- `adb` working on the development machine.
- A checkout of this repository.

### Tasks

Ordered. Each task ends with something checkable.

| # | Task | Check |
|---|------|-------|
| 0.1 | **Characterize the device, by automation over SSH.** A scripted probe — not a person typing `adb shell` — that collects the handset's base profile and writes it as a versioned file: SoC and core configuration (including the governor), RAM, internal storage (**total and free** — the tutorial's root is internal storage, not the card), flash type and wear node, battery capacity, health and cycle count, thermal zones, the Wi-Fi adapter, Android build and kernel, the **charger's model and rated output**, and the inventory of readable power nodes (`battery/current_now`, `usb/current_now`, the batterystats UID label). | A `phone-profile.json` and a `device-info.txt` produced by a repeatable script, committed alongside the campaign data, plus the probe script itself. It is the input to the route decision (0.6), to the storage budget (0.16), to the assumption register (A1's charger) and to the report's setup section. Re-running the probe on another handset is the intended way to port this project |
| 0.2 | **Install the stack the tutorial prescribes.** Termux from **F-Droid** (not the outdated Play Store build), Termux:Boot, `pkg update && pkg upgrade -y`, `termux-setup-storage` with the permission granted, `pkg install openssh -y`, and **File Browser** through the tutorial's `get.sh`. | The stack runs: `sshd` accepts a session and File Browser answers on `:8080`, serving the tutorial's root. The installation is recorded step by step, so another researcher reaches the same state. |
| 0.3 | **Pin the server's version and configuration.** Record the File Browser release tag and the checksum of the installed binary; replace the `admin` password; **disable previews/thumbnails and the command runner**; confirm the transport is plain HTTP and the root is `~/storage/shared`; note whether the upstream project still receives releases, since that decides how far its published documentation can be trusted. | A `versions.txt` and a configuration record produced by a repeatable command, not typed by hand, matching `techstack.md` §3.1. |
| 0.4 | **Confirm the API surface against the installed build.** Authenticate over the API, obtain a session token, and exercise **one upload and one download** of a small file, recording the exact method, path, query parameters and auth header that work. | A pinned client command per operation, reproduced twice with identical results. The endpoints are **verified, not assumed**: the upstream project is archived, so its published documentation cannot be relied on to describe the installed binary. |
| 0.5 | **Prepare the phone in factory state.** Termux with `sshd` running, the workload tools present, **no account signed in and no third-party app installed**, notifications silenced, the **Termux wake lock held**, and the serving state confirmed (File Browser listening on `:8080`, `termux-wake-lock` in effect). | A scripted preflight that prints a pass/fail line per check, including "no background app is drawing power" and "the wake lock is held". |
| 0.6 | **Choose the measurement route.** On mains with a full battery: does `usb/current_now` exist and does it respond to a known load? Does `battery/current_now` move? Which of the three routes (`techstack.md` §2.2) is therefore usable? | The chosen route is written down with the evidence that supports it, and the collector is pointed at that route. |
| 0.7 | **Build the collector.** 1 Hz sampling, warm-up excluded from the total, emitting the CSV + JSON pair of `techstack.md` §5 using the environment-variable convention rather than string interpolation into code. It reads the route chosen in 0.6 and records which one it used in every file. | Running it for 60 s produces a well-formed CSV and a JSON whose `energy_total_j` equals the sum of the CSV samples. |
| 0.8 | **Build the mock source.** A synthetic power source with a known profile and a known energy ramp, whose shape follows the route chosen in 0.6. | The mock is generated by a script, not hand-written — regenerable, with its expected value computable. |
| 0.9 | **Validate the collector against the mock.** Point the collector at the mock and compare the integrated energy against the analytic expectation. | **Error below 1 %** — the budget agreed for the harness itself. A collector that misses its own mock budget will not survive real noise. |
| 0.10 | **Write the acceptance suite** (`make check`, T1–T9 style): the collector starts and stops cleanly; it survives a workload that dies mid-run; it rejects a missing sensor node; it rejects an unwritable output directory; it handles a warm-up window correctly; it produces the same total on two identical runs; it writes valid JSON; it never leaks a background process. | `make check` passes end to end, and it fails loudly when a precondition is removed (a test that cannot fail is not a test). |
| 0.11 | **Generate the pinned dataset — both families.** Two payload families, each deterministic and each pinned: **`TEXT`** (a seeded generator over a pinned vocabulary, byte-for-byte reproducible from the seed alone) and **`IMAGE`** (a pinned image file committed to the repository, replicated to the required volume). For each family: the sizes 1/5/10/15 GB, the small-file variant with its fixed file count, the size-ladder profile (4 KiB / 64 KiB / 1 MiB — `TEXT` only), and the ballast set for the high-occupancy state. Record the SHA-256 of every artefact. | Re-running the generator reproduces the same SHA-256 — for **both** families. This is the single most important reproducibility guarantee in the project, and it now covers the *content* as well as the volume |
| 0.12 | **Prepare the peer workstation and define its silence.** `sshd`/`rsync` reachable from the phone, enough free space to receive the largest volume, **both client paths working from it** (the File Browser API client and the `rsync` client), and a procedure that parks the host's background jobs before each series. The collector runs here too, so the load this host carries is *known* rather than guessed. | A script that quiets the peer and records its load average before each series, and a successful end-to-end run of each client path against the phone. |
| 0.13 | **Measure the link speed.** The phone's Wi-Fi throughput against the peer — **as a scheduling input only**: how long a 15 GB leg takes, and therefore how long the campaign runs. It is never reported as a result. | A recorded figure feeding the schedule in 0.16, and no mention of it in the results. |
| 0.14 | **Read the flash life before starting.** The phone's flash endurance counter, before any write. | A recorded baseline, so the wear caused by the campaign is a measured number rather than a worry. |
| 0.15 | **Author the measurement protocol** as a new document under `specs/`: exact workload commands per scenario, **per family** and **per arm** (File Browser primary, `rsync` control), the repetition counts (n = 100 for transfers, n = 50 for idle), the order of the legs, families and occupancies across repetitions (so ambient drift is shared), the battery-state precondition, the **compression disabled on both paths**, the integrity-check procedure, and the metadata fields each run must carry. | The protocol exists as a versioned file, not as tribal knowledge. |
| 0.16 | **Compute the campaign's duration, write volume and storage budget.** From 0.13 and the grid of `techstack.md` §3.3: the wall-clock cost of the matrix at n = 100 / n = 50 (**≈ 32 TB moved, of the order of 2–5 weeks** on this phone's Wi-Fi); the GB written to the phone's flash (**≈ 17.6 TB**, dominated by the upload direction); the cost of the **integrity checks** (hashing a 15 GB payload twice per run × 100 repetitions is itself a schedule item — if it dominates, the protocol must define a cheaper check *before* the campaign starts, and the choice is recorded); and the **peak space** the phone must hold at once — dataset + ballast + the largest payload in flight — checked against its **internal** free space, because the tutorial's root is internal storage. | A figure for the campaign log — the cost of running the experiment, kept separate from its results — and a **pass/fail on the peak space and on the flash endurance** (0.14). If either fails, the grid is trimmed here, before the campaign starts, in the order fixed by `techstack.md` §3.4 — not discovered mid-run |
| 0.17 | **Raise the cloud's assumptions from the providers' published data.** The anchor is what the operators themselves publish: their reported energy consumption, their PUE, their grid mix, and — where they publish it — a per-unit-of-storage figure. Those become PUE (A2), carbon intensity (A3), on-site efficiency (A4) and the **disk term (A13)**, the only spinning media in the study. The network term (A5) is not published by the provider and is modelled from the literature. Cite every publication with its version and its date. | Every one of A2–A5 and A13 has a value, a **public source**, a version and a date, or is explicitly marked as an open gap |
| 0.18 | **Prepare the cloud account and stage its files.** A **free-tier** account (the provider's 15 GB allowance) with the `CLOUD_DOWNLOAD` payload uploaded and its file list recorded. No paid plan: the measurement is of the phone's side, and the tier is recorded in every run's metadata so it can never be mistaken for a measure of the paid product. | The cloud payload is present and its file list is written down; the account's tier is recorded. |

### Deliverables

- **The device profile**: the scripted probe, the script itself, its output
  (`phone-profile.json`, `device-info.txt`) and the pinned version list.
- **The installed server stack**: the tutorial's installation log, the pinned
  File Browser version and configuration, and the verified client commands for
  upload and download.
- The peer preparation and silence procedure.
- The collector, the mock-source generator, and the `make check` suite.
- The deterministic dataset with its SHA-256 manifest.
- The measurement protocol and the campaign schedule.
- The cloud's assumption table, sourced and dated, and the staged cloud account.

### Exit criterion

> The mock-source validation reports an error below 1 %, `make check` passes,
> the dataset regenerates with an identical SHA-256 **for both families**, and
> the phone preflight succeeds.
>
> **Second gate — the measurement route.** The phone's route is chosen by
> evidence (task 0.6), the collector is validated on it, and the choice is
> recorded. Without this the campaign cannot start, because every absolute
> number depends on it.
>
> **Third gate — the cloud's assumptions.** A2–A5 and A13 are populated with
> sources and dates. A campaign whose cost model has no disk term cannot
> answer RQ3, and finding that out after the measurements are in would waste
> the campaign.
>
> **Fourth gate — the budget.** The device profile (0.1) is on file, and the
> campaign's write volume and peak space (0.16) pass against the device's
> own figures. At n = 100 the campaign writes ≈ 17.6 TB to the phone's flash;
> if that does not fit the device's endurance with margin, the grid is
> trimmed **here**, in the order the spec fixes, and the trimmed matrix is
> the one the report describes.

### Risks at this phase

| Risk | Detection | Response |
|------|-----------|----------|
| The phone exposes no usable power node | 0.6 preflight finds neither `usb/current_now` nor a readable battery node | Fall back to route 3 (`dumpsys batterystats`) and declare the reduced resolution in the metadata and in the report. The within-device comparisons survive; only the absolute cost does, and it is reported as such |
| The battery node reads ≈ 0 on mains with a full battery | 0.6 preflight shows the node not moving under load | This is expected physics, not a fault: it is exactly why the battery node alone cannot be the primary sensor. Route 1 or 2 is chosen instead |
| The phone's battery drains during a long run | 0.6 and every run record `battery_level_start`/`_end` | The run is flagged; a run where the battery moved is not silently mixed with a run where it did not |
| The peer is noisy during a measured window | 0.12 records the peer's load before each series | The series is repeated later; the peer's load is recorded in every run's metadata |
| Ambient conditions drift across the campaign | 0.15 schedules the legs and occupancies to interleave | Drift is shared across the matrix rather than attributed to a scenario |
| The dataset generator is not portable | 0.11 SHA-256 mismatch across machines | Each family has a **documented, pinned** generator: the `TEXT` family's script is committed with its seed, the `IMAGE` family's seed file is committed to the repository. A mismatch is a mismatch of *ciphertext* to be investigated, never silently accepted |
| The campaign writes too much to the phone's flash | 0.14 baseline and 0.16 estimate | The flash life is re-read after the campaign and the wear reported; if the estimate exceeds the endurance, the matrix is trimmed **before** it starts, not after |
| **The campaign's write volume exceeds what the phone can take** | 0.14 endurance counter and 0.16 budget (≈ 17.6 TB at n = 100) | The grid is trimmed **before** the campaign starts, in the order `techstack.md` §3.4 fixes: the cloud cells → the control arm's 5 GB cells → the size ladder's rungs → and only then n. The idle baselines are never trimmed, and every reduction is recorded as a deviation next to the results it affects |
| The 15 GB legs take hours each | 0.13 link speed and 0.16 duration | The schedule is sized with margin, and the long legs are run unattended with a watchdog that stops the run on a stalled transfer |
| **The installed File Browser behaves differently from its published documentation** | 0.4 exercises the API against the running binary | The endpoints are taken from the installed build, not from the docs; the version and binary checksum are pinned, and the upstream project's archival status is treated as the reason to distrust the docs rather than to skip the check |
| **The phone's internal storage cannot hold the peak** | 0.1 inventory and 0.16 budget check | The grid is trimmed **before** the campaign starts. The dataset is **not** moved to the SD card: the tutorial's root is internal storage, and a split root would measure a different server |
| **The wake lock is not held in some run** | 0.5 preflight and the `wakelock_state` field of every run | The run is rejected by the quality gate rather than compared — a phone that intermittently drops into doze is a different configuration, not a noisier sample |

---

## 3. Phase 1 — Measurement campaigns

### Goal

Produce the raw measurements: every cell of the matrix — every scenario, every
family, every size, every leg — at **n = 100** for the transfers and **n = 50**
for the idle baselines.

**Fixed operating conditions.** Every run happens with the phone **connected
to mains**, **Wi-Fi associated**, **screen off**, **notifications silenced**,
in its serving state. These conditions are *held constant, not varied*.
Radio state on an old handset is not reproducible across chipsets and Android
versions (background scanning, doze behaviour, carrier assist), so varying it
would contribute a spread that reads as a device property when it is really a
property of the radio stack. A permanently-connected server on mains is also
the realistic 24/7 configuration — it is the one being asked about.

### Tasks

1. **Pilot run.** One repetition of every cell, to shake out path,
   permission and timeout problems before committing to the full matrix.
2. **Idle baselines.** `IDLE_LOW` and `IDLE_HIGH`, **n = 50** each, under the
   fixed operating conditions above. These bracket every other series, and
   their dispersion propagates into every number the study reports.
   **Wi-Fi on/off is not a variable**: no "isolated idle" state is measured,
   and the report says so explicitly, so that nobody later mistakes the
   absence of a disconnected measurement for an oversight.
3. **Transfer matrix — primary arm.** `MANY_SMALL` and `ONE_LARGE`, **both
   families**, sizes 1/5/10/15 GB, upload and download, **n = 100** each, in
   both legs — the phone serving (`phone_serves`) and the phone receiving
   (`peer_serves`) — over the **File Browser API**. Each leg records the
   phone's `role`; each run records its `protocol`, its `shape` and its
   `payload_family`.
4. **Control arm.** The same two shapes and **both families** at **1 GB and
   5 GB**, upload and download, **n = 100**, over **`rsync` over SSH** — the
   reduced matrix of `techstack.md` §3.3, over the *same* pinned dataset,
   from the *same* peer. Each control run is scheduled **next to** its
   matching primary run, so that any drift in the ambient conditions is
   shared between an arm and its control rather than falling on one of them.
5. **Size ladder.** 4 KiB / 64 KiB / 1 MiB per file, 5 GB fixed, upload
   direction, `TEXT` family, **n = 100** — the run that makes `E_overhead` a
   slope rather than an observation.
6. **Cloud download.** The phone as client of the real cloud service, 1 and
   5 GB, **both families**, **n = 100** each, on a free-tier account. This is
   the only run that touches the cloud, and it exists so that the RQ3
   access-path comparison is measured against measured. The tier and the file
   list used are recorded in each run's metadata.
7. **Quality gate per repetition.** Each run is validated before it is
   accepted: samples are contiguous at 1 Hz, the JSON total matches the CSV
   sum, the workload exited cleanly, the dataset SHA-256 matched at both ends,
   the battery level did not move during the window, the **wake lock was held
   throughout** and the serving daemon stayed alive, and no state flag
   contradicts the intended scenario.
8. **Log the environment.** Ambient temperature, the phone's thermal state,
   the peer's load average, battery health and firmware version, per series.

### Deliverables

- `data/raw/PHONE/<LEG>/<PROTOCOL>/<SCENARIO>/<label>.{csv,json}` for every
  accepted repetition.
- A rejected-run log naming the reason for every discarded run — a gap that
  is not explained is indistinguishable from a result that was never tried.
- The idle baseline tables used for ΔE.

### Exit criterion

> Every cell in the matrix has its full complement of repetitions — n = 100
> for the transfers, n = 50 for the idle baselines — or a documented and
> explained gap. The dataset SHA-256 matched on every accepted transfer, and
> the battery level did not move during any accepted window.

---

## 4. Phase 2 — Analysis and cost model

### Goal

Turn the raw measurements into comparable, scope-labelled numbers and into a
financial model whose every assumption is visible and overridable.

### Tasks

1. **Aggregate.** Walk `data/raw/`, validate each run against the quality
   gate, join runs into one consolidated table, and carry `role`, `leg`,
   `protocol`, `shape`, `payload_family`, `measurement_route`, `scope` and
   `source` on every energy value, so an invalid comparison cannot be made by
   accident.
2. **Compute ΔE and the normalized metrics.** `delta_energy_j`, `j_per_gb`,
   `j_per_file`, `idle_power_w`, the per-role splits (`e_per_gb_server`,
   `e_per_gb_client`), and the dispersion statistics (mean, SD, CV, and the
   95 % confidence interval of the mean) across the repetitions of each cell.
3. **Separate what is measured from what is modelled.** The phone's bars are
   solid; the cloud's are hatched and carry their derivation. Two panels, one
   for each, and no axis that mixes them without the label.
4. **Build the cost model.** CAPEX and OPEX over 24/36/60-month horizons for
   the phone, including the battery replacement as a recurring cost and the
   electricity at the wall. Every assumption comes from the register in
   `techstack.md` §7 via CLI flags — including the cloud's subscription and
   its modelled energy cost.
5. **Compute break-even.** The traffic volume at which the cloud's total cost
   falls below the phone's, and the comparison of the two RQ3 questions —
   the storage system (phone serving vs the installation) and the access path
   (phone receiving from the peer vs from the cloud).
6. **Sensitivity analysis.** Which assumptions actually move the conclusion.
   If the answer changes under a plausible variation of an assumption, that is
   a finding, not a nuisance — and it belongs in the report. A13 (the cloud's
   disk term) is the expected leader and is examined first.
7. **Compute the web server's share.** `E_web` (`mission.md` §5.1.3, R6): the
   primary arm's `j_per_gb` minus the control arm's, matched by leg, shape,
   family and size — with the dispersion of the difference reported, and with
   the arms' transport asymmetry (plain HTTP against a pinned SSH cipher)
   stated next to the number rather than in a footnote.
8. **Test resolvability, and report it.** For every pair of cells the report
   compares, apply the test of `mission.md` §5.1.3, R7: the difference is
   reported as **distinguishable** or **not distinguishable**, with both
   confidence intervals quoted. A pair that fails the test is reported as
   failing it — not rounded into a conclusion.

### Deliverables

- `data/processed/consolidated.csv` and the per-component breakdown table.
- `data/processed/cost_model.json`.
- The plots: energy per scenario, idle versus load, cost break-even.

### Exit criterion

> The cost model reproduces from CLI parameters alone, with no constant edited
> in source; the break-even chart uses the measured values, not placeholder
> defaults; every figure in every plot is traceable to the consolidated table,
> and no measured value shares an axis with a modelled one without the label.

---

## 5. Phase 3 — Report and conclusions

### Goal

Answer RQ1–RQ4 with the measured numbers and state plainly what the experiment
does and does not establish.

### Tasks

1. **Fill the results template** section by section: setup, methodology,
   raw-data provenance, results per RQ, limitations, conclusion. **The
   report shows the arithmetic in summary** — what was computed, from which
   raw files, to what precision — and points to the **larger spec file**
   (`mission.md` §5.1) for the complete derivation, wherever a figure is
   presented. The reader who wants the result is not made to read the method
   first; the reader who wants to check the method can find all of it.
2. **Answer RQ1** with the energy per GB and per file for each transfer shape,
   **content family**, size, direction and role, with dispersion, confidence
   intervals and scope labels.
3. **Answer RQ2** with the phone's idle power at low and high occupancy, and
   state whether idle cost tracks capacity used or capacity present.
4. **Answer RQ3** with the cost model, the break-even point, and the two
   comparisons — storage system and access path — stated separately.
5. **Answer RQ4** with the qualitative synthesis, separating what was measured
   from what is an engineering judgement about each platform.
6. **State the limitations in full** — the modelled (never measured) cloud,
   and the fact that its figures are the providers' published data rather
   than something this study observed; the phone's radio draw being
   inseparable from its consumption; the flash writes, and any trimming the
   budget gate forced; the synthetic workload's distance from a real data
   mix, in particular that the two content families are proxies for text and
   for images rather than a user's actual library; the charger-loss
   assumption, which is **sourced and not measured**; **the transport
   asymmetry between the two arms** (plain HTTP against a pinned SSH cipher),
   which makes `E_web` a difference between two stacks rather than a protocol
   ablation; **the archived upstream project** whose installed build had to be
   probed directly; and the uncontrolled ambient conditions, which no
   repetition count can make go away.
7. **Archive.** Freeze the raw data, the dataset manifest for both families,
   the device profile, the pinned versions and the exact commands used, so
   the campaign can be re-run or audited.

### Deliverables

- The final report.
- A frozen archive of raw data, dataset manifest, versions and commands.

### Exit criterion

> Every number in the report resolves to a file under `data/raw/`; the
> limitations are stated in full; RQ1–RQ4 each have an answer backed by data;
> every comparison the report makes states whether it is **distinguishable**
> at the measured dispersion; and the report points to the spec for the full
> derivation of every figure it presents.

---

## 6. Global constraints

These apply to every phase and override convenience at any point.

1. **A gap is documented, never hidden.** If a scenario cannot be run, the
   report says so and says what that prevents it from concluding.
2. **No firmware updates mid-project.** A governor change on the phone
   invalidates the comparison between pre- and post-update runs.
3. **A quiet peer, or no measurement.** The peer is doing the I/O while the
   phone is measured; its background load is recorded before every series and
   the series is repeated later if it is high.
4. **Same payload, same schedule**, always. One dataset per family,
   generated once, reused everywhere — and reused by **both arms**, so that
   the control's comparison with the primary is byte-for-byte.
5. **Interleave the legs and the occupancies.** Ambient drift is shared by
   rotating the order across repetitions; it is never allowed to be attributed
   to a scenario.
6. **Everything in this constitution is overridable by a recorded deviation.**
   Changing the method is allowed — hiding the change is not. Deviations are
   recorded in the report next to the results they affect.
7. **Fixed operating conditions.** On mains, Wi-Fi associated, screen off,
   notifications silenced, in the serving state — for every run, in every
   scenario. Conditions that are hard to reproduce are held constant rather
   than varied, because they are exactly the ones that would otherwise be read
   as device differences. A result is a result *about that configuration*, and
   the report says which configuration it is about.
8. **The instrument is not the subject.** The peer workstation and the network
   exist to carry bytes. Nothing about either is measured, compared, or
   reported as a finding.
9. **The server under study is the tutorial's.** The stack is installed as
   the reference tutorial configures it. Anything else — a different version,
   a different root, an extra feature — is a recorded deviation, and the
   deviation travels with the metadata of the run it affects.
10. **The arms differ only in the software that carries the bytes.** Same
    phone, same sensor, same payload, same peer, same link, same schedule.
    A difference between the primary arm and the control arm is a property of
    the server software, not of the surroundings.
11. **The repetition count is part of the result.** Every cell's report states
    the n it actually achieved. A mean over 60 runs is not a mean over 100,
    and a cell that fell short says so where the number is presented — not
    in a footnote, and not silently.

---

## 7. Deferred — outside the plan

Some things are deliberately **not** part of this project. They are recorded
here so that their absence is a decision rather than an oversight, and so that
nobody later reads them as work that was forgotten.

| Item | Status | What it would take | What it would mean |
|------|--------|--------------------|--------------------|
| **Reproducing the server environment in Docker on x86** — one attempt, as a stand-in for the server under study on a machine of the user's own | **Parked** by the researcher | A container image running the same stack (File Browser + `sshd` + the same root and configuration) on an x86 machine | Nothing in this campaign. If revived, it becomes a **post-experiment update**, outside the campaign and outside any comparison |

It has no task, no deliverable and no exit criterion in any phase, and it does
not appear in the campaign schedule. The peer workstation remains in the
laboratory for the duration of the campaign, as the phone's transfer peer and
storage endpoint — an instrument, never a candidate.
