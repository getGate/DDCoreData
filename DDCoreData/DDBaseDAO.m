//
//  DDBaseDAO.h
//  Example
//
//  Created by DING Leon on 4/17/13.
//  Copyright (c) 2013 LeonValley. All rights reserved.
//

#import "DDBaseDAO.h"
#import "DDCoreDataManager.h"

@implementation DDBaseDAO

- (id)initWithManagedObjectClass:(Class)objectClass {

    self = [super init];
    if (self) {
        _managedObjectClass = objectClass;
    }
    return self;
}

- (id)createInsertedManagedObject {
    NSManagedObjectContext *localContext = [DDCoreDataManager contextForCurrentThread];
    NSEntityDescription *entityDES = [NSEntityDescription entityForName:[_managedObjectClass description] inManagedObjectContext:localContext];
    NSManagedObject *managedObject = [[NSManagedObject alloc] initWithEntity:entityDES insertIntoManagedObjectContext:localContext];
    return managedObject;
}

- (id)createManagedObject {
    NSManagedObjectContext *localContext = [DDCoreDataManager contextForCurrentThread];
    NSEntityDescription *entityDES = [NSEntityDescription entityForName:[_managedObjectClass description] inManagedObjectContext:localContext];
    NSManagedObject *managedObject = [[NSManagedObject alloc] initWithEntity:entityDES insertIntoManagedObjectContext:nil];
    return managedObject;
}


- (void)saveContext:(NSManagedObjectContext *)context {
    NSError *error;
    [context save:&error];
    if (error) {
        NSLog(@"core data save error: %@\r\n%@",[error userInfo],[error debugDescription]);
    }
}

#pragma mark -
#pragma mark Insert
- (void)insertObject:(NSManagedObject *)object {
    [DDCoreDataManager performWriteBlock:^(NSManagedObjectContext *context) {
        [context insertObject:object];
        
        NSError *error;
        [context save:&error];
        if (error) {
            NSLog(@"insert object: %@\r\n%@",[error userInfo],[error debugDescription]);
        }
    }];
}

- (void)insertObjects:(NSArray *)objects {
    [DDCoreDataManager performWriteBlock:^(NSManagedObjectContext *context) {
        for (id object in objects) {
            [context insertObject:object];
        }
        
        if ([context hasChanges]) {
            NSError *error;
            [context save:&error];
            if (error) {
                NSLog(@"insert objects: %@\r\n%@",[error userInfo],[error debugDescription]);
            }
        }
    }];
}

#pragma mark -
#pragma mark Save&Update
- (void)saveOrUpdateObject:(NSManagedObject *)object withUniqueKey:(NSString *)uniqueKey {
    if (uniqueKey && uniqueKey.length>0) {
        [DDCoreDataManager performWriteBlock:^(NSManagedObjectContext *context) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@",uniqueKey,[object valueForKey:uniqueKey]];
            NSFetchRequest *fetchRequest = NSFetchRequest.new;
            fetchRequest.entity = object.entity;
            fetchRequest.predicate = predicate;
            
            NSError *fetchError;
            NSArray *detachedItems = [context executeFetchRequest:fetchRequest error:&fetchError];
            // TODO Report Error
            
            if ([detachedItems count]>0) {
                NSArray *properties = [object.entity properties];
                id detachedObject = [detachedItems objectAtIndex:0];
                for (NSAttributeDescription *anAttribute in properties) {
                    [detachedObject setValue:[object valueForKey:anAttribute.name] forKey:anAttribute.name];
                }
            
            } else {
                [context insertObject:object];
            }
            NSError *error;
            [context save:&error];
            // TODO Report Error
        }];
    } else {
        [self insertObject:object];
    }
}

- (void)saveOrUpdateObjects:(NSArray *)objects withUniqueKey:(NSString *)uniqueKey {
    //TODO
}

#pragma mark -
#pragma mark Delete
// delete
- (void)deleteObject:(NSManagedObject *)object {
    [self deleteObjects:[NSArray arrayWithObject:object]];
}

- (void)deleteObjects:(NSArray *)objects {
    [self deleteObjects:objects completion:nil];
}

- (void)deleteObjects:(NSArray *)objects completion:(void(^)())completion {
    [DDCoreDataManager performWriteBlock:^(NSManagedObjectContext *context) {
        for (NSManagedObject *anObject in objects) {
            [context deleteObject:anObject];
        }
        if ([context hasChanges]) {
            [context save:NULL];
        }
        
        if (completion) {
            completion();
        }
    }];
}

#pragma mark -
#pragma mark Find
- (void)findAll:(void (^)(NSArray *))callback {
    [self findbyPredicate:nil callback:callback];
}

- (void)findbyPredicate:(NSPredicate *)predicate callback:(void (^)(NSArray *))callback {
    [self findbyPredicate:predicate offset:-1 limit:-1 callback:callback];
}

- (void)findbyPredicate:(NSPredicate *)predicate offset:(int)offset limit:(int)limit callback:(void (^)(NSArray *))callback {
    NSFetchRequest *fetchRequest = NSFetchRequest.new;
    fetchRequest.predicate = predicate;
    
    if (offset>-1&&limit>0) {
        fetchRequest.fetchOffset = offset;
        fetchRequest.fetchLimit = limit;
    }
    [self findbyFetchRequest:fetchRequest callback:callback];
}

- (void)findbyFetchRequest:(NSFetchRequest *)fetchRequest callback:(void (^)(NSArray *))callback {
    [DDCoreDataManager performReadBlock:^(NSManagedObjectContext *context) {
        
        fetchRequest.entity = [NSEntityDescription entityForName:[_managedObjectClass description] inManagedObjectContext:context];
        NSError *error;
        NSArray *detachedObjects = [context executeFetchRequest:fetchRequest error:&error];
        //TODO report error
        
        if (callback) {
            callback(detachedObjects);
        }
    }];
}
@end
