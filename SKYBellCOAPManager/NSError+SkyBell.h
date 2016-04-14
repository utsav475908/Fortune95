//
//  NSError+SkyBell.h
//  SkyBell
//
//  Created by Luis Hernandez on 7/14/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, SKYCoAPError) {
    SKYCoAPErrorServiceUnavailable,
    SKYCoAPErrorUdpSocket,
    SKYCoAPErrorResponseTimeout,
    SKYCoAPErrorServerCommunication,
    SKYCoAPErrorUnauthorized
};

@interface NSError (SkyBell)

- (NSUInteger)httpErrorCode;
+ (instancetype)SKYWebServiceHTTPError: (NSHTTPURLResponse *)response;
+ (instancetype)SKYCoAPErrorWithCode:(SKYCoAPError)code userInfo:(NSDictionary *)dictionary;

@end
