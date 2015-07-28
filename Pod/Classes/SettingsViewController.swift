//
//  SettingsViewController.swift
//  MultipeerConnectivityChat
//
//  Created by Moray on 25/06/15.
//  Copyright © 2015 Moray. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class SettingsViewController: UIViewController,
                              UITextFieldDelegate,
                              UIImagePickerControllerDelegate,
                              UINavigationControllerDelegate,
                              UITableViewDataSource
{

    // MARK: Outlets
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var enableSoundsSwitch: UISwitch!
    @IBOutlet weak var tableView: UITableView!

    // MARK: Instance Variables
    var connectedPeers = [MCPeerID]()

    // View load/unload
    override func viewDidLoad()
    {
        super.viewDidLoad()

        print(imageView.superview!.frame)

        let recognizer = UITapGestureRecognizer(target: self, action: "selectImage:")
        imageView.userInteractionEnabled = true
        recognizer.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(recognizer)

        imageView.layer.cornerRadius = 34/2
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0

        let timer = NSTimer(timeInterval: 1, target: tableView, selector: "reloadData", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: "showEditDetailsView:")

    }

    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        displayNameField.text = NSUserDefaults.displayName
        imageView.image = NSUserDefaults.avatar ?? UIImage(named: "no-photo")?.scaledTo(CGSize(width: 34, height: 34))
        enableSoundsSwitch.on = NSUserDefaults.enableSounds
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "showDetails"
        {
			let peer = connectedPeers[tableView.indexPathForSelectedRow()!.row]
            (segue.destinationViewController as! DetailsViewController).userInfo =
                connectedUserInfo[peer.displayName]
        }
    }

	override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool
    {
        if identifier == "done"
        {
            NSUserDefaults.displayName = displayNameField.text ?? ""
            let name = NSUserDefaults.displayName
            if name.isEmpty || name.length > 63
            {
                let alert = UIAlertController(title: "Invalid name",
                    message: "Your display name can't be empty or longer then 63 characters.",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                presentViewController(alert, animated: true, completion: nil)
                return false
            }
        }

        return true
    }
    /*
    override func performSegueWithIdentifier(identifier: String, sender: AnyObject?)
    {
        /*let reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus = reachability.currentReachabilityStatus()
        print("Network status: \(networkStatus)")

        if identifier != "showHexMap" && identifier != "showMap"
        {
            super.performSegueWithIdentifier(identifier, sender: sender)
            return
        }

        var id = identifier
        if networkStatus == NotReachable
        {
            id = "showHexMap"
        }
        else
        {
            id = "showMap"
        }
        super.performSegueWithIdentifier(id, sender: sender)*/
    }*/

    // MARK: Actions
    func showEditDetailsView(sender : AnyObject)
    {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("EditDetails") as! UIViewController
        presentViewController(vc, animated: true, completion: nil)
    }
    func selectImage(sender : AnyObject?)
    {
        let alert = UIAlertController(title: "Remove or change?",
                                      message: nil,
                                      preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Remove", style: .Default, handler:
            {
                (alert) in
                NSUserDefaults.avatar = nil;
                self.imageView.image = UIImage(named: "no-photo")?.scaledTo(CGSize(width: 34, height: 34))
            }))
		
        alert.addAction(UIAlertAction(title: "Change", style: UIAlertActionStyle.Default, handler: self.pickImage))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }

    @IBAction func pickImage(sender : UIAlertAction!)
    {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true

        navigationController?.presentViewController(imagePickerController, animated: true, completion: nil)
    }

    @IBAction func textFieldChanged(sender: UITextField)
    {
        NSUserDefaults.displayName = sender.text ?? ""
    }

    @IBAction func done(sender: AnyObject)
    {
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func toggleSound(sender: UISwitch)
    {
        NSUserDefaults.enableSounds = sender.on
    }

    // MARK: UITextFieldDelegate
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange,
                   replacementString string: String) -> Bool
    {
        return (textField.text ?? "").length + string.length - range.length <= 63
    }

    func textFieldDidEndEditing(textField: UITextField)
    {
        NSUserDefaults.displayName = textField.text ?? ""
    }

    // MARK: UIImagePickerControllerDelegate
	func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!)
    {
        let realImage = image.scaledTo(CGSize(width: 34, height: 34))
        imageView.image = realImage
        NSUserDefaults.avatar = realImage
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UITableViewDatasource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return connectedPeers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCellWithIdentifier("peerCell") as? UITableViewCell
        if cell == nil
        {
            cell = UITableViewCell()
        }
        cell?.textLabel?.text = connectedPeers[indexPath.row].displayName
        let peer = connectedPeers[indexPath.row].displayName
        cell?.imageView?.image = avatarForDisplayName(peer).avatarImage().scaledTo(CGSize(width: 34, height: 34))
        return cell!
    }

}
