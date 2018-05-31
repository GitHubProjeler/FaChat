//
//  Constants.swift
//  FaChat
//
//  Created by fatih acar on 30.05.2018.
//  Copyright © 2018 fatih acar. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

struct Constants {
    static let dbRef = Database.database().reference()
    static let dbChats = dbRef.child("Mesajlar")
    static let dbMedias = dbRef.child("Gorseller")
    
    static let storageRef = Storage.storage().reference(forURL:"gs://chat-udemy-app-ece71.appspot.com/")
    static let imageStorageRef = storageRef.child("Resimler")
    static let videoStorageRef = storageRef.child("Videolar")
}
