// Copyright (C) 2019 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only
// Qt-Security score:significant reason:default

#include "qplatformdefs.h"
#include "qfilesystemengine_p.h"
#include "qfile.h"
#include "qurl.h"

#include <QtCore/private/qcore_mac_p.h>
#include <CoreFoundation/CoreFoundation.h>
#include <UniformTypeIdentifiers/UTType.h>
#include <UniformTypeIdentifiers/UTCoreTypes.h>
#include <Foundation/Foundation.h>

QT_BEGIN_NAMESPACE

#if !defined(QT_BOOTSTRAPPED)
/*
    This implementation does not enable the "put back" option in Finder
    for the trashed object. The only way to get this is to use Finder automation,
    which would query the user for permission to access Finder using a modal,
    blocking dialog - which we definitely can't have in a console application.

    Using Finder would also play the trash sound, which we don't want either in
    such a core API; applications that want that can play the sound themselves.
*/
//static
bool QFileSystemEngine::supportsMoveFileToTrash()
{
#ifdef Q_OS_MACOS // desktop macOS has a trash can
    return true;
#else // watch, tv, iOS don't have a trash can
    return false;
#endif
}

//static
bool QFileSystemEngine::moveFileToTrash(const QFileSystemEntry &source,
                                        QFileSystemEntry &newLocation, QSystemError &error)
{
#ifdef Q_OS_MACOS // desktop macOS has a trash can
    QMacAutoReleasePool pool;

    QFileInfo info(source.filePath());
    NSString *filepath = info.filePath().toNSString();
    NSURL *fileurl = [NSURL fileURLWithPath:filepath isDirectory:info.isDir()];
    NSURL *resultingUrl = nil;
    NSError *nserror = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm trashItemAtURL:fileurl resultingItemURL:&resultingUrl error:&nserror] != YES) {
        error = QSystemError(nserror.code, QSystemError::NativeError);
        return false;
    }
    newLocation = QFileSystemEntry(QUrl::fromNSURL(resultingUrl).path());
    return true;
#else // watch, tv, iOS don't have a trash can
    Q_UNUSED(source);
    Q_UNUSED(newLocation);
    error = QSystemError(ENOSYS, QSystemError::StandardLibraryError);
    return false;
#endif
}
#endif // !QT_BOOTSTRAPPED

using namespace Qt::StringLiterals;

bool hasResourcePropertyFlag(const QFileSystemMetaData &data,
                                           const QFileSystemEntry &entry,
                                           CFStringRef key)
{
    QCFString path = CFStringCreateWithFileSystemRepresentation(0,
        entry.nativeFilePath().constData());
    if (!path)
        return false;

    QCFType<CFURLRef> url = CFURLCreateWithFileSystemPath(0, path, kCFURLPOSIXPathStyle,
        data.hasFlags(QFileSystemMetaData::DirectoryType));
    if (!url)
        return false;

    CFBooleanRef value;
    if (CFURLCopyResourcePropertyForKey(url, key, &value, NULL)) {
        if (value == kCFBooleanTrue)
            return true;
    }

    return false;
}

bool isPackage(const QFileSystemMetaData &data, const QFileSystemEntry &entry)
{
    if (!data.isDirectory())
        return false;

    QFileInfo info(entry.filePath());
    QString suffix = info.suffix();

    if (suffix.length() > 0) {
        // First step: is it a bundle?
        const auto *utType = [UTType typeWithFilenameExtension:suffix.toNSString()];
        if ([utType conformsToType:UTTypeBundle])
            return true;

        // Second step: check if an application knows the package type
        QCFType<CFStringRef> path = entry.filePath().toCFString();
        QCFType<CFURLRef> url = CFURLCreateWithFileSystemPath(0, path, kCFURLPOSIXPathStyle, true);

        UInt32 type, creator;
        // Well created packages have the PkgInfo file
        if (CFBundleGetPackageInfoInDirectory(url, &type, &creator))
            return true;

#ifdef Q_OS_MACOS
        // Find if an application other than Finder claims to know how to handle the package
        QCFType<CFURLRef> application = LSCopyDefaultApplicationURLForURL(url,
            kLSRolesEditor | kLSRolesViewer, nullptr);

        if (application) {
            QCFType<CFBundleRef> bundle = CFBundleCreate(kCFAllocatorDefault, application);
            CFStringRef identifier = CFBundleGetIdentifier(bundle);
            QString applicationId = QString::fromCFString(identifier);
            if (applicationId != "com.apple.finder"_L1)
                return true;
        }
#endif
    }

    // Third step: check if the directory has the package bit set
    return hasResourcePropertyFlag(data, entry, kCFURLIsPackageKey);
}

QString getMacTemporaryDirectory()
{
    if (NSString *nsPath = NSTemporaryDirectory(); nsPath)
        return QString::fromCFString((CFStringRef)nsPath);

    return {};
}

QT_END_NAMESPACE
