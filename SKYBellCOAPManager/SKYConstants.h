//
//  SKYConstants.h
//  SkyBell
//
//  Created by Luis Hernandez on 8/12/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#ifndef SkyBell_SKYConstants_h
#define SkyBell_SKYConstants_h
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

typedef NS_ENUM (NSUInteger, SKYGestureDirection) {
    SKYGestureDirectionUp,
    SKYGestureDirectionDown,
    SKYGestureDirectionLeft,
    SKYGestureDirectionRight
};

typedef NS_ENUM (NSUInteger, SKYCallTrigger) {
    SKYCallTriggerUndefined,
    SKYCallTriggerMobileInitiated,
    SKYCallTriggerSkyBellButtonInitiated,
    SKYCallTriggerSkyBellMotionSensorInitiated,
    SKYCallTriggerSkyBellSoundSensorInitiated,
    SKYCallTriggerSkyBellApiInitiated
};

typedef NS_ENUM(NSUInteger, SKYSecurityType) {
    SKYSecurityTypeWPA,
    SKYSecurityTypeWPA2,
    SKYSecurityTypeWEP,
    SKYSecurityTypeNone
};

typedef NS_ENUM(NSUInteger, SKYActivityHistoryItemState) {
    SKYActivityHistoryItemStateAvailable,
    SKYActivityHistoryItemStateRequestedDownload,
    SKYActivityHistoryItemStateProcessingDownload,
    SKYActivityHistoryItemStateDownloadReady
};

// Paths
static NSString *const kUpdatePasswordUrl = @"/password/change";
static NSString *const kResourcesUrl = @"/resources";
static NSString *const kResetPasswordUrl = @"/password/request_reset";
static NSString *const kInviteTokenUrl = @"/device_invite_tokens";
static NSString *const kNotifiersUrl = @"/triggers";
static NSString *const kCreateUserUrl = @"/users";
static NSString *const kUserInfoUrl = @"/users/me";
static NSString *const kDevicesUrl = @"/devices";
static NSString *const kDeviceUrl = @"/devices/%@";
static NSString *const kDeviceActivityRequestVideoUrl = @"/devices/%@/activities/%@/create_video";
static NSString *const kDeviceActivityDownloadVideo = @"/devices/%@/activities/%@/video";
static NSString *const kDeviceActivitiesUrl = @"/devices/%@/activities";
static NSString *const kDeleteDeviceActivitiesUrl = @"/devices/%@/activities/%@";
static NSString *const kConfirmDeviceRegisterUrl = @"/device_invite_tokens/%@/ready";
static NSString *const kLinksUrl = @"/users/me/links";
static NSString *const kDeletePartnerUrl = @"/users/me/links/%@";
static NSString *const kDeviceAvatarUrl = @"/devices/%@/avatar";

extern NSString *const SKYAccountManagerUserDidAuthenticateNotification;
extern NSString *const SKYStreamStartNotification;
static NSString *const kUsernameKey = @"SKYUsernameKey";
static NSString *const kDeviceAddress = @"192.168.1.1";
static NSString *const kPushTokenDefaultsKey = @"SKYCurrentPushTokenDefaultsKey";
static NSString *const kRoleClient = @"client";
static NSString *const kRolePlayback = @"playback";
static NSUInteger const kCoAPRemotePort = 5683;
static NSString *const kNestName = @"nest";
static NSUInteger const kNoPacketsReceivedLimitInSeconds = 10;

static NSString *const kButtonInitiatedKey = @"device:sensor:button";
static NSString *const kMotionInitiatedKey = @"device:sensor:motion";
static NSString *const kSoundInitiatedKey = @"device:sensor:sound";

// Device Settings
static NSString *const kMotionPolicyDisabledKey = @"disabled";
static NSString *const kMotionPolicyEnabledKey = @"call";
static NSString *const kMotionSensorKey = @"motion_policy";
static NSString *const kVolumeSensorKey = @"speaker_volume";
static NSString *const kChimeLevelKey = @"chime_level";
static NSString *const kLedBrightnessSensorKey = @"led_intensity";
static NSString *const kMotionSensitivitySensorKey = @"motion_threshold";
static NSString *const kDigitalDoorBellKey = @"digital_doorbell";
static NSString *const kNotDisturbKey = @"do_not_disturb";
static NSString *const kNotRingKey = @"do_not_ring";
static NSString *const kLedRedValue = @"green_r";
static NSString *const kLedGreenValue = @"green_g";
static NSString *const kLedBlueValue = @"green_b";
static NSString *const kUseStagingServerKey = @"kSKYUseStagingServerKey";
static NSString *const kSpeakerVolumeValueKey = @"kSpeakerVolumeValueKey";
static NSString *const kUserIdKey = @"userId";
static NSString *const kAppIdKey = @"appId";
static NSString *const kAccessToken = @"_token_";

// developer settings
static NSString *const kIntrospectionRetryEnabledKey = @"introspectionEnabled";
static NSString *const kDecryptionEnabledKey = @"decryptionEnabled";

#endif
