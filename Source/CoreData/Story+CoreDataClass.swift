//
//  Story+CoreDataClass.swift
//  MoleMapper
//
// Copyright (c) 2018 OHSU. All rights reserved.
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

// TODO: remove from database

import Foundation
import CoreData

@objc(Story)
public class Story: NSManagedObject {


    class func deleteStory(story: Story) {
        let context = StoryStackFactory.createStoryStack().managedContext
        context.delete(story)
        do {
            try context.save()
        }
        catch let err as NSError {
            print("deleteStory failed  \(err), \(err.userInfo)")
        }
    }
    
    class func deleteExpiredStories() {
        let expiredStories = NSFetchRequest<NSFetchRequestResult>(entityName: "Story")
        expiredStories.predicate = NSPredicate(format: "expireDate < %@", Date() as NSDate)
        let batchDelete = NSBatchDeleteRequest(fetchRequest: expiredStories)
        do {
            try StoryStackFactory.createStoryStack().managedContext.execute(batchDelete)
        }
        catch {
            fatalError("failed to delete expired stories")
        }
    }
    
    class func storyFromID(uuid: UUID) -> Story? {
        let storyFetch: NSFetchRequest<Story> = Story.fetchRequest()
        storyFetch.predicate = NSPredicate(format: "storyID == %@", uuid as NSUUID)
        do {
            let result = try StoryStackFactory.createStoryStack().managedContext.fetch(storyFetch)
            if result.count > 0 {
                return result[0]   //
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) ")
        }
        return nil
    }
    
    class func unexpiredStories() -> [Story] {
        var stories: [Story] = []
        let storyFetch: NSFetchRequest<Story> = Story.fetchRequest()
        storyFetch.predicate = NSPredicate(format: "expireDate > %@", Date() as NSDate)
        let sortDesc = NSSortDescriptor(key: "publishDate", ascending: false)
        storyFetch.sortDescriptors = [sortDesc]
        do {
            let result = try StoryStackFactory.createStoryStack().managedContext.fetch(storyFetch)
            if result.count > 0 {
                stories = result   //
            } else {
                print("no stories")
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) ")
        }
        
        return stories
    }
    
    class func unreadStoryCount() -> Int {
        let storyFetch: NSFetchRequest<Story> = Story.fetchRequest()
        storyFetch.predicate = NSPredicate(format: "expireDate > %@ and hasBeenRead == NO", Date() as NSDate)
        do {
            let result = try StoryStackFactory.createStoryStack().managedContext.fetch(storyFetch)
            return result.count
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) ")
        }

        return 0
    }
}
