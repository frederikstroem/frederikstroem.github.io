---
layout: post
is_post: true

title: SOUNDBOKS with Spotify Connect using Raspotify and Home Assistant
---

*I dedicate this journal post to the public domain under the [CC0 1.0 Universal (CC0 1.0) Public Domain Dedication](https://creativecommons.org/publicdomain/zero/1.0/). I waive all rights to the work worldwide under copyright law, including all related and neighboring rights, to the extent allowed by law.*

![SOUNDBOKS 2 connected to a Raspberry Pi 3 running Raspotify](https://cdn.jsdelivr.net/gh/frederikstroem/frederikstroem.github.io/assets/img/2024-06-14-soundboks-with-spotify-connect.jpg)

I have lately been thinking about creating some journal posts about some of my hobby projects and sharing some of the things I have learned. I spend a lot of my time on different technology projects, and this is one of the simpler ones I have been working on lately. Anyway, here are some thoughts on creating a Spotify Connect speaker using a Raspberry Pi and a simple AUX-connected speaker.

I have a SOUNDBOKS 2 speaker that I wanted to use as a Spotify Connect speaker. I wanted it to power on when I started playing music and power off when I stopped playing music. I had an old Raspberry Pi 3 lying around, so I decided to use that as the controller for the speaker.

Since I wanted the speaker system to act like an appliance, I wanted to use NixOS to ensure that the system was reproducible and easy to manage. [Spotifyd](https://github.com/Spotifyd/spotifyd) is in the Nixpkgs collection, so that seemed like a good starting point. To make SD card images for the Raspberry Pi, I used [NixOS Docker-based SD image builder](https://github.com/Robertof/nixos-docker-sd-image-builder). I encountered some issues with the audio output when using NixOS, so I decided to use a Raspberry Pi OS image instead. But I might revisit transitioning to NixOS in the future.

I got [Spotifyd](https://github.com/Spotifyd/spotifyd) working on the Raspberry Pi OS image. However, after some testing, I found that [Raspotify](https://github.com/dtcooper/raspotify) was a better fit for my use case. [Raspotify](https://github.com/dtcooper/raspotify) is a fork of [librespot](https://github.com/librespot-org/librespot).

I also discovered an interesting thing about the SOUNDBOKS 2 firmware while working on this project. After turning on the speaker, it will only switch from the standard Bluetooth mode to the AUX mode if it detects an audio signal playing at around 60% volume from Raspotify (`LIBRESPOT_NORMALISATION_THRESHOLD="-4.0"` might also influence this, but I have not tested this). After switching to the AUX mode, the speaker will stay in AUX mode until it is powered off. This means that the speaker will not switch back to the Bluetooth mode if the volume is turned down or the audio signal stops.

With this out of the way, I will now explain how I set up the system. As always, I work iteratively, so the setup is definitely not perfect, and I want to improve it in the future. However, I think discrete incremental improvements to a working system are a good way to work.

I created an Ansible role to deploy the system. The role installs Raspotify, copies a configuration file, and copies a script that listens to events from Raspotify and sends webhooks to Home Assistant. The relevant source code is listed here:

**/ansible/roles/soundboks/files/conf:**
```shell
# /etc/raspotify/conf -- Arguments/configuration for librespot

# A non-exhaustive list of librespot options and flags.

# Please see https://github.com/dtcooper/raspotify/wiki &
# https://github.com/librespot-org/librespot/wiki/Options
# for configuration details and a full list of options and flags.

# You can also find a full list with `librespot -h`.

# To avoid name collisions environment variables must be prepended with
# `LIBRESPOT_`, so option/flag `foo-bar` becomes `LIBRESPOT_FOO_BAR`.

# Invalid environment variables will be ignored.

# Raspotify defaults may vary from librespot defaults.
# Commenting out the environment variable will fallback to librespot's default
# unless otherwise noted.

# Flags are either on (uncommented) or off (commented),
# their values are otherwise not evaluated (but the "=" is still needed).

# Only log warning and error messages.
LIBRESPOT_QUIET=

# Automatically play similar songs when your music ends.
LIBRESPOT_AUTOPLAY=

# Disable caching of the audio data.
# Enabling audio data caching can take up a lot of space
# if you don't limit the cache size with LIBRESPOT_CACHE_SIZE_LIMIT.
# It can also wear out your Micro SD card. You have been warned.
LIBRESPOT_DISABLE_AUDIO_CACHE=

# Disable caching of credentials.
# Caching of credentials is not necessary so long as
# LIBRESPOT_DISABLE_DISCOVERY is not set.
LIBRESPOT_DISABLE_CREDENTIAL_CACHE=

# Play all tracks at approximately the same apparent volume.
LIBRESPOT_ENABLE_VOLUME_NORMALISATION=

# Enable verbose log output.
#LIBRESPOT_VERBOSE=

# Disable zeroconf discovery mode.
#LIBRESPOT_DISABLE_DISCOVERY=

# Options will fallback to their defaults if commented out,
# otherwise they must have a valid value.

# Device name.
# Raspotify defaults to "raspotify (*hostname)".
# Librespot defaults to "Librespot".
#LIBRESPOT_NAME="Librespot"
LIBRESPOT_NAME="SOUNDBOKS"

# Bitrate (kbps) {96|160|320}. Defaults to 160.
#LIBRESPOT_BITRATE="160"
LIBRESPOT_BITRATE="320"

# Output format {F64|F32|S32|S24|S24_3|S16}. Defaults to S16.
#LIBRESPOT_FORMAT="S16"

# Sample Rate to Resample to {44.1kHz|48kHz|88.2kHz|96kHz}.
# Defaults to 44.1kHz meaning no resampling.
# The option does not exist in upstream librespot.
# DO NOT file a bug with librespot about this.
#LIBRESPOT_SAMPLE_RATE="44.1kHz"

# Interpolation Quality to use if Resampling. {Low|Medium|High}.
# Defaults to Low.
# The option does not exist in upstream librespot.
# DO NOT file a bug with librespot about this.
#LIBRESPOT_INTERPOLATION_QUALITY="Low"

# Displayed device type. Defaults to speaker.
#LIBRESPOT_DEVICE_TYPE="speaker"

# Limits the size of the cache for audio files.
# It's possible to use suffixes like K, M or G, e.g. 16G for example.
# Highly advised if audio caching isn't disabled. Otherwise the cache
# size is only limited by disk space.
#LIBRESPOT_CACHE_SIZE_LIMIT=""

# Audio backend to use, alsa or pulseaudio. Defaults to alsa.
#LIBRESPOT_BACKEND="alsa"

# Username used to sign in with.
# Credentials are not required if LIBRESPOT_DISABLE_DISCOVERY is not set.
#LIBRESPOT_USERNAME=""

# Password used to sign in with.
#LIBRESPOT_PASSWORD=""

# Audio device to use, use `librespot --device ?` to list options.
# Defaults to the system's default.
#LIBRESPOT_DEVICE="default"

# Initial volume in % from 0 - 100.
# Defaults to 50 For the alsa mixer: the current volume.
#LIBRESPOT_INITIAL_VOLUME="50"
LIBRESPOT_INITIAL_VOLUME="60"

# Volume control scale type {cubic|fixed|linear|log}.
# Defaults to log.
#LIBRESPOT_VOLUME_CTRL="log"

# Range of the volume control (dB) from 0.0 to 100.0.
# Default for softvol: 60.0.
# For the alsa mixer: what the control supports.
#LIBRESPOT_VOLUME_RANGE="60.0"

# Pregain (dB) applied by volume normalisation from -10.0 to 10.0.
# Defaults to 0.0.
#LIBRESPOT_NORMALISATION_PREGAIN="0.0"

# Threshold (dBFS) at which point the dynamic limiter engages
# to prevent clipping from 0.0 to -10.0.
# Defaults to -2.0.
#LIBRESPOT_NORMALISATION_THRESHOLD="-2.0"
LIBRESPOT_NORMALISATION_THRESHOLD="-4.0"

# The port the internal server advertises over zeroconf 1 - 65535.
# Ports <= 1024 may require root privileges.
#LIBRESPOT_ZEROCONF_PORT=""

# HTTP proxy to use when connecting.
#LIBRESPOT_PROXY=""

# ### This is NOT a librespot option or flag. ###
# This modifies the behavior of the Raspotify service.
# If you have issues with this option DO NOT file a bug with librespot.
#
# By default librespot "download buffers" tracks, meaning that it downloads
# the tracks to disk and plays them from the disk and then deletes them when
# the track is over. This practice is very common, many other audio frameworks
# and players do the exact same thing as a disk based tmp cache is easy to use
# and very resilient. That being said there may be cases where a user may want
# to minimize disk read/writes.
#
# Commenting this out will cause librespot to use a tmpfs so that provided there
# is enough RAM to hold the track nothing is written to disk but instead to a tmpfs.
# See https://github.com/dtcooper/raspotify/discussions/567
# And https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html
TMPDIR=/tmp

# The path to a script that gets run when one of librespot's events is triggered.
# Script name passed to the --onevent flag, make sure raspotify has permissons call this script or you'll get an error.
# See: https://github.com/dtcooper/raspotify/wiki/How-To:-Listen-To-Librespot-Events#available-events-and-variables
LIBRESPOT_ONEVENT="/usr/local/bin/librespot_onevent_hook"
```

**/ansible/roles/soundboks/files/librespot_onevent_hook:**
```bash
#!/bin/bash

# https://github.com/dtcooper/raspotify/wiki/How-To:-Listen-To-Librespot-Events
# https://github.com/JasonLG1979/librespot/blob/raspotify/src/player_event_handler.rs

# Webhooks
WEBHOOK_ON="http://192.168.0.100:8123/api/webhook/soundboks-hook-on-fFIwiC9Ntieqwb1EI5tRwy4Y"
WEBHOOK_OFF="http://192.168.0.100:8123/api/webhook/soundboks-hook-off-QuTX0IpJxDsrdALIrpA1B9Wx"

# Define arrays for on and off events
ON_EVENTS=("started" "playing" "preloading" "volume_set" "changed")
OFF_EVENTS=("stopped" "paused")

# Function to call webhook with a PUT request
call_webhook() {
    local url=$1
    curl -X PUT "$url"
}

# Function to check if an event is in a given array
is_event_in_array() {
    local event=$1
    shift
    local arr=("$@")
    for e in "${arr[@]}"; do
        if [[ "$e" == "$event" ]]; then
            return 0
        fi
    done
    return 1
}

# Main logic
if [[ -z "$PLAYER_EVENT" ]]; then
    echo "No PLAYER_EVENT environment variable found."
    exit 1
fi

if is_event_in_array "$PLAYER_EVENT" "${ON_EVENTS[@]}"; then
    echo "On event: $PLAYER_EVENT"
    call_webhook "$WEBHOOK_ON"
elif is_event_in_array "$PLAYER_EVENT" "${OFF_EVENTS[@]}"; then
    echo "Off event: $PLAYER_EVENT"
    call_webhook "$WEBHOOK_OFF"
else
    echo "Unknown event: $PLAYER_EVENT"
    exit 1
fi
```

**/ansible/roles/soundboks/tasks/main.yml:**
```yaml
---
- include_tasks:
    file: update.yml
    apply:
      tags:
        - update
  tags:
    - update

- include_tasks:
    file: init.yml
    apply:
      tags:
        - init
  tags:
    - init

- include_tasks:
    file: apply.yml
    apply:
      tags:
        - apply
  tags:
    - apply
```

**/ansible/roles/soundboks/tasks/update.yml:**
```yaml
---
- name: Update apt-cache and do upgrade
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 3600
    upgrade: yes
  become: yes

- name: Check if reboot required
  stat:
    path: /var/run/reboot-required
  register: reboot_required_file

- name: Reboot if required
  reboot:
  when: reboot_required_file.stat.exists == true
  become: yes
```

**/ansible/roles/soundboks/tasks/init.yml:**
```yaml
---
# Update apt cache
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 3600
  become: yes

# SSH
# TODO: Setup your SSH and other connection configurations here.

# Install Raspotify.
# https://github.com/dtcooper/raspotify
# https://github.com/dtcooper/raspotify/wiki/Basic-Setup-Guide
- name: Install curl
  ansible.builtin.apt:
    name: curl
    state: present
  become: yes

- name: Install Raspotify
  ansible.builtin.shell: "curl -sL https://dtcooper.github.io/raspotify/install.sh | sh"
  become: yes
```

**/ansible/roles/soundboks/tasks/apply.yml:**
```yaml
---
# Copy librespot onevent hook.
- name: Copy librespot onevent hook
  ansible.builtin.copy:
    src: files/librespot_onevent_hook
    dest: /usr/local/bin/librespot_onevent_hook
    owner: root
    group: root
    mode: 0755
  become: yes

# Copy Raspotify configuration file.
- name: Copy Raspotify configuration file
  ansible.builtin.copy:
    src: files/conf
    dest: /etc/raspotify/conf
    owner: root
    group: root
    mode: 0644
  become: yes

# Systemd.
- name: Enable and start raspotify service
  ansible.builtin.systemd:
    name: raspotify
    enabled: yes
    state: started
  become: yes

- name: Restart raspotify service
  ansible.builtin.systemd:
    name: raspotify
    state: restarted
  become: yes
```

In Home Assistant, I created an automation to turn the speaker on and off via webhooks. When a webhook to turn on the speaker is received, the automation will turn on the speaker relay instantly and turn it off after 1 hour and 30 minutes. When a webhook to turn off the speaker is received, the automation will turn off the speaker relay after 5 minutes to avoid turning off the speaker just because of a short pause in the music. The automation is importantly set to restart mode to function correctly. The automation yaml is listed here:

```yaml
alias: SOUNDBOKS Hook
description: ""
trigger:
  - platform: webhook
    allowed_methods:
      - PUT
    local_only: true
    webhook_id: soundboks-hook-on-fFIwiC9Ntieqwb1EI5tRwy4Y
    id: soundboks-hook-on
  - platform: webhook
    allowed_methods:
      - PUT
    local_only: true
    webhook_id: soundboks-hook-off-QuTX0IpJxDsrdALIrpA1B9Wx
    id: soundboks-hook-off
condition: []
action:
  - choose:
      - conditions:
          - condition: trigger
            id:
              - soundboks-hook-on
        sequence:
          - service: switch.turn_on
            target:
              entity_id:
                - switch.up_relay_soundboks
            data: {}
          - delay:
              hours: 1
              minutes: 30
              seconds: 0
              milliseconds: 0
          - service: switch.turn_off
            metadata: {}
            data: {}
            target:
              entity_id: switch.up_relay_soundboks
      - conditions:
          - condition: trigger
            id:
              - soundboks-hook-off
        sequence:
          - delay:
              hours: 0
              minutes: 5
              seconds: 0
              milliseconds: 0
          - service: switch.turn_off
            metadata: {}
            data: {}
            target:
              entity_id: switch.up_relay_soundboks
mode: restart
```

This post is a bit rushed, but maybe it can be useful for someone! 😊
