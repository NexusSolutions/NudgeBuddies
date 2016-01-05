//
//  AppDelegate.m
//  NudgeBuddies
//
//  Created by Xian Lee on 3/12/2015.
//  Copyright © 2015 Blue Silver. All rights reserved.
//

#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "SigninController.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

Global *g_var;
AppCenter *g_center;
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    g_var = [Global new];
    [g_var initSet];
    g_center = [AppCenter new];
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    [QBSettings setApplicationID:kQBApplicationID];
    [QBSettings setAuthKey:      kQBRegisterServiceKey];
    [QBSettings setAuthSecret:   kQBRegisterServiceSecret];
    [QBSettings setAccountKey:   kQBAccountKey];
    
    [QBSettings setAutoReconnectEnabled:YES];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ViewController *viewCtrl = (ViewController *)[mainStoryboard instantiateViewControllerWithIdentifier: @"viewCtrl"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"remember"]) {
        self.window.rootViewController = viewCtrl;
        [self.window makeKeyAndVisible];
        [self initialApp];
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    QBMSubscription *subscription = [QBMSubscription subscription];
    subscription.notificationChannel = QBMNotificationChannelAPNS;
    subscription.deviceUDID = deviceIdentifier;
    subscription.deviceToken = deviceToken;
    
    [QBRequest createSubscription:subscription successBlock:^(QBResponse *response, NSArray *objects) {
        
    } errorBlock:^(QBResponse *response) {

    }];
}

//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    AVAudioPlayer *audioPlayer;
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"effect" ofType:@"mp3"];
//    NSURL *file = [NSURL fileURLWithPath:path];
//    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:nil];
//    [audioPlayer prepareToPlay];
//    [audioPlayer play];
//}

- (void)initialApp {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *loginEmail = (NSString *)[userDefaults objectForKey:@"email"];
    NSString *loginPwd = (NSString *)[userDefaults objectForKey:@"pwd"];
    
    [QBRequest logInWithUserEmail:loginEmail password:loginPwd successBlock:^(QBResponse *response, QBUUser *user) {
        // Success, do something
        user.password = loginPwd;
        [g_center initCenter:user];
        
    } errorBlock:^(QBResponse *response) {
        // error handling
        NSLog(@"error: %@", response.error);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Login Failed!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[QBChat instance] disconnectWithCompletionBlock:^(NSError * _Nullable error) {
        
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[QBChat instance] disconnectWithCompletionBlock:^(NSError * _Nullable error) {
        
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[QBChat instance] connectWithUser:g_center.currentUser  completion:^(NSError * _Nullable error) {
        
    }];
}

@end
