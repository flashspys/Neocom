//
//  NCDBDgmppItemShipResources+CoreDataProperties.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBDgmppItemShipResources.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItemShipResources (CoreDataProperties)

@property (nonatomic) int16_t hiSlots;
@property (nonatomic) int16_t launchers;
@property (nonatomic) int16_t lowSlots;
@property (nonatomic) int16_t medSlots;
@property (nonatomic) int16_t rigSlots;
@property (nonatomic) int16_t turrets;
@property (nullable, nonatomic, retain) NCDBDgmppItem *item;

@end

NS_ASSUME_NONNULL_END
