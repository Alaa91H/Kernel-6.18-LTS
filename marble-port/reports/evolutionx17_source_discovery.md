# Discovery of Evolution X 17 source for marble

## Official source

- Device page: <https://evolution-x.org/devices/marble>
- Date of inspection: 2026-08-20
- Device displayed: Xiaomi Poco F5 / Redmi Note 12 Turbo (`marble`).
- Android version displayed: 17.
- Evolution X version displayed: 12.1.
- Release date displayed: 2026-08-12.
- Build type displayed: `user`.
- Size displayed: 3.29 GB.
- Maintenance status displayed: currently maintained = yes.
- Maintainer displayed: Joey.
- XDA link shown on the page: <https://xdaforums.com/t/rom-17-marble-official-evolution-x-07-20-26.4709959/>.

## Verification notes

The official page shows a `Download ROM` button, but the text extractor does not reveal the final file link. You must extract the `href` from the DOM or open the download path and then verify the filename and SHA-256 and any accompanying files before downloading or analyzing the ROM. These data alone are not evidence that the `boot`, `vendor_boot`, `dtbo`, `vendor_dlkm`, and `system_dlkm` images match the GKI kernel.

## References

[1] <https://evolution-x.org/devices/marble> — Official Evolution X page for the marble device.
[2] <https://sourceforge.net/projects/evolution-x/files/marble/> — A general file index that appeared in the search, and has not yet been accepted as a source for Android 17 due to insufficient extracted data.

## Dynamic download link inspection

A DOM inspection on 2026-08-20 showed that the `How to install`, `Changelog`, and `Download ROM` elements are buttons without a visible `href`. The data is dynamically loaded by a Next.js page, and contains a bundle for the path `app/devices/[codename]/page`. You must extract RSC data or observe the button's execution to learn the artifact link; the UI button should not be converted into an assumed source URL.

This step was performed without downloading the ROM and without performing any flashing actions.

## Discovered Android 17 link

The official page payload yielded the following current ROM link:

<https://cdn.evolution-x.org/marble/17/EvolutionX-17.0-20260812-marble-12.1-Official.zip/download>

The name contains the device `marble` and Android `17` and date `20260812` and Evolution X version `12.1`, which is consistent with the data shown on the device page. Links for Android 16, 15, 14 and historical root references also appeared; these are treated as historical data and are not part of the Android 17 integration.

It is still necessary to verify the download link's response, obtain the published fingerprint or compute it after downloading the file, then inventory the ZIP contents without extracting or executing any untrusted files.
