//
//  SKYEndpointsManager.m
//  SkyBell
//
//  Created by Gabriel Sosa Martínez on 11/4/15.
//  Copyright © 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import "SKYEndpointsManager.h"

NSString * const kSKYCurrentEndPointConfigurationKey = @"kSKYCurrentEndPointConfigurationKey";
NSString * const kSKYStagingEndPointResourceFile = @"application-configuration-staging";
NSString * const kSKYProductionEndPointResourceFile = @"application-configuration-production";

NSString * const kSKYEndpointsKey = @"endpoints";
NSString * const kSKYSecretsKey = @"secrets";
NSString * const kSKYVersionsKey = @"versions";
NSString * const kSKYOauthKey = @"auth";
NSString * const kSKYCoapKey = @"coap";
NSString * const kSKYApiKey = @"api";
NSString * const kSKYNestKey = @"nest";
NSString * const kSKYNestConfigurationKey = @"nestConfiguration";
NSString * const kSKYClientSecretId = @"clientId";
NSString * const kSKYAppSecretId = @"secret";
NSString * const kSKYNestClientSecretId = @"nestClientId";
NSString * const kSKYAWSAppId = @"awsAppId";
NSString * const kSKYAWSPoolId = @"awsPoolId";

@interface SKYEndpointsManager ()

@property (nonatomic, strong) NSDictionary *configuration;

- (void)loadConfiguration;
- (NSString *)serverEndpointForKey:(NSString *)endpointKey;
- (NSString *)secretForKey:(NSString *)secretKey;

@end

@implementation SKYEndpointsManager

#pragma mark -
#pragma mark Singleton Management

+ (id)sharedManager {
    static SKYEndpointsManager *_defaultConfiguration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultConfiguration = [[self alloc] init];

        if (![[NSUserDefaults standardUserDefaults] valueForKey:kSKYCurrentEndPointConfigurationKey]) {
            [[NSUserDefaults standardUserDefaults] setValue:kSKYProductionEndPointResourceFile
                                                     forKey:kSKYCurrentEndPointConfigurationKey];
        }
        
        [_defaultConfiguration loadConfiguration];
    });
    
    return _defaultConfiguration;
}

- (void)loadConfiguration {
    NSString *resource = [[NSUserDefaults standardUserDefaults] valueForKey:kSKYCurrentEndPointConfigurationKey];
    
    NSData *defaultConfigurationData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resource ofType:@"json"]];
    self.configuration = [NSJSONSerialization JSONObjectWithData:defaultConfigurationData options:0 error:nil];
}

- (void)switchToEndpoint:(SKYEndPoint)endPoint {
    if (endPoint == SKYEndPointStaging) {
        [[NSUserDefaults standardUserDefaults] setValue:kSKYStagingEndPointResourceFile
                                                 forKey:kSKYCurrentEndPointConfigurationKey];
    }
    else if (endPoint == SKYEndPointProduction) {
        [[NSUserDefaults standardUserDefaults] setValue:kSKYProductionEndPointResourceFile
                                                 forKey:kSKYCurrentEndPointConfigurationKey];
    }

    [self loadConfiguration];
}

- (NSString *)serverEndpointForKey:(NSString *)endpointKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *serverHost = self.configuration[kSKYEndpointsKey][endpointKey];
    
    if ([defaults boolForKey:kUseStagingServerKey]) {
        serverHost = self.configuration[kSKYEndpointsKey][endpointKey];
    }
    
    return serverHost;
}

- (NSString *)apiVersionForKey:(NSString *)endpointKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *apiVersion = self.configuration[kSKYVersionsKey][endpointKey];
    
    if ([defaults boolForKey:kUseStagingServerKey]) {
        apiVersion = self.configuration[kSKYVersionsKey][endpointKey];
    }
    
    return apiVersion;
}

- (NSString *)authServerEndpoint {
    return [self serverEndpointForKey:kSKYOauthKey];
}

- (NSString *)authUrlForServerPath:(NSString  *)path {
    return [NSString stringWithFormat:@"%@%@", [self authServerEndpoint], path];
}

- (NSString *)apiVersion {
    return [self apiVersionForKey:kSKYApiKey];
}

- (NSString *)apiServerEndpoint {
    return [self serverEndpointForKey:kSKYApiKey];
}

- (NSString *)apiUrlForServerPath:(NSString  *)path {
    return [NSString stringWithFormat:@"%@%@%@", [self apiServerEndpoint], [self apiVersion], path];
}

- (NSString *)coapServerEndpoint {
    return [self serverEndpointForKey:kSKYCoapKey];
}

- (NSString *)nestServerEndpoint {
    return [self serverEndpointForKey:kSKYNestKey];
}

- (NSString *)nestConfigurationServerEndpoint {
    return [self serverEndpointForKey:kSKYNestConfigurationKey];
}

- (NSString *)secretForKey:(NSString *)secretKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *secret = self.configuration[kSKYSecretsKey][secretKey];
    
    if ([defaults boolForKey:kUseStagingServerKey]) {
        secret = self.configuration[kSKYSecretsKey][secretKey];
    }
    
    return secret;
}

- (NSString *)clientSecret {
    return [self secretForKey:kSKYClientSecretId];
}

- (NSString *)appSecret {
    return [self secretForKey:kSKYAppSecretId];
}

- (NSString *)nestClientSecret {
    return [self secretForKey:kSKYNestClientSecretId];
}

- (NSString *)awsAppId {
    return [self secretForKey:kSKYAWSAppId];
}

- (NSString *)awsPoolId {
    return [self secretForKey:kSKYAWSPoolId];
}

- (SKYEndPoint)currentEndPoint {
    SKYEndPoint currentEndPoint = SKYEndPointStaging;

    NSString *resource = [[NSUserDefaults standardUserDefaults] valueForKey:kSKYCurrentEndPointConfigurationKey];
    
    if ([resource isEqualToString:kSKYProductionEndPointResourceFile]) {
        currentEndPoint = SKYEndPointProduction;
    }
    else if ([resource isEqualToString:kSKYStagingEndPointResourceFile]) {
        currentEndPoint = SKYEndPointStaging;
    }
    
    return currentEndPoint;
}

@end
