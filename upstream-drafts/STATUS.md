# Direct controller mode, upstream status

## pocknix-os#166
https://github.com/shuuri-labs/pocknix-os/issues/166
Closed by the maintainer on 2026-11-09 (direct mode not accepted). They said they would revisit if either of these lands:
1. rsinput reports the paddles and bottom-right button as real buttons (ROCKNIX driver).
2. InputPlumber fixes the 4.6 output reports per input report.

Reply drafted in this session (posted or not, unconfirmed):

> Thanks for looking at this and for the detailed reasoning.
>
> I still disagree on a couple of points, for the record:
>
> - The ~1 ms is a median. p90 is 1.58 ms, which is about half of a 333 Hz report interval, and it adds to every other stage in the chain. It is not a one-time cost.
> - 4.6 output reports per source report is extra work on every input, on top of the latency. Direct mode avoids both, and the injector for the paddles adds about 0.05 ms median (C, measured above).
> - As an opt-in toggle that is off by default, it would not change the default path. Anyone who turns it on accepts that it gets less testing.
>
> That said, I understand not wanting to maintain two input paths across every board. It's your call, and I respect it.
>
> I'll go after the two upstream changes you suggested instead:
> 1. A PR to the ROCKNIX rsinput driver so the paddles and the bottom-right button show up as real buttons on the gamepad node.
> 2. An issue for InputPlumber about the 4.6 output reports per input report, with the measurements from armada-os/armada#808.
>
> I'll link both here once they're open. In the meantime I'll keep running direct mode locally on the Odin 3 and Thor, and I can share the udev rules and injector if anyone else wants to try it unsupported.

## InputPlumber
Posted as https://github.com/ShadowBlip/InputPlumber/issues/799 (body matches `inputplumber-output-report-amplification.md`).

Unverified in the issue:
- InputPlumber latency numbers (0.99 / 0.20 / 1.58 ms) taken from the pocknix-os#166 summary, not read from armada-os/armada#808.
- InputPlumber version 0.83.0 taken from Armada commit c08dbba. Check with `rpm -q inputplumber`.
- Direct-mode row for non-paddle buttons ("no userspace hop") is not measured.
- Injector row uses C run 2 only (best on every column). Run 1 was 524 events, 0.061 / 0.014 / 0.169 / 1.142 ms.

## ROCKNIX rsinput paddles
Draft in `rocknix-rsinput-paddles.md`. Not posted.
ROCKNIX/distribution has no Issues tab; README points to Discord (https://discord.gg/seTxckZjJy).
Options: post the draft in Discord, or open a PR against ROCKNIX/distribution with the driver patch.

## TODO
- Link InputPlumber#799 (and the ROCKNIX item once posted) on pocknix-os#166.
- Post or PR the ROCKNIX rsinput change.
