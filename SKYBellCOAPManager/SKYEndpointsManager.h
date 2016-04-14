//
//  SKYEndpointsManager.h
//  SkyBell
//
//  Created by Gabriel Sosa Martínez on 11/4/15.
//  Copyright © 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKYConstants.h"

typedef enum : NSUInteger {
    SKYEndPointProduction,
    SKYEndPointStaging
} SKYEndPoint;

@interface SKYEndpointsManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) SKYEndPoint currentEndPoint;

- (void)switchToEndpoint:(SKYEndPoint)endPoint;
- (NSString *)authServerEndpoint;
- (NSString *)apiServerEndpoint;
- (NSString *)coapServerEndpoint;
- (NSString *)nestServerEndpoint;
- (NSString *)nestConfigurationServerEndpoint;
- (NSString *)clientSecret;
- (NSString *)appSecret;
- (NSString *)awsAppId;
- (NSString *)awsPoolId;
- (NSString *)nestClientSecret;
- (NSString *)apiUrlForServerPath:(NSString *)path;
- (NSString *)authUrlForServerPath:(NSString *)path;

@end
