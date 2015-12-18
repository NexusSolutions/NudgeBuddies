//
//  ViewController.m
//  NudgeBuddies
//
//  Created by Xian Lee on 3/12/2015.
//  Copyright © 2015 Blue Silver. All rights reserved.
//

#import "ViewController.h"
#import "SettingController.h"
#import "MenuController.h"
#import "SearchController.h"
#import <iAd/iAd.h>
#import <CoreMotion/CoreMotion.h>
#import "UIImagePickerHelper.h"
#import "NotificationCenter.h"

@interface ViewController () <SettingControllerDelegate, SearchControllerDelegate, ADBannerViewDelegate, UITextFieldDelegate, QBChatDelegate, MenuControllerDelegate, NudgeButtonDelegate>
{
    // general
    QBUUser *currentUser;
    NotificationCenter *center;
    
    // nudgebuddies
    IBOutlet UIScrollView *nudgebuddiesBar;
    IBOutlet UIView *notificationView;
    IBOutlet UIView *initSearchView;
    IBOutlet UIView *initFavView;
    IBOutlet UIView *initControlView;
    
    // group pages
    IBOutlet UIView *autoView;
    IBOutlet UIView *groupView;
    
    // favorite page
    CGRect rectFav1, rectFav2, rectFav3, rectFav4, rectFav5;
    CMMotionManager *motionManager;
    IBOutlet UIView *user1;
    IBOutlet UIView *user2;
    IBOutlet UIView *user3;
    IBOutlet UIView *user4;
    IBOutlet UIView *user5;
    
    // setting page
    SettingController *settingCtrl;
    IBOutlet UIView *settingView;
    
    // iAD page
    ADBannerView *bannerView;
    
    // search page
    SearchController *searchCtrl;
    IBOutlet UIView *searchView;
    IBOutlet UIButton *searchDoneButton;
    IBOutlet UITextField *searchBox;
    
    // profile page
    IBOutlet UIView *profileView;
    UIImagePickerHelper *iPH;
    NSData *profileImgData;
    IBOutlet UIButton *profileBtn;
    IBOutlet UILabel *uname;
    IBOutlet UITextField *email;
    IBOutlet UITextField *passwd;
    BOOL profilePictureUpdate;
    
    // add nudgers page
    IBOutlet UIView *addView;
    
    // menus module
    MenuController *menuCtrl;
    IBOutlet UIView *menuView;
    NSMutableArray *nudgeButtonArr;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // **********  setting page  ************
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    settingCtrl = (SettingController *)[mainStoryboard instantiateViewControllerWithIdentifier: @"settingCtrl"];
    [self addChildViewController:settingCtrl];
    [settingView addSubview:settingCtrl.view];
    [settingView setFrame:CGRectMake(0, settingView.frame.size.height*(-1), settingView.frame.size.width, settingView.frame.size.height)];
    settingCtrl.delegate = self;
    
    // **********  iAD module  ************
    bannerView = [[ADBannerView alloc]initWithFrame:
                  CGRectMake(0, 518, 320, 50)];
    // Optional to set background color to clear color
    [bannerView setBackgroundColor:[UIColor clearColor]];
//    [self.view addSubview: bannerView];
//    [self performSelector:@selector(removeIAD) withObject:nil afterDelay:15];
    
    // **********  search module  ************
    searchDoneButton.hidden = YES;
    searchView.hidden = YES;
    addView.hidden = YES;
    [searchBox addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    searchCtrl = (SearchController *)[mainStoryboard instantiateViewControllerWithIdentifier: @"searchCtrl"];
    [self addChildViewController:searchCtrl];
    [searchView addSubview:searchCtrl.view];
    searchCtrl.delegate = self;
    int tableSize = [searchCtrl searchResult:@""];
    if (tableSize > 320) {
        [searchView setFrame:CGRectMake(searchView.frame.origin.x, searchView.frame.origin.y, searchView.frame.size.width, 320)];
    } else {
        [searchView setFrame:CGRectMake(searchView.frame.origin.x, searchView.frame.origin.y, searchView.frame.size.width, tableSize)];
    }
    
    // **********  menu module  ************
    menuView.hidden = YES;
    menuCtrl = (MenuController *)[mainStoryboard instantiateViewControllerWithIdentifier: @"menuCtrl"];
    [self addChildViewController:menuCtrl];
    [menuView addSubview:menuCtrl.view];
    menuCtrl.delegate = self;

    // **********  group module  ************
    groupView.hidden = YES;
    profileView.hidden = YES;
    autoView.hidden = YES;
    
    currentUser = g_var.currentUser;
    if (currentUser == nil) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *loginEmail = (NSString *)[userDefaults objectForKey:@"email"];
        NSString *loginPwd = (NSString *)[userDefaults objectForKey:@"pwd"];
        
        nudgebuddiesBar.hidden = YES;
        notificationView.hidden = YES;
        initFavView.hidden = YES;
        [initSearchView setFrame:CGRectMake(0, initSearchView.frame.origin.y - initSearchView.frame.size.height, initSearchView.frame.size.width, initSearchView.frame.size.height)];
        [initControlView setFrame:CGRectMake(0, initControlView.frame.origin.y + initControlView.frame.size.height, initControlView.frame.size.width, initControlView.frame.size.height)];
        
        MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [HUD setMode:MBProgressHUDModeIndeterminate];
        [HUD setDetailsLabelText:@"Logging in..."];
        [HUD show:YES];
        
        [QBRequest logInWithUserEmail:loginEmail password:loginPwd successBlock:^(QBResponse *response, QBUUser *user) {
            // Success, do something
            g_var.currentUser = user;
            g_var.currentUser.password = loginPwd;
            [self initNudge];
            [[QBChat instance] addDelegate:self];
            [HUD hide:YES];
            [UIView animateWithDuration:0.5 animations:^(){
                nudgebuddiesBar.hidden = NO;
                notificationView.hidden = NO;
                initFavView.hidden = NO;
                [initSearchView setFrame:CGRectMake(0, initSearchView.frame.origin.y + initSearchView.frame.size.height, initSearchView.frame.size.width, initSearchView.frame.size.height)];
                [initControlView setFrame:CGRectMake(0, initControlView.frame.origin.y - initControlView.frame.size.height, initControlView.frame.size.width, initControlView.frame.size.height)];
                
            }];
        } errorBlock:^(QBResponse *response) {
            // error handling
            NSLog(@"error: %@", response.error);
            [HUD hide:YES];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Login Failed!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }];
    } else {
        [self initNudge];
        [[QBChat instance] addDelegate:self];
    }
}

- (void) initNudge {
    // **********  favorite module  ************
    rectFav1 = user1.frame;
    rectFav2 = user2.frame;
    rectFav3 = user3.frame;
    rectFav4 = user4.frame;
    rectFav5 = user5.frame;
    motionManager = [CMMotionManager new];
    motionManager.accelerometerUpdateInterval = .05;
    motionManager.gyroUpdateInterval = .05;
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        [self outputAccelerometer:accelerometerData.acceleration];
        if (error) {
            NSLog(@"%@", error);
        }
    }];
    
    // **********  profile module  ************
    NSData *profileData = [g_var loadFile:g_var.currentUser.ID];
    uname.text = g_var.currentUser.fullName;
    email.text = g_var.currentUser.email;
    [email setEnabled:NO];
    passwd.text = g_var.currentUser.password;
    if (profileData) {
        [profileBtn setBackgroundImage:[UIImage imageWithData:profileData] forState:UIControlStateNormal];
    } else {
        NSData *imgData = [g_var loadFile:g_var.currentUser.blobID];
        if (imgData) {
            [profileBtn setBackgroundImage:[UIImage imageWithData:imgData] forState:UIControlStateNormal];
        } else {
            [QBRequest downloadFileWithID:g_var.currentUser.blobID successBlock:^(QBResponse *response, NSData *fileData) {
                UIImage *img = [UIImage imageWithData:fileData];
                [profileBtn setBackgroundImage:img forState:UIControlStateNormal];
                NSLog(@"profile loaded");
            } statusBlock:^(QBRequest *request, QBRequestStatus *status) {
                // handle progress
            } errorBlock:^(QBResponse *response) {
                NSLog(@"error: %@", response.error);
            }];
        }
    }
    
    // **********  chat module  ************
    nudgeButtonArr = [NSMutableArray new];
    center = [NotificationCenter new];
    [center initCenter];
    [self refreshUI];
}

- (void) refreshUI {
    int lastIndex = 0;
    int barWidth = 20;
    int width = nudgebuddiesBar.frame.size.height;
    int notificationTmp = 0;
    
    for (int i=(int)center.notificationArray.count-1; i>=0; i--) {
        Nudger *nudger = [center.notificationArray objectAtIndex:i];
        lastIndex ++;
        NudgeButton *nudgeBtn = [NudgeButton new];
        [self addChildViewController:nudgeBtn];
        nudgeBtn.delegate = self;
        if (nudger.isNew) {
            notificationTmp ++;
            if (notificationTmp > 3) {
                [nudgebuddiesBar addSubview:nudgeBtn.view];
                nudger.menuPos = 1;
                [nudgeBtn.view setFrame:CGRectMake(barWidth, 0, width, width)];
                barWidth += (width + 70);
                [nudgebuddiesBar setContentSize:CGSizeMake(barWidth, width)];
                [nudgeBtn initNudge:nudger notify:NO];
            } else {
                nudger.menuPos = 0;
                if (nudgeButtonArr.count == 0) {
                    [nudgeBtn.view setFrame:CGRectMake(112, 0, width, width)];
                    [notificationView addSubview:nudgeBtn.view];
                    [nudgeBtn initNudge:nudger notify:YES];
                    nudgeBtn.index = 0;
                    [nudgeButtonArr addObject:nudgeBtn];
                } else if (nudgeButtonArr.count == 1) {
                    NudgeButton *oldBtn = [nudgeButtonArr objectAtIndex:0];
                    if (oldBtn.userInfo.user.ID == nudger.user.ID || [oldBtn.userInfo.group.gName isEqualToString:nudger.group.gName]) {
                        [oldBtn initNudge:nudger notify:YES];
                    } else {
                        [notificationView addSubview:nudgeBtn.view];
                        [nudgeBtn.view setHidden:YES];
                        [nudgeButtonArr addObject:nudgeBtn];
                        [UIView animateWithDuration:0.3 animations:^(){
                            [oldBtn.view setFrame:CGRectMake(15, 0, width, width)];
                        } completion:^(BOOL complete) {
                            [UIView animateWithDuration:0.3 animations:^(void){
                                [nudgeBtn initNudge:nudger notify:YES];
                                [nudgeBtn.view setFrame:CGRectMake(112, 0, width, width)];
                                [nudgeBtn.view setHidden:NO];
                            }];
                        }];
                    }
                } else if (nudgeButtonArr.count == 2) {
                    NudgeButton *old1Btn = [nudgeButtonArr objectAtIndex:0];
                    NudgeButton *old2Btn = [nudgeButtonArr objectAtIndex:1];
                    if (old1Btn.userInfo.user.ID == nudger.user.ID || [old1Btn.userInfo.group.gName isEqualToString:nudger.group.gName]) {
                        nudgeButtonArr = [NSMutableArray arrayWithObjects:old2Btn, old1Btn, nil];
                        [old1Btn initNudge:nudger notify:YES];
                        [old1Btn.view setFrame:CGRectMake(112, 0, width, width)];
                        [old1Btn.view setHidden:YES];
                        [UIView animateWithDuration:0.3 animations:^(){
                            [old2Btn.view setFrame:CGRectMake(15, 0, width, width)];
                        } completion:^(BOOL complete) {
                            [UIView animateWithDuration:0.3 animations:^(void){
                                [old1Btn.view setHidden:NO];
                            }];
                        }];
                    } else if (old2Btn.userInfo.user.ID == nudger.user.ID || [old2Btn.userInfo.group.gName isEqualToString:nudger.group.gName]) {
                        [old2Btn initNudge:nudger notify:YES];
                    } else {
                        [notificationView addSubview:nudgeBtn.view];
                        [nudgeBtn.view setHidden:YES];
                        [nudgeButtonArr addObject:nudgeBtn];
                        [UIView animateWithDuration:0.3 animations:^(){
                            [old2Btn.view setFrame:CGRectMake(211, 0, width, width)];
                        } completion:^(BOOL complete) {
                            [UIView animateWithDuration:0.3 animations:^(void){
                                [nudgeBtn initNudge:nudger notify:YES];
                                [nudgeBtn.view setFrame:CGRectMake(112, 0, width, width)];
                                [nudgeBtn.view setHidden:NO];
                            }];
                        }];
                    }
                } else if (nudgeButtonArr.count == 3) {
                    NudgeButton *old1Btn = [nudgeButtonArr objectAtIndex:0];
                    NudgeButton *old2Btn = [nudgeButtonArr objectAtIndex:1];
                    NudgeButton *old3Btn = [nudgeButtonArr objectAtIndex:2];
                    if (old1Btn.userInfo.user.ID == nudger.user.ID || [old1Btn.userInfo.group.gName isEqualToString:nudger.group.gName]) {
                        nudgeButtonArr = [NSMutableArray arrayWithObjects:old2Btn, old3Btn, old1Btn, nil];
                        [old1Btn initNudge:nudger notify:YES];
                        [old1Btn.view setFrame:CGRectMake(112, 0, width, width)];
                        [old1Btn.view setHidden:YES];
                        [UIView animateWithDuration:0.3 animations:^(){
                            [old2Btn.view setFrame:CGRectMake(15, 0, width, width)];
                        } completion:^(BOOL complete) {
                            [UIView animateWithDuration:0.3 animations:^(void){
                                [old1Btn.view setHidden:NO];
                            }];
                        }];
                        [UIView animateWithDuration:0.3 animations:^(){
                            [old3Btn.view setFrame:CGRectMake(211, 0, width, width)];
                        } completion:nil];
                    } else if (old2Btn.userInfo.user.ID == nudger.user.ID || [old2Btn.userInfo.group.gName isEqualToString:nudger.group.gName]) {
                        nudgeButtonArr = [NSMutableArray arrayWithObjects:old1Btn, old3Btn, old2Btn, nil];
                        [old2Btn initNudge:nudger notify:YES];
                        [old2Btn.view setFrame:CGRectMake(112, 0, width, width)];
                        [old2Btn.view setHidden:YES];
                        [UIView animateWithDuration:0.3 animations:^(){
                            [old3Btn.view setFrame:CGRectMake(211, 0, width, width)];
                        } completion:^(BOOL complete) {
                            [UIView animateWithDuration:0.3 animations:^(void){
                                [old2Btn.view setHidden:NO];
                            }];
                        }];
                    } else if (old3Btn.userInfo.user.ID == nudger.user.ID || [old3Btn.userInfo.group.gName isEqualToString:nudger.group.gName]) {
                        [old3Btn initNudge:nudger notify:YES];
                    } else {
                        NudgeButton *old1Btn = [nudgeButtonArr objectAtIndex:0];
                        NudgeButton *old2Btn = [nudgeButtonArr objectAtIndex:1];
                        NudgeButton *old3Btn = [nudgeButtonArr objectAtIndex:2];
                        [notificationView addSubview:nudgeBtn.view];
                        [nudgeBtn.view setHidden:YES];
                        nudgeButtonArr = [NSMutableArray arrayWithObjects:old2Btn, old3Btn, nudgeBtn, nil];
                        [old1Btn.view removeFromSuperview];
                        [UIView animateWithDuration:0.3 animations:^(){
                            [old2Btn.view setFrame:CGRectMake(15, 0, width, width)];
                        } completion:^(BOOL complete) {
                            [UIView animateWithDuration:0.3 animations:^(void){
                                [nudgeBtn initNudge:nudger notify:YES];
                                [nudgeBtn.view setFrame:CGRectMake(112, 0, width, width)];
                                [nudgeBtn.view setHidden:NO];
                            }];
                        }];
                        [UIView animateWithDuration:0.3 animations:^(){
                            [old3Btn.view setFrame:CGRectMake(211, 0, width, width)];
                        } completion:nil];
                    }
                }
            }
        } else {
            nudger.menuPos = 1;
            [nudgebuddiesBar addSubview:nudgeBtn.view];
            [nudgeBtn.view setFrame:CGRectMake(barWidth, 0, width, width)];
            barWidth += (width + 70);
            [nudgebuddiesBar setContentSize:CGSizeMake(barWidth, width)];
            [nudgeBtn initNudge:nudger notify:NO];
        }
    }
}

#pragma mark - Chat Module
///// --------- msg list ----------- /////////////////////////////////////////////////////////////////////////
- (void)chatRoomDidReceiveMessage:(QB_NONNULL QBChatMessage *)message fromDialogID:(QB_NONNULL NSString *)dialogID {
    
}
///// --------- contact list ----------- /////////////////////////////////////////////////////////////////////////
- (void)chatDidReceiveContactAddRequestFromUser:(NSUInteger)userID {
    [QBRequest userWithID:userID successBlock:^(QBResponse *response, QBUUser *user) {
        NSLog(@"--------Got add contact request from   %lu ---------", userID);
        Nudger *newUser = [[Nudger alloc] initWithUser:user];
        newUser.isNew = YES;
        newUser.status = NSInvited;
//        [center.contactArray addObject:newUser];
        [center.notificationArray addObject:newUser];
        [center sort];
        [self refreshUI];
    } errorBlock:^(QBResponse *response) {
        NSLog(@"Err: loading pending users");
    }];
}

- (void)chatContactListDidChange:(QB_NONNULL QBContactList *)contactList {
    NSLog(@"--------chatContactListDidChange--------- %@", contactList);
}

- (void)chatDidReceiveContactItemActivity:(NSUInteger)userID isOnline:(BOOL)isOnline status:(QB_NULLABLE NSString *)status {
    NSLog(@"--------chatDidReceiveContactItemActivity--------- %lu", userID);
}

- (void)chatDidReceiveAcceptContactRequestFromUser:(NSUInteger)userID {
    NSLog(@"--------chatDidReceiveAcceptContactRequestFromUser--------- %lu", userID);
    [[[UIAlertView alloc] initWithTitle:@"Alert" message:[NSString stringWithFormat:@"Your add contact request (ID:%lu is accepted!", userID] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    [center refresh];
    [self refreshUI];
}

- (void)chatDidReceiveRejectContactRequestFromUser:(NSUInteger)userID {
    NSLog(@"--------chatDidReceiveRejectContactRequestFromUser--------- %lu", userID);
    [[[UIAlertView alloc] initWithTitle:@"Alert" message:[NSString stringWithFormat:@"Your add contact request (ID:%lu is rejected!", userID] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
}

#pragma mark - Menu
///// --------- Menu Views ----------- /////////////////////////////////////////////////////////////////////////
- (void)onMenuClose {
    [UIView transitionWithView:self.view duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [menuView setHidden:YES];
    } completion:nil];
}

- (void)onNudgeClicked:(Nudger *)nudger frame:(CGRect)rect {
    [self hideSetting];
    [self onGroupClose:nil];
    [self onProfileClose:nil];
    [self onSearchDone];
    [self onAutoClose:nil];
    [self onAddClose:nil];

    CGSize size = [menuCtrl createMenu:nudger];
    Menu *menu = [center getMenu:rect menuSize:size];
    if (nudger.menuPos == 0) {
        [menuView setFrame:CGRectMake(menu.menuPoint.x, menu.menuPoint.y + notificationView.frame.origin.y, size.width, size.height+15)];
    } else if (nudger.menuPos == 1) {
        [menuView setFrame:CGRectMake(menu.menuPoint.x, menu.menuPoint.y + nudgebuddiesBar.frame.origin.y, size.width, size.height+15)];
    } else {
        [menuView setFrame:CGRectMake(menu.menuPoint.x, menu.menuPoint.y, size.width, size.height+15)];
    }
    UIImageView *triImg = (UIImageView *)[menuView viewWithTag:100];
    if (menu.triDirection) {
        [triImg setImage:[UIImage imageNamed:@"menu-tri"]];
        [menuCtrl.view setFrame:CGRectMake(0, triImg.frame.size.height, size.width, size.height)];
        [triImg setFrame:CGRectMake(menu.triPoint.x, 0, triImg.frame.size.width, triImg.frame.size.height)];
    } else {
        [triImg setImage:[UIImage imageNamed:@"menu-tri-down"]];
        [menuCtrl.view setFrame:CGRectMake(0, 0, size.width, size.height)];
        [triImg setFrame:CGRectMake(menu.triPoint.x, size.height, triImg.frame.size.width, triImg.frame.size.height)];
    }
    [UIView transitionWithView:self.view duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [menuView setHidden:NO];
    } completion:nil];
}

- (void)onMenuClicked:(MenuReturn)menuReturn nudger:(Nudger *)nudger{
    [self onMenuClose];
    if (menuReturn == MRNudge) {
        
    } else if (menuReturn == MRRumble) {
        
    } else if (menuReturn == MRRumbleSilent) {
        
    } else if (menuReturn == MRAnnoy) {
        
    } else if (menuReturn == MRAddGroup) {
        
    } else if (menuReturn == MRAuto) {
        
    } else if (menuReturn == MRBlock) {
        
    } else if (menuReturn == MREdit) {
        
    } else if (menuReturn == MREditGroup) {
        
    } else if (menuReturn == MRSilent) {
        
    } else if (menuReturn == MRStream) {
        
    } else if (menuReturn == MRStreamGroup) {
        
    } else if (menuReturn == MRViewGroup) {
        
    } else if (menuReturn == MRAdd) {
        [[QBChat instance] confirmAddContactRequest:nudger.user.ID completion:^(NSError * _Nullable error) {
            [center refresh];
            [self refreshUI];
        }];
    } else if (menuReturn == MRReject) {
        [[QBChat instance] rejectAddContactRequest:nudger.user.ID completion:^(NSError * _Nullable error) {
            [center refresh];
            [self refreshUI];
        }];
    }
}

#pragma mark - profile
///// --------- edit profile ----------- /////////////////////////////////////////////////////////////////////////
- (IBAction)onPhoto:(id)sender {
    iPH = [[UIImagePickerHelper alloc] init];
    [iPH imagePickerInView:self WithSuccess:^(UIImage *image) {
        CGSize newSize = CGSizeMake(RESIZE_WIDTH, RESIZE_HEIGHT);
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [profileBtn setBackgroundImage:newImage forState:UIControlStateNormal];
        profileImgData = UIImageJPEGRepresentation(newImage, 1.0f);
        g_var.profileImg = profileImgData;
        profilePictureUpdate = YES;
    } failure:^(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }];
}

- (IBAction)onProfileSave:(id)sender {
    [[MBProgressHUD showHUDAddedTo:self.view animated:YES] show:YES];
    if (profilePictureUpdate) {
        [QBRequest TUploadFile:g_var.profileImg fileName:@"profile.jpg" contentType:@"image/jpeg" isPublic:NO successBlock:^(QBResponse *response, QBCBlob *blob) {
            [g_var saveFile:g_var.profileImg uid:blob.ID];
            QBUpdateUserParameters *updateParameters = [QBUpdateUserParameters new];
            updateParameters.blobID = blob.ID;
            updateParameters.oldPassword = currentUser.password;
            updateParameters.password = passwd.text;
            [QBRequest updateCurrentUser:updateParameters successBlock:^(QBResponse *response, QBUUser *user) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [self onProfileClose:nil];
            } errorBlock:^(QBResponse *response) {
                NSLog(@"error: %@", response.error);
                [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", response.error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }];
        } statusBlock:^(QBRequest *request, QBRequestStatus *status) {
            // handle progress
            NSLog(@"profile status err");
        } errorBlock:^(QBResponse *response) {
            NSLog(@"error: %@", response.error);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", response.error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }];
    } else {
        QBUpdateUserParameters *updateParameters = [QBUpdateUserParameters new];
        updateParameters.oldPassword = currentUser.password;
        updateParameters.password = passwd.text;
        [QBRequest updateCurrentUser:updateParameters successBlock:^(QBResponse *response, QBUUser *user) {
            // User updated successfully
            NSLog(@"%@", user);
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [self onProfileClose:nil];
        } errorBlock:^(QBResponse *response) {
            // Handle error
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", response.error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }];
    }
}

- (IBAction)onProfileClose:(id)sender {
    [UIView transitionWithView:profileView duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        profileView.hidden = YES;
    } completion:nil];
}

#pragma mark - favorite
///// --------- favorite views ----------- /////////////////////////////////////////////////////////////////////////
- (void)outputAccelerometer:(CMAcceleration)acceleration {

    [UIView transitionWithView:user1 duration:.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [user1 setFrame:CGRectMake(rectFav1.origin.x+acceleration.x*10, rectFav1.origin.y+acceleration.y*10, rectFav1.size.width, rectFav1.size.height)];
    } completion:nil];
    [UIView transitionWithView:user2 duration:.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [user2 setFrame:CGRectMake(rectFav2.origin.x+acceleration.x*20*0.8, rectFav2.origin.y+acceleration.y*20*0.9, rectFav2.size.width, rectFav2.size.height)];
    } completion:nil];
    [UIView transitionWithView:user3 duration:.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [user3 setFrame:CGRectMake(rectFav3.origin.x-acceleration.x*20*0.9, rectFav3.origin.y+acceleration.y*20*0.8, rectFav3.size.width, rectFav3.size.height)];
    } completion:nil];
    [UIView transitionWithView:user4 duration:.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [user4 setFrame:CGRectMake(rectFav4.origin.x-acceleration.x*30*0.5, rectFav4.origin.y+acceleration.y*30*0.86, rectFav4.size.width, rectFav4.size.height)];
    } completion:nil];
    [UIView transitionWithView:user5 duration:.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [user5 setFrame:CGRectMake(rectFav5.origin.x-acceleration.x*30*0.86, rectFav5.origin.y-acceleration.y*30*0.5, rectFav5.size.width, rectFav5.size.height)];
    } completion:nil];
}

#pragma mark - setting
///// --------- setting Views ----------- /////////////////////////////////////////////////////////////////////////
- (IBAction)onSettingOpen:(id)sender {
    [self onGroupClose:nil];
    [self onAutoClose:nil];
    [self onProfileClose:nil];
    [self onSearchDone];
    [self onAddClose:nil];
    [self onMenuClose];
    UIButton *senderBtn = (UIButton *)sender;
    if (senderBtn.tag == 2) {
        [settingCtrl initView:YES];
    }
    if (settingView.frame.origin.y < 0) {
        [UIView transitionWithView:settingView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [settingView setFrame:CGRectMake(0, 0, settingView.frame.size.width, settingView.frame.size.height)];        settingView.hidden = NO;
        } completion:nil];
    } else {
        [self hideSetting];
    }
}

- (void)hideSetting {
    [UIView transitionWithView:settingView duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [settingView setFrame:CGRectMake(0, settingView.frame.size.height*(-1), settingView.frame.size.width, settingView.frame.size.height)];        settingView.hidden = NO;
    } completion:^(BOOL finished){
        [settingCtrl initView:NO];
    }];
}

- (void)onSettingDone:(int)status {
    [UIView transitionWithView:settingView duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
    [settingView setFrame:CGRectMake(0, settingView.frame.size.height*(-1), settingView.frame.size.width, settingView.frame.size.height)];
    } completion:nil];
    if (status == 1) {
        [self onGroupClose:nil];
        [self onAutoClose:nil];
        [self onSearchDone];
        [self onAddClose:nil];
        [self onMenuClose];
        if (profileView.hidden == NO) {
            [self onProfileClose:nil];
        }
        [UIView transitionWithView:profileView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            profileView.hidden = NO;
        } completion:nil];
    }
}

#pragma mark - Search
///// --------- search view ----------- /////////////////////////////////////////////////////////////////////////
- (IBAction)onSearchClose:(id)sender {
    [searchBox resignFirstResponder];
    [UIView transitionWithView:searchDoneButton duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        searchDoneButton.hidden = YES;
    } completion:nil];
    
    [UIView transitionWithView:searchView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [searchView setFrame:CGRectMake(searchView.frame.origin.x, searchView.frame.origin.y, searchView.frame.size.width, 0)];
    } completion:^(BOOL flag){
        searchView.hidden = YES;
        [searchCtrl emptyTable];
        searchBox.text = @"";
    }];
}

- (void)onSearchDone {
    NSLog(@"search done");
    [self onSearchClose:nil];
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSLog(@"changed");
    searchView.hidden = NO;
    [self hideSetting];
    [self onGroupClose:nil];
    [self onAutoClose:nil];
    [self onProfileClose:nil];
    [self onAddClose:nil];
    [self onMenuClose];
    int size = [searchCtrl searchResult:textField.text];
    [searchView setFrame:CGRectMake(searchView.frame.origin.x, searchView.frame.origin.y, searchView.frame.size.width, 0)];
    [UIView transitionWithView:searchView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [searchView setFrame:CGRectMake(searchView.frame.origin.x, searchView.frame.origin.y, searchView.frame.size.width, size)];
        [searchCtrl.view setFrame:CGRectMake(0, 0, searchCtrl.view.frame.size.width, size)];
    } completion:nil];
    [UIView transitionWithView:searchDoneButton duration:0.8 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        searchDoneButton.hidden = NO;
    } completion:nil];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    searchView.hidden = NO;
    int size = [searchCtrl searchResult:textField.text];
    [self hideSetting];
    [self onGroupClose:nil];
    [self onAutoClose:nil];
    [self onProfileClose:nil];
    [self onAddClose:nil];
    [self onMenuClose];
    [searchView setFrame:CGRectMake(searchView.frame.origin.x, searchView.frame.origin.y, searchView.frame.size.width, 0)];
    [UIView transitionWithView:searchView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [searchView setFrame:CGRectMake(searchView.frame.origin.x, searchView.frame.origin.y, searchView.frame.size.width, size)];
        [searchCtrl.view setFrame:CGRectMake(0, 0, searchCtrl.view.frame.size.width, size)];
    } completion:nil];
    [UIView transitionWithView:searchDoneButton duration:0.8 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        searchDoneButton.hidden = NO;
    } completion:nil];
    NSLog(@"started");
    return YES;
}

#pragma mark - Add Friend
///// --------- Add Friend ----------- /////////////////////////////////////////////////////////////////////////
- (IBAction)onAddOpen:(id)sender {
    [self hideSetting];
    [self onGroupClose:nil];
    [self onProfileClose:nil];
    [self onSearchDone];
    [self onAutoClose:nil];
    [self onMenuClose];
    if (addView.hidden == NO) {
        [self onAddClose:nil];
        return;
    }
    [UIView transitionWithView:addView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        addView.hidden = NO;
    } completion:nil];
}

- (IBAction)onAddClose:(id)sender {
    if (sender) {
        [searchBox becomeFirstResponder];
    } else {
        [UIView transitionWithView:addView duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            addView.hidden = YES;
        } completion:nil];
    }
}

#pragma mark - Auto Group
///// --------- Auto Group view ----------- /////////////////////////////////////////////////////////////////////////
- (IBAction)onAutoOpen:(id)sender {
    [self hideSetting];
    [self onGroupClose:nil];
    [self onProfileClose:nil];
    [self onSearchDone];
    [self onAddClose:nil];
    [self onMenuClose];
    if (autoView.hidden == NO) {
        [self onAutoClose:nil];
        return;
    }
    [UIView transitionWithView:autoView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        autoView.hidden = NO;
    } completion:nil];
}

- (IBAction)onAutoClose:(id)sender {
    [UIView transitionWithView:autoView duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        autoView.hidden = YES;
    } completion:nil];
}

#pragma mark - Add Group
///// --------- Add Group View ----------- /////////////////////////////////////////////////////////////////////////
- (IBAction)onGropOpen:(id)sender {
    [self hideSetting];
    [self onAutoClose:nil];
    [self onProfileClose:nil];
    [self onSearchDone];
    [self onAddClose:nil];
    [self onMenuClose];
    if (groupView.hidden == NO) {
        [self onGroupClose:nil];
        return;
    }
    [UIView transitionWithView:groupView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        groupView.hidden = NO;
    } completion:nil];
}

- (IBAction)onGroupClose:(id)sender {
    [UIView transitionWithView:groupView duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        groupView.hidden = YES;
    } completion:nil];
}

#pragma mark - iAd
///// --------- iAd ----------- /////////////////////////////////////////////////////////////////////////
-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error{
    NSLog(@"Error loading");
}

-(void)bannerViewDidLoadAd:(ADBannerView *)banner{
    NSLog(@"Ad loaded");
}
-(void)bannerViewWillLoadAd:(ADBannerView *)banner{
    NSLog(@"Ad will load");
}
-(void)bannerViewActionDidFinish:(ADBannerView *)banner{
    NSLog(@"Ad did finish");
}

-(void)removeIAD {
    bannerView.hidden = YES;
}

@end
