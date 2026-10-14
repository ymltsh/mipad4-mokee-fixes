"""Build the resource-only overlay and the four Magisk ZIPs (Windows)."""
from pathlib import Path
import argparse
import hashlib
import secrets
import shutil
import subprocess
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
APKTOOL_URL = 'https://github.com/iBotPeaches/Apktool/releases/download/v3.0.3/apktool_3.0.3.jar'
APKTOOL_SHA256 = 'dbf930b076c6b9be08d57c449cacefc3bdd6b71ebd59b3066fc0e1f5b14f9423'
PACKAGES = {
    'light-hal-label-fix': 'MiPad4-Light-HAL-Label-Fix-v1.0.0.zip',
    'lockscreen-rotation': 'MiPad4-Lockscreen-Rotation-v1.0.0.zip',
    'bottom-dock': 'MiPad4-Lawnchair-BottomDock-v1.0.0.zip',
    'combined': 'MiPad4-MoKee-Fixes-v1.0.0.zip',
}


def run(*args):
    subprocess.run([str(x) for x in args], check=True)


def pack(source, output):
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for path in sorted(source.rglob('*')):
            if not path.is_file():
                continue
            info = zipfile.ZipInfo(path.relative_to(source).as_posix(), (2026, 10, 14, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, path.read_bytes())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--framework', type=Path, required=True,
                        help='framework-res.apk pulled from the target Android 10 device')
    parser.add_argument('--java-bin', type=Path, required=True,
                        help='JDK 17+ bin directory containing keytool.exe and jarsigner.exe')
    args = parser.parse_args()
    if not args.framework.is_file():
        parser.error('The supplied framework APK does not exist.')
    for name in ('keytool.exe', 'jarsigner.exe'):
        if not (args.java_bin / name).is_file():
            parser.error(f'Missing JDK tool: {name}')

    scratch = ROOT / '.build'
    scratch.mkdir(exist_ok=True)
    jar = scratch / 'apktool-3.0.3.jar'
    if not jar.exists():
        urllib.request.urlretrieve(APKTOOL_URL, jar)
    if hashlib.sha256(jar.read_bytes()).hexdigest() != APKTOOL_SHA256:
        raise RuntimeError('Apktool SHA-256 mismatch; refusing to use downloaded tool.')
    aapt = scratch / 'aapt2.exe'
    with zipfile.ZipFile(jar) as z:
        aapt.write_bytes(z.read('prebuilt/windows/aapt2.exe'))

    compiled = scratch / 'compiled.zip'
    unsigned = scratch / 'overlay-unsigned.apk'
    signed = scratch / 'MiPad4BottomDock.apk'
    run(aapt, 'compile', '--dir', ROOT / 'overlay-src/res', '-o', compiled)
    run(aapt, 'link', '-I', args.framework.resolve(), '--manifest',
        ROOT / 'overlay-src/AndroidManifest.xml', '-R', compiled,
        '--auto-add-overlay', '-o', unsigned)

    keystore = scratch / 'overlay-signing.p12'
    if keystore.exists():
        keystore.unlink()
    password = secrets.token_urlsafe(24)
    run(args.java_bin / 'keytool.exe', '-genkeypair', '-keystore', keystore,
        '-storepass', password, '-keypass', password, '-alias', 'overlay',
        '-keyalg', 'RSA', '-keysize', '2048', '-validity', '3650',
        '-dname', 'CN=Local MiPad4 Resource Overlay')
    run(args.java_bin / 'jarsigner.exe', '-keystore', keystore,
        '-storepass', password, '-signedjar', signed, unsigned, 'overlay')
    run(args.java_bin / 'jarsigner.exe', '-verify', signed)
    with zipfile.ZipFile(signed) as z:
        if any(p.endswith('.dex') for p in z.namelist()):
            raise RuntimeError('Resource overlay unexpectedly contains DEX code.')

    for module in ('bottom-dock', 'combined'):
        target = ROOT / f'modules/{module}/system/product/overlay/MiPad4BottomDock.apk'
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(signed, target)
    downloads = ROOT / 'downloads'
    downloads.mkdir(exist_ok=True)
    for module, filename in PACKAGES.items():
        pack(ROOT / 'modules' / module, downloads / filename)
    sums = '\n'.join(hashlib.sha256((downloads / name).read_bytes()).hexdigest()
                     + '  downloads/' + name for name in PACKAGES.values())
    (ROOT / 'SHA256SUMS.txt').write_text(sums + '\n', encoding='utf-8', newline='\n')
    print('Built resource APK and four Magisk ZIPs. SHA256SUMS.txt refreshed.')


if __name__ == '__main__':
    main()
