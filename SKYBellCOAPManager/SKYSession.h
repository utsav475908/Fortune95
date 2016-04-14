//
//  SKYSession.h
//  SkyBell
//
//  Created by Luis Hernandez on 6/4/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//



typedef void (^onNestUserLinkedInfoFail)(void);

#import <Foundation/Foundation.h>
@class AFOAuthCredential;
@class AFOAuth2Manager;
typedef void (^onNestUserLinkedInfoSuccess) (BOOL isSignedIn);
@interface SKYSession : NSObject

@property (nonatomic, strong) AFOAuth2Manager *oAuth2Manager;
@property (nonatomic, copy) onNestUserLinkedInfoSuccess onNestUserLinkedInfoSuccess;
@property (nonatomic, copy) onNestUserLinkedInfoFail onNestUserLinkedInfoFail;

+ (instancetype)sharedInstance;
- (void)requestInviteTokenWithSuccess:(void(^) (NSString * inviteToken)) success
                              failure:(void(^) (NSError * error))failure;
- (BOOL)isValid;
- (void)signInWithParameters:(NSDictionary *)parameters
                     success:(void(^) (void)) success
                     failure:(void(^) (NSError * error))failure;
- (void)signUpWithParameters:(NSDictionary *)parameters
                     success:(void(^) (void)) success
                     failure:(void(^) (NSError * error))failure;
- (void)killSessionWithSuccess:(void (^) (BOOL success))success;
- (void)sendPushNotificationTokenToServer:(NSString *)notificationToken;
- (void)updatePasswordWithOldPassword:(NSString *)oldPassword
                          newPassword:(NSString *)newPassword
                              success:(void(^) (void)) success
                              failure:(void(^) (NSError * error))failure;
- (void)updateUsername:(NSString *)username
               success:(void(^) (void)) success
               failure:(void(^) (NSError * error))failure;
- (void)resetPasswordForUsername:(NSString *)username
                         success:(void (^) (void))success
                         failure:(void (^) (NSError *error))failure;
- (void)forcePushRegistration;
- (void)getUserLinkedInfo;
- (NSString *)accessToken;

@end
