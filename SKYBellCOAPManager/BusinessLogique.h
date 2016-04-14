//
//  BusinessLogique.h
//  SKYBellCOAPManager
//
//  Created by Kumar Utsav on 11/04/16.
//  Copyright © 2016 Kumar Utsav. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SKYDeviceRecord;
@interface BusinessLogique : NSObject

- (void)confirmDeviceRegistrationWithInviteToken:(NSString *)inviteToken
                                         success:(void(^) (void)) success
                                         failure:(void(^) (NSError * error))failure;
- (void)fetchDevices:(void(^)(NSArray * devices)) completionBlock failureBlock:(void(^)(NSError * error))failure;
- (void)deleteDevices:(void(^)(NSError * error))completionBlock;
- (void)deleteDeviceWithDeviceIdentifier:(NSString *)deviceIdentifier
                                 success:(void(^) (void)) success
                                 failure:(void(^) (NSError * error))failure;
- (void)updateDeviceNameWithDeviceRecord:(SKYDeviceRecord *)device
                                 newName:(NSString *)name
                                 success:(void(^) (void))success
                                 failure:(void(^) (NSError * error))failure;
- (void)getAvatarUrlForDevice:(SKYDeviceRecord *)device
                      success:(void(^) (NSString *url))success
                      failure:(void(^) (NSError * error))failure;
- (NSString *)deviceNameWithDeviceId:(NSString *)deviceId;



@end
