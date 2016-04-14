//
//  SKYNestPartnerService.h
//  SkyBell
//
//  Created by Juan Jose Karam on 8/25/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const SKYNestCamNameProperty;
extern NSString * const SKYNestCamIsOnlineProperty;
extern NSString * const SKYNestCamIsStreamingProperty;
extern NSString * const SKYNestCamIdentifierProperty;
extern NSString * const SKYNestCamStructureNameProperty;
extern NSString * const SKYNestCameraListDidUpdateNotification;

@protocol SKYNestPartnerServiceDelegate;

@interface SKYNestPartnerService : NSObject

@property (nonatomic, strong, readonly) NSArray *cameraList;
@property (nonatomic, strong) NSString *authorizationCode;
@property (nonatomic, strong, readonly) NSString *accessToken;
@property (nonatomic, weak) id <SKYNestPartnerServiceDelegate> delegate;

+ (instancetype)defaultService;
- (NSURL *)authorizationURL;
- (NSURL *)redirectURL;
- (BOOL)isAuthenticated;
- (void)authenticateWithAccessToken:(NSString *)accessToken expirationTime:(NSTimeInterval)time completion:(void (^)(BOOL authenticated, NSError *error))completion;
- (void)saveAuthenticationWithAccessToken:(NSString *)token;
- (void)deauthenticate;
- (void)deleteCredentials;
- (void)updateCameraListWithCompletion:(void (^)(NSArray *cameraList, NSError *error))completion;
- (void)updateCameraStreaming:(BOOL)streaming withIdentifier:(NSString *)identifier completion:(void (^)(NSError *error))completion;
- (void)deleteNestTokenFromServer;

@end

@protocol SKYNestPartnerServiceDelegate <NSObject>

@optional
- (void)partnerServiceDidDeauthenticate;
- (void)partnerServiceDidFailToDeauthenticateWithError:(NSError *)error;
- (void)partnerServiceDidDeleteCredentials;

@end
