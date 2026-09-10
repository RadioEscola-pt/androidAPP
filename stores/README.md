# Store listing assets

Generated, not authored — like `flutter_app/assets/content/`. The source is the site's
`logo-radioescola.svg`; only the diamond mark (its `g50` group) is used, on the app's brand
orange `#FF9A17`.

- `play/icon-512.png` — Google Play listing icon. 512x512, 32-bit PNG, no alpha, square with
  no baked-in rounded corners (Play applies its own mask).

The framing matches the launcher icon: the mark is 72.2% of the square's height, which is the
same as the 52dp mark inside the 72dp visible viewport of
`flutter_app/android/app/src/main/res/mipmap-*/ic_launcher_foreground.png`. Keep the two in
step — a listing icon that does not match the installed launcher icon looks like a different
app on the store page.

Android's own spec allows a logo up to 66dp of the 108dp canvas, but measured Google apps
(Gmail, Maps, Docs, Keep, Photos, YouTube, Calendar) all sit at 49-54dp. 52dp is that median,
and it leaves 13.9% of the diameter as margin under a circular mask.
