// Copyright (C) 2016 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

#include "qwizard.h"
#include <QtWidgets/private/qtwidgetsglobal_p.h>

#if defined(Q_OS_MACOS)
#include <AppKit/AppKit.h>
#include <QtGui/private/qcoregraphics_p.h>

QT_BEGIN_NAMESPACE

using namespace Qt::StringLiterals;

#ifdef Q_OS_MACOS
QPixmap QWizardPrivate::findDefaultBackgroundPixmap()
{
    auto *keyboardAssistantURL = [NSWorkspace.sharedWorkspace
        URLForApplicationWithBundleIdentifier:@"com.apple.KeyboardSetupAssistant"];
    auto *keyboardAssistantBundle = [NSBundle bundleWithURL:keyboardAssistantURL];
    auto *assistantBackground = [keyboardAssistantBundle imageForResource:@"Background"];
    auto size = QSizeF::fromCGSize(assistantBackground.size);
    static const QSizeF expectedSize(242, 414);
    if (size == expectedSize)
        return qt_mac_toQPixmap(assistantBackground, size);

    return QPixmap();
}
#endif

QT_END_NAMESPACE
