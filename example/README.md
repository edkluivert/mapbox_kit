# mapbox_kit example

Two demos of `mapbox_kit`, the Mapbox Maps SDK for DartNative:

- **Journal** – a night globe with four bracket markers (San Francisco,
  Denver, Austin, New York). Tap one: its brackets turn orange and the map
  flies down among that city's 3D buildings. Tap the map there for A, tap
  again for B, and **Get us there** fetches the driving route and runs an
  orange line from A to B; **Drive it in 3D** then drives it with a puck and
  a low follow camera until "We are here". The pill at the top switches
  between all eight built-in Mapbox styles (Standard, Standard Satellite,
  Streets, Outdoors, Light, Dark, Satellite, Satellite Streets); on the two
  Standard styles its sun button cycles the light preset (night → dawn →
  day → dusk). The route, pins and puck survive a style switch. The button
  under the arrow zooms back out to the globe and **Clear** starts over.
- **Navigate** – turn-by-turn driving on Mapbox Streets. Tap the map where
  you are (pin A) and where you are going (pin B), then **Navigate there**
  fetches a Directions route and drives it: the route greys out behind a
  bearing puck, with a maneuver banner, an ETA bar, overview / recenter /
  mute buttons and spoken guidance synthesised on the device. Open it from
  the arrow button on the journal; the X brings you back.

## Run it

You need a public Mapbox token (`pk.…`). Copy `mapbox.env.example` to
`mapbox.env` (gitignored, bundled as an asset), paste the token in, and run:

```sh
cp mapbox.env.example mapbox.env   # then edit MAPBOX_ACCESS_TOKEN=pk.…
dn pub get
dn run -d <device-id>
```

## Switches

All in `lib/config.dart`:

| Switch | Default | What it does |
| --- | --- | --- |
| `mapboxAccessToken` | from `mapbox.env` | Your token, read at startup. |
| `verboseLogs` | `false` | Extra readbacks from the SDK in the log. |

## Where things are

```
lib/
  main.dart                     app entry; switches between the two screens
  config.dart                   the switches above
  journal/
    places.dart                 the four places, the globe camera, the style list
    journal_map.dart            style switching + setup, look, markers + taps, fly-to, A/B pins, route, 3D drive
    journal_screen.dart         the journal UI
  navigation/
    directions.dart             Directions API client
    drive_simulator.dart        drives the route on a timer, fires voice cues
    voice.dart                  on-device speech (SuperTonic TTS + PCM player)
    navigation_screen.dart      the navigation UI: pins, route, drive
  shared/
    geo.dart                    distances, bearings, RoutePlayer
    marker_images.dart          place / pin / puck PNGs drawn at runtime
    widgets.dart                buttons, pills, colours
```

The voice models (about 144 MB) download on the first run and are cached;
until then the banner shows the instruction text only. Both screens need a
network connection for the Directions routes.
