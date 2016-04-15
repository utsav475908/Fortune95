//
//  BusinessLogic.m
//  SKYBellCOAPManager
//
//  Created by Kumar Utsav on 11/04/16.
//  Copyright © 2016 Kumar Utsav. All rights reserved.
//

#import "BusinessLogic.h"
#import "ICoAPExchange.h"
#import "SKYConstants.h"
#import "SKYEndpointsManager.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

static NSString * const kSdpFormatString =
@"\""
@"v=0\n"
@"no=0 0 IN IP4 %@\n"
@"s=%@\n"
@"t=0 0\n"
@"a=tool:libavformat 56.25.101\n"
@"m=video %lu RTP/AVP 96\n"
@"c=IN IP4 %@\n"
@"b=AS:2021\n"
@"a=rtpmap:96 H264/90000\n"
@"a=fmtp:96 packetization-mode=1;sprop-parameter-sets=Z2QAH6wsxQFAFuwEQAAAGQAABdqjxgxlgA==,aOkrLIs=; profile-level-id=64001F\n"
@"m=audio %lu RTP/AVP 97\n"
@"c=IN IP4 %@\n"
@"b=AS:155\n"
@"a=rtpmap:97 MPEG4-GENERIC/44100/2\n"
@"a=fmtp:97 profile-level-id=1;mode=AAC-hbr;sizelength=13;indexlength=3;indexdeltalength=3; config=1210"
@"\"";

@implementation BusinessLogic

// send invitation needs token to send invite. How is token coming to this call?

-(void)sendInvite:(NSString*)inviteToken success:(Success)success failure:(Failure)failure{
    
    NSString *payload = [NSString stringWithFormat:@"{\"token\":\"%@\"}", inviteToken];
    ICoAPMessage *cO = [[ICoAPMessage alloc] initAsRequestConfirmable:YES
                                                        requestMethod:IC_POST
                                                            sendToken:YES
                                                              payload:payload];
    
    [cO addOption:IC_URI_PATH withValue:@"invite_token"];
    ICoAPExchange *tokenExchange;
    tokenExchange = [[ICoAPExchange alloc] init];
    tokenExchange.isRequestLocal = YES;
    tokenExchange.delegate = self;
    [tokenExchange sendRequestWithCoAPMessage:cO toHost:kDeviceAddress port:kCoAPRemotePort];
    
}



-(void)scanForAvailableNetworkWithSuccess:(Success)success failure:(Failure)failure {
    ICoAPMessage *cO = [[ICoAPMessage alloc] initAsRequestConfirmable:YES requestMethod:IC_POST sendToken:YES payload:nil];
    [cO addOption:IC_URI_PATH withValue:@"apscan"];
    
   ICoAPExchange* scanExchange = [[ICoAPExchange alloc] init];
    scanExchange.isRequestLocal = YES;
    scanExchange.delegate = self;
    [scanExchange sendRequestWithCoAPMessage:cO toHost:kDeviceAddress port:kCoAPRemotePort];
    
}

-(void)provisionSkyBell:(BOOL)isAdvancedStuffEnabledForReal selectNetworkSSID:(NSString *)selectedNetworkSSID password:(NSString *)passwordForSelectedNetwork ipTypeIsDHCPOrManual:(NSString*)ipType success:(Success)success failure:(Failure)failure {
    // I am adding ipType because provision dictionary requires this.
    //self.cancelButton.hidden = YES;
    NSError *error = [NSError errorWithDomain:@"com.myskybell.doorbell" code:10008000 userInfo:@{@"description": @"error encoding data from dictionary"}];
    //self provisionDictionaryipTypeIsDHCPOrManual
    // this will give the provision dictionary with password and network name.
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self provisionDictionaryWithPassword:passwordForSelectedNetwork withNetworkName:selectedNetworkSSID]
                                                       options:0
                                                         error:&error];
    NSString *payload = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
#if DEBUG
    NSLog(@"updating with payload: %@", payload);
#endif
    
    if (!isAdvancedStuffEnabledForReal) {
        //SIMPLE PAYLOAD WORKING BUT ADVANCED IS FUCKED UP. NEED TO DISCUSS WITH HITEM
        
        //THIS IS FIXED NOW BUT STILL NECESSARY TO DEPLOY STABLE SKYBELL FIRMWARE TO PRODUCTION TO BE ABLE TO
        //USE THE ADVANCED PAYLOAD
        payload = [NSString stringWithFormat:@"{\"provision\":{\"essid\":\"%@\",\"psk\":\"%@\"}}",
                   selectedNetworkSSID, passwordForSelectedNetwork];
    }
    
    if (selectedNetworkSSID && passwordForSelectedNetwork) {
        ICoAPMessage *cO = [[ICoAPMessage alloc] initAsRequestConfirmable:YES
                                                            requestMethod:IC_POST
                                                                sendToken:YES
                                                                  payload:payload];
        [cO addOption:IC_URI_PATH withValue:@"provision"];
        
        
        ICoAPExchange * provisionExchange = [[ICoAPExchange alloc] init];
        provisionExchange.isRequestLocal = YES;
        provisionExchange.delegate = self;
        
        [provisionExchange sendRequestWithCoAPMessage:cO toHost:kDeviceAddress port:kCoAPRemotePort];
    }

}

//-(void)requestInvite:(BOOL)isIntrospectionEnabled success:(void(^)(void))success failure:(void(^)(NSError *NSError))failure{

-(void)requestInvite:(BOOL)isIntrospectionEnabled success:(Success)success failure:(Failure)failure{
    SKYCallConfiguration * callConfiguration = [[SKYCallConfiguration alloc]init];
    NSString *hostIpAddress = [[SKYEndpointsManager sharedManager] coapServerEndpoint];
    NSString *deviceIpAddress = [self getIPAddress];
    NSString *reason = callConfiguration.triggerDescription;
    
    NSString *sdp = [NSString stringWithFormat:kSdpFormatString, deviceIpAddress, reason,
                     (unsigned long)callConfiguration.localVideoPort, deviceIpAddress,
                     (unsigned long)callConfiguration.localAudioPort, deviceIpAddress];
    
    //    NSUUID *inviteId = [NSUUID UUID];
    
    SKYKeychainService *keychainService = [SKYKeychainService defaultKeychainService];
    NSString *appId = [keychainService retrieveObjectWithIdentifier:kAppIdKey];
    
    if (!appId) {
        appId = [[NSUserDefaults standardUserDefaults] objectForKey:kAppIdKey];
    }
    
    NSString *payload = [NSString stringWithFormat:@"{\"uuid\" : \"%@\",\"callid\" : \"%@\",\"sdp\": %@, \"device_id\": \"%@\", \"role\": \"%@\"}", appId,callConfiguration.callId, sdp,callConfiguration.deviceId,callConfiguration.role];
    ICoAPMessage * inviteMessage;
    inviteMessage = [[ICoAPMessage alloc] initAsRequestConfirmable:YES requestMethod:IC_POST sendToken:YES payload:payload];
    [inviteMessage addOption:IC_URI_PATH withValue:@"invite"];
    [inviteMessage addOption:IC_CONTENT_FORMAT withValue:[NSString stringWithFormat:@"%lu", (unsigned long)IC_JSON]];
    if (isIntrospectionEnabled) {
        NSString *bearerToken = [self bearerToken];
        
        if (bearerToken) {
            [inviteMessage addOption:IC_INTROSPECTION withValue:bearerToken];
        }
    }
    ICoAPExchange *inviteExchange;
    
    inviteExchange = [[ICoAPExchange alloc] init];
    inviteExchange.delegate = self;
    //self.currentExchange = self.inviteExchange;
    [inviteExchange sendRequestWithCoAPMessage:inviteMessage toHost:hostIpAddress port:kCoAPRemotePort];
    
}

- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = getifaddrs(&interfaces);
    
    if (success == 0) {
        temp_addr = interfaces;
        
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    return address;
}

- (NSString *)bearerToken {
    SKYSession *session = [SKYSession sharedInstance];
    //    AFOAuthCredential *credential = nil;
    
    NSString *accessToken = @"";
    if ([session isValid]) {
        accessToken = [session accessToken];
    }
    
    return accessToken;
}


//- (NSDictionary *)provisionDictionary withComletionHandler:(CompletionHandler)completionHandler
-(NSDictionary *)provisionDictionaryWithPassword:(NSString *)password withNetworkName:(NSString *)networkName; {
    NSMutableDictionary *mutableProvision = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *ipConfig = [NSMutableDictionary dictionary];
    NSString *ipType = @"";
    int securityType;
    
    if ((ipType = @"dhcp")) {
        // what the secutiytype has a role in this?
//        if ([self.networkPasswordTextField.text isEqualToString:@""]) {
//            self.securityType = SKYSecurityTypeNone;
        securityType = SKYSecurityTypeNone ;
//        }
        NSLog(@"No SKYSecurityTypeNone is the security");
    }
    else if ((ipType = @"manual")) {
        
//        [ipConfig setValue:self.ipAddressTextField.text forKey:@"ip"];
//        [ipConfig setValue:self.subnetMaskTextField.text forKey:@"mask"];
//        [ipConfig setValue:self.gatewayTextField.text forKey:@"gateway"];
//        [ipConfig setValue:self.dnsTextField.text forKey:@"dns0"];
//        [ipConfig setValue:self.dnsTextField.text forKey:@"dns1"];
    }
    
    [ipConfig setValue:ipType forKey:@"type"];
//    NSString *networkToName = networkName;
//    NSString *passwordToName = password;
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    [config setValue:@"dhcp" forKey:@"type"];
    [config setValue:networkName forKey:@"essid"];
    
    if (securityType == SKYSecurityTypeWEP) {
        [config setValue:password forKey:@"wep_key0"];
    }
    else {
        [config setValue:password forKey:@"psk"];
    }
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSString *currentTimeZone = [timeZone name];
    
    [mutableProvision setValue:config forKey:@"wirelessConfig"];
    [mutableProvision setValue:ipConfig forKey:@"ipConfig"];
    [mutableProvision setValue:@"Front Door" forKey:@"deviceName"];
    [mutableProvision setValue:currentTimeZone forKey:@"timezone"];
    // remember to check the logic for selected time zone because it checks on other parameters.
    NSDictionary *provision = [NSDictionary dictionaryWithDictionary:mutableProvision];
    NSMutableDictionary *provisionDict = [NSMutableDictionary dictionary];
    
    [provisionDict setValue:provision forKey:@"provision"];
    
    return provisionDict;
}

//----
//- (NSDictionary *)provisionDictionary ipTypeIsDHCPOrManual:(NSString*)ipType {
//    NSMutableDictionary *mutableProvision = [NSMutableDictionary dictionary];
//    
//    NSMutableDictionary *ipConfig = [NSMutableDictionary dictionary];
//    NSString *ipType = @"";
//    
//    if (self.networkSegmentedControl.selectedSegmentIndex == 0) {
//        ipType = @"dhcp";
//        if ([self.networkPasswordTextField.text isEqualToString:@""]) {
//            self.securityType = SKYSecurityTypeNone;
//        }
//    }
//    else if (self.networkSegmentedControl.selectedSegmentIndex == 1) {
//        ipType = @"manual";
//        [ipConfig setValue:self.ipAddressTextField.text forKey:@"ip"];
//        [ipConfig setValue:self.subnetMaskTextField.text forKey:@"mask"];
//        [ipConfig setValue:self.gatewayTextField.text forKey:@"gateway"];
//        [ipConfig setValue:self.dnsTextField.text forKey:@"dns0"];
//        [ipConfig setValue:self.dnsTextField.text forKey:@"dns1"];
//    }
//    
//    [ipConfig setValue:ipType forKey:@"type"];
//    
//    NSMutableDictionary *config = [NSMutableDictionary dictionary];
//    [config setValue:[self securityTypeName] forKey:@"type"];
//    [config setValue:self.selectedNetworkSSID forKey:@"essid"];
//    
//    if (self.securityType == SKYSecurityTypeWEP) {
//        [config setValue:self.passwordForSelectedNetwork forKey:@"wep_key0"];
//    }
//    else {
//        [config setValue:self.passwordForSelectedNetwork forKey:@"psk"];
//    }
//    
//    [mutableProvision setValue:config forKey:@"wirelessConfig"];
//    [mutableProvision setValue:ipConfig forKey:@"ipConfig"];
//    [mutableProvision setValue:@"Front Door" forKey:@"deviceName"];
//    [mutableProvision setValue:self.selectedTimeZone forKey:@"timezone"];
//    
//    NSDictionary *provision = [NSDictionary dictionaryWithDictionary:mutableProvision];
//    NSMutableDictionary *provisionDict = [NSMutableDictionary dictionary];
//    
//    [provisionDict setValue:provision forKey:@"provision"];
//    
//    return provisionDict;
//}

//----

-(NSString*)payload{
    return @"payload contains device id, and current date";
}


-(void)requestRegisterCallEvent:(NSString*)payload isIntrospectionEnabled:(BOOL)isIntrospectionEnabled {
//    NSString *payload = [NSString stringWithFormat:@"{\"deviceId\": \"%@\",\"callId\": \"%@\",\"event\": \"application:on-demand\",\"sentAt\": \"%@\"}", self.callConfiguration.deviceId, self.callConfiguration.callId, [[NSDate date] zuluFormattedStringDate]];
    //#if DEBUG
    //    NSLog(@"device ID: %@, call ID: %@", self.callConfiguration.deviceId, self.callConfiguration.callId);
    //#endif
    ICoAPMessage *eventMessage = [[ICoAPMessage alloc] initAsRequestConfirmable:YES requestMethod:IC_POST sendToken:YES payload:payload];
    [eventMessage addOption:IC_URI_PATH withValue:@"event"];
    [eventMessage addOption:IC_CONTENT_FORMAT withValue:[NSString stringWithFormat:@"%lu", (unsigned long)IC_JSON]];
    ICoAPMessage* inviteMessage;
    if (isIntrospectionEnabled) {
        NSString *bearerToken = [self bearerToken];
        
        if (bearerToken) {
            [inviteMessage addOption:IC_INTROSPECTION withValue:bearerToken];
        }
    }
    
    ICoAPExchange *registerExchange = [[ICoAPExchange alloc] init];
    [registerExchange sendRequestWithCoAPMessage:eventMessage
                                          toHost:[[SKYEndpointsManager sharedManager] coapServerEndpoint]
                                            port:kCoAPRemotePort];

}

-(void)requestHangUp :(NSString*)payload isIntrospectionEnabled:(BOOL)isIntrospectionEnabled {
    NSString *hostIpAddress = [[SKYEndpointsManager sharedManager] coapServerEndpoint];
    
    SKYKeychainService *keychainService = [SKYKeychainService defaultKeychainService];
    NSString *appId = [keychainService retrieveObjectWithIdentifier:kAppIdKey];
    
    if (!appId) {
        appId = [[NSUserDefaults standardUserDefaults] objectForKey:kAppIdKey];
    }
    
//    NSString *payload = [NSString stringWithFormat:@"{\"uuid\" : \"%@\",\"event\" : \"event:hangup\",\"time\": \"%@\",\"device_id\": \"%@\",\"callid\" : \"%@\", \"role\": \"%@\"}",
//                         appId, [[NSDate date] zuluFormattedStringDate], self.callConfiguration.deviceId, self.callConfiguration.callId, self.callConfiguration.role];
    ICoAPMessage *hangUpMessage;
    hangUpMessage = [[ICoAPMessage alloc] initAsRequestConfirmable:YES requestMethod:IC_POST sendToken:YES payload:payload];
    [hangUpMessage addOption:IC_URI_PATH withValue:@"hangup"];
    [hangUpMessage addOption:IC_CONTENT_FORMAT withValue:[NSString stringWithFormat:@"%lu", (unsigned long)IC_JSON]];
    ICoAPMessage* inviteMessage;
    ICoAPExchange* hangUpExchange;
    ICoAPExchange* currentExchange;
    if (isIntrospectionEnabled) {
        NSString *bearerToken = [self bearerToken];
        
        if (bearerToken) {
            [inviteMessage addOption:IC_INTROSPECTION withValue:bearerToken];
        }
    }
    
    hangUpExchange = [[ICoAPExchange alloc] init];
    hangUpExchange.delegate = self;
    currentExchange = hangUpExchange;
    [hangUpExchange sendRequestWithCoAPMessage:hangUpMessage toHost:hostIpAddress port:kCoAPRemotePort];
}

#pragma mark - ICoAPExchangeDelegate

- (void)iCoAPExchange:(ICoAPExchange *)exchange didReceiveCoAPMessage:(ICoAPMessage *)coapMessage
{
    if(coapMessage != nil)
    {
        NSData *data = [coapMessage.payload dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        success(dictionary);
    }
}

- (void)iCoAPExchange:(ICoAPExchange *)exchange didFailWithError:(NSError *)error
{
    
    failure(error);
}

- (void)iCoAPExchange:(ICoAPExchange *)exchange didRetransmitCoAPMessage:(ICoAPMessage *)coapMessage number:(uint)number finalRetransmission:(BOOL)final;
{
    
}

@end
