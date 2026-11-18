#!/usr/bin/env python3
"""Run the production countdown model in English and Chinese without a Plasma shell."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET


REPO = Path(__file__).resolve().parent.parent


def test_configuration():
    """Expose the same observable configuration properties that Plasma provides."""
    schema = ET.parse(REPO / "contents/config/main.xml")
    namespace = {"kcfg": "http://www.kde.org/standards/kcfg/1.0"}
    properties = []
    for entry in schema.findall(".//kcfg:entry", namespace):
        kind = {"String": "string", "Int": "int", "Bool": "bool"}[entry.attrib["type"]]
        default = entry.findtext("kcfg:default", default="", namespaces=namespace)
        if kind == "string":
            default = json.dumps(default, ensure_ascii=False)
        properties.append(f"    property {kind} {entry.attrib['name']}: {default}")
    return "import QtQml\nQtObject {\n" + "\n".join(properties) + "\n}\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=REPO / "contents/ui/Countdown.qml",
                        help="test an alternative Countdown.qml model")
    args = parser.parse_args()
    runner = os.environ.get("QMLTESTRUNNER")
    if not runner:
        candidates = ["/usr/lib/qt6/bin/qmltestrunner", shutil.which("qmltestrunner6"), shutil.which("qmltestrunner")]
        runner = next((path for path in candidates if path and Path(path).is_file()), None)
    if not runner:
        parser.error("Qt 6 qmltestrunner is required; set QMLTESTRUNNER to its path")

    with tempfile.TemporaryDirectory(prefix="gaokao-countdown-tests-") as directory:
        temporary = Path(directory)
        shutil.copy(args.source, temporary / "Countdown.qml")
        shutil.copy(REPO / "tests/tst_title.qml", temporary)
        (temporary / "TestConfiguration.qml").write_text(test_configuration())

        environment = os.environ.copy()
        environment.update({
            "QT_QPA_PLATFORM": "offscreen",
            "QT_QPA_PLATFORMTHEME": "generic",
            "QT_QUICK_CONTROLS_STYLE": "Basic",
            "QT_QUICK_BACKEND": "software",
            "TZ": "UTC",
        })
        for variable in ("XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR"):
            path = temporary / variable.lower()
            path.mkdir(mode=0o700)
            environment[variable] = str(path)
        # Make the packaged translations available to the standalone KI18n context.
        (Path(environment["XDG_DATA_HOME"]) / "locale").symlink_to(REPO / "contents/locale")

        for language in ("en_US", "zh_CN"):
            print(f"Running countdown tests in {language}", flush=True)
            environment.update(LANGUAGE=language, LANG=f"{language}.UTF-8", LC_ALL=f"{language}.UTF-8")
            result = subprocess.run([runner, "-input", str(temporary)], env=environment, cwd=temporary)
            if result.returncode:
                return result.returncode
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
