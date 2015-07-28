//
//  Extensions.swift
//  BluetoothChat
//
//  Created by Moray on 23/06/15.
//  Copyright © 2015 Moray. All rights reserved.
//

import UIKit
import JSQMessagesViewController

var orientation = 0.0

func avatarForDisplayName(name : String) -> JSQMessageAvatarImageDataSource
{
    let avatar : JSQMessageAvatarImageDataSource

    if NSUserDefaults.displayName == name
    {
        if NSUserDefaults.avatar == nil
        {
            // Initials
            avatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(
                name,
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
        if connectedUserInfo[name]?.avatar == nil
        {
            // Initials
            avatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(
                name.initials,
                backgroundColor: UIColor.grayColor(),
                textColor: UIColor.whiteColor(),
                font: UIFont.systemFontOfSize(14),
                diameter: 34)
        }
        else
        {
            // Avatar
            avatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(connectedUserInfo[name]?.avatar, diameter: 34)
        }
    }

    return avatar
}



extension String
{
    var length : Int
    {
        return lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
    }
    subscript(i : Int) -> Character
    {
        return Character(UnicodeScalar((self as NSString).characterAtIndex(i)))
    }

    var initials : String
    {
        let str = self as NSString
        var initials = str.substringToIndex(1)

        for i in 1..<str.length
        {
            if self[i-1] == Character(" ") && self[i] != Character(" ")
            {
                initials = initials + "\(self[i])"
            }
        }
        return initials
    }

}

extension UIImage
{

    func scaledTo(size : CGSize) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.drawInRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }

}

enum MessageDataType : UInt8
{
    case UserInfo = 0
    case TextMessage
    case ImageMessage
    case Location
}

extension NSData
{
    class func dataWithOneByte(x : UInt8) -> NSMutableData
    {
        let data = UnsafeMutablePointer<UInt8>(malloc(1))
        data.memory = x
        let byteData = NSMutableData(bytes: data, length: 1)
        data.destroy()
        return byteData
    }

    class func dataForUserInfo(userInfo : UserInfo) -> NSData
    {
        let data = dataWithOneByte(0)
        data.appendData(NSKeyedArchiver.archivedDataWithRootObject(userInfo))
        return data
    }

    class func dataForTextMessage(message : String) -> NSData
    {
        let data = dataWithOneByte(1)
        data.appendData(message.dataUsingEncoding(NSUTF8StringEncoding)!)
        return data
    }

    class func dataForImageMessage(image : UIImage) -> NSData
    {
        let data = dataWithOneByte(2)
        data.appendData(NSKeyedArchiver.archivedDataWithRootObject(image))
        return data
    }
    
    class func dataForLocation(location : CLLocation) -> NSData
    {
        let data = dataWithOneByte(3)
        data.appendData(NSKeyedArchiver.archivedDataWithRootObject(location))
        return data
    }

    class func messageData(data : NSData) -> (MessageDataType, AnyObject?)
    {
        let control = UnsafePointer<UInt8>(data.bytes)

        let messageData = NSMutableData()
        messageData.appendBytes(control.advancedBy(1), length: data.length - 1)
        let type = MessageDataType(rawValue: control.memory)!
        let obj : AnyObject?
        if type != .TextMessage
        {
            obj = NSKeyedUnarchiver.unarchiveObjectWithData(messageData)
        }
        else
        {
            obj = NSString(data: messageData, encoding: NSUTF8StringEncoding) as? String
        }
        return (type, obj)
    }
}

extension JSQMessagesBubbleImageFactory
{
    class var incomingMessageBubble : JSQMessageBubbleImageDataSource
    {
        return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    }

    class var outgoingMessageBubble : JSQMessageBubbleImageDataSource
    {
        return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleRedColor())
    }
    class var systemMessageBubble : JSQMessageBubbleImageDataSource
    {
        return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    }
}

extension NSUserDefaults
{
    private static let displayNameKey = "MCCDisplayNameKey"
    private static let avatarKey = "MCCAvatarKey"
    private static let disableSoundsKey = "MCCEnableSoundsKey"
    private static let firstNameKey = "MCCFirstNameKey"
    private static let lastNameKey = "MCCLastNameKey"
    private static let ageKey = "MCCAgeKey"
    private static let bioKey = "MCCBioKey"
    private static let sessionDateKey = "MCCSessionDate"

    class var displayName : String
    {
        get
        {
            let name = NSUserDefaults.standardUserDefaults().stringForKey(displayNameKey)
            return name == nil  || name! == "" ? UIDevice.currentDevice().name : name!
        }
        set
        {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: displayNameKey)
        }
    }

    class var avatar : UIImage?
    {
        get
        {
            let data = NSUserDefaults.standardUserDefaults().dataForKey(avatarKey)
            if data == nil
            {
                return nil
            }
            return NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? UIImage
        }
        set
        {
            let data : NSData? = newValue == nil ? nil : NSKeyedArchiver.archivedDataWithRootObject(newValue!)
            NSUserDefaults.standardUserDefaults().setObject(data, forKey: avatarKey)
        }
    }

    class var enableSounds : Bool
    {

        get
        {
            return !NSUserDefaults.standardUserDefaults().boolForKey(disableSoundsKey)
        }
        set
        {
            NSUserDefaults.standardUserDefaults().setBool(!newValue, forKey: disableSoundsKey)
        }
    }

    class var firstName : String
    {
        get
        {
            let name = NSUserDefaults.standardUserDefaults().stringForKey(firstNameKey)
            return name ?? randomString(7)
        }
        set
        {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: firstNameKey)
        }
    }

    class var lastName : String
    {
        get
        {
            let name = NSUserDefaults.standardUserDefaults().stringForKey(lastNameKey)
            return name ?? randomString(7)
        }
        set
        {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: lastNameKey)
        }
    }

    class var age : Int
    {
        get
        {
            let age = NSUserDefaults.standardUserDefaults().integerForKey(ageKey)
            return age != 0 ? age : Int(arc4random() % 98 + 1)
        }
        set
        {
            NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: ageKey)
        }
    }

    class var bio : String
    {
        get
        {
            let bio = NSUserDefaults.standardUserDefaults().stringForKey(bioKey)
            return bio ?? randomString(100)
        }
        set
        {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: bioKey)
        }
    }

    class var sessionDate : NSDate
    {
        get
        {
            let date = NSUserDefaults.standardUserDefaults().objectForKey(sessionDateKey) as? NSDate
            if date == nil
            {
                self.sessionDate = NSDate()
                return self.sessionDate
            }
            return date!
        }
        set
        {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: sessionDateKey)
        }
    }

    class var userInfo : UserInfo
    {
        let userInfo = UserInfo(displayName: displayName, sessionDate: NSUserDefaults.sessionDate)
        userInfo.firstName = NSUserDefaults.firstName
        userInfo.lastName = NSUserDefaults.lastName
        userInfo.age = NSUserDefaults.age
        userInfo.bio = NSUserDefaults.bio
        userInfo.avatar = NSUserDefaults.avatar
        userInfo.orientation = orientation
        
        return userInfo
    }

    class func resetDefaults()
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(nil, forKey: displayNameKey)
        defaults.setObject(nil, forKey: avatarKey)
        defaults.setBool(false, forKey: disableSoundsKey)
    }

    private class func randomString(length : Int) -> String
    {
        var str = ""
        for i in 0..<length
        {
            str += i % 5 == 0 ? " " : "\(Character(UnicodeScalar(arc4random() % 26 + 97)))"
        }
        return str
    }

}

extension CGPoint
{
    func distanceTo(point : CGPoint) -> Double
    {
        let dx2 = Double((x - point.x)*(x - point.x))
        let dy2 = Double((y - point.y)*(y - point.y))
        return sqrt(dx2 + dy2)
    }
}

