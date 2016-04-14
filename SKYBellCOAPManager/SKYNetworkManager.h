//
//  SKYNetworkManager.h
//  SkyBell
//
//  Created by Luis Hernandez on 7/10/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^onRequestSuccess) (id responseObject);
typedef void (^onRequestFail) (NSError *error);

extern NSInteger const kAccessTokenNotFound;

@interface SKYNetworkManager : NSObject

@property (nonatomic, copy) onRequestSuccess onRequestSuccess;
@property (nonatomic, copy) onRequestFail onRequestFail;

- (void)POST:(NSDictionary *)parameters url:(NSString *)url;
- (void)GET:(NSDictionary *)parameters url:(NSString *)url;
- (void)PATCH:(NSDictionary *)parameters url:(NSString *)url;
- (void)DELETE:(NSDictionary *)parameters url:(NSString *)url;
- (void)cancelAllRequests;

@end
