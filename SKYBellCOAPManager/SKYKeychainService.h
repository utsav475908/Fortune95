//
//  SKYKeychainService.h
//  SkyBell
//
//  Created by Juan Jose Karam on 8/25/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKYKeychainService : NSObject

@property (nonatomic, assign) BOOL didFailToReadKeychain;

+ (instancetype)defaultKeychainService;
- (BOOL)storeObject:(id)object withIdentifier:(NSString *)identifier;
- (id)retrieveObjectWithIdentifier:(NSString *)identifier;
- (BOOL)deleteObjectWithIdentifier:(NSString *)identifier;

@end
