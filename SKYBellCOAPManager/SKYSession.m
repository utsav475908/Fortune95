//
//  SKYSession.m
//  SkyBell
//
//  Created by Luis Hernandez on 6/4/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import "SKYSession.h"
#import "AFOAuth2Manager.h"
#import "SKYNetworkManager.h"
#import "SKYKeychainService.h"
#import "SKYNestPartnerService.h"
#import "SKYEndpointsManager.h"

@interface SKYSession ()

@property (nonatomic, assign) BOOL isSessionValid;
@property (nonatomic, strong) NSString *resourceId;

@end

@implementation SKYSession
#define UNIQUE_KEY( x ) NSString * const x = @#x

UNIQUE_KEY(SKYAccountManagerUserDidAuthenticateNotification);

__strong static id _sharedObject = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t pred = 0;

    dispatch_once(&pred, ^
    {
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}

- (void)forcePushRegistration {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerForRemoteNotifications)]) {
        UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

- (void)signInWithParameters:(NSDictionary *)parameters
                     success:(void (^) (void))success
                     failure:(void (^) (NSError *error))failure {
    [self.oAuth2Manager setUseHTTPBasicAuthentication:YES];
    [self.oAuth2Manager
     authenticateUsingOAuthWithURLString:@"token"
                              parameters:parameters
                                 success:^(AFOAuthCredential *credential)
    {
        //Still saving in keychain for "security" reasons
        //but this https://forums.developer.apple.com/thread/4743
        //is still an open bug from Apple that prevents
        //app from reading from the keychain when switching
        //from background to foreground and make the users lose their session
        [AFOAuthCredential storeCredential:credential
                            withIdentifier:self.oAuth2Manager.serviceProviderIdentifier];

        //In the meantime we need to user user defaults because
        //this is a problem with a lot of users getting their session finished
        //So, until this bug is fixed from Apple, we need a workaround on this side
        [[NSUserDefaults standardUserDefaults] setObject:credential.accessToken forKey:kAccessToken];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [[NSNotificationCenter defaultCenter]
         postNotificationName:SKYAccountManagerUserDidAuthenticateNotification
                       object:self];
        [self forcePushRegistration];
        [self getUserLinkedInfo];
        success();
    }
                                 failure:^(NSError *error)
    {
        failure(error);
    }];
}

- (void)signUpWithParameters:(NSDictionary *)parameters
                     success:(void (^) (void))success
                     failure:(void (^) (NSError *error))failure {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    networkManager.onRequestSuccess = ^(id responseObject)
    {
        if ([responseObject valueForKey:@"resourceId"]) {
            self.resourceId = [responseObject valueForKey:@"resourceId"];
        }

        NSDictionary *tokenParameters = @{ @"grant_type": @"password",
                                           @"username": [parameters valueForKey:@"username"],
                                           @"password": [parameters valueForKey:@"password"],
                                           @"scope": @"application" };

        [self createAccessTokenWithParameters:tokenParameters
                                 tokenSuccess:^ {
            [self createUserWithParameters:@{ @"firstName": [parameters valueForKey:@"firstName"],
                                              @"lastName": [parameters valueForKey:@"lastName"] }
                               userSuccess:^ {
                if (success) {
                    success();
                }
            }
                               userFailure:^(NSError *error) {
                if (failure) {
                    failure(error);
                }
            }];
        }
                                 tokenFailure:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    };

    networkManager.onRequestFail = ^(NSError *error) {
        if (failure) {
            failure(error);
        }
    };

    NSString *url = [[SKYEndpointsManager sharedManager] authUrlForServerPath:kResourcesUrl];

    [networkManager POST:@{ @"username": [parameters valueForKey:@"username"],
                            @"password": [parameters valueForKey:@"password"],
                            @"resourceClass": @"user" }
                     url:url];
}

- (void)createAccessTokenWithParameters:(NSDictionary *)parameters
                           tokenSuccess:(void (^) (void))tokenSuccess
                           tokenFailure:(void (^) (NSError *error))tokenFailure {
    [self.oAuth2Manager setUseHTTPBasicAuthentication:YES];
    [self.oAuth2Manager
     authenticateUsingOAuthWithURLString:@"token"
                              parameters:parameters
                                 success:^(AFOAuthCredential *credential) {
                                     [AFOAuthCredential  storeCredential:credential
                                     withIdentifier:self.oAuth2Manager.serviceProviderIdentifier];
                                     tokenSuccess();
                                 }
                                 failure:^(NSError *error) {
                                     tokenFailure(error);
                                 }];
}

- (void)createUserWithParameters:(NSDictionary *)parameters
                     userSuccess:(void (^) (void))userSuccess
                     userFailure:(void (^) (NSError *error))userFailure {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    networkManager.onRequestSuccess = ^(id responseObject)
    {
        userSuccess();
    };

    networkManager.onRequestFail = ^(NSError *error)
    {
        userFailure(error);
    };

    NSString *url = [[SKYEndpointsManager sharedManager] apiUrlForServerPath:kCreateUserUrl];
    
    [networkManager POST:parameters url:url];
}

- (void)requestInviteTokenWithSuccess:(void (^) (NSString *inviteToken))success
                              failure:(void (^) (NSError *error))failure {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    networkManager.onRequestSuccess = ^(id responseObject)
    {
        NSString *token;

        if ([responseObject valueForKey:@"token"]) {
            token = [responseObject valueForKey:@"token"];
        }

        if (success) {
            success(token);
        }
    };

    networkManager.onRequestFail = ^(NSError *error)
    {
        if (failure) {
            failure(error);
        }
    };

    NSString *url = [[SKYEndpointsManager sharedManager] apiUrlForServerPath:kInviteTokenUrl];
    [networkManager POST:nil url:url];
}

- (void)updatePasswordWithOldPassword:(NSString *)oldPassword
                          newPassword:(NSString *)newPassword
                              success:(void (^) (void))success
                              failure:(void (^) (NSError *error))failure {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    networkManager.onRequestSuccess = ^(id responseObject) {
        if (success) {
            success();
        }
    };

    networkManager.onRequestFail = ^(NSError *error) {
        if (failure) {
            failure(error);
        }
    };

    NSString *url = [[SKYEndpointsManager sharedManager] authUrlForServerPath:kUpdatePasswordUrl];
    
    [networkManager PATCH:@{
         @"newPassword": newPassword,
         @"password": oldPassword
     }
                      url:url];
}

- (void)updateUsername:(NSString *)newUsername
               success:(void(^) (void)) success
               failure:(void(^) (NSError * error))failure {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    networkManager.onRequestSuccess = ^(id responseObject) {
        if (success) {
            success();
        }
    };

    networkManager.onRequestFail = ^(NSError *error) {
        if (failure) {
            failure(error);
        }
    };

    NSString *url = [[SKYEndpointsManager sharedManager] authUrlForServerPath:kResourcesUrl];

    [networkManager PATCH:@{@"username": newUsername}
                     url:url];
}

- (void)sendPushNotificationTokenToServer:(NSString *)notificationToken {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    networkManager.onRequestSuccess = ^(id responseObject){
#if DEBUG
        NSLog(@"success token register: %@", responseObject);
#endif
    };

    networkManager.onRequestFail = ^(NSError *error) {
#if DEBUG
        NSLog(@"error token register: %@", error);
#endif
    };

    NSString *url = [[SKYEndpointsManager sharedManager] apiUrlForServerPath:kNotifiersUrl];
    NSString *protocol = @"apns";

#if DEBUG
    if ([[SKYEndpointsManager sharedManager] currentEndPoint] == SKYEndPointStaging) {
        protocol = @"apns-sandbox";
    }
#endif

    SKYKeychainService *keychainService = [SKYKeychainService defaultKeychainService];
    NSString *appId = [keychainService retrieveObjectWithIdentifier:kAppIdKey];

    if (!appId) {
        if (keychainService.didFailToReadKeychain) {
            appId = [[NSUserDefaults standardUserDefaults] objectForKey:kAppIdKey];
        }
        if (!appId) {
            appId = @"null";
        }
    }

    [networkManager POST:@{
         @"protocol": protocol,
         @"eventType": @"device:sensor:motion",
         @"token": notificationToken,
         @"appId" : appId
     }
                     url:url];
}

- (void)getUserLinkedInfo {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    networkManager.onRequestSuccess = ^(id responseObject) {
        [self updateUserLinkedAccountWithDictionary:[responseObject valueForKey:@"userLinks"]];
        SKYKeychainService *keychainService = [SKYKeychainService defaultKeychainService];
        [keychainService storeObject:[responseObject valueForKey:@"id"] withIdentifier:kUserIdKey];
    };

    networkManager.onRequestFail = ^(NSError *error) {
#if DEBUG
        NSLog(@"ERROR retrieving user links");
#endif
        if (self.onNestUserLinkedInfoFail) {
            self.onNestUserLinkedInfoFail();
        }
    };

    NSString *url = [[SKYEndpointsManager sharedManager] apiUrlForServerPath:kUserInfoUrl];
    [networkManager GET:nil url:url];
}

- (void)updateUserLinkedAccountWithDictionary:(id)userLink {
    BOOL isLinkedToNest = NO;
    if (userLink && [userLink count] > 0) {
        NSDictionary *values = [userLink objectAtIndex:0];
        if ([values valueForKey:@"partnerName"]) {
            if ([[values valueForKey:@"partnerName"] isEqualToString:@"nest"]) {
                NSString *accessToken = [values valueForKey:@"accessToken"];
                [[SKYNestPartnerService defaultService] saveAuthenticationWithAccessToken:accessToken];
                isLinkedToNest = YES;
            }
        }
    }
    else if ((userLink && [userLink count] == 0) || !userLink) {
        if ([[SKYNestPartnerService defaultService] isAuthenticated]) {
            [[SKYNestPartnerService defaultService] deauthenticate];
        }
    }

    if (self.onNestUserLinkedInfoSuccess) {
        self.onNestUserLinkedInfoSuccess(isLinkedToNest);
    }
}

- (void)deleteNotificationTokenFromServer {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    NSString *notificationToken = [[NSUserDefaults standardUserDefaults] objectForKey:kPushTokenDefaultsKey];

    networkManager.onRequestSuccess = ^(id responseObject) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPushTokenDefaultsKey];
    };

    networkManager.onRequestFail = ^(NSError *error) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPushTokenDefaultsKey];
    };

    if (notificationToken) {
        NSString *url = [[SKYEndpointsManager sharedManager] apiUrlForServerPath:kNotifiersUrl];
        [networkManager DELETE:@{@"token": notificationToken} url:url];
    }
}

- (void)resetPasswordForUsername:(NSString *)username
                         success:(void (^) (void))success
                         failure:(void (^) (NSError *error))failure {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];
    networkManager.onRequestSuccess = ^(id responseObject) {
        if (success) {
            success();
        }
    };

    networkManager.onRequestFail = ^(NSError * error) {
        if (failure) {
            failure(error);
        }
    };

    NSString *url = [[SKYEndpointsManager sharedManager] authUrlForServerPath:kResetPasswordUrl];
    [networkManager POST:@{@"username": username} url:url];
}

- (BOOL)isValid {
    return [self accessToken] == nil ? NO : YES;
}

- (NSString *)accessToken {
    AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:self.oAuth2Manager.serviceProviderIdentifier];
#if DEBUG
    NSLog(@"access token: %@", credential.accessToken);
#endif
    NSString *accessToken = credential.accessToken;

    if (!credential) {
        accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:kAccessToken];
    }

    return accessToken;
}

- (void)killSessionWithSuccess:(void (^) (BOOL success))success {
    if (![AFOAuthCredential deleteCredentialWithIdentifier:self.oAuth2Manager.serviceProviderIdentifier]) {
#if DEBUG
        if (success) {
            success(NO);
        }
        return;
#endif
    }

    [self deleteNotificationTokenFromServer];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAccessToken];
    [[NSUserDefaults standardUserDefaults] synchronize];

    self.oAuth2Manager = nil;
    
    SKYKeychainService *keychainService = [SKYKeychainService defaultKeychainService];
    [keychainService deleteObjectWithIdentifier:kUsernameKey];
    
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    //Only deauthenticating locally
    [[SKYNestPartnerService defaultService] deleteCredentials];
}

- (AFOAuth2Manager *)oAuth2Manager {
    if (_oAuth2Manager == nil) {
        NSURL *baseURL = [NSURL URLWithString:[[SKYEndpointsManager sharedManager] authServerEndpoint]];

        _oAuth2Manager = [AFOAuth2Manager clientWithBaseURL:baseURL
                                                   clientID:[[SKYEndpointsManager sharedManager] clientSecret]
                                                     secret:[[SKYEndpointsManager sharedManager] appSecret]];
    }

    return _oAuth2Manager;
}

@end
