# Mission

**Project:** Energy and cost comparison of personal storage servers
**Type:** Academic experiment (reproducible method, not a product)
**Status:** Constitution v3 — normative (revised 2026-11-16: the peer
workstation replaces the previous transfer peer, the repetitions are n = 100 /
n = 50, the payloads are split into text and image families, and the cloud is
anchored on the providers' published data). This document supersedes any
earlier specification; where it conflicts with anything else in the
repository, this file wins.

---

## 1. Purpose

This project answers a practical question with a measurement rather than an
opinion:

> **If I need a storage server that runs 24/7 at home, what does it actually
> cost me — in energy, in money, and in effort — when the candidates are an old
> Android phone and a cloud service?**

The two candidates are treated as *equivalent workloads on unequal hardware*.
The experiment quantifies where the energy goes, what it costs, and which
candidate wins under which constraint (budget, availability, hardware on hand).

**The server under study is a real one, not a synthetic file server.** The
phone runs the stack the user would actually deploy — Termux with OpenSSH and
the **File Browser** web file manager, exactly as configured in the
[reference tutorial](https://github.com/MarcusMix/articles/blob/master/tutorial_servidor_nas.md)
— and the measured transfer path is the one that stack serves: File Browser's
HTTP API. A second path (`rsync` over SSH) is measured as a **control**, on
the same payload and the same device, so that the energy attributable to the
web server is separable from the energy of moving bytes at all. The payloads
are **two kinds of content, measured separately** — text and images — because
a NAS carries two kinds of content and the server's cost may depend on which.

**One candidate is measured; one is modelled.** The phone is measured with
software only. The cloud is modelled from **the providers' own published
energy data** — their environmental and sustainability reports — and is never
instrumented. A peer workstation sits in the laboratory as the phone's
transfer peer and nothing more: its energy is not measured, its numbers are
not reported, and it is not a candidate.

The study is reproducible: every number in the final report must be traceable
to a raw measurement file, and any other student with the same hardware and
this method must be able to land on the same answer within the reported
variability.

## 2. The constitution

This project is governed by three files, all normative and all living in
`specs/`:

| File | Answers |
|------|---------|
| `mission.md` (this file) | *Why* the study exists, what is being asked, what is out of scope, and which methodological rules are non-negotiable. |
| `techstack.md` | *With what* the measurements are taken — hardware, instrumentation, workload tools, data contract, and the assumption register. |
| `roadmap.md` | *In what order* the work gets done, phase by phase, with entry/exit criteria. |

When a decision is needed that belongs to no file, it goes to the file whose
question it answers. When two files disagree, `mission.md` wins on scope and
method, `techstack.md` wins on instrumentation, `roadmap.md` wins on order.

The research questions themselves originate in [`AGENTS.md`](../AGENTS.md) at the
repository root. That file is the statement of intent; this constitution is the
normative expansion of it.

## 3. Research questions

Derived from `AGENTS.md` and made measurable. Two candidates: the phone
(measured) and the cloud (modelled).

### RQ1 — Energy per unit of transferred data

How much energy does the phone spend to upload and to download (a) many small
files in one batch, and (b) one very large file — at working set sizes of
**1 GB, 5 GB, 10 GB and 15 GB**?

**The question is asked twice: once over text, once over images.** A NAS
carries two kinds of content, and the server's cost may depend on which one
is moving. The two families differ in **content and in nothing else** — same
byte volume, same file counts, same schedule, same apparatus — and
compression is disabled on both paths, so the text family's compressibility
cannot leak into the comparison. Each family is measured with **n = 100**
repetitions per cell.

*Comparability requires:* the identical byte stream across every run; the
same logical operation (same file count, same sizes, same transfer protocol);
energy reported per GB and per file, not per second. Every comparison is made
**within one arm**; the only cross-arm comparison in the study is the
control's, and it exists precisely to be a difference.

**The control arm.** `rsync` over SSH is measured on a reduced matrix of the
same payloads (`techstack.md` §3.3). Its purpose is one number: how much of
the phone's per-GB energy belongs to the **web server** rather than to the act
of moving bytes. It is a within-device comparison — same phone, same sensor,
same payload, same direction — and inherits therefore the invariance to the
measurement route that every other comparison in this study has.

It is **not** a clean protocol ablation. File Browser serves plain HTTP, while
`rsync` over SSH encrypts the payload with a pinned cipher, so the control
measures *the two stacks as the tutorial configures them*, not "HTTP versus
SSH" in the abstract. Wherever the two numbers appear side by side, the report
states this in those words.

### RQ2 — Idle energy as a function of stored data

What is the phone's energy draw while **idle** (server running, no transfer in
progress), and how does it change with the amount of data actually stored on
it — **low occupancy (≤ 20 GB)** versus **high occupancy (≥ 50 GB)**?

This is the question that decides long-run cost, because a storage server is
idle most of the time. It also tests whether the idle cost tracks *capacity
used* (index size, flash wear-levelling, background maintenance) or merely
*capacity present* (device architecture).

Both occupancy states are measured with **n = 50** repetitions. The idle
baseline is subtracted from every transfer cell in the study, so its
dispersion propagates into every number reported — which is why it earns
more repetitions than a casual baseline would warrant, and why it is the one
thing the campaign's trimming order never touches.

### RQ3 — Cost-benefit: own hardware versus cloud

Is the phone cheaper than the cloud for this user's volume and access pattern,
over 24-, 36- and 60-month horizons?

| Candidate | Capital cost | Running cost | Availability |
|-----------|---------------|--------------|--------------|
| Phone | near zero (already owned) | electricity + battery wear | single point of failure, personal device |
| Cloud | recurring subscription | included in subscription | 99.9 %+ by contract, no hardware |

A cloud plan the user explicitly does not want to pay for is still the
baseline for comparison — that is the point of including it.

**The comparison is measured against modelled, and the two roles differ.** In
the own-hardware scenario the phone is the **server**; in the cloud scenario
it is the **client** (the data lives elsewhere). That asymmetry is real and is
not smoothed over: the study reports two distinct questions — the energy of
the *storage system* (phone serving vs. the cloud installation) and the energy
of the *access path* (phone receiving from the peer vs. phone receiving from
the cloud). The second is **measured against measured**: the `CLOUD_DOWNLOAD`
scenario puts the phone on the real cloud service while the collector reads
the phone's own sensor, so the phone's client-side draw per GB is an
observation rather than an assumption. The cloud's server-side energy stays
the model it always was.

### RQ4 — Advantages and disadvantages

A qualitative synthesis of the two candidates' operational properties, drawn
from the measured results and from what the hardware imposes: network role,
thermal behaviour, uptime, maintenance, data custody, and failure modes.

**The synthesis is a two-column comparison, and the peer is not one of them.**
The phone and the cloud are compared on their operational properties; the
peer workstation — which carries the bytes while the phone is measured — is an
instrument, and is never a column in any table (see [§4](#4-scope)). Every
property listed above is therefore a statement about one of the two
candidates, with the measured numbers attached where they exist and the
engineering judgement marked as such where they do not.

## 4. Scope

### In scope

- **Phone** — an old Android device running the reference stack of the
  [tutorial](https://github.com/MarcusMix/articles/blob/master/tutorial_servidor_nas.md)
  — Termux, OpenSSH and the **File Browser** web file manager — acting as a
  storage server. The **only measured candidate**.
- **Cloud** — a cloud storage service, the comparison baseline, and
  **modelled only, never measured**.

Two candidate configurations, plus the cross-cutting dimensions of transfer
shape (many-small vs one-large), **content family (text vs images)**,
working-set size (1/5/10/15 GB), storage occupancy (low vs high) and
**transfer path** (File Browser's HTTP API — primary; `rsync` over SSH —
control, on a reduced matrix).

**Fixed operating conditions.** Every measurement in this study describes the
same configuration: the phone **connected to mains**, **Wi-Fi associated**,
**screen off**, **notifications silenced**, in its serving state. These are
held *constant* rather than varied. The conditions that are hard to reproduce
are exactly the ones that would otherwise be read as device differences: radio
state on an old handset varies with chipset, carrier assist and doze
behaviour from run to run, and a phone charging while it serves draws load
plus charge current. Varying an unreproducible condition adds a spread that
masquerades as a property of the device. So there is one configuration, it is
stated in every raw file, and a result is a result *about that configuration*.

**The serving state is part of the configuration — and it is the tutorial's.**
The phone does not idle in a bare Android state: Termux holds a wake lock
(`termux-wake-lock`) so the NAS survives with the screen off, and the File
Browser daemon is listening on the LAN. That wake lock belongs to the real
24/7 configuration the study is about, so it is **held, not varied** — and
because it exempts the Termux app from doze, the earlier assumption that
`dumpsys deviceidle force-idle` alone holds the device in a quiescent state
no longer holds. The collector records the wake-lock and idle state in every
run, and the report describes the configuration in these terms: *a
mains-powered handset, screen off, Termux wake lock held, File Browser
serving, Wi-Fi associated.*

The peer workstation is under the same discipline from the other side: it is
**silent** while the phone is being measured, because it is the one doing the
I/O during the measured window. Its background load is recorded before every
series and held as low as practical — and since it is also the host of the
collector, that record includes the collector's own load, so the
measurement's overhead is disclosed rather than assumed away.

### Out of scope

- **The peer workstation, as a candidate.** It is the phone's transfer peer
  and the endpoint that receives the volumes; without it there is no transfer
  leg at all. It is an **instrument, not a candidate**: its energy is not
  measured, its numbers are not reported, it contributes nothing to any
  comparison, and no research question is asked of it.
- **Anything about the peer or the network as a research object.** The
  network is the *medium* of the transfer, never a subject of it. There is no
  link characterisation, no bandwidth or throughput comparison between
  interfaces, no Wi-Fi-versus-Ethernet measurement, and no energy term
  attributed to the network as a finding. The link's speed enters only as
  scheduling input (how long a run takes) and as a declared property of the
  phone's hardware.
- **Direct measurement of the cloud.** The cloud has no sensor we can read.
  It is modelled from **the providers' own published energy data**, and every
  figure used is registered as an assumption with its source, its version and
  its date.
- **Throughput and bandwidth as results.** The link's speed is measured once,
  as a scheduling input — how long a run takes — and never reported as a
  finding. The metric of record is energy and cost.
- **Production-grade server software.** The workloads are synthetic and
  reproducible by design, not a realistic data mix.

## 5. Non-negotiables

These are methodological rules. Breaking one invalidates the measurement, not
just the presentation.

1. **Normalize per unit of work.** Report energy per unit of work — **J/GB**
   (with **J/Gbit** as its SI-clean companion) and **J/file** — and never
   energy per unit of time alone. Wall clock may accompany a number; it never
   replaces the denominator. What each unit means, whether it belongs to the
   SI, and the fixed chain from a raw sample to a reported figure are in
   [§5.1](#51-the-quantities-defined).
2. **One dataset, byte-for-byte.** The workload payload is generated
   deterministically and pinned by SHA-256, and it is generated **once** and
   reused. "Transferring 2 GB" must mean the same bytes in every run, in every
   repetition and in every leg.
3. **Same workload, not proportional workload.** Every run receives the
   identical logical task — same file count, same file sizes, same protocol,
   in both directions and in both legs. Do not scale a run down to make it
   look comparable; the phone's disadvantage *is* the finding.
4. **Idle is a first-class measurement.** Every scenario is reported twice:
   raw (`E_tot`) and marginal (`E_Δ`, the energy the workload itself caused).
   The marginal figure comes from the difference of *powers*
   (`ΔP = P̄ − P̄_idle`), so the idle baseline and the scenario need not have
   the same duration — but they must have the same *conditions* (occupancy,
   connectivity, thermal state) or they are not a baseline for each other.
5. **Declare the scope of every measurement.** Each number carries the scope
   it covers and the sensor it came from. There is one measured device, so
   there is no cross-device scope mismatch to reconcile — but the phone's
   scope and the cloud's scope are **not** the same, and the cloud's is a
   model. Every cloud figure travels with its derivation chain; every phone
   figure travels with its measurement route. See
   [R3](#r3--the-single-scope-and-the-modelled-one).
6. **The cloud is modelled, never measured.** Any cloud energy number carries
   its derivation chain and its source — and its source is **the providers'
   own published data**, cited with version and date.
7. **n = 100 repetitions for transfers, n = 50 for idle.** Report mean,
   standard deviation, coefficient of variation and the confidence interval of
   the mean. The number is not a claim of significance in an uncontrolled
   environment; it is what makes the few-percentage-point effects the study
   asks about *distinguishable at all* — at n = 5 the standard error of a cell
   mean is of the same order as the effects themselves. The dispersion is
   still reported honestly, and no significance is claimed beyond what the
   intervals support (see [R7](#r7--what-n-buys-resolvability)).
8. **The wall-side truth is disclosed, not assumed.** The phone's sensor
   reads the device, not the plug. Charger losses, standby behaviour and the
   fact that a plugged-in phone charges rather than runs are stated explicitly
   wherever a phone number is converted into money or compared with the cloud.
   The route by which the phone was measured (plug-side current, battery
   current, or batterystats) is recorded in every raw file, because it
   changes the absolute numbers — though not the within-device comparisons.
9. **A quiet environment is a precondition.** The peer workstation is the
   phone's transfer peer and does the I/O while the phone is being measured,
   so its background load is recorded before every series and held as low as
   practical. It is also the host of the collector, so that record includes
   the collector's own load. No firmware updates, at any point, for the whole
   project.
10. **Every number is traceable.** Each figure in the report cites the raw
    file(s) it came from.
11. **The report shows the arithmetic in summary; the spec holds the full
    derivation.** The report states what was computed, from which raw files,
    and to what precision — and points to the larger spec file, where the
    complete chain from a raw sample to a reported figure is written out. A
    reader who wants to check the arithmetic finds it; a reader who wants the
    result is not made to read the derivation first.

---

### 5.1 The quantities, defined

This section fixes the vocabulary of the study: what each quantity is, how it
is computed from the raw samples, and which relations the conclusions rest
on. Nothing in the report may use a quantity that is not defined here.

#### 5.1.1 What each unit is — and what the SI does and does not cover

| Quantity | Unit | Status in the SI | Notes |
|----------|------|------------------|-------|
| Power `P` | **W** (watt) | SI derived unit, coherent (`kg·m²·s⁻³`) | read from the device's native sensor |
| Energy `E` | **J** (joule) | SI derived unit, coherent (`kg·m²·s⁻²`) | `1 J = 1 W·s` |
| Payload volume `B` | **byte** | **Not an SI unit** — defined by IEC 80000-13 | the count of payload delivered, *not* the bytes on the wire |
| `GB` | `10⁹` bytes | **Not an SI unit** — IEC 80000-13 decimal prefix | `GiB = 2³⁰ B`, which is **7.37 % larger** |
| Energy per GB `E_GB` | **J/GB** | **Not an SI unit** — see below | the headline metric |
| Specific energy | **J/kg** | SI derived unit, coherent | the shape `J/GB` *would* have if the denominator were a mass |
| Energy per bit `E_bit` | **J/bit** | Coherent derived unit | a bit is a dimensionless count, so the quotient is legitimate |
| Energy per terabyte `E_TB` | **Wh/TB** | `Wh` is a unit *accepted for use with the SI* | the unit tariffs and storage quotes use |

**Does J/GB exist in the SI? No — for two separate reasons, and the report
must respect both.**

1. **The denominator is not an SI unit.** The byte is not part of the SI.
   `GB` is a decimal prefix applied to the byte under **IEC 80000-13**, the
   same standard that defines the binary set `KiB`…`EiB` as *distinct* from
   the decimal `kB`…`EB`. A quotient whose numerator is an SI unit and whose
   denominator is not is a derived unit used in practice, but it is neither an
   SI unit nor coherent.
2. **A quotient across dimensions is not an SI unit.** The SI Brochure is
   explicit that units of one dimension divided by units of another — here
   energy ÷ information — are not SI units. Such quantities are perfectly
   legitimate (specific energy, `J/kg`, is one of them, and it *is* coherent),
   but they live outside the SI.

What would sit inside the SI: `J/kg` is a coherent SI derived unit, and
because a bit is a dimensionless count, `J/bit` and `J/Gbit` are coherent too.

**What the experiment does.** The headline metric is **J/GB**, because that is
what a reader of a storage-energy comparison expects and what costs are
quoted in. Every figure therefore states, next to the number, that the
denominator is **payload bytes, decimal (`1 GB = 10⁹ bytes`)** — not wire
bytes, not `GiB`. **J/Gbit** is reported alongside as the SI-clean companion
metric, and **Wh/TB** on the cost side.

The decimal/binary choice is not pedantry. `GiB` is 7.37 % larger than `GB`,
and 7 % is the same order as the dispersion the campaign is trying to
measure. A metric whose denominator is ambiguous by 7 % cannot support a
conclusion about a 10 % difference.

#### 5.1.2 From a raw sample to a reported number

| Symbol | Quantity | Unit |
|--------|----------|------|
| `P_i` | instantaneous power, sample *i* | W |
| `Δt` | sampling interval (1 s) | s |
| `n`, `T` | samples in the measured window, and its duration (`T = n·Δt`, warm-up excluded) | —, s |
| `P̄` | mean power of a run | W |
| `P̄_idle` | mean power of the matching idle baseline | W |
| `B`, `N` | payload bytes transferred, files transferred | byte, — |
| `η` | wall-side conversion efficiency (the charger, between the plug and the device) | — |
| `tariff` | price of electricity | currency/kWh |
| `T_h`, `V` | cost horizon in months, data moved per year | months, GB |
| `role` | the phone's role **by data direction**: `server` (it holds the payload and transmits it) or `client` (it acquires the payload from an external source) | — |
| `leg` | which transfer a run belongs to: `phone_serves` or `peer_serves` | — |
| `protocol` | the measured transfer path: `filebrowser` (primary) or `rsync` (control) | — |
| `family` | the content family of a run: `text` or `image` | — |
| `R` | the number of repetitions of a cell: **R = 100** for transfers, **R = 50** for idle | — |
| `s` | standard deviation of a cell's `E_GB` across its repetitions | J/GB |
| `measurement_route` | how the phone was measured (see `techstack.md` §2.2) | — |
| `E_device` | the phone's energy on its own scope, by one route | J |
| `E_facility` | the cloud's modelled energy, installation scope | J |

**`role` is a property of the data flow, not of the protocol's client/server
relationship.** File Browser is an HTTP *server* on the phone in **both**
directions: in the inbound leg the peer uploads to it and the phone's daemon
receives and writes the payload. The role label therefore describes what the
phone does with the data — holds it and sends it (`server`), or acquires it
from somewhere else (`client`) — and it is what RQ3's two questions (storage
system vs access path) are built on. `leg` names the same thing by direction;
`protocol` says which software carried the bytes.

**In this grid, the leg and the direction are the same axis.** `phone_serves`
**is** the download direction (the phone serves a download) and `peer_serves`
**is** the upload direction (the phone receives an upload). The direction is
therefore not an independent axis of the matrix, and a run is identified by
*(leg, protocol, family, scenario, size)* — see `techstack.md` §3.3.

**The route affects absolute numbers only.** Every comparison the study draws
— many-small vs one-large, 1 vs 5 vs 10 vs 15 GB, upload vs download, idle at
low vs high occupancy — is a ratio or a difference **within the same device
and the same sensor**, and is therefore invariant to the measurement route.
Only the conversion of an absolute energy into currency depends on it. The
report states this, because it means the study's main findings survive even
if the route has to be re-chosen.

**Step 1 — total energy of the run.**

```
E_tot = Σ(i = 1..n)  P_i · Δt          [J]
P̄     = E_tot / T                      [W]
```

**Step 2 — the matching idle baseline.** Every scenario run is paired with an
idle run on the same device, at the same storage occupancy, with the same
connectivity and in the same ambient window. Because step 3 compares *powers*,
the two runs need not have the same duration.

**Step 3 — the marginal (load-induced) energy.**

```
ΔP  = P̄ − P̄_idle                      [W]
E_Δ  = ΔP · T                           [J]
```

`E_Δ` is the energy attributable to the workload — the quantity that
normalizes per unit of work. `E_tot` is reported beside it, never instead of
it.

**Step 4 — normalization.**

```
E_GB   = E_Δ / (B / 10⁹)               [J/GB]     (decimal gigabyte)
E_file = E_Δ / N                       [J/file]
E_bit  = E_Δ / (8 · B)                 [J/bit]
E_TB   = (E_Δ / 3600) / (B / 10¹²)     [Wh/TB]
```

**Step 5 — dispersion, and what it buys.**

```
SE(Ē_GB) = s(E_GB) / √R                     [J/GB]
CI95(Ē_GB) = Ē_GB ± 1.96 · SE(Ē_GB)        [J/GB]
Δ_se      = √( SE²(Ē_GB,A) + SE²(Ē_GB,B) )  [J/GB]   (two cells)
```

Two cells are reported as **distinguishable** when their 95 % intervals do
not overlap, or — the stricter test, used throughout — when
`|Ē_GB,A − Ē_GB,B| > 1.96 · Δ_se`. Where they are not distinguishable, the
report says so in those words and quotes both intervals. This is the whole
point of R = 100: at R = 5 the standard error of a cell mean is of the same
order as the few-percentage-point effects the study asks about, and the
comparison would be a matter of opinion rather than of measurement.

**Step 6 — wall-side conversion (cost only).**

```
P̄_wall = P̄ / η                        [W]
E_wall = E_tot / η                     [J]
C_energy = (E_wall / 3.6e6) · tariff   [currency]      (1 kWh = 3.6e6 J)
```

**Step 7 — horizon cost and break-even.** For a horizon of `T_h` months and
an annual volume `V` GB:

```
P̄_idle,wall = P̄_idle / η                   [W]
C_idle(T_h) = [ P̄_idle,wall × 8760 × (T_h/12) ] / 1000 × tariff
c_own       = (E_GB / η) / 3.6e6 × tariff            [currency/GB]
C_own(T_h, V) = CAPEX + C_idle(T_h) + V · c_own + C_batt(T_h)
C_cloud(T_h, V) = Sub(T_h) + V · c_cloud

V* = [ C_cloud(T_h, 0) − CAPEX − C_idle(T_h) − C_batt(T_h) ] / (c_cloud − c_own)
```

`c_own` is the phone serving (the `phone_serves` leg's `E_GB`, **primary
arm** — the File Browser path, because that is the server the user would
actually run); `c_cloud` is the cloud's modelled per-GB cost plus the phone's
own draw as the client (the `peer_serves` leg's `E_GB`, likewise from the
primary arm). `CAPEX` is zero for a phone already in hand; `C_batt` is the
battery replacement over the horizon (A6); `Sub` is the cloud subscription
(A-assumption, not measured).

A positive `V*` requires `c_cloud > c_own`. When it does not hold, the
own-hardware side is cheaper at *every* volume and the break-even is not a
volume but a statement about fixed costs — which is itself an answer to RQ3.

#### 5.1.3 The relations the conclusions rest on

##### R1 — Idle versus transfer, annually

```
E_year = P̄_idle × 8760  +  ΔP × t_active
```

The standing share `P̄_idle × 8760 / E_year` is expected to dominate for a
storage server. The campaign **tests** that expectation; it does not assume
it. It is the reason RQ2 carries as much weight as RQ1.

##### R2 — Per-file overhead versus per-byte cost

```
E_tot(N, B) = E_byte(B)  +  N · E_overhead
E_GB(N)     = E_byte_per_GB  +  N · E_overhead / 10⁹
```

The second term grows linearly with the file count; the first does not. The
same volume moved as 10 000 small files and as one large file therefore
differs by `N · E_overhead / 10⁹` in `E_GB`, and `E_file` shows the same
effect directly. If `E_GB(MANY_SMALL)` comes out equal to `E_GB(ONE_LARGE)`
inside the measured dispersion, the per-file overhead is **below the noise
floor** — which is a finding, not a null result.

To extract `E_overhead` rather than merely observe it, the campaign also
runs a **file-size ladder at a fixed total volume** (4 KiB, 64 KiB and 1 MiB
per file, 5 GB in each case): `E_GB` is then linear in `N`, and the slope is
`E_overhead / 10⁹`.

**In the primary arm, `E_overhead` includes the server's own per-file work** —
File Browser's metadata write for each file, on top of the protocol framing
and the flash write. That is not a contamination of the measurement; it *is*
the measurement, because a NAS that is slow with many small files is exactly
the failure mode the workload is designed to expose. The control arm measures
the same slope through a plain SSH copy, and the two slopes together separate
"the cost of a file" from "the cost of this server's handling of a file".

##### R3 — The single scope, and the modelled one

```
PHONE:  E_device  = the phone's own sensor, by one of three routes
CLOUD:  E_facility = facility_energy/GB ÷ PUE
                     + network_energy/GB
                     + client_device_energy/GB
```

There is one measured device, so there is no cross-device scope mismatch to
reconcile and no error-bound rule to apply between two sensors: the phone's
absolute numbers stand on their own scope, and the cloud's stand on the
installation's scope.

What the study must not do is place them on the same axis without saying so.
The cloud's figure covers a datacenter's worth of hardware, its share of the
grid, and the network; the phone's figure covers one handset, minus the
charger loss between plug and device. The comparison is therefore made
**explicitly asymmetric**: each side carries its own derivation, and the
report states which terms are measured and which are modelled — which, for
the cloud, is *all* of them.

##### R4 — The occupancy slope

```
P̄_idle(B_stored) = P_base + k · B_stored
k = ( P̄_idle,high − P̄_idle,low ) / ( B_high − B_low )
```

The finding is whether `k` is distinguishable from zero. It counts only if
`| P̄_idle,high − P̄_idle,low |` exceeds the pooled dispersion of the n = 5
repetitions. The difference and the pooled CV are both reported, and no
statistical significance is claimed beyond that comparison.

##### R5 — The network is the medium, never the subject

```
E_Δ,server = E_bytes + E_per_file + E_net
```

The phone's radio draw is physically part of its consumption, so the third
term exists whether or not it is named. The study **does not turn it into a
finding**: there is no link characterisation, no interface comparison, and no
energy attributed to the network as a result. The link enters only as
scheduling input (how long a 15 GB leg takes on this phone's Wi-Fi) and as a
declared property of the hardware being studied.

This is a deliberate narrowing. The peer's Ethernet link, the router and
the switch are all outside the measurement, and the study says so rather than
letting a reader assume they were accounted for.

##### R6 — The web server's share of the serving energy

```
E_web = E_GB(filebrowser, phone_serves) − E_GB(rsync, phone_serves)   [J/GB]
```

The control arm's single number: how much of the phone's per-GB serving
energy belongs to the **web server** rather than to the act of moving bytes.
It is a difference of two marginal energies measured on the same phone, by the
same sensor, over the same payload, in the same direction — so it inherits
the route-invariance of §5.1.2 and is commensurable with every other number
in the study.

It is **not** a protocol ablation. File Browser serves plain HTTP; `rsync`
over SSH encrypts the payload with a pinned cipher. `E_web` is the
difference between the two stacks **as the tutorial configures them**, and it
carries the cipher work that the plain-HTTP stack does not do. The report
states this wherever the two arms are shown side by side, and the SSH cipher
is pinned precisely so that this number is reproducible.

##### R7 — What n buys: resolvability

```
SE(Ē_GB)      = s / √R                             [J/GB]
SE(Δ)          = √( SE²(A) + SE²(B) )               [J/GB]
distinguishable  ⟺  |Ē_GB,A − Ē_GB,B| > 1.96 · SE(Δ)
```

The study's effects are small by construction: the difference between
`MANY_SMALL` and `ONE_LARGE` at the same volume, the difference between the
two content families, the web server's share of the serving energy, the
difference between `GB` and `GiB` (7.37 %). At R = 5, the standard error of a
cell mean is of the same order as these effects, and the comparison would be
an opinion. At R = 100 it is roughly a fifth of them; at R = 50, for the
idle baselines, it is about a seventh.

R = 100 therefore does not buy "more confidence" in the abstract — it buys
**the ability to tell two cells apart at all**. The relation is also the
discipline the report owes the reader: a difference that fails the test is
reported as *not distinguishable*, with both intervals quoted, and not
quietly rounded into a conclusion.

---

## 6. Success criteria

The experiment is complete when:

- [ ] All four research questions are answered with numbers, not opinions.
- [ ] Every cell of the matrix has its full complement of repetitions —
      **n = 100** for the transfer cells, **n = 50** for the idle baselines —
      with valid raw data, or a documented reason why it does not (and an
      honest statement of what can and cannot be concluded).
- [ ] Both content families were measured for every transfer cell that is
      reported, or the gap is documented cell by cell.
- [ ] The dataset is deterministic and its SHA-256 is recorded — for both
      families.
- [ ] Idle baselines exist for both occupancy states of the phone, n = 50
      each.
- [ ] The control arm is complete — or has a documented, explained gap — over
      the same payload and in the same direction as the arm it is compared
      against.
- [ ] The File Browser version and configuration are pinned and recorded,
      including the features that were deliberately disabled.
- [ ] The device profile is on file — processor, memory, storage, battery,
      charger, thermal zones and sensor inventory — collected by the scripted
      probe of roadmap task 0.1.
- [ ] The measurement route is chosen by preflight, validated, and recorded in
      every raw file.
- [ ] The cost model runs entirely from parameterized assumptions, with no
      hard-coded prices buried in code, and every cloud figure resolves to a
      provider publication with its version and date.
- [ ] Every reported number resolves to a file under `data/raw/`.
- [ ] The limitations of the study are stated in full, alongside the results.

## 7. Deliverables

| Deliverable | Description |
|-------------|-------------|
| Device profile | The scripted base-information probe and its output — processor, memory, storage, battery, charger, thermal zones, sensor inventory |
| Raw measurements | Timestamped 1 Hz samples + metadata, one directory per leg/protocol/scenario/repetition |
| Consolidated dataset | One row per repetition, with role, scope and source attached to every energy value |
| Energy report | ΔE per GB / per file per scenario and family, with dispersion, confidence intervals and scope labels |
| Protocol control | The `rsync`-over-SSH control arm, and the web server's share of the serving energy (`E_web`) |
| Cost model | CAPEX + OPEX over 24/36/60-month horizons, plus break-even traffic volume, with every cloud figure traced to a provider publication |
| Comparison | RQ1–RQ4 answered, with the qualitative synthesis of RQ4 |
| Limitations | Explicit list of what this experiment cannot claim |

**How the report shows the arithmetic.** The report is written for a reader
who wants the result: each figure arrives with the raw files it came from, the
precision it carries, and — where it matters — the test it passed. The
**complete derivation** — every quantity, every unit convention, every step
from a raw sample to a reported figure — lives in this specification, in
[§5.1](#51-the-quantities-defined), and the report points to it by section
wherever a figure is presented. The two are not duplicates of each other:
the spec is the method, the report is the finding, and the report says which
part of the method produced each number.

## 8. Assumptions that are *not* part of the method

These change as facts arrive and are tracked in the assumption register in
`techstack.md`; they never enter the method itself:

- Charger efficiency — the loss between the wall and the device. A plug-side
  reading covers everything downstream of it, so only this segment remains an
  assumption, and only when the phone is measured on the battery.
- Ambient temperature and cooling noise, both outdoor-adjacent and inside a
  rack.
- The user's actual data-transfer mix and frequency — the synthetic workload
  is a controlled proxy, not a prediction of personal use.
- Cloud-side efficiency at the time of the report, which is a moving target,
  and which includes the only rotating disks in the entire study.
