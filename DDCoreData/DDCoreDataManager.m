//
//  DDCoreDataManager.h
//  Example
//
//  Created by DING Leon on 4/17/13.
//  Copyright (c) 2013 LeonValley. All rights reserved.
//

#import "DDCoreDataManager.h"

static DDCoreDataManager *sharedCoreDataManager = nil;
NSString *const kDDCoreDataManagedObjectContextKey = @"kDDCoreDataManagedObjectContextKey";

dispatch_queue_t background_save_queue(void);
void cleanup_save_queue(void);

static dispatch_queue_t coredata_background_save_queue;

dispatch_queue_t background_save_queue()
{
    if (coredata_background_save_queue == NULL)
    {
        coredata_background_save_queue = dispatch_queue_create("me.leon.coredata.background", 0);
    }
    return coredata_background_save_queue;
}

void cleanup_save_queue()
{
	if (coredata_background_save_queue != NULL)
	{
        coredata_background_save_queue = NULL;
	}
}

@interface DDCoreDataManager ()
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@end

@implementation DDCoreDataManager
+ (void) setupCoreDataStackWithModelURL:(NSURL *)modelURL atStoreURL:(NSURL *)storeURL {
    
    @synchronized (self) {
        // call clean up first, when re-setup
        if (sharedCoreDataManager) {
            return;
        }
        
        NSManagedObjectModel *managedModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedModel];
        
        NSError *error;
        NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                            configuration:nil
                                                                                      URL:storeURL
                                                                                  options:options
                                                                                    error:&error];
        if (!store) {
            NSLog(@"Core Data Stack setup failed %@, %@",error,[error userInfo]);
#ifdef DEBUG
            abort();
#endif
        } else {
            DDCoreDataManager *coreDataManager = DDCoreDataManager.new;
            coreDataManager.managedObjectModel = managedModel;
            coreDataManager.persistentStoreCoordinator = persistentStoreCoordinator;
            
            sharedCoreDataManager = coreDataManager;
        }
        
    }
}

+ (void)cleanUpCoreDataStack {
    
}

- (NSString *)description {
    NSMutableString *description = [NSString stringWithFormat:@"Core Data Stack: ---- \n"];
    
    //TODO debug 
    return description;
}

#pragma mark -
#pragma mark Context
+ (NSManagedObjectContext *) mainContext {
    return sharedCoreDataManager.mainContext;
}

- (NSManagedObjectContext *) mainContext {
    
    if (_mainContext) {
        return _mainContext;
    }
    
    if ([NSThread isMainThread]) {
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
        _mainContext = context;
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
            [context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
            _mainContext = context;
        });
    }
    return _mainContext;
}

+ (NSManagedObjectContext *) contextForCurrentThread {
    if ([NSThread isMainThread]) {
        return [self mainContext];
    } else {
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSManagedObjectContext *threadContext = [threadDictionary objectForKey:kDDCoreDataManagedObjectContextKey];
        if (threadContext == nil) {
            threadContext = [[NSManagedObjectContext alloc] init];
            [threadContext setPersistentStoreCoordinator:sharedCoreDataManager.persistentStoreCoordinator];
            [threadDictionary setObject:threadContext forKey:kDDCoreDataManagedObjectContextKey];
        }
        return threadContext;
    }
    return nil;
}

+ (void) closeContextForCurrentThread {
    //TODO 
}

#pragma mark -
#pragma mark Operation On
+ (void) performReadBlock:(DDCoreDataBlock)readBlock {
    NSManagedObjectContext *managedObjectContext = [self contextForCurrentThread];
    if (readBlock) {
        readBlock(managedObjectContext);
    }
}

+ (void) performWriteBlock:(DDCoreDataBlock)writeBlock {
    NSManagedObjectContext *managedContext = [self contextForCurrentThread];
    //TODO merge to mainContext;
    if (writeBlock) {
        writeBlock(managedContext);
    }
}

#pragma mark -
#pragma mark Operation on Background Thread 
+ (void) performReadBlockInBackgroundThread:(DDCoreDataBlock)readBlock {
    dispatch_async(background_save_queue(), ^{
        [self performReadBlock:readBlock];
    });
}

+ (void) performWriteBlockInBackgroundThread:(DDCoreDataBlock)writeBlock {
    dispatch_async(background_save_queue(), ^{
        [self performWriteBlock:writeBlock];
    });
}
@end
