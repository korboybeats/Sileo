//
//  SileoViewController.swift
//  Sileo
//
//  Created by CoolStar on 7/27/20.
//  Copyright © 2022 Sileo Team. All rights reserved.
//

import UIKit
import Evander

public class SileoViewController: UIViewController {
    private var adHocDownloadTask: EvanderDownloader?

    var statusBarStyle: UIStatusBarStyle = .default {
        didSet {
            var style = statusBarStyle
            if style == .default {
                if SileoThemeManager.shared.currentTheme
                    .preferredUserInterfaceStyle == .dark
                {
                    style = .lightContent
                } else if SileoThemeManager.shared.currentTheme
                    .preferredUserInterfaceStyle == .light
                {
                    if #available(iOS 13.0, *) {
                        style = .darkContent
                    }
                }
            }
        }
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if statusBarStyle == .default {
            if SileoThemeManager.shared.currentTheme.preferredUserInterfaceStyle
                == .dark
            {
                return .lightContent
            } else if SileoThemeManager.shared.currentTheme
                .preferredUserInterfaceStyle == .light
            {
                if #available(iOS 13.0, *) {
                    return .darkContent
                }
            }
        }
        return statusBarStyle
    }
    
    func presentVersionSelectionAndDownload(
        for basePackage: Package,
        anchor: UIView?
    ) {
        let sheet = UIAlertController(
            title: String(localizationKey: "Select_Version"),
            message: String(
                localizationKey: "Select_Version_Message"
            ),
            preferredStyle: .actionSheet
        )

        var allVersionsSorted = basePackage.allVersions.sorted {
            DpkgWrapper.isVersion($0.version, greaterThan: $1.version)
        }

        var foundRepo: Repo? = nil
        if let repoURL = URL(string: basePackage.sourceFile ?? ""),
           let repo = RepoManager.shared.repo(with: repoURL) {
            foundRepo = repo
        }
        
        if foundRepo == nil {
            foundRepo = RepoManager.shared.repoList.first {
                $0.packageDict[basePackage.packageID] != nil
            }
        }
        
        if let repo = foundRepo {
            if let repoPackage = repo.packageDict[basePackage.packageID] {
                allVersionsSorted = repoPackage.allVersions.sorted {
                    DpkgWrapper.isVersion($0.version, greaterThan: $1.version)
                }
            }
            
            for version in allVersionsSorted {
                if version.sourceFile == nil {
                    version.sourceFile = repo.rawEntry
                }
                if version.filename == nil {
                    if let repoPackage = repo.packageDict[basePackage.packageID],
                       repoPackage.version == version.version {
                        version.filename = repoPackage.filename
                        version.size = repoPackage.size
                    } else if let versionInRepo = repo.packageDict[basePackage.packageID]?.getVersion(version.version) {
                         version.filename = versionInRepo.filename
                         version.size = versionInRepo.size
                    }
                }
            }
        }

        for pkg in allVersionsSorted {
            if (pkg.sourceRepo?.rawURL.hasPrefix("https://") == true)
                || (pkg.sourceRepo?.rawURL.hasPrefix("http://") == true),
                pkg.filename != nil
            {
                sheet.addAction(
                    UIAlertAction(title: pkg.version, style: .default) {
                        [weak self] _ in
                        self?.startDownloadAndShare(for: pkg, anchor: anchor)
                    }
                )
            }
        }

        sheet.addAction(
            UIAlertAction(
                title: String(localizationKey: "Package_Cancel_Action"),
                style: .cancel
            )
        )

        if UIDevice.current.userInterfaceIdiom == .pad {
            sheet.popoverPresentationController?.sourceView =
                anchor ?? self.view
        }
        self.present(sheet, animated: true)
    }

    private func startDownloadAndShare(for pkg: Package, anchor: UIView?) {
        let wait = UIAlertController(
            title: String(localizationKey: "Downloading_Ellipsis"),
            message: nil,
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(
            title: String(localizationKey: "Cancel"),
            style: .cancel
        ) { [weak self] _ in
            self?.adHocDownloadTask?.cancel()
        }
        wait.addAction(cancelAction)
        self.present(wait, animated: true)

        DownloadManager.shared.downloadFile(
            for: pkg,
            progress: nil,
            waiting: nil,
            onStart: { [weak self] task in
                self?.adHocDownloadTask = task
            },
            completion: { result in
                DispatchQueue.main.async {
                    self.adHocDownloadTask = nil
                    switch result {
                    case .success(let localURL):
                        wait.dismiss(animated: true) {
                            var shareURL = localURL
                            let tmpDir = FileManager.default.temporaryDirectory
                            let tmpURL = tmpDir.appendingPathComponent(localURL.lastPathComponent)
                            do {
                                if FileManager.default.fileExists(atPath: tmpURL.path) {
                                    try? FileManager.default.removeItem(at: tmpURL)
                                }
                                try FileManager.default.copyItem(at: localURL, to: tmpURL)
                                shareURL = tmpURL
                            } catch {
                                shareURL = localURL
                            }
                            let avc = UIActivityViewController(
                                activityItems: [shareURL], applicationActivities: nil)
                            avc.popoverPresentationController?.sourceView = anchor ?? self.view
                            self.present(avc, animated: true)
                        }
                    case .failure(let error):
                        wait.dismiss(animated: true) {
                            let err = UIAlertController(
                                title: "Download Failed", message: error.localizedDescription,
                                preferredStyle: .alert)
                            err.addAction(
                                UIAlertAction(title: String(localizationKey: "OK"), style: .default)
                            )
                            self.present(err, animated: true)
                        }
                    }
                }
            }
        )
    }
}
