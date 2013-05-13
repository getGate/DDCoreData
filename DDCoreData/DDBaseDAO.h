//
//  DDBaseDAO.h
//  Example
//
//  Created by DING Leon on 4/17/13.
//  Copyright (c) 2013 LeonValley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DDBaseDAO : NSObject

@property (nonatomic, assign, readonly) Class managedObjectClass;

- (id)initWithManagedObjectClass:(Class)objectClass;

// create a managedObject and insert it into current context
// equal to createManagedObject + insertObject
- (id)createInsertedManagedObject;

// recommended method for creating managedObject
- (id)createManagedObject;

- (void)saveContext:(NSManagedObjectContext *)context;

// insert 
- (void)insertObject:(NSManagedObject *)object;
- (void)insertObjects:(NSArray *)objects;

// save or update
// Managed object must have an uniqueKey，otherwise equal to insert methods
- (void)saveOrUpdateObject:(NSManagedObject *)object withUniqueKey:(NSString *)uniqueKey;
- (void)saveOrUpdateObjects:(NSArray *)objects withUniqueKey:(NSString *)uniqueKey;

// delete
- (void)deleteObject:(NSManagedObject *)object;
- (void)deleteObjects:(NSArray *)objects;
- (void)deleteObjects:(NSArray *)objects completion:(void(^)())completion;

// find
- (void)findbyFetchRequest:(NSFetchRequest *)fetchRequest callback:(void(^)(NSArray *detachedObjects))callback;

- (void)findAll:(void(^)(NSArray *detachedObjects))callback;

// see http://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795-SW1
- (void)findbyPredicate:(NSPredicate *)predicate callback:(void(^)(NSArray *detachedObjects))callback;
- (void)findbyPredicate:(NSPredicate *)predicate offset:(int)offset limit:(int)limit callback:(void (^)(NSArray *))callback;
@end
