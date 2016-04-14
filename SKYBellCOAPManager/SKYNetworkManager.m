//
//  SKYNetworkManager.m
//  SkyBell
//
//  Created by Luis Hernandez on 7/10/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import "SKYNetworkManager.h"
#import "AFNetworking.h"
#import "AFOAuth2Manager.h"
#import "SKYSession.h"
#import "SKYEndpointsManager.h"
//#import <AWSMobileAnalytics/AWSMobileAnalytics.h>

// AFNetworking 404 error code
NSInteger const kAccessTokenNotFound = -1011;

@interface SKYNetworkManager ()

@property (nonatomic, strong) AFHTTPRequestOperationManager *operationManager;
@property (nonatomic, strong) AFOAuth2Manager *oAuth2Manager;

@end

@implementation SKYNetworkManager

- (void)POST:(NSDictionary *)parameters url:(NSString *)url {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self.operationManager
     POST:url
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#if DEBUG
//         NSLog(@"%@", responseObject);
#endif
        if (self.onRequestSuccess) {
            self.onRequestSuccess(responseObject);
        }
    }
           failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
#if DEBUG
        NSLog(@"%@", error);
#endif
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        SKYSession *session = [SKYSession sharedInstance];

        if (operation.response.statusCode == 401) {
            [self report401Error];
            [self cancelAllRequests];
            [session killSessionWithSuccess:nil];
        }

        if (self.onRequestFail) {
            self.onRequestFail(error);
        }
    }];
}

- (void)GET:(NSDictionary *)parameters url:(NSString *)url {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self.operationManager
     GET:url
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

#if DEBUG
//               NSLog(@"%@", responseObject);
#endif
               if (self.onRequestSuccess) {
               self.onRequestSuccess(responseObject);
               }
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
#if DEBUG
        NSLog(@"%@", error);
#endif
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        SKYSession *session = [SKYSession sharedInstance];

        if (operation.response.statusCode == 401) {
            [self report401Error];
            [self cancelAllRequests];
            [session killSessionWithSuccess:nil];
        }

        if (self.onRequestFail) {
            self.onRequestFail(error);
        }
    }];
}

- (void)PATCH:(NSDictionary *)parameters url:(NSString *)url {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self.operationManager
     PATCH:url
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

#if DEBUG
        NSLog(@"%@", responseObject);
#endif

        if (self.onRequestSuccess) {
            self.onRequestSuccess(responseObject);
        }
    }
           failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
#if DEBUG
        NSLog(@"%@", error);
#endif
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        SKYSession *session = [SKYSession sharedInstance];

        if (operation.response.statusCode == 401) {
            [self report401Error];
            [self cancelAllRequests];
            [session killSessionWithSuccess:nil];
        }

        if (self.onRequestFail) {
            self.onRequestFail(error);
        }
    }];
}

- (void)DELETE:(NSDictionary *)parameters url:(NSString *)url {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self.operationManager
     DELETE:url
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

#if DEBUG
        NSLog(@"%@", responseObject);
#endif

        if (self.onRequestSuccess) {
            self.onRequestSuccess(responseObject);
        }
    }
           failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
#if DEBUG
        NSLog(@"%@", error);
#endif
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        SKYSession *session = [SKYSession sharedInstance];

        if (operation.response.statusCode == 401) {
            [self report401Error];
            [self cancelAllRequests];
            [session killSessionWithSuccess:nil];
        }

        if (self.onRequestFail) {
            self.onRequestFail(error);
        }
    }];
}

- (void)cancelAllRequests {
    [self.operationManager.operationQueue cancelAllOperations];
}

- (AFHTTPRequestOperationManager *)operationManager {
    if (!_operationManager) {
        _operationManager = [AFHTTPRequestOperationManager manager];
        _operationManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_operationManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        _operationManager.securityPolicy = [self securityPolicy];
    }

    SKYSession *session = [SKYSession sharedInstance];

    if ([session isValid]) {
        //if credential is nil, the keychain bug is probably happening
        //for now, only used to report the status
        AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:self.oAuth2Manager.serviceProviderIdentifier];

        NSString *accessToken = [NSString stringWithFormat:@"Bearer %@", [session accessToken]];

//        ///// Analytics code
//        AWSMobileAnalytics *analytics = [AWSMobileAnalytics
//                                         mobileAnalyticsForAppId:[[SKYEndpointsManager sharedManager] awsAppId]
//                                         identityPoolId:[[SKYEndpointsManager sharedManager] awsPoolId]];
//        id<AWSMobileAnalyticsEventClient> eventClient = analytics.eventClient;
//        id<AWSMobileAnalyticsEvent> editNameEvent = [eventClient createEventWithEventType:@"networking - bearer token not found"];

//        if (!accessToken) {
//            [editNameEvent addAttribute:@"nil" forKey:@"bearer_token"];
//        }
//
//        if (!credential) {
//            [editNameEvent addAttribute:@"nil" forKey:@"credential"];
//        }
//
//        NSString *date = [NSString stringWithFormat:@"%@", [NSDate date]];
//        [editNameEvent addAttribute:date forKey:@"date"];
//
//        [editNameEvent addAttribute:self.oAuth2Manager.serviceProviderIdentifier forKey:@"service_provider_identifier"];
//
//        [eventClient recordEvent:editNameEvent];
//        [eventClient submitEvents];
        /////

        [_operationManager.requestSerializer setValue:accessToken forHTTPHeaderField:@"Authorization"];
    }

    return _operationManager;
}

- (void)report401Error {
//    AWSMobileAnalytics *analytics = [AWSMobileAnalytics
//                                     mobileAnalyticsForAppId:[[SKYEndpointsManager sharedManager] awsAppId]
//                                     identityPoolId:[[SKYEndpointsManager sharedManager] awsPoolId]];
//    id<AWSMobileAnalyticsEventClient> eventClient = analytics.eventClient;
//    id<AWSMobileAnalyticsEvent> editNameEvent = [eventClient createEventWithEventType:@"networking - bearer token not found"];
//
//    [editNameEvent addAttribute:self.oAuth2Manager.serviceProviderIdentifier forKey:@"service_provider_identifier"];
//
//    NSString *date = [NSString stringWithFormat:@"%@", [NSDate date]];
//    [editNameEvent addAttribute:date forKey:@"date"];
//    [editNameEvent addAttribute:@"401" forKey:@"session"];

//    [eventClient recordEvent:editNameEvent];
//    [eventClient submitEvents];
}

//does it need to be a property???
- (AFOAuth2Manager *)oAuth2Manager {
    if (_oAuth2Manager == nil) {
        NSURL *baseURL = [NSURL URLWithString:[[SKYEndpointsManager sharedManager] authServerEndpoint]];

        _oAuth2Manager = [AFOAuth2Manager clientWithBaseURL:baseURL
                                                   clientID:[[SKYEndpointsManager sharedManager] clientSecret]
                                                     secret:[[SKYEndpointsManager sharedManager] appSecret]];
    }

    return _oAuth2Manager;
}

// myskybell.cer
// Requested On     10-SEP-2015 6:21 PM
// Validity         11-SEP-2015 to 13-NOV-2017

- (AFSecurityPolicy *)securityPolicy {
    AFSecurityPolicy *securityPolicy = nil;
    
    SKYEndpointsManager *endpointsManager = [SKYEndpointsManager sharedManager];
    
    if (endpointsManager.currentEndPoint == SKYEndPointProduction) {
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
        securityPolicy.validatesCertificateChain = NO;
    }
    else {
        securityPolicy = [AFSecurityPolicy defaultPolicy];
    }

    return securityPolicy;
}

@end
