//
//  UserInfo.swift
//  MultipeerConnectivityChat
//
//  Created by Moray on 30/06/15.
//  Copyright © 2015 Moray. All rights reserved.
//

import UIKit

class UserInfo : NSObject, NSCoding
{
    var displayName : String
    var firstName : String?
    var lastName : String?
    var age : Int?
    var bio : String?
    var avatar : UIImage?
    var sessionDate : NSDate
    var orientation : Double = 0.0

    init(displayName : String, sessionDate : NSDate)
    {
        self.displayName = displayName
        self.sessionDate = sessionDate
    }

    required init(coder decoder: NSCoder)
    {

        self.displayName = ""
        self.firstName = decoder.decodeObjectForKey("MCCFirstName") as? String
        self.lastName = decoder.decodeObjectForKey("MCCLastName") as? String
        self.age = decoder.decodeIntegerForKey("MCCAge")
        self.bio = decoder.decodeObjectForKey("MCCBio") as? String
        self.avatar = decoder.decodeObjectForKey("MCCAvatar") as? UIImage
        self.sessionDate = NSDate()
        self.orientation = decoder.decodeDoubleForKey("MCCOrientation")

		let displayName = decoder.decodeObjectForKey("MCCDisplayName") as? String
		let sessionDate = decoder.decodeObjectForKey("MCCSessionDate") as? NSDate

        if displayName == nil || sessionDate == nil
        {
            super.init()
            return
        }

        self.sessionDate = sessionDate!
        self.displayName = displayName!
        super.init()
    }

    func encodeWithCoder(coder: NSCoder)
    {
        coder.encodeObject(displayName, forKey: "MCCDisplayName")
        coder.encodeObject(firstName, forKey: "MCCFirstName")
        coder.encodeObject(lastName, forKey: "MCCLastName")
        if age != nil
        {
            coder.encodeInteger(age!, forKey: "MCCAge")
        }
        coder.encodeObject(bio, forKey: "MCCBio")
        coder.encodeObject(avatar, forKey: "MCCAvatar")
        coder.encodeObject(sessionDate, forKey: "MCCSessionDate")
        coder.encodeDouble(orientation, forKey: "MCCOrientation")
    }
}
