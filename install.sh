#!/bin/bash
cd "$(dirname "$0")"
kpackagetool6 -t Plasma/Applet -u . || kpackagetool6 -t Plasma/Applet -i .
