/*
 * SPDX-FileCopyrightText: 2025 molang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("常规")
        icon: "configure"
        source: "configGeneral.qml"
    }
}
