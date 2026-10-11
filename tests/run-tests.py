#!/usr/bin/env python3
"""Run the widget's actual QML properties/functions without a Plasma shell."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET


REPO = Path(__file__).resolve().parent.parent


def harness(source):
    # Keep the production bindings and functions, excluding only the color
    # binding that needs Kirigami. Missing section markers fail loudly.
    for marker in ("PlasmoidItem {\n", "    Plasmoid.icon:", "    function normalizedTitle() {", "    Timer {"):
        if source.count(marker) != 1:
            raise ValueError(f"Cannot locate the widget section: {marker.strip()}")
    properties = source.split("PlasmoidItem {\n", 1)[1].split("    Plasmoid.icon:", 1)[0]
    color = "    readonly property color accentColor: urgencyColor()\n"
    if properties.count(color) != 1:
        raise ValueError("Cannot locate the widget's accentColor binding")
    properties = properties.replace(color, "")
    functions = source.split("    function normalizedTitle() {", 1)[1].split("    Timer {", 1)[0]

    # Use the real configuration schema's defaults rather than repeating them.
    schema = ET.parse(REPO / "contents/config/main.xml")
    namespace = {"kcfg": "http://www.kde.org/standards/kcfg/1.0"}
    declarations = []
    for entry in schema.findall(".//kcfg:entry", namespace):
        kind = {"String": "string", "Int": "int", "Bool": "bool"}[entry.attrib["type"]]
        default = entry.find("kcfg:default", namespace).text
        if kind == "string":
            default = json.dumps(default, ensure_ascii=False)
        declarations.append(f"property {kind} {entry.attrib['name']}: {default}")
    configuration = "\n".join(declarations)
    return (
        "import QtQml\nQtObject {\n" + properties
        + "property QtObject plasmoid: QtObject {\n"
        + "property QtObject configuration: QtObject {\n" + configuration + "\n}\n}\n"
        + "function i18n(message) {\n"
        + "    for (let index = 1; index < arguments.length; ++index) {\n"
        + "        message = message.replace('%' + index, arguments[index]);\n"
        + "    }\n    return message;\n}\n"
        + "    function normalizedTitle() {" + functions + "}\n"
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=REPO / "contents/ui/main.qml")
    args = parser.parse_args()
    runner = os.environ.get("QMLTESTRUNNER")
    if not runner:
        candidates = ["/usr/lib/qt6/bin/qmltestrunner", shutil.which("qmltestrunner6"), shutil.which("qmltestrunner")]
        runner = next((path for path in candidates if path and Path(path).is_file()), None)
    if not runner:
        parser.error("Qt 6 qmltestrunner is required; set QMLTESTRUNNER to its path")

    with tempfile.TemporaryDirectory(prefix="gaokao-countdown-tests-") as directory:
        temporary = Path(directory)
        (temporary / "CountdownUnderTest.qml").write_text(harness(args.source.read_text()))
        shutil.copy(REPO / "tests/tst_title.qml", temporary)
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
        return subprocess.run([runner, "-input", str(temporary)], env=environment, cwd=temporary).returncode


if __name__ == "__main__":
    raise SystemExit(main())
