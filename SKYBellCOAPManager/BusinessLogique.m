//
//  BusinessLogique.m
//  SKYBellCOAPManager
//
//  Created by Kumar Utsav on 11/04/16.
//  Copyright © 2016 Kumar Utsav. All rights reserved.
//

#import "BusinessLogique.h"

@implementation BusinessLogique

- (void)confirmDeviceRegistrationWithInviteToken:(NSString *)inviteToken
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
    
    NSString *baseUrl = [[SKYEndpointsManager sharedManager] apiUrlForServerPath:kConfirmDeviceRegisterUrl];
    NSString *url = [NSString stringWithFormat:baseUrl, inviteToken];
    [networkManager GET:nil url:url];
}


@end
