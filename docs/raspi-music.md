# Raspberry music destination

The Raspberry Pi is a lightweight remote `mpv` destination. The Mac controls it
over the `raspi` SSH alias; no application server or persistent player daemon is
required.

```text
Raycast or raspi-music -> SSH -> mpv -> Raspberry analog headphone output
```

## Mac commands

Install the console command and Raycast entries:

```bash
./install/raspi-music.sh install
```

The public console interface is:

```bash
raspi-music play 'https://www.youtube.com/watch?v=VIDEO_ID'
raspi-music stop
raspi-music status
raspi-music logs
```

`play` accepts one HTTP or HTTPS URL. It stops an existing remote `mpv`, waits up
to two seconds, and starts the replacement in the background. Playback logs are
kept at `/tmp/mpv.log` on the Raspberry.

The new Raycast commands are:

- Play House on Raspberry
- Play Deep Techno on Raspberry
- Stop Music on Raspberry

The original local music scripts are unchanged.

## Raspberry configuration

The host runs Raspbian 13 on ARMv6. `mpv` and QuickJS come from Raspbian, while
the architecture-independent official `yt-dlp` executable is installed at
`/usr/local/bin/yt-dlp`. The release checksum is verified during the initial
installation.

The checked-in `mpv.conf` selects audio only and pins output to the analog jack:

```text
install/raspi-music/mpv.conf
```

It is installed remotely as `~/.config/mpv/mpv.conf`.

## yt-dlp updates

`yt-dlp-update.timer` runs daily with a random delay of up to six hours and is
persistent across downtime. It invokes the built-in updater for the standalone
official release.

```bash
ssh raspi 'systemctl list-timers yt-dlp-update.timer'
ssh raspi 'sudo systemctl start yt-dlp-update.service'
ssh raspi 'sudo journalctl -u yt-dlp-update.service -n 50 --no-pager'
```

The unit sources are stored in `install/raspi-music/` and installed under
`/etc/systemd/system/` on the Raspberry.

## Known preset status

As of 2026-08-02, the Deep Techno URL resolves and plays successfully. The House
URL retained from the local script is an ended live-stream recording that
YouTube reports as unavailable. Replace that wrapper URL when a successor stream
is selected; generic console playback is unaffected.

## Uninstall local entry points

```bash
./install/raspi-music.sh uninstall
```

This removes only links owned by the Raspberry music installer. It does not
change the Raspberry or remove the original local playback scripts.
