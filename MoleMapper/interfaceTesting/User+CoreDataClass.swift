//
//  User+CoreDataClass.swift
//  MoleMapper
//
// Copyright (c) 2016, 2017 OHSU. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//

import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject {
    
    /**
     create creates a new ZoneMeasurement30 object using the global context maintained
     by the V30Stack singleton factory.
     */
    class func create() -> User {
        return User(context: V30StackFactory.createV30Stack().managedContext)
    }
    
    /**
    getCurrentUser retrieves the user object for a given ID; if no ID is given, it retrieves
    the default (first) ID. If no User exists, it creates one.
    */
    class func getCurrentUser(_ userID: String?) -> User {
        let managedContext = V30StackFactory.createV30Stack().managedContext
        var user: User!
        let userFetch: NSFetchRequest<User> = User.fetchRequest()
        
        do {
            if userID != nil {
                userFetch.predicate = NSPredicate(format: "mmUserID == %@", userID!)
            }
            let result = try managedContext.fetch(userFetch)
            if result.count == 0 {
                let newUser = User(context: managedContext)
                newUser.mmUserID = NSUUID().uuidString
                try managedContext.save()
                user = newUser
            } else {
                user = result[0]
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo)")
        }
        return user
    }

}
