//
//  MessagesViewController.swift
//  FetLife
//
//  Created by Jose Cortinas on 4/20/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import RealmSwift
import JSQMessagesViewController

class MessagesViewController: JSQMessagesViewController {
    var conversation: Conversation! {
        didSet {
            self.messages = try! Realm()
                .objects(Message)
                .filter("conversationId == %@", self.conversation.id)
                .sorted("createdAt", ascending: false)
        }
    }
    
    var messages: Results<Message>!
    var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputToolbar.contentView.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        collectionView.backgroundColor = UIColor.backgroundColor()
        
        if let conversation = conversation {
            self.notificationToken = messages.addNotificationBlock({ [unowned self] results, error in
                guard let results = results where !results.isEmpty else { return }
                
                self.collectionView.reloadData()
                
                let newMessageIds = results.filter("isNew == true").map { $0.id }
                
                if !newMessageIds.isEmpty {
                    API.sharedInstance.markMessagesAsRead(conversation.id, messageIds: newMessageIds)
                }
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.springinessEnabled = true
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        cell.textView.textColor = UIColor.whiteColor()
        cell.textView.backgroundColor = UIColor.blackColor()
        
        cell.textView.linkTextAttributes = [
            NSForegroundColorAttributeName: cell.textView.textColor!
        ]
        
        return cell
    }
    
    @IBAction func refreshAction(sender: UIBarButtonItem) {
        fetchMessages()
    }
    
    func fetchMessages() {
        if let conversation = conversation, let messages = messages {
            let conversationId = conversation.id
            
            if let lastMessage = messages.first {
                let parameters: Dictionary<String, AnyObject> = [
                    "since": Int(lastMessage.createdAt.timeIntervalSince1970),
                    "since_id": lastMessage.id
                ]
                
                Dispatch.asyncOnUserInitiatedQueue() {
                    API.sharedInstance.loadMessages(conversationId, parameters: parameters, completion: nil)
                }
            } else {
                Dispatch.asyncOnUserInitiatedQueue() {
                    API.sharedInstance.loadMessages(conversationId, completion: nil)
                }
            }
        }
    }
}