//
//  DetailsViewViewController.swift
//  MultipeerConnectivityChat
//
//  Created by Moray on 26/06/15.
//  Copyright © 2015 Moray. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController
{
    // MARK: Outlets
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var compassImageView: UIImageView!

    // MARK: Instance Variables
    var userInfo : UserInfo?

    // MARK: View load/unload
    override func viewDidLoad()
    {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismiss:")
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "dismiss:")
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.numberOfTouchesRequired = 1
        view.addGestureRecognizer(gestureRecognizer)
        compassImageView.transform = CGAffineTransformMakeRotation(CGFloat(userInfo!.orientation * M_PI / 180.0))
    }

    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)

        imageView.layer.cornerRadius = 34
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0
        imageView.image = userInfo!.avatar ?? avatarForDisplayName(userInfo!.displayName).avatarImage()

        compassImageView.layer.cornerRadius = 34
        compassImageView.layer.masksToBounds = true
        compassImageView.layer.borderWidth = 0



        displayNameLabel.text = userInfo!.displayName

        firstNameLabel.text = userInfo!.firstName
        lastNameLabel.text = userInfo!.lastName
        ageLabel.text = "\(userInfo!.age!)"
        bioLabel.numberOfLines = 0
        bioLabel.text = userInfo!.bio
        
    }

    // MARK: Actions
    func dismiss(sender : AnyObject)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }


}
