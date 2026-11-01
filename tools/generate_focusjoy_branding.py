"""Regenerate FocusJoy artwork from assets/logo/focusjoy.svg (no app build).

Requires Pillow and resvg-py: python -m pip install Pillow resvg-py
Run from any directory: python tools/generate_focusjoy_branding.py
"""

import copy
import io
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from PIL import Image
import resvg_py

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/logo'
NAVY = '#0F0D21'
ICON_BACKGROUND = '#FFFFFF'
SVG = 'http://www.w3.org/2000/svg'
ANDROID = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('', SVG)
master = ET.parse(ASSETS / 'focusjoy.svg').getroot()


def variant(name, groups, viewbox, white_text=False):
    root = copy.deepcopy(master)
    root.attrib.pop('aria-labelledby', None)
    root.attrib.pop('role', None)
    root.set('viewBox', viewbox)
    bounds = list(map(float, viewbox.split()))
    root.set('width', str(bounds[2]))
    root.set('height', str(bounds[3]))
    for child in list(root):
        if child.tag == f'{{{SVG}}}title':
            root.remove(child)
        elif child.tag == f'{{{SVG}}}g' and child.get('id') not in groups:
            root.remove(child)
    if white_text:
        for child in root.iter():
            if child.get('fill') == '#000000':
                child.set('fill', '#FFFFFF')
    ET.indent(root, space='  ')
    path = ASSETS / name
    ET.ElementTree(root).write(path, encoding='utf-8', xml_declaration=True)
    return path


gem = variant('focusjoy-gem.svg', {'gem-facets', 'focus-target'}, '88 14 288 252')
variant('focusjoy-wordmark-dark.svg', {'label-outlined'}, '105 255 283 63', True)
dark_logo = variant('focusjoy-dark.svg', {'gem-facets', 'focus-target', 'label-outlined'}, '80 12 320 312', True)


def render(path, width):
    return Image.open(io.BytesIO(resvg_py.svg_to_bytes(
        svg_path=str(path), width=width, skip_system_fonts=True,
    ))).convert('RGBA')


def icon(size, ratio=0.68, background=None, monochrome=False):
    # Draw large, then downsample to keep small launcher assets crisp.
    work = max(1024, size)
    artwork = render(gem, round(work * ratio))
    if monochrome:
        solid = Image.new('RGBA', artwork.size, 'white')
        solid.putalpha(artwork.getchannel('A'))
        artwork = solid
    canvas = Image.new('RGBA', (work, work), background)
    canvas.alpha_composite(artwork, ((work-artwork.width)//2, (work-artwork.height)//2))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


icon(1024).save(ASSETS / 'focusjoy-app-icon.png')
icon(1080, 0.54, None).save(ASSETS / 'focusjoy-adaptive-foreground.png')
icon(1080, 0.54, None, True).save(ASSETS / 'focusjoy-monochrome.png')
icon(960, 0.54, None).save(ASSETS / 'focusjoy-android12-splash.png')
render(dark_logo, 288).save(ASSETS / 'focusjoy-splash.png')

res = ROOT / 'android/app/src/main/res'
for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    folder = res / f'mipmap-{density}'
    folder.mkdir(exist_ok=True)
    icon(round(48*scale)).save(folder / 'ic_launcher.png')
    icon(round(108*scale), 0.54, None).save(folder / 'ic_launcher_foreground.png')
    icon(round(108*scale), 0.54, None, True).save(folder / 'ic_launcher_monochrome.png')
    Image.new('RGB', (round(108*scale), round(108*scale)), ICON_BACKGROUND).save(folder / 'ic_launcher_background.png')
    drawable = res / f'drawable-{density}'
    drawable.mkdir(exist_ok=True)
    render(dark_logo, round(288*scale)).save(drawable / 'splash.png')
    icon(round(288*scale), 0.54, None).save(drawable / 'android12splash.png')
    night = res / f'drawable-night-{density}'
    night.mkdir(exist_ok=True)
    icon(round(288*scale), 0.54, None).save(night / 'android12splash.png')

for folder in ['drawable', 'drawable-v21']:
    path = res / folder / 'launch_background.xml'
    text = path.read_text(encoding='utf-8')
    start = text.index('<layer-list')
    path.write_text(text[:start] + '''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><shape><solid android:color="#0F0D21" /></shape></item>
    <item><bitmap android:gravity="center" android:src="@drawable/splash" /></item>
</layer-list>
''', encoding='utf-8')

# Define Android 12's launch theme for both light and dark device settings.
launch_items = '''
    <style name="LaunchTheme" parent="Theme.AppCompat.DayNight.NoActionBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowSplashScreenBackground">#0F0D21</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/android12splash</item>
        <item name="android:windowSplashScreenIconBackgroundColor">#0F0D21</item>
        <item name="android:statusBarColor">#0F0D21</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:navigationBarColor">#0F0D21</item>
    </style>
'''
for folder in ['values-v31', 'values-night-v31']:
    path = res / folder / 'styles.xml'
    text = path.read_text(encoding='utf-8')
    import re
    text = re.sub(r'\s*<style name="LaunchTheme".*?</style>', '', text, flags=re.S)
    text = text.replace('</resources>', launch_items + '</resources>')
    path.write_text(text, encoding='utf-8')

strings = res / 'values/strings.xml'
strings.write_text(strings.read_text(encoding='utf-8').replace(
    '<string name="app_name">ManoDhyan</string>', '<string name="app_name">FocusJoy</string>',
), encoding='utf-8')

for asset_dir in [ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset', ROOT / 'macos/Runner/Assets.xcassets/AppIcon.appiconset']:
    contents = json.loads((asset_dir / 'Contents.json').read_text(encoding='utf-8'))
    for entry in contents['images']:
        if 'filename' in entry:
            size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
            artwork = icon(size, background=ICON_BACKGROUND) if 'ios' in asset_dir.parts else icon(size)
            if 'ios' in asset_dir.parts:
                artwork = artwork.convert('RGB')
            artwork.save(asset_dir / entry['filename'])

for scale, suffix in [(1, ''), (2, '@2x'), (3, '@3x')]:
    render(dark_logo, 288*scale).save(ROOT / f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png')
Image.new('RGB', (1, 1), NAVY).save(ROOT / 'ios/Runner/Assets.xcassets/LaunchBackground.imageset/background.png')

icon(256).save(ROOT / 'windows/runner/resources/app_icon.ico', sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
for size in [192, 512]:
    for name in [f'Icon-{size}.png', f'Icon-maskable-{size}.png']:
        icon(size, background=ICON_BACKGROUND if 'maskable' in name else None).save(ROOT / 'web/icons' / name)
icon(32).save(ROOT / 'web/favicon.png')
print('Generated FocusJoy vector variants, splash artwork, and platform icons.')
