//
//  DeleteSample.m
//  SKYBellCOAPManager
//
//  Created by Kumar Utsav on 13/04/16.
//  Copyright © 2016 Kumar Utsav. All rights reserved.
//

#import "DeleteSample.h"

@implementation DeleteSample


[self.sbServiceAPI getDevicesOnCompletion:^(SBGetDevicesResponse *response , NSError *error)
 {
     NSLog(@"%@",response);
     if (error)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             
             if ([UIAlertController class])
             {
                 UIAlertController *errorAlert= [UIAlertController
                                                 alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                 message:error.localizedDescription
                                                 preferredStyle:UIAlertControllerStyleAlert];
                 
                 UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    [errorAlert dismissViewControllerAnimated:YES completion:nil];
                                                                    [self hideActivityIndicatorForSkyBellActivities];
                                                                    
                                                                }];
                 
                 [errorAlert addAction:cancel];
                 [self presentViewController:errorAlert animated:YES completion:nil];
                 errorAlert.view.tintColor = [UIColor colorWithRGBHex:0x0A5FFE];
             }
             else
             {
                 UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                 [errorAlert show];
             }
             [self hideActivityIndicatorForSkyBellActivities];
             [self hideNoActivitiesLabel:NO];
         });
     }
     else
     {
         if(response.success)
         {
             self.deviceListArray = response.deviceList;
             if (self.deviceListArray.count == 0)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     [self hideActivityIndicatorForSkyBellActivities];
                     _noActivitiesLabel.text = NSLocalizedString(@"No Devices Found", nil);
                     self.watchLiveButton.hidden = YES;
                 });
             }
             else
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     self.watchLiveButton.hidden = NO;
                 });
                 [self sortDeviceID:self.deviceListArray];
                 [self getActivityHistoryService];
             }
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 if ([self isIPad])
                 {
                     if ([self.delegate respondsToSelector:@selector(activityHistoryScreen:skybellDeviceList:)])
                     {
                         [self.delegate activityHistoryScreen:self skybellDeviceList:self.deviceListArray];
                     }
                     [[NSNotificationCenter defaultCenter]postNotificationName:SkybellDevicesDidReceivedNotification object:self.deviceListArray];
                 }
             });
         }
         else
         {
             for (SBError *error in response.errors)
             {
                 if (error.errorCode == 401) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self hideActivityIndicatorForSkyBellActivities];
                         [self invalidSkybellLoginHandling];
                         return;
                         
                     });
                 }
                 
             }
             [self showAlertForRetry:YES];
         }
         if (self.deviceListArray.count == 0)
         {
             [self hideNoActivitiesLabel:NO];
         }
         else
         {
             [self hideNoActivitiesLabel:YES];
         }
     }
 }];
@end
