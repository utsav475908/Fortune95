//
//  SKYNestPartnerService.m
//  SkyBell
//
//  Created by Juan Jose Karam on 8/25/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import "SKYNestPartnerService.h"
#import "SKYSecrets.h"
#import "SKYKeychainService.h"
#import "SKYNetworkManager.h"
#import "NSError+SkyBell.h"
#import "SKYEndpointsManager.h"

static NSString * const kNestAuthorizationURL = @"https://%@/login/oauth2?client_id=%@&state=%@";
static NSString * const kNestDeauthenticationURL = @"https://api.%@/oauth2/access_tokens/%@";
static NSString * const kNestCamerasApiURL = @"https://developer-api.nest.com?auth=%@";
static NSString * const kNestUpdateCameraApiURL = @"https://developer-api.nest.com/devices/cameras/%@?auth=%@";
static NSString * const kNestAccessTokenIdentifier = @"SKYNestAccessToken";
static NSString * const kNestCamerasIdentifier = @"SKYNestCamerasIdentifier";

NSString * const SKYNestCameraListDidUpdateNotification = @"SKYNestCameraListDidUpdateNotification";
NSString * const SKYNestCamNameProperty = @"SKYNestCamNameProperty";
NSString * const SKYNestCamIsOnlineProperty = @"SKYNestCamIsOnlineProperty";
NSString * const SKYNestCamIsStreamingProperty = @"SKYNestCamIsStreamingProperty";
NSString * const SKYNestCamIdentifierProperty = @"SKYNestCamIdentifierProperty";
NSString * const SKYNestCamStructureIdentifierProperty = @"SKYNestCamStructureIdentifierProperty";
NSString * const SKYNestCamStructureNameProperty = @"SKYNestCamStructureNameProperty";

@interface SKYNestPartnerService ()

@property (nonatomic, strong) NSArray *cameraList;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSDate *expirationDate;

@end

@implementation SKYNestPartnerService

@synthesize cameraList = _cameraList;

+ (instancetype)defaultService {
    static SKYNestPartnerService *_defaultService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultService = [[SKYNestPartnerService alloc] init];
    });
    
    return _defaultService;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadAuthentication];
    }
    return self;
}

- (NSURL *)authorizationURL {
    NSUUID *uuid = [NSUUID UUID];
    NSString *state = [[uuid UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *urlString = [[NSString alloc] initWithFormat:kNestAuthorizationURL, kNestCurrentAPIDomain, [[SKYEndpointsManager sharedManager] nestClientSecret], state];
    return [NSURL URLWithString:urlString];
}

- (NSURL *)deauthenticationURL {
    NSString *urlString = [[NSString alloc] initWithFormat:kNestDeauthenticationURL, kNestCurrentAPIDomain, [self accessToken]];
    return [NSURL URLWithString:urlString];
}

- (NSURL *)redirectURL {
    return [NSURL URLWithString:[[SKYEndpointsManager sharedManager] nestServerEndpoint]];
}

- (BOOL)isAuthenticated {
    if (![self accessToken]) {
        [self forceRetrieveAccessToken];
    }

    BOOL validExpiration = [[NSDate date] compare:[self expirationDate]] == NSOrderedAscending;
    return !![self accessToken] && !!validExpiration;
}

- (void)authenticateWithAccessToken:(NSString *)accessToken
                     expirationTime:(NSTimeInterval)time
                         completion:(void (^)(BOOL authenticated, NSError *error))completion {
    NSParameterAssert(accessToken);
    
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];
    
    __weak typeof(self)weakSelf = self;
    
    networkManager.onRequestSuccess = ^(id responseObject) {
        if(!!completion) {
            [weakSelf setAccessToken:accessToken];
            
            NSDate *expirationDate = [[NSDate date] dateByAddingTimeInterval:time];
            [weakSelf setExpirationDate:expirationDate];
            
            if(!!completion) {
                return completion(!![weakSelf expirationDate] && !![weakSelf accessToken], nil);
            }
        }
    };
    
    networkManager.onRequestFail = ^(NSError *error) {
#if DEBUG
        NSLog(@"Failed to authenticate with NEST API Services, with error: %@", [error localizedDescription]);
#endif
        self.authorizationCode = nil;
        
        if (!!completion) return completion(false, error);
    };
    
    NSString *url = [[SKYEndpointsManager sharedManager] apiUrlForServerPath:kLinksUrl];
    NSDictionary *parameters = @{@"accessToken": accessToken,
                                 @"partnerName": @"nest",
                                 @"type": @"oauth2"};
    
    [networkManager POST:parameters url:url];
}

- (void)deauthenticate {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    __weak typeof(self)weakSelf = self;

    networkManager.onRequestSuccess = ^(id responseObject) {
        [self deleteCredentials];
        [self deleteNestTokenFromServer];

        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(partnerServiceDidDeauthenticate)]) {
            [weakSelf.delegate partnerServiceDidDeauthenticate];
        }
    };
    
    networkManager.onRequestFail = ^(NSError *error) {
        if (error.httpErrorCode == 404 || !error.httpErrorCode) {
            [self deleteCredentials];
            [self deleteNestTokenFromServer];

            if ([weakSelf.delegate respondsToSelector:@selector(partnerServiceDidDeauthenticate)]) {
                [weakSelf.delegate partnerServiceDidDeauthenticate];
            }
        }
        else if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(partnerServiceDidFailToDeauthenticateWithError:)]) {
            [weakSelf.delegate partnerServiceDidFailToDeauthenticateWithError:error];
        }
    };
    
    NSString *url = [[self deauthenticationURL] absoluteString];
    
    [networkManager DELETE:nil url:url];
}

- (void)deleteNestTokenFromServer {
    SKYNetworkManager *networkManager = [[SKYNetworkManager alloc] init];

    networkManager.onRequestSuccess = ^(id responseObject) {
        [self deleteCredentials];
    };

    networkManager.onRequestFail = ^(NSError *error) {
        [self deleteCredentials];
    };

    NSString *baseUrl = [[SKYEndpointsManager sharedManager] apiUrlForServerPath:kDeletePartnerUrl];
    NSString *url = [NSString stringWithFormat:baseUrl, kNestName];

    [networkManager DELETE:nil url:url];
}

- (void)deleteCredentials {
    [self deleteAuthentication];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kNestCamerasIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.authorizationCode = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(partnerServiceDidDeleteCredentials)]) {
        [self.delegate partnerServiceDidDeleteCredentials];
    }
}

- (void)updateCameraListWithCompletion:(void (^)(NSArray *cameraList, NSError *error))completion {
    NSString *cameraApiURL = [[NSString alloc] initWithFormat:kNestCamerasApiURL, [self accessToken]];
    NSMutableURLRequest *authenticationRequest = [[NSMutableURLRequest alloc] init];
    [authenticationRequest setURL:[NSURL URLWithString:cameraApiURL]];
    [authenticationRequest setHTTPMethod:@"GET"];
    [authenticationRequest setAllHTTPHeaderFields:@{ @"Accept" : @"application/json" }];
    
    __weak typeof(self)weakSelf = self;
    [[[NSURLSession sharedSession] dataTaskWithRequest:authenticationRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        id responseData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

        if ([(NSHTTPURLResponse *)response statusCode] == 401 || [(NSHTTPURLResponse *)response statusCode] == 403) {
            [self deauthenticate];
            if (!error) {
                NSError *builtError = [NSError errorWithDomain:@"com.skybell.doorbell"
                                                          code:401
                                                      userInfo:@{@"reason" : @"Nest Session is not valid anymore"}];
                error = builtError;
            }

            if (!!completion) return completion(nil, error);
        }

        else {
            if (!!responseData && !error) {
                NSMutableArray *cameras = [[NSMutableArray alloc] init];

                id camerasData = [responseData valueForKeyPath:@"devices.cameras"];
                id structuresData = [responseData valueForKeyPath:@"structures"];

                if (!!camerasData && !!structuresData) {
                    for (NSString *cameraIdentifier in [camerasData allKeys]) {
                        NSString *name = camerasData[cameraIdentifier][@"name_long"];
                        NSNumber *isOnline = @([camerasData[cameraIdentifier][@"is_online"] integerValue]);
                        NSNumber *isStreaming = @([camerasData[cameraIdentifier][@"is_streaming"] integerValue]);
                        NSString *structureIdentifier = camerasData[cameraIdentifier][@"structure_id"];
                        NSString *structureName = nil;

                        for (NSString *structureIdentifier in [structuresData allKeys]) {
                            structureName = structuresData[structureIdentifier][@"name"];
                        }

                        [cameras addObject:@{ SKYNestCamIdentifierProperty : cameraIdentifier,
                                              SKYNestCamNameProperty : name,
                                              SKYNestCamIsOnlineProperty : isOnline,
                                              SKYNestCamIsStreamingProperty : isStreaming,
                                              SKYNestCamStructureIdentifierProperty: structureIdentifier,
                                              SKYNestCamStructureNameProperty: structureName}];
                    }
                }

                [weakSelf setCameraList:cameras];
                if(!!completion) return completion(cameras, nil);
            }
            
            if (!!completion) return completion(nil, error);
        }
    }] resume];
}

- (void)updateCameraStreaming:(BOOL)streaming withIdentifier:(NSString *)identifier completion:(void (^)(NSError *error))completion {
    NSParameterAssert(identifier);
    
    NSString *cameraApiURL = [[NSString alloc] initWithFormat:kNestUpdateCameraApiURL, identifier, [self accessToken]];
    NSMutableURLRequest *authenticationRequest = [[NSMutableURLRequest alloc] init];
    [authenticationRequest setURL:[NSURL URLWithString:cameraApiURL]];
    [authenticationRequest setHTTPMethod:@"PUT"];
    [authenticationRequest setAllHTTPHeaderFields:@{ @"Content-Type" : @"application/json" }];
    
    NSString *body = [[NSString alloc] initWithFormat:@"{\"is_streaming\": %@}", streaming ? @"true" : @"false"];
    [authenticationRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    __weak typeof(self)weakSelf = self;
    [[[NSURLSession sharedSession] dataTaskWithRequest:authenticationRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        id streamingData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        if (!!streamingData && !error) {
            NSInteger cameraIndexToUpdate = NSNotFound;
            for (id camera in [weakSelf cameraList]) {
                if ([camera[SKYNestCamIdentifierProperty] isEqualToString:identifier]) {
                    cameraIndexToUpdate = [[weakSelf cameraList] indexOfObject:camera];
                }
            }

            if (cameraIndexToUpdate != NSNotFound) {
                id updatedCamera = [[self cameraList][cameraIndexToUpdate] mutableCopy];
                updatedCamera[SKYNestCamIsStreamingProperty] = @(streaming);

                NSMutableArray *cameraList = [[weakSelf cameraList] mutableCopy];
                [cameraList replaceObjectAtIndex:cameraIndexToUpdate withObject:updatedCamera];
                [self setCameraList:cameraList];
            }
            if (completion) return completion(nil);
        } else {
            if (completion) return completion(error);
        }
    }] resume];
}

#pragma - Access Token Persistance

- (void)loadAuthentication {
    NSDictionary *accessToken = [[SKYKeychainService defaultKeychainService] retrieveObjectWithIdentifier:kNestAccessTokenIdentifier];
    _accessToken = accessToken[@"AccessToken"];
    _expirationDate = accessToken[@"ExpirationDate"];
}

- (void)saveAuthentication {
    NSDictionary *accessToken = nil;

    if (!![self accessToken] && !![self expirationDate]) {
        accessToken = @{ @"AccessToken" : [self accessToken], @"ExpirationDate" : [self expirationDate], @"AuthorizationCode" : [self authorizationCode] };
    }

    [[SKYKeychainService defaultKeychainService] storeObject:accessToken withIdentifier:kNestAccessTokenIdentifier];
}

- (void)saveAuthenticationWithAccessToken:(NSString *)token {
    NSDictionary *accessToken = nil;
    
    _accessToken = token;
    _expirationDate = [NSDate dateWithTimeIntervalSinceNow:315360000];
    
    if (!![self accessToken] && !![self expirationDate]) {
        accessToken = @{ @"AccessToken" : [self accessToken], @"ExpirationDate" : [self expirationDate] };
    }

    [[SKYKeychainService defaultKeychainService] storeObject:accessToken withIdentifier:kNestAccessTokenIdentifier];
}

- (void)deleteAuthentication {
    [[SKYKeychainService defaultKeychainService] deleteObjectWithIdentifier:kNestAccessTokenIdentifier];
    _accessToken = nil;
    _expirationDate = nil;
}

- (void)forceRetrieveAccessToken {
    [self loadAuthentication];
}

#pragma mark - Properties

- (void)setAccessToken:(NSString *)accessToken {
    if (accessToken != _accessToken) {
        _accessToken = accessToken;
        [self saveAuthentication];
    }
}

- (void)setExpirationDate:(NSDate *)expirationDate {
    if (expirationDate != _expirationDate) {
        _expirationDate = expirationDate;
        [self saveAuthentication];
    }
}

- (NSArray *)cameraList {
    if (!_cameraList) {
        NSData *encodedObject = [[NSUserDefaults standardUserDefaults] objectForKey:kNestCamerasIdentifier];
        if (!!encodedObject) {
            _cameraList = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        }
    }
    
    return _cameraList;
}

- (void)setCameraList:(NSArray *)cameraList {
    if (_cameraList != cameraList) {
        _cameraList = cameraList;
        NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:_cameraList];
        [[NSUserDefaults standardUserDefaults] setObject:encodedObject forKey:kNestCamerasIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


@end
