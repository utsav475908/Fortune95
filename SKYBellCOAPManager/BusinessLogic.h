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
//typedef void (^onNestUserLinkedInfoSuccess) (BOOL isSignedIn);
//typedef void (^onNestUserLinkedInfoFail)(void);

@interface BusinessLogic : NSObject <ICoAPExchangeDelegate> {
    CompletionHandler completionHandler;
    Success success;
    Failure failure;
    //void(^)(void))success successHandler;
    
}
@property (nonatomic, strong) ICoAPExchange *tokenExchange;
@property (nonatomic, strong) ICoAPExchange *scanExchange;
//@property (nonatomic, copy) CompletionHandler completionHandler;
//@property (nonatomic, copy) onNestUserLinkedInfoSuccess onNestUserLinkedInfoSuccess;
//@property (nonatomic, copy) onNestUserLinkedInfoFail onNestUserLinkedInfoFail;

//-(void)provisionDictionary withCompletionHandler:(CompletionHandler)completionHandler;

-(void)requestInvite:(BOOL)isIntrospectionEnabled success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *NSError))failure;

-(NSDictionary *)provisionDictionaryWithPassword:(NSString *)password withNetworkName:(NSString *)networkName success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *NSError))failure;;

-(void)sendInvite:(NSString*)inviteToken success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *NSError))failure;


//-(void)sendInvite:(NSString*)inviteToken success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *NSError))failure ;
//- (NSDictionary *)provisionDictionary ipTypeIsDHCPOrManual:(NSString*)ipType;

-(void)scanForAvailableNetwork success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *NSError))failure;

-(void)provisionSkyBell success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *NSError))failure;;

-(void)provisionSkyBell:(BOOL)isAdvancedStuffEnabledForReal selectNetworkSSID:(NSString *)selectedNetworkSSID password:(NSString *)passwordForSelectedNetwork ipTypeIsDHCPOrManual:(NSString*)ipType;


//-(void)requestInvite:(NSString*)inviteToken success:(void(^)(void))success failure:(void(^)(NSError *NSError))failure;

-(void)requestRegisterCallEvent;

-(void)requestHangUp;



@end
