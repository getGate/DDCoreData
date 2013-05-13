//
//  DDCoreDataManager.h
//  Example
//
//  Created by DING Leon on 4/17/13.
//  Copyright (c) 2013 LeonValley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void (^DDCoreDataBlock)(NSManagedObjectContext *context);

extern NSString *const kDDCoreDataManagedObjectContextKey;

@interface DDCoreDataManager : NSObject

//use this method to setup a core data stack
+ (void) setupCoreDataStackWithModelURL:(NSURL *)modelURL atStoreURL:(NSURL *)storeURL;
+ (void) cleanUpCoreDataStack;

// database connetion
+ (NSManagedObjectContext *) mainContext;

// Util now, I haven`t found a good strategy to manage contexts on different threads.
// So, make sure to call closeContextForCurrentThread when you are no longer use it
+ (NSManagedObjectContext *) contextForCurrentThread;
+ (void) closeContextForCurrentThread;

// Use these methods below to do save, update, delete operations
// We will prepare an Appropriate managed context for you :D
+ (void) performWriteBlock:(DDCoreDataBlock)writeBlock;
+ (void) performReadBlock:(DDCoreDataBlock)readBlock;

// enqueque a write block, which are forced to be performed in background thread
// you can use this method to perform large save/update operations
+ (void) performWriteBlockInBackgroundThread:(DDCoreDataBlock)writeBlock;

// we do not recommend enqueue a read operation to background thread from main thread
// Because NSManagedObject is not thread safe also. Show respect to this principle when you are using this method.
+ (void) performReadBlockInBackgroundThread:(DDCoreDataBlock)readBlock;
@end
