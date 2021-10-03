//
//  YiAppUpdater.swift
//  YiAppUpdater
//
//  Created by coderyi on 2021/10/3.
//

import Foundation
import SystemConfiguration

public protocol YiAppUpdaterDelegate: NSObjectProtocol {
    func appUpdaterDidShowUpdateDialog()
    func appUpdaterUserDidLaunchAppStore()
    func appUpdaterUserDidCancel()
}

open class YiAppUpdater: NSObject {

    public weak var delegate: YiAppUpdaterDelegate?
    public var alertTitle: String
    public var alertMessage: String
    public var alertUpdateButtonTitle: String
    public var alertCancelButtonTitle: String
    var appStoreURL: String?
    public static let shared = YiAppUpdater()
    
    public override init() {
        self.alertTitle = "New Version"
        self.alertMessage = ""
        self.alertUpdateButtonTitle = "Update"
        self.alertCancelButtonTitle = "Not Now"
    }

    func showUpdateWithForce() {
        if !hasConnection() {
            return
        }
        checkNewAppVersion { [weak self] (newVersion, version) in
            guard let `self` = self else {
                return
            }
            if newVersion {
                self.alertUpdate(version: version, force: true)
            }
        }
    }
    
    public func showUpdateWithConfirmation() {
        if !hasConnection() {
            return
        }
        checkNewAppVersion { [weak self] (newVersion, version) in
            guard let `self` = self else {
                return
            }
            if newVersion {
                self.alertUpdate(version: version, force: false)
            }
        }
    }
    
    func showUpdateWithConfirmationOnce() {
        if !hasConnection() {
            return
        }
        
        checkNewAppVersion { [weak self] (newVersion, version) in
            guard let `self` = self else {
                return
            }
            if newVersion {
                let info = UserDefaults.standard.object(forKey: "versionPromptInfo") as? [AnyHashable: Any]
                let localVersion = info?["version"] as? String ?? ""
                if localVersion != version {
                    self.alertUpdate(version: version, force: false)
                    let newInfo = ["version": version, "versionDate": Date()] as [AnyHashable : Any]
                    UserDefaults.standard.setValue(newInfo, forKey: "versionPromptInfo")
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    func hasConnection() -> Bool {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, "itunes.apple.com") else { return false }
        var flags = SCNetworkReachabilityFlags()
        guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return (isReachable && !needsConnection)
    }
    
    func checkNewAppVersion(completion: @escaping (Bool, String) -> Void) {
        let bundleInfo = Bundle.main.infoDictionary
        let bundleIdentifier = bundleInfo?["CFBundleIdentifier"] as? String ?? ""
        let currentVersion = bundleInfo?["CFBundleShortVersionString"] as? String ?? ""
        DispatchQueue.global().async {
            do {
                if let lookupURL = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)&t=\(Date().timeIntervalSince1970)") {
                    let lookupResults = try Data(contentsOf: lookupURL)
                    let jsonResults = try JSONSerialization.jsonObject(with: lookupResults, options: .init(rawValue: 0))
                    DispatchQueue.main.async {
                        if let jsonResults = jsonResults as? [AnyHashable: Any], let resultCount = jsonResults["resultCount"] as? Int, resultCount > 0 {
                            let results = jsonResults["results"] as? [Any]
                            let appDetails = results?.first as? [AnyHashable: Any]
                            let trackViewUrl = appDetails?["trackViewUrl"] as? String
                            let appItunesUrl = trackViewUrl?.replacingOccurrences(of: "&uo=4", with: "")
                            let latestVersion = appDetails?["version"] as? String
                            
                            if let compare = latestVersion?.compare(currentVersion, options: .numeric, range: nil, locale: nil), compare == .orderedDescending {
                                self.appStoreURL = appItunesUrl
                                completion(true, latestVersion ?? "")
                            } else {
                                completion(false , "")
                            }
                        } else {
                            completion(false , "")
                        }
                    }
                }
            } catch {
            }
        }
    }
    
    func alertUpdate(version: String, force: Bool) {
        var alertMsg = "Version \(version) is available on the AppStore."
        if !alertMessage.isEmpty {
            alertMsg = alertMessage
        }
        let alert = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: .alert)
        let updateAction = UIAlertAction(title: alertUpdateButtonTitle, style: .default) { (action) in
            if let url = URL(string: self.appStoreURL ?? "") {
                UIApplication.shared.openURL(url)
                if let delegate = self.delegate {
                    delegate.appUpdaterUserDidLaunchAppStore()
                }
            }
        }
        alert.addAction(updateAction)
        
        if !force {
            let cancelAction = UIAlertAction(title: alertCancelButtonTitle, style: .cancel) { (action) in
                if let delegate = self.delegate {
                    delegate.appUpdaterUserDidCancel()
                }
            }
            alert.addAction(cancelAction)
        }
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: {
            if let delegate = self.delegate {
                delegate.appUpdaterDidShowUpdateDialog()
            }
        })
    }
}
