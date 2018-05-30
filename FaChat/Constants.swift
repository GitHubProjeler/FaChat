//
//  Constants.swift
//  FaChat
//
//  Created by fatih acar on 30.05.2018.
//  Copyright © 2018 fatih acar. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Constants {
    static let dbRef = Database.database().reference()
    static let dbChats = dbRef.child("mesajlar")
}
