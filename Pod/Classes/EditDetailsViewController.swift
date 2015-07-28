//
//  EditDetailsViewController.swift
//  MultipeerConnectivityChat
//
//  Created by Moray on 30/06/15.
//  Copyright © 2015 Moray. All rights reserved.
//

import UIKit

class EditDetailsViewController: UIViewController
{
    // MARK: Outlets
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var ageField: UITextField!
    @IBOutlet weak var bioView: UITextView!

    // MARK: View load/unload
    override func viewDidLoad()
    {
        super.viewDidLoad()

        nameField.text = NSUserDefaults.firstName
        lastNameField.text = NSUserDefaults.lastName
        ageField.text = "\(NSUserDefaults.age)"
        bioView.text = NSUserDefaults.bio

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "dismiss:")
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.numberOfTouchesRequired = 1

        view.addGestureRecognizer(gestureRecognizer)
    }

    override func viewWillDisappear(animated: Bool)
    {
        NSUserDefaults.firstName = nameField.text ?? ""
        NSUserDefaults.lastName = lastNameField.text ?? ""

		var age = ageField?.text?.toInt()
		NSUserDefaults.age = age == nil ? 0 : age!

        NSUserDefaults.bio = bioView.text ?? ""

    }

    // MARK: Actions
    func dismiss(sender : AnyObject)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }


}
