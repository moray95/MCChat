//
//  ViewController.swift
//  BluetoothChat
//
//  Created by Moray on 22/06/15.
//  Copyright © 2015 Moray. All rights reserved.
//



import UIKit
import MultipeerConnectivity
import JSQMessagesViewController
import JSQSystemSoundPlayer
import CoreLocation

var serviceTypeSet = false

public var serviceType = ""
{
	willSet
	{
		assert(!serviceTypeSet, "You shouldn't change serviceType once set. This might break MCChat's functionality.")
		serviceTypeSet = true
	}
}
let avatarDictionaryInfo = "AvatarDictionaryInfo"
var connectedUserInfo = [String : UserInfo]()
var locations = [String : CLLocation]()


public class MCChatLoader
{
	public class func instantiateChatViewController() -> UIViewController
	{
		assert(serviceType.length > 0 && serviceType.length < 16,
				"Your should set serviceType variable to a unique value for MCChat to work properly.")
		
		let bundle = NSBundle(forClass: self)

		let storyboard = UIStoryboard(name: "Main", bundle: bundle)
		let viewController = storyboard.instantiateInitialViewController() as! UIViewController
		return viewController
	}
}


class ChatViewController: JSQMessagesViewController,
                          UINavigationControllerDelegate,
                          UIImagePickerControllerDelegate,
                          UIActionSheetDelegate,
                          MCSessionDelegate,
                          MCNearbyServiceBrowserDelegate,
                          MCNearbyServiceAdvertiserDelegate,
                          UITableViewDataSource,
                          CLLocationManagerDelegate
{
    

    // MARK: Instance variables
    var session : MCSession?
    var messages = [Message]()
    let timeout = 20.0
    var browser : MCNearbyServiceBrowser?
    var connectedUsers = [String]()
    var shouldDisconnect = true
    var imageMessage = true
    var advertiser : MCNearbyServiceAdvertiser?
    var locationManager = CLLocationManager()

    // MARK: View load/unload
    override func viewDidLoad()
    {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .Plain, target: self, action: "showSettings:")
        collectionView!.delegate = self
        NSUserDefaults.sessionDate = NSDate()
        title = "Chat (0)"

        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined
        {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }

    override func viewWillAppear(animated: Bool)
    {
        shouldDisconnect = true

        session = MCSession(peer: MCPeerID(displayName: NSUserDefaults.displayName))

        session!.delegate = self
        senderDisplayName = session!.myPeerID.displayName
        senderId = session!.myPeerID.displayName
        browser = MCNearbyServiceBrowser(peer: session!.myPeerID, serviceType: serviceType)
        browser!.delegate = self
        browser!.startBrowsingForPeers()
        collectionView?.collectionViewLayout.springinessEnabled = true

        advertiser = MCNearbyServiceAdvertiser(peer: session!.myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser!.delegate = self
        advertiser!.startAdvertisingPeer()

        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(animated : Bool)
    {
        super.viewWillDisappear(animated)
        if shouldDisconnect
        {
            session!.disconnect()
            browser?.stopBrowsingForPeers()
            locationManager.stopUpdatingLocation()
        }
    }

    // MARK: Actions
    func showSettings(sender : AnyObject?)
    {
        let settings = storyboard!.instantiateViewControllerWithIdentifier("Settings") as! SettingsViewController
        shouldDisconnect = false
        settings.connectedPeers = session!.connectedPeers as! [MCPeerID]
        navigationController?.pushViewController(settings, animated: true)
        //presentViewController(settings, animated: true, completion: nil)
    }

    func simulateMessage(sender : AnyObject?)
    {
        let message = Message(sender: "Message Simulator", body: imageMessage ? "" : "Test message")
        message.image = imageMessage ? UIImage(named: "test") : nil
        imageMessage = !imageMessage
        messages.append(message)

        dispatch_async(dispatch_get_main_queue())
        {
            if NSUserDefaults.enableSounds
            {
                JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            }
            self.finishReceivingMessageAnimated(true)
        }
    }
    
    override func didPressSendButton(button: UIButton!,
                                     withMessageText text: String!,
                                     senderId: String!,
                                     senderDisplayName: String!,
                                     date: NSDate!)
    {
        println("sending: \(text) to:")
        for peer in session!.connectedPeers
        {
            println(peer.displayName)
        }
        let message = Message(sender: senderDisplayName, body: text)

		var error : NSError? = nil
		session!.sendData(NSData.dataForTextMessage(text),
					toPeers: session!.connectedPeers as! [MCPeerID],
					withMode: MCSessionSendDataMode.Reliable,
					error: &error)

		if session!.connectedPeers.count != 0 && error != nil
		{
			println("error sending message : \(error)")
		}


        messages.append(message)
        if NSUserDefaults.enableSounds
        {
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
        }
        dispatch_async(dispatch_get_main_queue())
		{
			self.finishSendingMessageAnimated(true)
        }

    }

    override func didPressAccessoryButton(sender: UIButton!)
    {
        let alert = UIAlertController(title: "Send Photo",
                                      message: "Where do you want to send your photo from?",
                                      preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default, handler:
        {
            (alert) in
            self.selectPhoto(.PhotoLibrary)
        }))

        alert.addAction(UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default, handler:
        {
            (alert) in
            self.selectPhoto(.Camera)
        }))
        shouldDisconnect = false
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler:nil))
        presentViewController(alert, animated: true, completion: nil)
    }

    func selectPhoto(sourceType : UIImagePickerControllerSourceType)
    {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        self.navigationController?.presentViewController(imagePicker, animated: true, completion: nil)
    }

    // MARK: UIImagePickerControllerDelegate
	func imagePickerController(picker: UIImagePickerController,
			didFinishPickingImage image: UIImage!, info: [NSObject : AnyObject]!)
	{
        picker.dismissViewControllerAnimated(true, completion: nil)
        shouldDisconnect = true
        dispatch_async(dispatch_get_global_queue(0, 0))
        {
			var error : NSError? = nil

			self.session?.sendData(NSData.dataForImageMessage(image),
				toPeers: self.session!.connectedPeers,
				withMode: .Reliable,
				error: &error)

			if self.session!.connectedPeers.count != 0 && error != nil
			{
				println("Sending image failed with error: \(error)")
			}

			let message = Message(sender: self.senderDisplayName, body: "")
			message.image = image
			self.messages.append(message)
			dispatch_async(dispatch_get_main_queue())
			{
				if NSUserDefaults.enableSounds
				{
					JSQSystemSoundPlayer.jsq_playMessageSentSound()
				}
				self.finishSendingMessage()
			}
		}
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        picker.dismissViewControllerAnimated(true, completion: nil)
        shouldDisconnect = true
    }

    // MARK: JSQMessagesCollectionViewDataSource
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                    messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData!
    {
        return messages[indexPath.row].jsqMessage
    }

    override func collectionView(collectionView: JSQMessagesCollectionView!,
                    messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource!
    {
        if messages[indexPath.item].isSystemMessage
        {
            return JSQMessagesBubbleImageFactory.systemMessageBubble
        }
        if messages[indexPath.item].senderDisplayName() != session!.myPeerID.displayName
        {
            return JSQMessagesBubbleImageFactory.incomingMessageBubble
        }
        return JSQMessagesBubbleImageFactory.outgoingMessageBubble
    }

    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!)
                                 -> JSQMessageAvatarImageDataSource!
    {
        let avatar : JSQMessageAvatarImageDataSource

        if session!.myPeerID.displayName == messages[indexPath.row].senderId()
        {
            if NSUserDefaults.avatar == nil
            {
                // Initials
                avatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(
                    messages[indexPath.row].initials,
                    backgroundColor: UIColor.grayColor(),
                    textColor: UIColor.whiteColor(),
                    font: UIFont.systemFontOfSize(14),
                    diameter: 34)
            }
            else
            {
                // Avatar
                avatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(NSUserDefaults.avatar, diameter: 34)
            }
        }
        else
        {
            if connectedUserInfo[messages[indexPath.row].senderId()]?.avatar == nil
            {
                // Initials
                avatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(
                    messages[indexPath.row].initials,
                    backgroundColor: UIColor.grayColor(),
                    textColor: UIColor.whiteColor(),
                    font: UIFont.systemFontOfSize(14),
                    diameter: 34)
            }
            else
            {
                // Avatar
                avatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(connectedUserInfo[messages[indexPath.row].sender]?.avatar, diameter: 34)
            }
        }
        
        return avatar
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return messages.count
    }

    override func collectionView(collectionView: UICollectionView,
                  cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        var cell = super.collectionView(collectionView, cellForItemAtIndexPath:indexPath) as? JSQMessagesCollectionViewCell

        if cell == nil
        {
            cell = JSQMessagesCollectionViewCell()
        }
        if messages[indexPath.item].senderId() != senderId
        {
            cell!.textView?.textColor = UIColor.blackColor()
        }

        return cell!
    }

    // MARK: MCBrowserViewControllerDelegate
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController)
    {
        browserViewController.dismissViewControllerAnimated(true, completion: nil)
    }

    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController)
    {
        browserViewController.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: MCSessionDelegate
    func session(session: MCSession,
                didReceiveData data: NSData,
                fromPeer peerID: MCPeerID)
    {
        let (type, messageObject : AnyObject?) = NSData.messageData(data)

        if type == .UserInfo
        {
            // Got UserInfo
            let userInfo = messageObject as! UserInfo
            connectedUserInfo[peerID.displayName] = userInfo
            collectionView?.reloadData()
            return
        }

        if type == .Location
        {
            // Got location
            let location = messageObject as! CLLocation
            println("Received location from \(peerID.displayName)")
            locations[peerID.displayName] = location
            return
        }

        var message : Message

        if type == .TextMessage
        {
            // Got text message
            message = Message(sender: peerID.displayName, body:  messageObject as! NSString as String)
            println("Received message: \(message.body)")
            messages.append(message)
        }

        if type == .ImageMessage
        {
            // Got image message
            println("received image from \(peerID.displayName)")
            message = Message(sender: peerID.displayName, body: "")
            message.image = messageObject as? UIImage
            messages.append(message)
        }


        if NSUserDefaults.enableSounds
        {
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
        }
        dispatch_async(dispatch_get_main_queue())
        {
            self.finishReceivingMessageAnimated(false)
        }

    }

    func session(session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        withProgress progress: NSProgress)
    {

    }

    func session(session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        atURL localURL: NSURL,
        withError error: NSError)
    {

    }

    func session(session: MCSession,
        didReceiveStream stream: NSInputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID)
    {

    }

    func session(session: MCSession,
        peer peerID: MCPeerID,
        didChangeState state: MCSessionState)
    {
        switch state
        {
        case .Connected:
            println("\(peerID.displayName) is now conected.")

            if find(connectedUsers, peerID.displayName) == nil
            {
                connectedUsers.append(peerID.displayName)
            }

            let userInfo = NSUserDefaults.userInfo
			var error : NSError? = nil
                session.sendData(NSData.dataForUserInfo(userInfo),
					toPeers: [peerID],
					withMode: .Reliable,
					error: &error)

                if session.connectedPeers.count > 0
                {
                    println("Error sending info to \(peerID.displayName): \(error)")
                }

            let message = Message(systemMessage: peerID.displayName, body: peerID.displayName + " has connected.")

            messages.append(message)
            dispatch_async(dispatch_get_main_queue())
            {
                    self.finishReceivingMessageAnimated(true)
            }
            title = "Chat (\(session.connectedPeers.count))"

        case .Connecting:
            println("\(peerID.displayName) is now connecting.")
        case .NotConnected:
            println("\(peerID.displayName) has disconnected.")

            if contains(connectedUsers, peerID.displayName) && !contains(session.connectedPeers as! [MCPeerID], peerID)
			{
                connectedUsers.removeAtIndex(find(connectedUsers, peerID.displayName)!)

                let message = Message(systemMessage: peerID.displayName, body: peerID.displayName + " has disconnected.")
                messages.append(message)
                dispatch_async(dispatch_get_main_queue())
                {
                    self.finishReceivingMessageAnimated(true)
                }
                title = "Chat (\(session.connectedPeers.count))"
            }
            locations[peerID.displayName] = nil
            connectedUserInfo[peerID.displayName] = nil
        }
    }

    // MARK: MCNearbyServiceAdvertiserDelegate
	func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!)
	{
		let date = NSKeyedUnarchiver.unarchiveObjectWithData(context!) as! NSDate

		if date.compare(NSUserDefaults.sessionDate) == .OrderedAscending
		{
			println("Joining older session")
			invitationHandler(true, session!)
			NSUserDefaults.sessionDate = date
			for peer in session!.connectedPeers
			{
				browser?.invitePeer(peer as! MCPeerID, toSession: session!, withContext: NSKeyedArchiver.archivedDataWithRootObject(date), timeout: timeout)
			}
		}
	}

    // MARK: MCNearbyServiceBrowserDelegate
	func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!)
    {
        println("Inviting \(peerID.displayName)")

        browser.invitePeer(peerID, toSession: session!,
                           withContext: NSKeyedArchiver.archivedDataWithRootObject(NSUserDefaults.sessionDate),
                           timeout: timeout)
        
    }

	func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!)
    {
        println("Lost peer: \(peerID.displayName)")
    }

    // MARK: UITableViewDataSource (DetailsViewController)
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("detailCell") as? UITableViewCell ?? UITableViewCell()
        cell.textLabel!.text = connectedUsers[indexPath.row]
        return cell
    }

    func tableView(tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int
    {
        return connectedUsers.count
    }

    // Mark: CLLocationManagerDelegate

	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        MCChat.locations[NSUserDefaults.displayName] = locations.last! as? CLLocation
        println("Location updated")
		var error : NSError? = nil

		session?.sendData(NSData.dataForLocation(locations.last! as! CLLocation),
			toPeers: session!.connectedPeers,
			withMode: MCSessionSendDataMode.Reliable,
			error: &error)

		if session?.connectedPeers.count > 0
		{
			println("Error sending location data: \(error)")
		}

    }

}

