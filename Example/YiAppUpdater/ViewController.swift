//
//  ViewController.swift
//  YiAppUpdater
//
//  Created by coderyi on 10/03/2021.
//  Copyright (c) 2021 coderyi. All rights reserved.
//

import UIKit
import YiAppUpdater
class ViewController: UIViewController, YiAppUpdaterDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        let showCutomAlert = false
//        if showCutomAlert {
//            let updater = YiAppUpdater.shared
//            updater.alertTitle = "Alert Title"
//            updater.alertMessage = "Alert Message"
//            updater.alertUpdateButtonTitle = "Update"
//            updater.alertCancelButtonTitle = "Cancel"
//            updater.showUpdateWithConfirmation()
//        } else {
            YiAppUpdater.shared.showUpdateWithConfirmation()
            YiAppUpdater.shared.delegate = self
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func appUpdaterDidShowUpdateDialog() {
        print("appUpdaterDidShowUpdateDialog")
    }
    
    func appUpdaterUserDidLaunchAppStore() {
        print("appUpdaterUserDidLaunchAppStore")
    }
    
    func appUpdaterUserDidCancel() {
        print("appUpdaterUserDidCancel")
    }

}

