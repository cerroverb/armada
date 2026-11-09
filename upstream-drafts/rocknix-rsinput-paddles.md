Title: rsinput: report back paddles (and bottom-right button) on the gamepad input device

Repo: ROCKNIX/distribution

## Summary

On the AYN Odin 2 / Odin 3 and Retroid Pocket 6, the back paddles are wired to TLMM GPIOs, not the gamepad MCU. The device trees expose them as a separate `gpio-keys` node emitting `BTN_Z` (M1/left) and `BTN_C` (M2/right). InputPlumber then merges that node with the rsinput gamepad.

Without InputPlumber, SDL and Steam see the paddles on a different device from the gamepad, so they cannot be used as gamepad buttons.

## Hardware (from the device trees)

| Device | Left / M1 | Right / M2 |
|---|---|---|
| Odin 3 (cq8725s) | tlmm 3 | tlmm 7 |
| Odin 2 (qcs8550) | tlmm 57 | tlmm 58 |
| RP6 (qcs8550) | tlmm 57 | tlmm 58 |

All are `GPIO_ACTIVE_LOW`, pull-up, 15 ms debounce.

## Proposal

1. Add an optional DT property to rsinput, for example `paddle-gpios`, listing the paddle GPIOs. Request them as IRQs, debounce them, and report them as gamepad buttons on the rsinput input device (for example `BTN_TRIGGER_HAPPY1` / `BTN_TRIGGER_HAPPY2`).
2. Remove the `gpio-keys-paddles` node from boards that use the new property.
3. The bottom-right button is reported as `BTN_BACK`. SDL's Linux joystick backend has no mapping for `BTN_BACK`, so it does nothing without InputPlumber. Reporting it as a code SDL maps would fix that. Feedback on which code to use is welcome.

The default path should not change. InputPlumber's `ayn_mcu.yaml` would need its paddle mapping updated to read the new codes from the rsinput device.

## Motivation

A direct-controller setup (InputPlumber masked, raw rsinput node used by SDL/Steam) works on the Odin 3 and Thor. The paddles currently need a userspace injector that copies `gpio-keys` events into the gamepad's evdev node. Reporting them from the driver removes that injector.

Measured overhead of InputPlumber on the Odin 3: median 0.99 ms (p10 0.20, p90 1.58) from rsinput report to virtual output. Details in armada-os/armada#808.

Related: shuuri-labs/pocknix-os#166

I am willing to write and test the patch on the Odin 3 if the approach is acceptable.
