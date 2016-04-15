//
//  BusinessLogic.h
//  SKYBellCOAPManager
//
//  Created by Kumar Utsav on 11/04/16.
//  Copyright © 2016 Kumar Utsav. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICoAPExchange.h"
#import "SKYCallConfiguration.h"
#import "SKYKeychainService.h"
#import "SKYSession.h"
#import "SKYConstants.h"

typedef void (^CompletionHandler)(NSArray *users, NSError *error);
typedef void (^Success)(NSDictionary *);
typedef void (^Failure)(NSError *error);


@interface BusinessLogic : NSObject <ICoAPExchangeDelegate> {
    CompletionHandler completionHandler;
    Success success;
    Failure failure;

}


-(void)requestInvite:(BOOL)isIntrospectionEnabled success:(Success)success failure:(Failure)failure;

-(NSDictionary *)provisionDictionaryWithPassword:(NSString *)password withNetworkName:(NSString *)networkName;
// sendInvitation.
-(void)sendInvite:(NSString*)inviteToken success:(Success)success failure:(Failure)failure;



//scanning Network.
-(void)scanForAvailableNetworkWithSuccess:(Success)success failure:(Failure)failure;

// provisioning 

-(void)provisionSkyBell:(BOOL)isAdvancedStuffEnabledForReal selectNetworkSSID:(NSString *)selectedNetworkSSID password:(NSString *)passwordForSelectedNetwork ipTypeIsDHCPOrManual:(NSString*)ipType success:(Success)success failure:(Failure)failure;



-(void)requestRegisterCallEvent:(NSString*)payload isIntrospectionEnabled:(BOOL)isIntrospectionEnabled;

-(void)requestHangUp :(NSString*)payload isIntrospectionEnabled:(BOOL)isIntrospectionEnabled success:(Success)success failure:(Failure)failure;



@end
