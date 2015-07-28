//
//  Message.swift
//  BluetoothChat
//
//  Created by Moray on 23/06/15.
//  Copyright © 2015 Moray. All rights reserved.
//

import UIKit
import JSQMessagesViewController

@objc class Message : NSObject, JSQMessageData
{

    var body : String
    var sender : String
    let dateCreated = NSDate()
    var initials : String
    var image : UIImage?
    let isSystemMessage : Bool

    init(sender : String, body : String)
    {
        self.sender = sender
        self.body = body

        let str = sender as NSString
        initials = str.substringToIndex(1)

        for i in 1..<sender.length
        {
            if sender[i-1] == Character(" ") && sender[i] != Character(" ")
            {
                initials = initials + "\(sender[i])"
            }
        }
        isSystemMessage = false
    }

    init(systemMessage sender : String, body : String)
    {
        self.sender = sender
        self.body = body

        let str = sender as NSString
        initials = str.substringToIndex(1)

        for i in 1..<sender.length
        {
            if sender[i-1] == Character(" ") && sender[i] != Character(" ")
            {
                initials = initials + "\(sender[i])"
            }
        }
        isSystemMessage = true
    }

    var jsqMessage : JSQMessage
    {
        if image == nil
        {
            return JSQMessage(senderId: senderId(), senderDisplayName: senderDisplayName(), date: date(), text: text())
        }
        return JSQMessage(senderId: senderId(), senderDisplayName: senderDisplayName(), date: date(), media: JSQPhotoMediaItem(image: image!))
    }

    // MARK: JSQMessageData
    func senderDisplayName() -> String!
    {
        return sender
    }

    func senderId() -> String!
    {
        return senderDisplayName()
    }

    func text() -> String!
    {
        return body
    }

    func date() -> NSDate!
    {
        return dateCreated
    }

    func isMediaMessage() -> Bool
    {
        return false
    }

    func messageHash() -> UInt
    {
        return UInt(abs(body.hash))
    }

}