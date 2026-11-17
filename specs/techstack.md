# Tech Stack

**Status:** Constitution v3 — normative (revised 2026-11-16: the peer
workstation replaces the previous transfer peer, the repetitions are n = 100 /
n = 50, and the payloads are split into text and image families). Governed by
[`mission.md`](mission.md); see [`roadmap.md`](roadmap.md) for the order in
which these pieces get built and validated.

This document specifies *with what* the experiment is measured and *how* the
data moves from sensor to conclusion. Anything with a default value here is a
**default that can be overridden by CLI flag**, never a constant hard-coded in
an analysis script.

---

## 1. Hardware targets

| ID | Role | Platform | Energy measured at | Access |
|----|------|----------|--------------------|--------|
| `PHONE` | **The only measured candidate** | Android (old device) + Termux + File Browser | The device, by one of three routes (§2.2) | `adb` over USB, SSH |
| `PEER` | **Instrument** — the transfer peer and storage endpoint, and the workstation that runs the collection and the analysis | Linux | **Never measured, never reported** | SSH, local shell |
| `CLOUD` | Comparison baseline | Managed cloud storage | **Never measured — modelled** | API / client |

**Device IDs are stable strings.** They appear in directory names, in the
`device` field of every JSON metadata file, and in the `scope`/`source` columns
of the consolidated dataset. Renaming one is a breaking change to the raw data
layout and requires re-running `aggregate.py`.

**The `PEER` row is an instrument, and never a candidate.** It is the
workstation that runs the collector, the two client paths and the analysis; it
holds the payload while the phone is being measured; and it is the endpoint
that receives the volumes. Its energy is not measured, its numbers are not
reported, and it contributes nothing to any comparison. Because it is also the
host of the collector, its background load is a **known** quantity rather than
an unknown one: the load average is recorded before every series, and the
collector's own cost is inside that record.

### 1.1 What "the phone" is, precisely

An old Android handset repurposed as a storage server, running the stack of
the [reference tutorial](https://github.com/MarcusMix/articles/blob/master/tutorial_servidor_nas.md).
That tutorial is **normative for the software stack**: Termux (installed via
F-Droid, not the outdated Play Store build), Termux:Boot, OpenSSH, and
**File Browser** as the web file manager and file-transfer interface. The
tutorial's `htop` is optional monitoring, not part of the measured server.

Concretely, the serving state is:

| Element | As configured in the tutorial | Role in the study |
|---------|-------------------------------|-------------------|
| Termux | via F-Droid; `pkg update && pkg upgrade -y`; `termux-setup-storage` | the Linux userland the server runs in |
| OpenSSH (`sshd`) | `pkg install openssh -y`; `sshd` | **administration** — and the transport of the control arm |
| **File Browser** | `filebrowser -a 0.0.0.0 -p 8080 -r ~/storage/shared` | **the server under study** — it serves the files, and its API is the measured transfer path |
| Termux:Boot | `~/.termux/boot/start-services.sh` starting `termux-wake-lock`, `sshd` and `filebrowser` | makes the serving state survive a reboot, as a real NAS must |
| Wake lock | `termux-wake-lock` | **part of the fixed operating conditions** — see §2.2 |
| `admin` account | default password replaced via `filebrowser users update admin --password …` | the credential the client uses; the password itself is never recorded in the data |

The File Browser root is `~/storage/shared` — the phone's **shared internal
storage**, not the SD card and not the Termux-private directory. Two
consequences follow, and the study respects both: the payload lives on
internal flash (the endurance concern of §3.4), and the free space the
campaign needs is measured against internal storage rather than against
whatever card happens to be inserted (roadmap task 0.16).

**Everything the tutorial does not specify is a deviation.** If the campaign
needs a tweak the tutorial does not have — a pinned File Browser version, a
pinned SSH cipher, a disabled preview generator — that tweak is recorded as a
deviation, with its reason, in the metadata of every run it affects.

**The device is characterized before it is measured.** The first task of the
campaign (roadmap task 0.1) is a scripted probe, run over SSH, that collects
the base profile of the handset: SoC and core configuration, RAM, internal
storage and its wear counters, battery capacity, health and cycle count,
thermal zones, the Wi-Fi adapter, the Android build and the kernel, and the
charger's model and rated output. The output is a versioned profile file, not
a paragraph typed by hand — it is the input to the assumption register, to the
report's setup section, and to the decision about how the phone is measured at
all.

**The charger's efficiency is part of that profile, and it is not a
measurement.** The scope has no instrument at the wall, so `η` (A1) cannot be
measured: the probe records the charger's model and rated output, and the
device-side readings give a *bracket* — the difference between the plug-side
and the device-side reading bounds the loss across the charger, but does not
measure it. `η` enters the model as a sourced assumption with the charger
identified, and the report says so wherever a phone number is converted into
money.

The handset is expected to be an older SoC with a single big core, a modest
battery and no active cooling.

Two facts about this device dominate the experiment and must be handled
explicitly rather than discovered later:

- **The phone runs on mains, permanently.** The fixed operating condition for
  every measurement is: connected to the outlet, Wi-Fi associated, screen off.
  The battery is therefore a short buffer — a UPS of a few minutes — not a
  power supply, and this changes what the battery sensor *means*. On mains,
  the current into the battery is **charge current**, not the device's draw:
  a phone that is charging while serving draws load *plus* charge current,
  and the two must never be mixed into one number. The battery node alone
  therefore cannot be the primary sensor — see §2.2 for the three routes and
  why the obvious proxy fails.
- **It is a multi-purpose personal device.** It will be carried, used, and
  charged by the user. That is a legitimate part of its cost-benefit profile
  (RQ4) but it must not contaminate the measurements: the screen is off,
  notifications are silenced, and the **rest** of the device is forced idle
  where possible — the server itself holds a wake lock, as the tutorial
  prescribes (§2.2).

### 1.2 What "the peer" is, precisely

**The peer is an instrument, not a candidate.** It is the workstation that
runs the collection and the analysis, and it is the phone's transfer peer and
the endpoint that receives the volumes: without it there is no transfer leg at
all, because the phone is the only device with a radio and the peer is the
only one on the wired side of the link.

What that means concretely:

- Its energy is **not measured**. No sensor is read for the study's benefit,
  no figure is reported, and it contributes to no comparison.
- It is **not** a candidate, so none of the RQs are asked of it.
- Its practical duties are minimal and are the only things specified here:
  `sshd`/`rsync` reachable from the phone, enough free space to receive the
  largest volume, and **silence** — it does the I/O while the phone is being
  measured, so its background load is recorded before every series and held
  as low as practical.
- It hosts **both client paths** of the campaign: the File Browser API client
  (primary arm) and the `rsync`/`ssh` client (control arm). The two are run
  from the same machine, over the same wired link, so the control compares
  software stacks rather than links.
- Nothing about it is a research object: no link characterisation, no
  interface comparison, no energy term of its own.

The peer's own consumption is a known cost of running the experiment, not a
result of it. It is reported as such in the campaign log, never mixed into
the study's numbers.

### 1.3 What "the cloud" is, precisely

A managed cloud storage service. It is included because it is the option the
user would otherwise default to, and because it is the only candidate with
no hardware cost but a guaranteed recurring one. Its energy is **modelled**
from **the provider's own published energy data** — the environmental and
sustainability reports in which the operators disclose their consumption and
the efficiency of their infrastructure. It is never instrumented, and no
number derived from it is ever presented as a measurement.

The rule for the cloud side is therefore simple and absolute: **every term
comes from public data, and every term carries its source, its version and
its date.** What the provider publishes is used as published; what it does
not publish — the network's share, the energy of the spinning media behind
the capacity — is modelled from the literature and marked as an assumption.
Nothing is invented, and no figure is quietly carried over from a previous
year without saying so.

**The cloud holds the only rotating disks in the entire study.** The phone
stores on flash; the peer workstation stores on SSD; the cloud's capacity is
backed by spinning drives, whose energy per terabyte is a function of how
many are spinning. That term is the most sensitive assumption in the whole
model (A13), and it is why the provider's published figures are cited with
their version and date rather than paraphrased.

---

## 2. Measurement instrumentation

### 2.1 Peer (instrument — not measured)

No energy sensor is read from the peer for the study's benefit. What it must
provide is operational, not metrological:

| Requirement | Detail |
|-------------|--------|
| Reachability | `sshd` and `rsync` reachable from the phone over the wired link |
| Client paths | both clients the campaign uses: the **File Browser API client** (primary arm) and the **`rsync`/`ssh` client** (control arm). They run from the same host, over the same link, so the control compares software stacks rather than links |
| Storage | enough free space to receive the largest volume in the matrix, and to hold the pinned dataset between runs |
| Host of the collector | the same machine runs the collector and the analysis, so the peer's background load is a **known** quantity: it is recorded before every series, and the collector's own cost is inside that record |
| Silence | background load recorded before every series and held as low as practical — it is the peer doing the I/O while the phone is measured |
| Stability | no reboots, no updates, no long-running background jobs during a series |

Its consumption is a cost of running the experiment, recorded in the campaign
log and reported as such — never mixed into the study's numbers.

### 2.2 Phone (Android) — the measured device

The phone has one measured device, one scope, and **three candidate
measurement routes**. A preflight (roadmap task 0.6) tests them in order and
the route it picks is recorded in every raw file.

#### Why the obvious proxy fails

On mains with a full battery, the phone's charge current is ≈ 0 **even while
the device is working hard** — the charger feeds the load directly and the
battery is not being topped up. A collector that reads the battery node and
classifies "high current ⇒ busy, low current ⇒ idle" would therefore report a
fully-loaded server as idle, and the idle baseline would come out absurdly
cheap. The subtraction idea is right; it needs **two** currents, not one.

#### The three routes

| Route | Reads | Gives | When it applies |
|-------|-------|-------|-----------------|
| **1 — plug-side** | `usb/current_now` (or the USB gadget's `power_now`) × `voltage_now`, sampled from the host | the phone's whole draw **at the plug**, no charger loss to correct | the device exposes a USB-side power node (preferred: energy is already wall-side) |
| **2 — battery-side** | `battery/current_now` × `voltage_now`, with the battery **off mains** for the measured window | the device's draw, on the battery | no USB-side node, and the charger loss becomes assumption A1 |
| **3 — batterystats** | `dumpsys batterystats` totals | whole-device, coarse, battery-side | no route-1 or route-2 node is readable |

Route 1 is preferred; route 2 is the fallback; route 3 keeps the campaign
alive with a declared loss of resolution. **The route only affects absolute
numbers.** Every comparison the study draws is within one device and one
sensor, so it is invariant to the route — see `mission.md` §5.1.2.

#### Supporting signals (all routes)

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Sampling | 1 Hz, timestamped on the host | Host-side timestamps avoid trusting the phone's clock. |
| Attribution | `dumpsys batterystats` filtered by the Termux UID | The Android analogue of per-process attribution: separates the server workload from the phone's own baseline draw. The UID is resolved from `pm list packages -U com.termux`, **not** from `adb shell id -u`, which returns the shell UID and silently attributes the wrong thing. |
| Mains state | `dumpsys battery` (AC / USB / wireless / discharging) **plus the battery level at run start and end** | Mandatory. On mains with a full battery the current goes to the load; the same phone charging draws load + charge. The level at start and end is what tells them apart, and it also detects the battery draining during a long run. |
| Device state | Screen off, notifications silenced, **Termux wake lock held** (`termux-wake-lock`), `dumpsys deviceidle force-idle` for the rest of the system | The wake lock is part of the real 24/7 configuration — the tutorial needs it so the NAS survives with the screen off — and holding it exempts the Termux app from doze. `force-idle` therefore quiesces the *rest* of the handset, not the server. Both states are recorded per run; the earlier assumption that `force-idle` alone held the whole device no longer holds |
| Server state | File Browser process alive and listening on `:8080`, `sshd` alive, no third-party service running | The measured configuration is the *serving* configuration of §1.1. A run in which the daemon died mid-window is a failed run, not an idle one |
| Network | **Wi-Fi on and associated, for every run** | Fixed, not varied. Radio state on an old handset is not reproducible across chipsets and Android versions, and a permanently-connected server on mains is the realistic 24/7 configuration anyway. The link's speed is **scheduling input only** — never a measured quantity of the study. |
| Flash wear | `/sys/class/mmc_host/*/life_time` (or the equivalent node) | The campaign writes to the phone's flash; the wear is read before and after so the cost is a number instead of a worry. |
| Temperature | `*/thermal_zone*/temp` | The phone's thermal state is a precondition of every run, recorded alongside. |

### 2.3 Cloud (model)

The cloud's energy is derived, never measured. The derivation chain is fixed:

```
cloud_energy_per_GB
  = facility_energy_per_GB / PUE                 (PUE from the provider's report)
  + network_energy_per_GB                        (network share, sourced or assumed)
  + client_device_energy_per_GB                   (the phone's own measured draw)
```

Every term is a named, sourced, CLI-overridable parameter. The provider
figures used as defaults must be re-verified against the published
environmental report at the time of the report, and the version/date of the
report recorded next to them. The **disk term** — the spinning drives behind
the capacity — is the most sensitive of these (A13) and is the one that
carries the study's only rotating media.

**The anchor is the provider's own published data.** Where the provider
publishes an energy or carbon figure per unit of storage, that figure is the
starting point and the derivation only fills in what the provider does not
publish. Where it publishes only aggregate infrastructure figures — total
consumption, PUE, the share of renewables — those are combined with the
capacity actually used, and the combination is shown, step by step, in the
report's appendix. The report cites the provider's report by version and
date, never a paraphrase of it, and the sensitivity analysis (§2.3's terms,
in the assumption register) states which published figures the conclusion
actually depends on.

---

## 3. Workload tooling

**The transfer path is the server's own API.** The workload is a file
transfer performed by the software the tutorial installs — not a synthetic
benchmark run beside it. Two paths are measured:

| Arm | Path | Transport | What it isolates |
|-----|------|-----------|------------------|
| **Primary** | File Browser's HTTP API against `http://<phone>:8080` | HTTP over the phone's Wi-Fi | the serving cost of the NAS as the user would actually use it |
| **Control** | `rsync` over SSH (phone ↔ peer workstation) | SSH over the phone's Wi-Fi | the cost of the web server's stack relative to a plain SSH copy |

The control is a *within-device* comparison: same phone, same sensor, same
payload, same direction, same peer. What it isolates is the server software —
plus, unavoidably, the cipher work that plain HTTP does not do (§3.1).

**Two payload families, measured separately.** The campaign moves two kinds of
content, because a NAS carries two kinds of content and the server's cost may
depend on which: **TEXT** (a deterministic, compressible UTF-8 corpus) and
**IMAGE** (a pinned image file — already compressed, like the media it
stands for). Every transfer cell is run for both families, each with
**n = 100**. The two families differ in content and in nothing else: same byte
volume, same file count, same schedule, same apparatus, same peer.

To keep that true, **compression is disabled on both paths** — `rsync` runs
without `-z`, and the HTTP transfer does not negotiate content encoding. With
compression on, the text family would be unfairly cheap under one path and
the comparison would measure gzip rather than the server.

| Need | Tool | Pinning / notes |
|------|------|-----------------|
| Copy / transfer — primary | **File Browser HTTP API**: `POST /api/login` for a session token, then the resources upload/download endpoints | The exact endpoint paths, query parameters and auth header are **confirmed against the installed version in Phase 0** (roadmap task 0.4) and pinned there; they are not assumed here. The client is a pinned `curl` invocation, so the peer adds no daemon of its own |
| Copy / transfer — control | `rsync` over SSH (phone ↔ peer workstation) | The SSH cipher and key exchange are **pinned**, and `-z` is **off**, because the control's number is only reproducible if they are |
| Payload generation — `TEXT` | a deterministic, seeded text generator (seeded PRNG over a pinned vocabulary) | Byte-for-byte reproducible from the seed alone; the SHA-256 of every artefact is pinned in the manifest |
| Payload generation — `IMAGE` | a **pinned image file** (committed to the repository, its SHA-256 in the manifest), replicated to the required volume | Real, already-compressed media — reproducing it byte-for-byte on every machine is trivial |
| Compression | **disabled on both paths** | `rsync` without `-z`; no content encoding on the HTTP transfer. Otherwise the two families would differ in transport cost rather than in content |
| Integrity check | `sha256sum` before and after each transfer | Proves the transfer was lossless and that both sides carried identical bytes. Its cost is part of the campaign budget (roadmap task 0.16) |
| Link speed | `iperf3` | **Only** as a scheduling measurement (how long a leg takes), never as a reported result. |

**There is no synthetic CPU, memory or disk load in this study.** The grid
contains only transfers and idle; the transfer *is* the workload, and the
phone's protocol overhead, its encryption work and its flash writes are part of
what is being measured rather than something to be held constant by a
separate stress tool. That is also why the `stress-ng`/`fio` version-divergence
problem between Termux and the peer never arises: the peer only stores and
sends bytes, it does not run a benchmark.

### 3.1 The server under study — File Browser's configuration

The measured server is a configurable daemon, and its configuration is part
of the measurement. The following is fixed for the whole campaign, recorded
in the metadata of every run, and changed only by a recorded deviation:

| Setting | Value | Why |
|---------|-------|-----|
| Version | the installed release, pinned by tag and binary checksum | the daemon's behaviour — and its cost — changes between releases |
| Bind address and port | `0.0.0.0:8080`, as the tutorial | the tutorial's configuration; changing it would change what is being studied |
| Root | `~/storage/shared` | the tutorial's root; also the phone's internal storage |
| Transport | **plain HTTP** | as the tutorial configures it. No TLS is added: adding it would measure a different server |
| Authentication | the `admin` account with its default password replaced; the client authenticates once and holds a session token | the credential itself is **never written to the data**; only the fact that a token was used is recorded |
| Preview / thumbnail generation | **disabled** | previews are CPU work that is not part of moving bytes; leaving them on would charge the server for a feature the study is not about |
| Command runner | **disabled** | the upstream project warns against leaving it enabled, and a file server does not need it |
| Its own database | kept in the default location on internal storage | the daemon writes metadata on every operation; that write is part of the measured cost and is not excluded |

Two of these lines are load-bearing for the headline number. **Plain HTTP**
means the primary arm does not pay for a cipher while the control arm does
(§3.4) — the primary arm is therefore not flattered by an accidental
advantage; it measures a NAS configured as the tutorial configures it.
**Disabled previews** keep the difference between the arms about *serving
bytes*, not about *generating thumbnails*.

### 3.2 Topology — two legs, two paths, one device with two roles

The phone is the only measured device, and it plays a different role in each
leg. The role is a property of the **data flow**, not of the device, and it
is recorded in every raw file.

| Leg | The phone is… | Data flows | The peer is… |
|-----|---------------|------------|-------------|
| `phone_serves` | **server** — it holds the data and transmits it | phone → peer | the receiver and the storage endpoint |
| `peer_serves` | **client** — it acquires the data from an external source | peer → phone | the sender and the storage endpoint |

Each leg measures the phone. In `phone_serves` the phone's cost is dominated
by transmission; in `peer_serves` by reception. **Both legs are needed**:
the first isolates the serving cost, the second isolates the access cost, and
the difference between them is the phone's asymmetry as a storage server.

**The role label describes the data flow, not the protocol's client/server
relationship.** File Browser is an HTTP server on the phone in *both*
directions: in `peer_serves` the peer uploads to it and the phone's daemon
receives the body and writes it to storage. So "client" here means *the phone
is the one acquiring the data* — exactly the role the phone plays in the
`CLOUD_DOWNLOAD` scenario, and the role RQ3's access-path question is about.

Each leg is measured over **both** transfer paths (§3): the primary arm
(File Browser) and the control arm (`rsync` over SSH). The peer is the same
machine and the link is the same cable in both arms, so the control compares
the server's software, not its surroundings.

The link is the phone's Wi-Fi in both legs — the peer has no radio,
so every byte in the study crosses the phone's wireless interface. That is a
property of the hardware under study, not a variable: the study makes no
comparison of links and attributes no result to the network.

### 3.3 The experiment grid

**The axes.** A run is identified by *(leg, protocol, family, scenario,
size)*, and the number of repetitions is fixed per scenario. The direction is
**not** an independent axis: the leg *is* the direction, because the leg says
which side holds the payload.

**Directions are named from the user's side**, the way a NAS user would name
them: **upload** = the payload is sent *to* the phone (the phone receives and
writes it); **download** = the payload is read *from* the phone (the phone
serves it). The mapping to the legs is therefore one-to-one —
`peer_serves` **is** the upload direction, `phone_serves` **is** the download
direction — and only the upload direction writes to the phone's flash. The
naming is what makes the flash arithmetic of §3.4 legible.

| Scenario | Shape | Family | Sizes | Direction (leg) | n | Path |
|----------|-------|--------|-------|------------------|---|------|
| `IDLE_LOW` | idle, ≤ 20 GB stored | — | — | — | **50** | path-independent |
| `IDLE_HIGH` | idle, ≥ 50 GB stored | — | — | — | **50** | path-independent |
| `MANY_SMALL_TEXT` | many small files | `TEXT` | 1/5/10/15 GB | upload and download | **100** | **File Browser** (primary) |
| `MANY_SMALL_IMAGE` | many small files | `IMAGE` | 1/5/10/15 GB | upload and download | **100** | **File Browser** (primary) |
| `ONE_LARGE_TEXT` | one large file | `TEXT` | 1/5/10/15 GB | upload and download | **100** | **File Browser** (primary) |
| `ONE_LARGE_IMAGE` | one large file | `IMAGE` | 1/5/10/15 GB | upload and download | **100** | **File Browser** (primary) |
| `SIZE_LADDER` | 4 KiB / 64 KiB / 1 MiB per file | `TEXT` | 5 GB fixed | upload | **100** | **File Browser** (primary) |
| `CLOUD_DOWNLOAD_TEXT` | the phone as **client** of the real cloud service | `TEXT` | 1 and 5 GB | download only | **100** | the cloud's own client — not File Browser |
| `CLOUD_DOWNLOAD_IMAGE` | the phone as **client** of the real cloud service | `IMAGE` | 1 and 5 GB | download only | **100** | the cloud's own client — not File Browser |

**Why n = 100 and n = 50.** The campaign runs unattended on a real device, in
an uncontrolled environment, so the limiting factor was never the apparatus —
it was the *dispersion*. With five repetitions the standard error of a cell
mean is of the same order as the differences the study asks about, and a 7 %
effect (the difference between `GB` and `GiB`, the margin the metric
conventions themselves turn on) is simply not resolvable. At n = 100 the
standard error of a cell mean falls by roughly a factor of 4.5, and the
difference between two cells becomes resolvable at the two-percentage-point
level — which is what the study's own quantity definitions demand. The idle
baselines are measured n = 50 times per occupancy state: they are cheap, they
bracket every other series, and the energy of an idle phone is exactly the
quantity whose dispersion matters most, because it is subtracted from every
single transfer.

The size ladder runs on the `TEXT` family only, in the **upload** direction,
where the per-file work accumulates on the phone (a file creation and a
metadata write per file); the ladder's job is the *slope* of `E_GB` against
the file count, and the image family would add write volume without adding a
second slope to interpret.

**The control arm is a reduced matrix, deliberately.** The `rsync` arm
measures the same two shapes (`MANY_SMALL` and `ONE_LARGE`), both families,
at **1 GB and 5 GB**, in **both directions**, with n = 100:

| Scenario | Shape | Family | Sizes | Direction (leg) | n | Path |
|----------|-------|--------|-------|------------------|---|------|
| `MANY_SMALL_TEXT` | many small files | `TEXT` | 1 and 5 GB | upload and download | **100** | `rsync` over SSH (control) |
| `MANY_SMALL_IMAGE` | many small files | `IMAGE` | 1 and 5 GB | upload and download | **100** | `rsync` over SSH (control) |
| `ONE_LARGE_TEXT` | one large file | `TEXT` | 1 and 5 GB | upload and download | **100** | `rsync` over SSH (control) |
| `ONE_LARGE_IMAGE` | one large file | `IMAGE` | 1 and 5 GB | upload and download | **100** | `rsync` over SSH (control) |

It is reduced in **size**, not in rigour: the control exists to produce **one**
number — `E_web` (`mission.md` §5.1.3, R6) — and that number is a *difference*
of two marginal energies. A difference does not need the whole matrix to be
meaningful, but it does need dispersion on both sides of it, hence n = 100
here as well. The 10 GB and 15 GB sizes are dropped because they would add
(10 + 15) GB × 2 shapes × 2 families × 2 directions × 100 ≈ **20 TB** of
extra transfer — and about 10 TB of extra writes to the phone — to produce
the same difference at a size where the per-GB figure has already flattened.

**The two arms share the payload by construction**: the control reuses the
*same* pinned dataset as the primary arm, at the same sizes, so the comparison
is byte-for-byte.

`CLOUD_DOWNLOAD` is the one scenario that touches the real cloud, and it
exists for a specific reason: it makes the RQ3 **access-path** comparison
*measured against measured* instead of modelled against measured. The phone
downloads from the cloud while the collector reads the phone's own sensor —
so the phone's client-side draw per GB becomes an observation, and the cloud's
server-side energy stays the model it always was.

It needs no paid subscription: the measurement is of the **phone's** side, and
a free-tier account (the provider's 15 GB allowance) is enough to move 1 and
5 GB. The server-side figures come from the model regardless of which tier
the data came from, and that separation is stated in the metadata: the tier
and the file list used are recorded per run, so nobody later mistakes a
free-tier transfer for a measure of the paid product.

File counts for `MANY_SMALL` are fixed by size and recorded in the metadata
(e.g. 1 GB in 10 000 files of ~100 KiB). Sizes are **decimal**
(`1 GB = 10⁹ bytes`, IEC 80000-13) and every metadata file states the unit
explicitly, so no one has to infer GB vs GiB later — the two differ by
7.37 %, which is the same order as the dispersion being measured. The byte
count that reaches the denominators is the **payload**, never the wire
traffic with its framing overhead.

### 3.4 One dataset, reused — and what it costs in flash writes

The dataset is generated **once** — for each of the two families — and reused
across every scenario, every repetition and both occupancy states. The
occupancy is created with **ballast** (extra files already present) rather
than by rewriting: the `IDLE_LOW` state is the dataset as generated, and
`IDLE_HIGH` is the same dataset plus a ballast set that is written once and
left in place.

What this does **not** eliminate: an *upload* has to be written somewhere. The
upload direction writes the payload into the phone's storage on every
repetition. At n = 100, with two families, the campaign's write volume is:

| Source | Written to the phone |
|--------|---------------------|
| `MANY_SMALL` + `ONE_LARGE`, primary arm | (1 + 5 + 10 + 15) GB × 2 shapes × 2 families × 100 = **12,400 GB** |
| `SIZE_LADDER` (upload direction) | 5 GB × 3 rungs × 100 = **1,500 GB** |
| Control arm | (1 + 5) GB × 2 shapes × 2 families × 100 = **2,400 GB** |
| `CLOUD_DOWNLOAD` | (1 + 5) GB × 2 families × 100 = **1,200 GB** |
| Dataset and ballast | ≈ **50 GB** |
| **Total** | **≈ 17,600 GB — 17.6 TB** |

(The download direction reads what is already there and writes nothing new;
File Browser's own metadata writes are small but real, and are included in
the measured cost rather than excluded from it.)

**17.6 TB is a serious number, and the device's endurance is what decides the
campaign's shape.** The wear is a measured number rather than an argument —
the device's own figure is **read from `life_time` before the campaign and
after it** (§2.2) — but it has to be checked *before*, not after: roadmap
task 0.16 compares this estimate against the device's figure, and if the two
do not leave the device a comfortable margin, the grid is trimmed **before**
the campaign starts. The order of the trimming is fixed in advance, so that
the decision is never taken in the middle of a series:

1. the `CLOUD_DOWNLOAD` cells drop to the smallest size that still measures
   the client-side draw;
2. the control arm drops its 5 GB cells;
3. the size ladder drops to its largest rung;
4. and only then is **n** reduced — uniformly, across the cells affected —
   with the reduction and its reason recorded as a deviation.

The idle baselines are never trimmed: they are the baseline every other
number is subtracted from, they cost two runs per occupancy state per
repetition, and their volume is negligible next to the transfers.

The same budget has to fit on the device at once: dataset + ballast + the
payload in flight during the largest download. That peak is checked against
the phone's free space in Phase 0 (roadmap task 0.16) *before* the campaign
starts — a phone that cannot hold the peak gets a smaller grid, decided in
advance rather than discovered mid-run.

**The peak is checked against internal storage, because that is where the
tutorial puts the root.** `~/storage/shared` is the phone's shared internal
storage; an inserted SD card does not help it, and a dataset split across
internal and card storage would break the single-root configuration the
tutorial defines. A phone whose internal storage cannot hold the peak is a
phone whose grid gets trimmed in Phase 0 — not a phone whose dataset gets
moved to the card.

---

## 4. Environment isolation

**On the phone, the isolation is the Termux UID boundary.** The workload runs
as the Termux user and `dumpsys batterystats` attributes energy to that UID,
separating the server workload from the phone's own baseline draw. There is
no container: Android's own process accounting is the boundary, and adding a
runtime inside the phone would add energy to the measurement rather than
remove it.

| Rule | Setting |
|------|---------|
| Workload user | the Termux UID, and no other app is active |
| Device idle | `dumpsys deviceidle force-idle` before each series — for the rest of the handset; the Termux app itself is exempt while the wake lock is held (§2.2) |
| Server state | File Browser serving on `:8080`, `sshd` alive, `termux-wake-lock` held — the serving state the tutorial prescribes (§1.1) |
| Screen | off, and the phone is not touched during a window |
| Notifications | all silenced, no accounts signed in (factory state) |
| Peer isolation | the peer runs **no** benchmark of its own; it only stores, sends, and drives the two client paths (File Browser API and `rsync`) |

The peer holds no measurement instrumentation at all, so there is nothing for
it to contribute to a scope and nothing for it to pollute one. Its only
influence on the phone's numbers is the I/O it performs on the phone's behalf
— which is the workload itself — and the background load it carries, which is
why its silence is a precondition rather than a nicety. Because the peer is
also the host of the collector, the collector's own load sits inside that
record rather than outside it: the load average is read before every series,
and a series whose peer was not quiet is repeated later.

---

## 5. Data contract

### 5.1 Layout

```
data/raw/PHONE/<LEG>/<PROTOCOL>/<SCENARIO>/<label>.csv     # 1 Hz samples
data/raw/PHONE/<LEG>/<PROTOCOL>/<SCENARIO>/<label>.json    # metadata + totals + provenance
data/processed/consolidated.csv                            # one row per repetition
data/processed/cost_model.json                             # financial model output
```

`<LEG>` is `phone_serves` or `peer_serves`. Since only one device is
measured, the layout carries the leg in place of a device dimension — the
role is what distinguishes one run from another, and a run whose role is
ambiguous is a run that cannot be interpreted.

`<PROTOCOL>` is `filebrowser` or `rsync`, and it is a **new level** in the
layout: the control arm's runs are the same legs and the same scenarios as
the primary arm's, so without a protocol level the two would collide. The
level was added before any raw data existed, so no migration is needed — but
`aggregate.py` reads it from the directory path, and a run whose protocol
cannot be read from its own path is a run whose numbers cannot be attributed.

`<SCENARIO>` carries **shape and family together**, because a cell of the
grid is a pair: `MANY_SMALL_TEXT`, `MANY_SMALL_IMAGE`, `ONE_LARGE_TEXT`,
`ONE_LARGE_IMAGE`, `SIZE_LADDER`, `CLOUD_DOWNLOAD_TEXT`,
`CLOUD_DOWNLOAD_IMAGE`, `IDLE_LOW`, `IDLE_HIGH`. The two attributes are also
written separately into the metadata (`shape`, `payload_family`), so the
aggregator never has to parse a scenario name to know what a run was.

### 5.2 Sample CSV columns

`t_s, energy_j, power_w, voltage_v, current_a, temp_c, scope, source, extra`

* `scope` — what the energy number covers. For the phone: `device` (route 2
  and 3) or `plug` (route 1). Never blank.
* `source` — which sensor produced it: `usb_current_now`, `battery_current_now`,
  `batterystats`, `model`. Never blank.

### 5.3 Metadata JSON fields

`device`, `leg`, `protocol`, `role`, `scenario`, `shape`, `payload_family`,
`repetition`, `label`, `started_at`, `ended_at`, `duration_s`, `warmup_s`,
`interval_s`, `measurement_route`, `scope`, `energy_total_j`, `avg_power_w`,
`workload_cmd`, `dataset_sha256`, `dataset_reused`, `payload_bytes`,
`file_count`, `storage_occupancy_gb`, `charge_state`,
`battery_level_start`, `battery_level_end`, `wifi_state`, `screen_state`,
`flash_lifetime`, `peer_load_avg`, `cloud_tier`, `cloud_file_list`, `notes`.

Three of those fields exist because the grid grew a dimension each:

| Field | Content |
|-------|---------|
| `shape` | `many_small`, `one_large`, `size_ladder`, `idle` or `cloud_download` — the *shape* of the workload, independent of its content |
| `payload_family` | `text` or `image` — which content was moved. The two are separate fields so that no analysis ever has to parse the scenario name |
| `repetition` | the index of the repetition within its cell (1…n), so a rejected run is a *missing* repetition and not a hole in the record |

Four of those fields exist because the server under study is a configurable
daemon, and a run is only reproducible if the configuration travels with it:

| Field | Content |
|-------|---------|
| `protocol` | `filebrowser` or `rsync` — which arm the run belongs to |
| `server_software` | `filebrowser` for the primary arm; `openssh` + `rsync` for the control arm |
| `server_version` | the installed version, as reported by the daemon itself (`filebrowser version`), plus the release tag it came from |
| `server_config` | the pinned settings of §3.1 that this run was served under (transport, root, previews, command runner, database location) |

One more field records a precondition that the wake lock makes non-obvious:

| Field | Content |
|-------|---------|
| `wakelock_state` | whether the Termux wake lock was held during the window, and the device's idle state (`dumpsys deviceidle`) alongside it. A run in which the lock was not held is not the configuration the study is about, and is rejected by the quality gate rather than compared |

**Generation rule:** shell scripts never interpolate values into embedded
program code. They export `M_*` environment variables and call a Python
helper that reads them from the environment. This prevents quoting breakage
and content injection; the pattern is kept when new fields are added.

`peer_load_avg` is the peer's load average at the start of the run. It is the
only field that carries any trace of the peer into the dataset, and it exists
because the peer is doing the I/O during the measured window — not to
characterise the peer, which is not a subject of this study. Since the peer
also hosts the collector, this figure **includes the collector's own load**:
the measurement's own overhead is disclosed, not hidden.

### 5.4 Derived metrics

The definitions, the unit conventions and the full chain from sample to
figure live in [`mission.md` §5.1](mission.md#51-the-quantities-defined). This
table is the column-to-quantity mapping the aggregator writes into
`consolidated.csv`.

| Column | Quantity | Definition | Used for |
|--------|----------|------------|----------|
| `energy_total_j` | `E_tot` | `Σ P_i · Δt` over the measured window, warm-up excluded | Raw reporting |
| `delta_energy_j` | `E_Δ` | `ΔP · T`, with `ΔP = P̄ − P̄_idle` from the matching idle baseline | **The comparable metric** |
| `j_per_gb` | `E_GB` | `E_Δ / (payload_bytes / 1e9)` — decimal GB, payload bytes, never wire bytes | RQ1 |
| `j_per_file` | `E_file` | `E_Δ / file_count` | RQ1 (`MANY_SMALL`) |
| `j_per_gbit` | `E_bit` | `E_Δ / (8 · payload_bytes)` — the SI-clean companion metric | RQ1 |
| `e_per_gb_server` | `E_GB` | `E_Δ` of the leg where the phone is the **server**, per GB | RQ1, RQ3 |
| `e_per_gb_client` | `E_GB` | `E_Δ` of the leg where the phone is the **client**, per GB | RQ1, RQ3 |
| `idle_power_w` | `P̄_idle` | `E_tot / T` of an idle run at the matching occupancy | RQ2 |
| `cv_pct` | — | `100 × stdev / mean` across the repetitions of the cell (n = 100 for transfers, n = 50 for idle) | Dispersion |
| `ci95_j_per_gb` | — | the half-width of the 95 % confidence interval of the cell's `j_per_gb` mean | **Resolvability** — what this cell can distinguish from another |
| `wall_energy_j` | `E_wall` | `E_tot / η`, with `η` = A1; `η = 1` when the reading was already taken at the plug (route 1) | Cost model |
| `e_web_j_per_gb` | `E_web` | `j_per_gb` of the primary arm minus `j_per_gb` of the control arm, matched by leg, shape and size | RQ1 (control) — the web server's share of the serving energy |

---

## 6. Analysis and automation stack

| Component | Technology | Responsibility |
|-----------|-----------|----------------|
| Orchestration | **GNU Make** | One target per scenario, `LEG`/`PROTOCOL`/`FAMILY`/`DURATION`/`REPEATS`/`SIZE`/`OCCUPANCY` variables, `make setup`, `make check`, `make aggregate`, `make cost`, `make plots` |
| Aggregation | **Python 3, standard library only** | Walk `data/raw/`, validate, join, emit `consolidated.csv`; enforce the role/scope/source columns |
| Cost model | **Python 3, standard library only** | CAPEX + OPEX over 24/36/60-month horizons, break-even traffic, sensitivity analysis; **every assumption in a `DEFAULT` dict, every value overridable by CLI** |
| Plots | **Python 3 + matplotlib** (backend `Agg`) | Measured and modelled on separate panels, hatched bars for every estimated value, break-even chart |
| Validation | **No test framework** | A `make check` acceptance script (T1–T9 style) plus a **mock battery source**, validated before any real hardware is touched |

The mock-source validation is a first-class step, not a nicety: the collector
is proven against a synthetic source with a known expected error (target
< 1 %) *before* the campaign begins, so a hardware problem is never mistaken
for a code problem. The mock's shape follows the route the preflight picks.

### 6.1 Version pinning

Every component that can drift is pinned and the pin is recorded next to the
results: the phone's Android build and firmware, Termux package versions, the
**File Browser release tag and binary checksum**, the **SSH cipher and key
exchange** of the control arm, `rsync`, `openssl`, `iperf3`, `curl`, Python
version, matplotlib version, and the peer workstation's OS and package set.

The File Browser pin carries more weight than the others, because **the
upstream project appears to be archived** (its archival status is confirmed
in Phase 0, task 0.3): there is no maintenance release to absorb a behaviour
change, the installed binary may not match any published documentation, and
the API surface has to be established against the binary itself (roadmap
task 0.4) rather than read off a manual.

---

## 7. Assumption register

Every entry is a fact that is **not** measured by this experiment. It enters
the model as a named, sourced, overridable parameter. The table is copied into
the final report alongside the results.

| ID | Assumption | Default | Source | Status |
|----|-----------|---------|--------|--------|
| A1 | Charger efficiency (plug → device). `η = 1` on route 1, where the reading is already at the plug | **sourced, not measured**: the charger's model and rated output come from the device profile (roadmap task 0.1); the device-side readings only *bracket* the loss across it | charger documentation, cross-checked against the profile | open |
| A2 | Cloud PUE | verify | provider environmental report | open |
| A3 | Cloud grid carbon intensity | verify | provider environmental report | open |
| A4 | Cloud on-site efficiency (24/7 fraction) | verify | provider environmental report | open |
| A5 | Network energy per GB | to be sourced | literature / measurement | open |
| A6 | Battery replacement cost over horizon | to be sourced | market | open |
| A7 | Electricity tariff (R$/kWh) | to be sourced | user's bill | open |
| A8 | Phone battery wear from sustained server duty | to be sourced | literature | open |
| A9 | Idle floor of the phone as a client | measured | campaign | open |
| A10 | Phone flash endurance under the campaign's write volume | the device's own figure, read before and after the campaign; the **pre-flight** comparison against the campaign's ≈ 17.6 TB estimate is a gate on the grid, not a footnote | campaign, plus the device's endurance spec | open |
| A11 | Router energy (not measured; shared by every leg) | to be sourced | local / literature | open |
| A12 | The phone's Wi-Fi link speed (scheduling input only) | measured | campaign | open |
| A13 | **Cloud disk term** — energy per TB of spinning storage behind the capacity, and how it scales with drive count | to be sourced | provider report / literature | open |
| A14 | Local grid carbon intensity, if the report makes a carbon claim | to be sourced | local grid / national data | open |
| A15 | File Browser's internal overhead beyond moving bytes — its metadata writes, and preview/thumbnail generation if it were enabled | previews and thumbnails **disabled**; metadata writes included in the measured cost | the pinned configuration of §3.1 | declared by configuration |
| A16 | Transport asymmetry between the two arms — File Browser over **plain HTTP** (no cipher) against `rsync` over SSH (pinned cipher) | the pinned SSH cipher and key exchange | `sshd` configuration, recorded per run | open — a property of the comparison, stated wherever the arms appear together |
| A17 | **The providers' published energy data** — the anchor of the cloud model: the consumption and PUE each operator reports, and any per-unit-of-storage figure it publishes | the provider's latest environmental / sustainability report | provider publication, with version and date | open — re-verified at report time |
| A18 | The two payload families differ in **content only** — compression is disabled on both paths, so the text family's compressibility does not leak into the comparison | compression disabled (`rsync` without `-z`; no content encoding on the HTTP transfer) | the pinned client and server configuration | declared by configuration |

**A13 is the most sensitive assumption in the model.** It is the only term
that carries spinning disks, and the cloud's per-GB energy is dominated by
it. If the sensitivity analysis of Phase 2 shows it moving the conclusion,
that is reported as a finding about the *model's* fragility, not buried in a
footnote.

No assumption starts life as a "reasonable default" inside a calculation. A
default lives in the assumption register or in the CLI, never buried in an
arithmetic expression.

---

## 8. Key decisions and rejected alternatives

| Decision | Chosen | Rejected | Why |
|----------|--------|----------|-----|
| **Wall-side measurement** | **None — software only** | Smart plug, inline USB power meter, UPS with energy reporting | An instrument at the wall would have to stay in place across every repetition; the cost and the impracticality of that outweigh the scope it would buy. Every candidate comparison is now made within one device, which removes the scope-mismatch problem entirely rather than measuring around it. |
| **The peer** | **Instrument, never a candidate** — the workstation that runs the collection, the two client paths and the analysis | Treating it as a third candidate | It is the phone's transfer peer and the endpoint that receives the volumes; without it there is no transfer leg. Its energy is not measured, its numbers are not reported, and it contributes nothing to any comparison |
| **Repetitions** | **n = 100** for transfers, **n = 50** for idle | n = 5 | The campaign runs unattended on a real device, so the apparatus was never the limit — the *dispersion* was. At n = 100 the standard error of a cell mean falls by roughly 4.5×, which is what makes the few-percentage-point effects the study asks about resolvable at all |
| **Payload families** | **TEXT and IMAGE**, measured separately, n = 100 each | A single synthetic payload | A NAS carries two kinds of content and the server's cost may depend on which. With compression disabled on both paths, the families differ in content and in nothing else |
| **Compression** | **disabled on both paths** | `rsync`'s `-z`, or an HTTP transfer that negotiates content encoding | With compression on, the text family would be unfairly cheap under one path, and the comparison would measure gzip rather than the server |
| **The cloud's energy** | **the providers' own published energy data** | A bottom-up estimate built from first principles | The operators publish their consumption, their PUE and — where they publish it — their per-unit-of-storage figures. Those are the anchor; the terms they do not publish are modelled from the literature and marked as assumptions |
| **The server under study** | **File Browser, exactly as the tutorial configures it** | A generic file server (a bare `http.server`, an SMB share) | The study is about the energy of the NAS the user would actually run. The tutorial is normative for the stack; anything else is a recorded deviation |
| **Measured transfer path** | **File Browser's HTTP API (primary), with `rsync` over SSH as a control arm** | `rsync` alone | The control arm separates the web server's share of the serving energy from the cost of moving bytes at all — within one device, one sensor, one payload |
| **The network** | **The medium, never the subject** | Characterising links, comparing Wi-Fi against Ethernet, attributing energy to the network | The desktop peer exists only to carry bytes. Making the link a measured quantity would put the instrument's properties into the study's results. |
| Energy measurement on the phone | Three routes, chosen by preflight | The battery node alone | On mains with a full battery, charge current is ≈ 0 even under load — the obvious proxy would classify a loaded server as idle. Route 1 (plug-side) is preferred; route 2 puts the phone on the battery; route 3 keeps the campaign alive with declared coarser resolution. |
| Cloud treatment | Modelled from published figures | Excluded as "not measurable" | Excluding it would leave the comparison the user explicitly asked for unanswered. |
| Container runtime | **None** | Podman rootless, Docker | The desktop runs no benchmark of its own — it only stores and sends. A runtime inside the phone would add energy to the measurement rather than remove it. |
| Workload payload | Deterministic, SHA-256-pinned, generated once and reused | Random file generation, regenerated per run | Without a pinned payload, "1 GB" is not the same experiment in every repetition; and regenerating it would multiply the flash writes the campaign already causes. |
| Occupancy states | Created with **ballast** (written once, left in place) | Rewriting the dataset per state | Rewriting would add tens of GB of flash writes for no methodological gain. |
| Repetitions | n = 5 | n = 1 or n = 3 | n = 1 cannot produce a dispersion figure, which is half the honesty of the result. |
| Test framework | `make check` + a mock battery source | pytest | The project has no test framework and does not need one; the mock-source validation is the stronger check for this specific risk. |
| Language for this constitution | English | Portuguese | Project decision — the constitution is the document read by reviewers and tooling; code comments and terminal output remain in pt-BR. |
