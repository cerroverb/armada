Title: About 4.6 target output reports per rsinput source report (≈1 ms added latency)

Repo: ShadowBlip/InputPlumber

## Summary

On an AYN Odin 3 (rsinput gamepad, Steam Deck target), InputPlumber sends about 4.6 output reports to the virtual device for each source input report from the rsinput gamepad.

Measured latency from rsinput report to virtual output:

| Median | p10 | p90 |
|---|---|---|
| 0.99 ms | 0.20 ms | 1.58 ms |

The method and raw data are in armada-os/armada#808.

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
