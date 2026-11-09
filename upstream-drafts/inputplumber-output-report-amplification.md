Title: About 4.6 target output reports per rsinput source report (≈1 ms added latency)

Repo: ShadowBlip/InputPlumber

## Summary

On an AYN Odin 3 (rsinput gamepad, Steam Deck target), InputPlumber sends about 4.6 output reports to the virtual device for each source input report from the rsinput gamepad.

Measured latency from rsinput report to virtual output:

| Median | p10 | p90 |
|---|---|---|
| 0.99 ms | 0.20 ms | 1.58 ms |

The method and raw data are in armada-os/armada#808.

## Comparison with direct mode (InputPlumber masked)

With InputPlumber masked, SDL and Steam read the raw rsinput evdev node directly. Gamepad buttons and sticks go through no userspace process, so the hop measured above is gone.

The back paddles sit on a separate `gpio-keys` node, so in direct mode a small C injector copies them into the gamepad's evdev node. Measured from the kernel paddle event timestamp to the injected event timestamp, at realtime priority 50:

| Path | Events | Median | p10 | p90 | Max |
|---|---|---|---|---|---|
| InputPlumber (rsinput report to virtual output) | | 0.99 ms | 0.20 ms | 1.58 ms | |
| Direct mode, C injector, run 1 (paddles only) | 524 | 0.061 ms | 0.014 ms | 0.169 ms | 1.142 ms |
| Direct mode, C injector, run 2 (paddles only) | 511 | 0.046 ms | 0.013 ms | 0.122 ms | 0.577 ms |
| Direct mode, all other buttons and sticks | | no userspace hop | | | |

At the median, the injector adds about 1/16 to 1/20 of InputPlumber's added latency, and that only applies to the paddles.

## Expected

About one output report per changed source report, or batching per source report, so a single rsinput frame that changes several axes/buttons produces one target report.

## Environment

- Device: AYN Odin 3 (SM8750), rsinput driver
- InputPlumber: 0.83.0 with distro patches (armada)
- Target: Steam Deck

## Questions

- Is one target report per source event code (instead of per source report / `SYN_REPORT`) intended?
- Would a patch that coalesces events up to `SYN_REPORT` before writing the target report be accepted?

Related: shuuri-labs/pocknix-os#166
