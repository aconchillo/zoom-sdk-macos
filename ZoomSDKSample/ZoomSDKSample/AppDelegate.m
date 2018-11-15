//
//  AppDelegate.m
//  ZoomSDKSample
//
//  Created by TOTTI on 7/20/16.
//  Copyright © 2016 TOTTI. All rights reserved.
//

#import "AppDelegate.h"
#import "ZoomSDKWindowController.h"
#import "ShareContentView.h"
#import "ZoomSDKScheduleWindowCtr.h"

#import <time.h>
#import "ZoomSDKWebinarController.h"

#define kZoomSDKDomain      @"https://www.zoom.us"
//#define kZoomSDKAppKey      @"EMXjNaKjSkZzHFmmwM50X6NW6InkYumpf3rK"
//#define kZoomSDKAppSecret   @"jBv7wMcOQbmfWGMp4G9tcGkpLncuZiCoidSl"
//for IBM test
#define kZoomSDKAppKey      @"S8BRYbBoy5jYOCEO4eE1BJQW6RK4qcY6aJMs"
#define kZoomSDKAppSecret   @"rjPqyfIVTe7yoV7emCucS3Lwc0B9YLnwwKky"

//#define kZoomSDKAppKey      @"kCbuCejBQrSuMYANeNDNvw"
//#define kZoomSDKAppSecret   @"QZIp3ruajiRUVPlLxZM6q8Nh2yiUOy2I1ncN"
@interface AppDelegate ()
- (void) switchToZoomUserTab;
- (void) switchToMeetingTab;
@end

@implementation AppDelegate
@synthesize sdkSettingWindowController = _sdkSettingWindowController;

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    [_logoView setImage:[[NSBundle mainBundle] imageForResource:@"ZoomLogo"]];
    [_devZoomAuth setHidden:NO];
    [_authResultField setHidden:YES];
    [_authResultFieldWelcome setHidden:YES];
    [_recordConvertFinishLabel setHidden:YES];
    [_mainWindow setLevel:NSPopUpMenuWindowLevel];
    _mainWindow.delegate = self;
    [_chatButton setEnabled:NO];
    [_recordButton setEnabled:NO];
    [_shareButton setEnabled:NO];
    [_mainWindowButton setEnabled:YES];
    [_endMeeting setEnabled:NO];
    [_revokeRemoteControl setEnabled:NO];
    [_declineRemoteControl setEnabled:NO];
    [_preMeetingError setHidden:YES];
    [_listMeetingError setHidden:YES];
    [_preMeetingButton setEnabled:NO];
    [_logoutButton setEnabled:NO];
    [_H323Button setEnabled:NO];
    [_waitingRoomButton setEnabled:NO];
    [_calloutButton setEnabled:NO];
    [_videoContainerButton setEnabled:NO];
    [_participantsButton setEnabled:NO];
    [_multiShareButton setEnabled:NO];
    [_deviceTypeButton removeAllItems];
    [_ssoTokenField setEnabled:NO];
    NSArray* deviceTypeArray = [NSArray arrayWithObjects:@"H323",@"SIP",@"Unknow", nil];
    for (NSString* key in deviceTypeArray) {
        [_deviceTypeButton.menu addItemWithTitle:key action:@selector(onH323DeviceTypeSelect:) keyEquivalent:@""];
    }
    [_screenTypeSelectButton removeAllItems];
    NSArray* screenTypeArray = [NSArray arrayWithObjects:@"First",@"Second", nil];
    for (NSString* key in screenTypeArray) {
        [_screenTypeSelectButton.menu addItemWithTitle:key action:@selector(onScreenTypeSelected:) keyEquivalent:@""];
    }
    
    _hasLogined = NO;
    _selectDeviceType = H323DeviceType_H323;
    _screenType = ScreenType_First;
    [[ZoomSDK sharedSDK]initSDK:NO];
    ZoomSDKNetworkService* networkService = [[ZoomSDK sharedSDK] getNetworkService];
    networkService.delegate = self;
    //video window init
    _wndCtrl = [[ZoomSDKWindowController alloc] init];
    [_wndCtrl.window setTitle:@"New SDK Window"];
    [_wndCtrl.window setFrame:NSMakeRect(300, 300, 1280, 720) display:YES];
    [_wndCtrl.window orderOut:nil];
    //share window init
    _shareCtrl = [[ZoomSDKWindowController alloc] init];
    [_shareCtrl.window setFrame:NSMakeRect(300, 300, 1280, 720) display:YES];
    [_shareCtrl.window setTitle:@"Share Window"];
    [_shareCtrl.window orderOut:nil];
    _wndCtrl.window.delegate = self;
    
    [self initUI];
    [self initNotification];
}
- (void)initUI
{
    [_WebinarControlButton setEnabled:NO];
    [_settingMenuItem setHidden:YES];
}
-  (void)initService
{
    ZoomSDKMeetingService *meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    meetingService.delegate = self;
    ZoomSDKWebinarController *webinarController = [meetingService getWebinarController];
    webinarController.delegate = self;
    ZoomSDKWaitingRoomController* waitController = [meetingService getWaitingRoomController];
    waitController.delegate = self;
    
    ZoomSDKMeetingActionController* actionCtr = [meetingService getMeetingActionController];
    actionCtr.delegate = self;
    
    ZoomSDKMeetingUIController* uiController = [meetingService getMeetingUIController];
    uiController.delegate = self;
    
    _sdkSettingWindowController = [[ZSDKSettingWindowController alloc] init];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    signal(SIGPIPE, processSignal);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self cleanUp];
}

-(void)cleanUp
{
    [_wndCtrl release];
    [_shareCtrl release];
    _wndCtrl = nil;
    _shareCtrl = nil;
    if (_scheduleEditWindow) {
        [_scheduleEditWindow release];
        _scheduleEditWindow = nil;
    }
    if(_sdkSettingWindowController)
    {
        [_sdkSettingWindowController cleanUp];
        [_sdkSettingWindowController release];
        _sdkSettingWindowController = nil;
    }
    if(_shareCameraWindowCtrl)
    {
        [_shareCameraWindowCtrl release];
        _shareCameraWindowCtrl = nil;
    }
    [self uninitNotification];
}
- (void)uninitNotification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}
-(void)initNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMeetingMainWindow) name:@"ShowMeetingMainWindow" object:nil];
}

//for pipe error
void processSignal(int num)
{
    if ( SIGPIPE == num ) {
    
    }
}

-(IBAction)clickSDKUser:(id)sender
{
    [self switchToMeetingTab];
}
-(IBAction)clickZoomUser:(id)sender
{
    [self switchToZoomUserTab];
}

-(IBAction)clickChat:(id)sender
{
    [self switchToChatTab];
}

-(IBAction)clickShare:(id)sender
{
    [self switchToShareTab];
}

-(IBAction)clickRecord:(id)sender
{
    [self switchToRecordTab];
}


-(IBAction)showSettingDlg:(id)sender
{
    //test
    ZoomSDKSettingService* setting = [[ZoomSDK sharedSDK] getSettingService];
    [[setting getGeneralSetting] hideSettingComponent:SettingComponent_AdvancedFeatureButton hide:YES];
    [[setting getGeneralSetting] hideSettingComponent:SettingComponent_AdvancedFeatureTab hide:YES];
    
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller showMeetingComponent:MeetingComponent_Setting window:nil show:YES InPanel:YES frame:NSZeroRect];
    
    [[setting getGeneralSetting] setCustomFeedbackURL:@"www.baidu.com"];
}

-(IBAction)clickAuthDevZoom:(id)sender
{
    [[ZoomSDK sharedSDK] setZoomDomain:kZoomSDKDomain];
    [self authSDK:kZoomSDKAppKey appSecret:kZoomSDKAppSecret];
    [_connectLabel setStringValue:@"Start Authing..."];
    [self switchToConnectingTab];

}

-(IBAction)sdkAuth:(id)sender
{
    if (!_webDomainField.stringValue.length || !_appKeyField.stringValue.length || !_appSecretField.stringValue.length) {
        [_authResultFieldWelcome setHidden:NO];
        [_authResultFieldWelcome setStringValue:@"Invalid Input Parameter!"];
        return;

    }
    [[ZoomSDK sharedSDK] setZoomDomain:_webDomainField.stringValue];
    [self authSDK:_appKeyField.stringValue appSecret:_appSecretField.stringValue];
    [_connectLabel setStringValue:@"Start Authing..."];
    [self switchToConnectingTab];
}

-(IBAction)loginZoom:(id)sender
{
    [_authResultField setHidden:YES];
    ZoomSDKAuthService *authService = [[ZoomSDK sharedSDK] getAuthService];
    if (authService)
    {
        if(NSOnState == [_enableSSOButton state])
        {
            [authService loginSSO:[_ssoTokenField stringValue]];
        }
        else
        {
            BOOL remember = [_rememberMeButton state]== NSOnState? YES:NO;
            [authService login: [_userNameField stringValue] Password:[_passwordField stringValue] RememberMe:remember];
        }
        [self switchToConnectingTab];
    }
}

-(IBAction)enableSSO:(id)sender{
    if (NSOnState == [_enableSSOButton state]) {
        [_userNameField setEnabled:NO];
        [_passwordField setEnabled:NO];
        [_ssoTokenField setEnabled:YES];
    }else{
        [_userNameField setEnabled:YES];
        [_passwordField setEnabled:YES];
        [_ssoTokenField setEnabled:NO];
    }
    
}
-(IBAction)clickPremeeting:(id)sender
{
    [self switchToPreMeetingTab];
    ZoomSDKPremeetingService *premeetingService = [[ZoomSDK sharedSDK] getPremeetingService];
    premeetingService.delegate = self;
    ZoomSDKDirectShareHelper* helper = [premeetingService getDirectShareHelper];
    helper.delegate = self;
}

-(IBAction)clickMainWindow:(id)sender
{
    [self switchToMainWindowTab];
}

-(IBAction)clickH323:(id)sender
{
    [self switchToH323Tab];
}
-(IBAction)clickModifyParticipants:(id)sender
{
    [_tabView selectTabViewItemWithIdentifier:@"Participants"];
}

-(IBAction)clickMultiShare:(id)sender
{
     [_tabView selectTabViewItemWithIdentifier:@"MultiShare"];
}

-(IBAction)clickWaitingRoom:(id)sender
{
    [_tabView selectTabViewItemWithIdentifier:@"WaitingRoom"];
}

-(IBAction)clickPhoneCallout:(id)sender
{
     [_tabView selectTabViewItemWithIdentifier:@"Callout"];
}

-(IBAction)clickVideoContainer:(id)sender
{
     [_tabView selectTabViewItemWithIdentifier:@"VideoContainer"];
}

-(IBAction)onBackClicked:(id)sender
{
    [self switchToMeetingTab];
}

-(IBAction)onBackToUserClicked:(id)sender
{
    [self switchToUserTab];
    [_authResultField setHidden:YES];
}

-(IBAction)onBackToLoginClicked:(id)sender
{
    [self switchToZoomUserTab];
}


-(IBAction)logout:(id)sender
{
    ZoomSDKAuthService* authService = [[ZoomSDK sharedSDK] getAuthService];
    [authService logout];
}

- (void) switchToWelcomeTab
{
    [_tabView selectTabViewItemWithIdentifier:@"Welcome"];
    [_indicator stopAnimation:nil];
}

- (void) switchToUserTab
{
     [_tabView selectTabViewItemWithIdentifier:@"User"];
    [_indicator stopAnimation:nil];
}
- (void) switchToZoomUserTab
{
     [_loginErrorField setHidden:YES];
     [_tabView selectTabViewItemWithIdentifier:@"Login"];
    
}
- (void) switchToMeetingTab
{
    [_tabView selectTabViewItemWithIdentifier:@"Meeting"];
    [_indicator stopAnimation:nil];
}

- (void)switchToMainWindowTab
{
    [_tabView selectTabViewItemWithIdentifier:@"MainWindow"];
}

- (void)switchToH323Tab
{
    [_tabView selectTabViewItemWithIdentifier:@"H323"];
}

- (void) switchToConnectingTab
{
    [_tabView selectTabViewItemWithIdentifier:@"Connecting"];
    [_indicator startAnimation:nil];
}

- (void) switchToShareTab
{
    [_tabView selectTabViewItemWithIdentifier:@"Share"];
}

- (void) switchToChatTab
{
    [_tabView selectTabViewItemWithIdentifier:@"Chat"];
}

- (void) switchToRecordTab
{
    [_tabView selectTabViewItemWithIdentifier:@"Record"];
}

- (void) switchToPreMeetingTab
{
    [_tabView selectTabViewItemWithIdentifier:@"Premeeting"];
}



-(IBAction)startMeeting:(id)sender
{
    //Test customized UI
    [_wndCtrl.window makeKeyAndOrderFront:nil];
    [self drawPreviewVideoView];
    ZoomSDKAuthService* authService = [[ZoomSDK sharedSDK] getAuthService];
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingConfiguration* config = [meetingService getMeetingConfiguration];
   // config.floatVideoPoint =  NSMakePoint(300, 300);
    config.mainToolBarVisible = YES;
    config.mainVideoPoint = NSMakePoint(500, 500);
    ZoomSDKError ret = ZoomSDKError_UnKnow;
    config.enableChime = YES;
    config.enableMuteOnEntry = YES;
    config.disableDoubleClickToFullScreen = YES;
    config.disableRenameInMeeting = YES;
    config.hideFullPhoneNumber4PureCallinUser = YES;
  //  config.hideLeaveMeetingWindow = YES;
    [config hideSDKButtons:NO ButtonType:FitBarNewShareButton];
    [config hideSDKButtons:NO ButtonType:ToolBarInviteButton];
    [config modifyWindowTitle:YES NewMeetingNum:0];
    config.disableEndOtherMeetingAlert = YES;
    ZoomSDKGeneralSetting* setting = [[[ZoomSDK sharedSDK] getSettingService] getGeneralSetting];
    if(setting)
    {
    [setting enableMeetingSetting:NO SettingCmd:MeetingSettingCmd_AutoFitToWindowWhenViewShare];
    [setting enableMeetingSetting:NO SettingCmd:MeetingSettingCmd_AutoFullScreenWhenJoinMeeting];
    [setting enableMeetingSetting:YES SettingCmd:MeetingSettingCmd_DualScreenMode];
    [setting setCustomInviteURL:@"Hello TOTTI"];
        //[setting hideSettingComponent:SettingComponent_AdvancedFeatureButton hide:YES];
        //[setting hideSettingComponent:SettingComponent_AdvancedFeatureTab hide:YES];
    }
    if(meetingService)
    {
         if ([authService isAuthorized])
         {
              meetingService.delegate = self;
             //action controller delegate
             ZoomSDKMeetingActionController* actionCtr = [meetingService getMeetingActionController];
             actionCtr.delegate = self;
             //waiting room delegate
             ZoomSDKWaitingRoomController* waitController = [meetingService getWaitingRoomController];
             waitController.delegate = self;
             //ui controller
             ZoomSDKMeetingUIController* uiController = [meetingService getMeetingUIController];
             uiController.delegate = self;
             if (_hasLogined) {
                 //for zoom user
                 ret = [meetingService startMeeting:ZoomSDKUserType_ZoomUser userID:nil userToken:nil displayName:nil meetingNumber:[_startMeetingNum stringValue]  isDirectShare:NO sharedApp:0 isVideoOff:NO isAuidoOff:NO vanityID:nil];
             }else{
                 //for api user
                 ret =[meetingService startMeeting:ZoomSDKUserType_APIUser userID:[_sdkUserID stringValue] userToken:[_sdkUserToken stringValue] displayName:[_startUserName stringValue] meetingNumber:[_startMeetingNum stringValue] isDirectShare:NO sharedApp:0 isVideoOff:NO isAuidoOff:NO vanityID:@"francescototti"];
                 //test for zak
               /*  NSString* token = @"gUKmv5ONRs-76qlrwtmDbtqWoLQ7G__PgUvNnv5dsrc.BgQgQTYyYzlZdldJWkdabDc3dHdQeVpEVnI0VXhCVUQzdkpANmRiOTIyOTVjNDk3YzQ0NzM3NDNmZjBkZGU0M2YwMGRkNGVmNjg4YmU2NTk2ZDRkNTNlZDlkMjRjZWRmNTVmMQAMM0NCQXVvaVlTM3M9AA";
                 NSString* zak = @"eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjbGllbnQiLCJ1aWQiOiJvSDA5WWg5eVNrZTlULVFJc1FaRmNBIiwiaXNzIjoid2ViIiwic3R5IjoxMDAsImNsdCI6MCwic3RrIjoiZ1VLbXY1T05Scy03NnFscnd0bURidHFXb0xRN0dfX1BnVXZObnY1ZHNyYy5CZ1FnUVRZeVl6bFpkbGRKV2tkYWJEYzNkSGRRZVZwRVZuSTBWWGhDVlVRemRrcEFObVJpT1RJeU9UVmpORGszWXpRME56TTNORE5tWmpCa1pHVTBNMll3TUdSa05HVm1Oamc0WW1VMk5UazJaRFJrTlRObFpEbGtNalJqWldSbU5UVm1NUUFNTTBOQ1FYVnZhVmxUTTNNOUFBIiwiZXhwIjoxNTI3MDY4MDM2LCJpYXQiOjE1MjcwNjc3MzYsImFpZCI6IjF0VDFmT3VEVEIySWhaV3BjazM5cVEiLCJjaWQiOiIifQ.ZI0KMZBFF-6xMj9Rt_-E4xz-Jj7ouHmmrJCFTQ5YqLs";
                 
                 NSString* userid = @"oH09Yh9ySke9T-QIsQZFcA";
                 ret =[meetingService startMeetingWithZAK:zak userType:SDKUserType_EmailLogin userID:userid  userToken:token displayName:[_startUserName stringValue] meetingNumber:[_startMeetingNum stringValue] isDirectShare:NO sharedApp:0 isVideoOff:0 isAuidoOff:NO vanityID:nil];*/
             }
         }
         NSLog(@"startMeeting ret:%d", ret);
    }
}

-(IBAction)joinMeeting:(id)sender
{
    ZoomSDKAuthService* authService = [[ZoomSDK sharedSDK] getAuthService];
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingConfiguration* config = [meetingService getMeetingConfiguration];
    config.floatVideoPoint =  NSMakePoint(300, 300);
    config.mainToolBarVisible = NO;
    config.mainVideoPoint = NSMakePoint(500, 500);
    config.enableChime = YES;
    config.enableMuteOnEntry = YES;
    config.disablePopupWrongPasswordWindow = YES;
    config.disableDoubleClickToFullScreen = YES;
    config.jbhWindowVisible = YES;
    config.hideFullPhoneNumber4PureCallinUser = YES;
    ZoomSDKError ret = ZoomSDKError_UnKnow;
    if(meetingService)
    {
        if ([authService isAuthorized])
        {   meetingService.delegate = self;
            if (_hasLogined) {
                 ret =[meetingService joinMeeting:ZoomSDKUserType_ZoomUser toke4enfrocelogin:nil webinarToken:nil  participantId:@"10" meetingNumber:[_joinMeetingNum stringValue] displayName:[_joinUserName stringValue] password:@"" isDirectShare:NO sharedApp:0 isVideoOff:NO isAuidoOff:NO vanityID:nil];
            }else{
                 ret =[meetingService joinMeeting:ZoomSDKUserType_APIUser toke4enfrocelogin:nil webinarToken:nil  participantId:@"10" meetingNumber:[_joinMeetingNum stringValue]  displayName:[_joinUserName stringValue] password:@"" isDirectShare:NO sharedApp:0 isVideoOff:NO isAuidoOff:NO vanityID:nil];
            }
           
        }
        NSLog(@"joinMeeting ret:%d", ret);
    }
}

-(IBAction)joinWebinar:(id)sender
{
    ZoomSDKAuthService* authService = [[ZoomSDK sharedSDK] getAuthService];
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingConfiguration* config = [meetingService getMeetingConfiguration];
    config.floatVideoPoint =  NSMakePoint(300, 300);
    config.mainToolBarVisible = NO;
    config.mainVideoPoint = NSMakePoint(500, 500);
    config.enableChime = YES;
    config.enableMuteOnEntry = YES;
    config.disablePopupWrongPasswordWindow = YES;
    config.disableDoubleClickToFullScreen = YES;
    config.needPrefillWebinarJoinInfo = NO;
    //[config prefillWebinarUserName:[_joinUserName stringValue] Email:@"t@t.com"];
    ZoomSDKError ret = ZoomSDKError_UnKnow;
    if(meetingService)
    {
        if ([authService isAuthorized])
        {
            if (_hasLogined) {
                ret =[meetingService joinMeeting:ZoomSDKUserType_ZoomUser toke4enfrocelogin:nil webinarToken:nil  participantId:@"10" meetingNumber:[_joinMeetingNum stringValue] displayName:[_joinUserName stringValue] password:@"" isDirectShare:NO sharedApp:0 isVideoOff:NO isAuidoOff:NO vanityID:nil];
            }else{
                ret =[meetingService joinMeeting:ZoomSDKUserType_APIUser toke4enfrocelogin:nil webinarToken:nil  participantId:@"10" meetingNumber:[_joinMeetingNum stringValue]  displayName:[_joinUserName stringValue] password:@"" isDirectShare:NO sharedApp:0 isVideoOff:NO isAuidoOff:NO vanityID:nil];
            }
            
        }
        NSLog(@"joinMeeting ret:%d", ret);
    }
}


-(IBAction)endMeeting:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [meetingService leaveMeetingWithCmd:(LeaveMeetingCmd_End)];
}

-(IBAction)showChatDlg:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller showMeetingComponent:MeetingComponent_Chat window:nil show:YES InPanel:NO frame:NSMakeRect(500, 500, 0, 0)];
}


-(IBAction)showChatDlgInPanel:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller showMeetingComponent:MeetingComponent_Chat window:nil show:YES InPanel:YES frame:NSZeroRect];
}
-(IBAction)hideChatDlg:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller showMeetingComponent:MeetingComponent_Chat window:nil show:NO InPanel:NO frame:NSZeroRect];
}

-(IBAction)showParticipantsDlg:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller showMeetingComponent:MeetingComponent_Participants window:nil show:YES InPanel:NO frame:NSMakeRect(500, 500, 0, 0)];
}


-(IBAction)showParticipantsDlgInPanel:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller showMeetingComponent:MeetingComponent_Participants window:nil show:YES InPanel:YES frame:NSZeroRect];
}
-(IBAction)hideParticipantsDlg:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller showMeetingComponent:MeetingComponent_Participants window:nil show:NO InPanel:NO frame:NSZeroRect];
}

-(IBAction)showAudioDlg:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_MuteAudio userID:0 onScreen:ScreenType_First];
  //  ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
  //  [controller showMeetingComponent:MeetingComponent_Audio window:nil show:YES InPanel:NO frame:NSMakeRect(650, 650, 0, 0)];
}

-(IBAction)hideAudioDlg:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
     [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_UnMuteAudio userID:0 onScreen:ScreenType_First];
   // ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
  //  [controller showMeetingComponent:MeetingComponent_Audio window:nil show:NO InPanel:NO frame:NSZeroRect];
}

-(IBAction)showConfToolbar:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller showMeetingComponent:MeetingComponent_MainToolBar window:nil show:YES InPanel:NO frame:NSZeroRect];
}
-(IBAction)hideConfToolbar:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller showMeetingComponent:MeetingComponent_MainToolBar window:nil show:NO InPanel:NO frame:NSZeroRect];
}

-(IBAction)switchMiniVideoMode:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    BOOL isInMiniMode = [controller isInMiniVideoMode];
    if(isInMiniMode)
    {
        [controller switchMiniVideoModeUI];
    }
}

-(IBAction)showFitToolBar:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    //[[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_MuteVideo userID:0 onScreen:ScreenType_First];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    if ([_shareOnSecondScreenButton state] == NSOnState) {
         [controller showMeetingComponent:MeetingComponent_AuxShareToolBar window:nil show:YES InPanel:NO frame:NSZeroRect];
    }else{
         [controller showMeetingComponent:MeetingComponent_MainShareToolBar window:nil show:YES InPanel:NO frame:NSZeroRect];
    }
   
}
-(IBAction)hideFitToolBar:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
  //  [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_UnMuteVideo userID:0 onScreen:ScreenType_First];
   ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    if ([_shareOnSecondScreenButton state] == NSOnState) {
        [controller showMeetingComponent:MeetingComponent_AuxShareToolBar window:nil show:NO InPanel:NO frame:NSZeroRect];
    }else{
        [controller showMeetingComponent:MeetingComponent_MainShareToolBar window:nil show:NO InPanel:NO frame:NSZeroRect];
    }
    
}

-(IBAction)showThumbnailVideo:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getMeetingUIController] showMeetingComponent:MeetingComponent_ThumbnailVideo window:nil show:YES InPanel:NO frame:NSZeroRect];
}
-(IBAction)hideThumbnailVideo:(id)sender{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getMeetingUIController] showMeetingComponent:MeetingComponent_ThumbnailVideo window:nil show:NO InPanel:NO frame:NSZeroRect];
}
-(IBAction)requestRemoteControl:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
  //  [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_RequestRemoteControl userID:0 onScreen:_screenType];
    ZoomSDKRemoteControllerHelper* rchelper = [[meetingService getASController] getRemoteControllerHelper];
    NSLog(@"Request remote control userid:%u", _userID);
    [rchelper requestRemoteControl:_userID];
    

}

-(IBAction)giveupRemoteControl:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_GiveUpRemoteControl userID:0 onScreen:_screenType];
    ZoomSDKASController* asController = [meetingService getASController];
    unsigned int userID;
   [asController getCurrentRemoteController:&userID];
    NSLog(@"Remote control ID:%d",userID);
}

-(IBAction)revokeRemoteControl:(id)sender
{
     ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_RevokeRemoteControl userID:_userID onScreen:_screenType];
}

-(IBAction)declineRemoteControl:(id)sender
{
    //test to grab remote control
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    //  [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_RequestRemoteControl userID:0 onScreen:_screenType];
    ZoomSDKRemoteControllerHelper* rchelper = [[meetingService getASController] getRemoteControllerHelper];
    [rchelper startRemoteControl:_userID];
    /*
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_DeclineRemoteControlRequest userID:_userID onScreen:_screenType];
     */
}

-(IBAction)giveRemoteControlTo:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_GiveRemoteControlTo userID:_userID onScreen:_screenType];
}

-(IBAction)getScreenID:(id)sender
{
    NSString* info = [self getScreenDisplayID];
    _shareStatusMsgView.string = info;
}

-(IBAction)lockShare:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_LockShare userID:0 onScreen:ScreenType_First];
}

-(IBAction)enterShareFitWindowMode:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_ShareFitWindowMode userID:0 onScreen:_screenType];
}

-(IBAction)minimizeFloatWnd:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller minimizeShareFloatVideoWindow:YES];

}

-(IBAction)maxFloatWnd:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller minimizeShareFloatVideoWindow:NO];
}

-(IBAction)swithFloatWndToActiveSpk:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller switchFloatVideoToActiveSpeakerMode];
}

-(IBAction)swithFloatWndToGallery:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller switchFloatVideoToGalleryMode];
}


-(IBAction)sendHello:(id)sender;
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    
    NSString* sendContent = [[_sendMsgContent stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([sendContent length] != 0) {
        NSArray* userlist = [[meetingService getMeetingActionController] getParticipantsList];
        for (NSNumber*user in userlist) {
            NSLog(@"ATTEND USERID:%d", [user unsignedIntValue]);
            ZoomSDKUserInfo* userInfo = [[meetingService getMeetingActionController] getUserByUserID:[user unsignedIntValue]];
            if (![userInfo isHost]) {
                ZoomSDKError result = [[meetingService getMeetingActionController] sendChat:sendContent toUser:[user unsignedIntValue]];
                NSLog(@"send chat result:%d", result);
            }
        }
    }
    [_sendMsgContent setStringValue:@""];
}

-(IBAction)startRecording:(id)sender
{
     [_recordConvertFinishLabel setHidden:YES];
    _recordIndicator.doubleValue = 0.0f;
     ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    time_t starttimestamp;
    [[meetingService getRecordController] startRecording:&starttimestamp saveFilePath:@"/Users/totti/Documents/record"];
    NSLog(@"record start time, %ld", starttimestamp);
    [[meetingService getRecordController] requestCustomizedLocalRecordingNotification:YES];
}
-(IBAction)stopRecording:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    time_t stoptimestamp;
    [[meetingService getRecordController] stopRecording:&stoptimestamp];
    NSLog(@"record stop time, %ld", stoptimestamp);
}

-(IBAction)startAnnotation:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    //BOOL annotateSelf =[_annotationSelf state] == NSOnState? YES: NO;
    [asController startAnnotation: NSMakePoint(1000, 500) onScreen:_screenType];
    // [meetingService startAnnotation:NSMakePoint(800, 500) onScreen:ScreenType_First];
    ZoomSDKAnnotationController* controller = [asController getAnnotationController];
    [controller setColor:0.8f Green:0.8f Black:0.8f onScreen:_screenType];
    [controller setLineWidth: 5 onScreen:_screenType];
    
}

-(IBAction)stopAnnotation:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    // BOOL annotateSelf =[_annotationSelf state] == NSOnState? YES: NO;
    ZoomSDKASController* asController = [meetingService getASController];
    [asController stopAnnotation:_screenType];
}


-(IBAction)showNoVideoUserOnWall:(id)sender
{
    
   ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
   
    ZoomSDKMeetingActionController* ctrl = [meetingService getMeetingActionController];
     [ctrl actionMeetingWithCmd:ActionMeetingCmd_UnMuteVideo userID:0 onScreen:ScreenType_First];
  /*  NSString* string = _selectedUserID.stringValue;
    NSNumberFormatter *f = [[[NSNumberFormatter alloc] init] autorelease];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *myNumber = [f numberFromString:string];

    [ctrl actionMeetingWithCmd:ActionMeetingCmd_UnMuteVideo userID:[myNumber unsignedIntValue] onScreen:ScreenType_First];
    ZoomSDKUserInfo* userInfo = [[[[ZoomSDK sharedSDK] getMeetingService] getMeetingActionController] getUserByUserID:16778240];
    if(!userInfo)
        return;
    NSRect videoFrame =NSZeroRect;
    if([userInfo isMySelf])
    {
        videoFrame = NSMakeRect(0, 0, 160, 90);
    }else{
        videoFrame = NSMakeRect(200, 200, 160, 90);
    }
    ZoomSDKVideoElement* newUserVideo = [[ZoomSDKVideoElement alloc] initWithUserID:16778240 Frame:videoFrame];
    [_container createVideoElement:&newUserVideo];
    [newUserVideo showVideo:YES];
    [_container setNeedsDisplay:YES];
    [_wndCtrl showWindow:nil];*/
    // ZoomSDKMeetingUIController* uiController = [meetingService getMeetingUIController];
   // [uiController hideOrShowNoVideoUserOnVideoWall:NO];
}

-(IBAction)hideNoVideoUserOnWall:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    
    ZoomSDKMeetingActionController* ctrl = [meetingService getMeetingActionController];
    [ctrl actionMeetingWithCmd:ActionMeetingCmd_MuteVideo userID:0 onScreen:ScreenType_First];
    /*
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* uiController = [meetingService getMeetingUIController];
    [uiController hideOrShowNoVideoUserOnVideoWall:YES];*/
}


-(IBAction)startShare:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    [asController startMonitorShare:[[_selectedScreenField stringValue] intValue]];
  /*  NSNumberFormatter* f = [[[NSNumberFormatter alloc] init] autorelease];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber* number =[f numberFromString:[_selectedScreenField stringValue]];
   [meetingService startMonitorShare:[number unsignedIntValue]];*/
}

-(IBAction)setEraser:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    ZoomSDKAnnotationController* annotation = [asController getAnnotationController];
    [annotation setTool:AnnotationToolType_ERASER onScreen:_screenType];
}

-(IBAction)setPen:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    ZoomSDKAnnotationController* annotation = [asController getAnnotationController];
    [annotation setTool:AnnotationToolType_Pen onScreen:_screenType];
}
-(IBAction)setNone:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    ZoomSDKAnnotationController* annotation = [asController getAnnotationController];
    [annotation setTool:AnnotationToolType_None onScreen:_screenType];
}

-(IBAction)clearAll:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    ZoomSDKAnnotationController* annotation = [asController getAnnotationController];
    [annotation clear:AnnotationClearType_All onScreen:_screenType];
}
-(IBAction)clearMine:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    ZoomSDKAnnotationController* annotation = [asController getAnnotationController];
    [annotation clear:AnnotationClearType_Self onScreen:_screenType];
}
-(IBAction)redo:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    ZoomSDKAnnotationController* annotation = [asController getAnnotationController];
    [annotation redo:_screenType];
}
-(IBAction)undo:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    ZoomSDKAnnotationController* annotation = [asController getAnnotationController];
    [annotation undo:_screenType];
}

-(IBAction)switchToActiveSpkView:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* UIController = [meetingService getMeetingUIController];
    [UIController switchToActiveSpeakerView];

}
-(IBAction)switchToWallView:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* UIController = [meetingService getMeetingUIController];
    [UIController switchToVideoWallView];
}


-(IBAction)enableMuteOnEntry:(id)sender
{
    ZoomSDKSettingService* settingService = [[ZoomSDK sharedSDK] getSettingService];
    [[settingService getGeneralSetting] enableMeetingSetting:YES SettingCmd:MeetingSettingCmd_EnableMuteOnEntry];
}

-(IBAction)hideSettingDlg:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* uiController = [meetingService getMeetingUIController];
    [uiController showMeetingComponent:MeetingComponent_Setting window:nil show:NO InPanel:NO frame:NSZeroRect];
}


- (void)authSDK:(NSString*)key appSecret:(NSString*)secret
{
    ZoomSDKAuthService *authService = [[ZoomSDK sharedSDK] getAuthService];
    if (authService)
    {
        authService.delegate = self;
        [authService sdkAuth:key appSecret:secret];
    }
}

#pragma auth delegate
- (void)onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue
{
    NSLog(@"onZoomSDKAuthReturn %d", returnValue);
    [self initService];
    if(returnValue == ZoomSDKAuthError_Success)
    {
        ZoomSDKSettingService* setService = [[ZoomSDK sharedSDK] getSettingService];
        [[setService getRecordSetting] setRecordingPath:@"/Users/totti/Documents/record"];
        [_authResultField setHidden:NO];
        [_authResultField setTextColor:[NSColor blueColor]];
        [_authResultField setStringValue:@"Auth SDK Success!"];
        [self switchToUserTab];
        ZoomSDKOutlookPluginHelper* outlookhelper = [[[ZoomSDK sharedSDK]getPremeetingService] getOutlookPluginHelper];
        outlookhelper.delegate = self;
        [outlookhelper start:@"ZoomVideoClientToZoomOutlookPlugin_RINGCENTRAL" IPCNoti:@"ZoomOutlookPluginToZoomVideoClient_RINGCENTRAL" AppName:@"RingCentral Meetings" AppIdentity:@"zoom.us.ringcentral"];
        ZoomSDKMeetingConfiguration* config = [[[ZoomSDK sharedSDK]getMeetingService] getMeetingConfiguration];
        // config.floatVideoPoint =  NSMakePoint(300, 300);
        config.mainToolBarVisible = NO;
        config.mainVideoPoint = NSMakePoint(500, 500);
        config.enableChime = YES;
        config.enableMuteOnEntry = YES;
        config.disableDoubleClickToFullScreen = YES;
        config.disableRenameInMeeting = YES;
        config.hideFullPhoneNumber4PureCallinUser = YES;
        //  config.hideLeaveMeetingWindow = YES;
        [config hideSDKButtons:YES ButtonType:FitBarNewShareButton];
        [config hideSDKButtons:YES ButtonType:ToolBarInviteButton];
        [config modifyWindowTitle:YES NewMeetingNum:0];
        config.disableEndOtherMeetingAlert = YES;
        [_settingMenuItem setHidden:NO];
    }else{
        [self switchToWelcomeTab];
        [_authResultFieldWelcome setHidden:NO];
        [_authResultFieldWelcome setStringValue:[NSString stringWithFormat:@"Auth Faild, Error:%d", returnValue]];
    }

    
}
-(void)drawPreviewVideoView //when start meeting call drawPreviewVideoView, join meeting don't
{
    previewElement = [[ZoomSDKPreViewVideoElement alloc] initWithFrame:NSMakeRect(0, 0, 320, 240)];
    ZoomSDKVideoContainer* videoContainer = [[[ZoomSDK sharedSDK] getMeetingService] getVideoContainer];
    [videoContainer createVideoElement:&previewElement];
    [_wndCtrl.window.contentView addSubview:[previewElement getVideoView] positioned:NSWindowAbove relativeTo:nil];
}
-(void)drawUsersVideoView
{
    newUserVideo1 = [[ZoomSDKNormalVideoElement alloc] initWithFrame:NSMakeRect(0, 0, 320, 240)];
    newUserVideo2 = [[ZoomSDKNormalVideoElement alloc] initWithFrame:NSMakeRect(0, 240, 320, 240)];
    newUserVideo3 = [[ZoomSDKNormalVideoElement alloc] initWithFrame:NSMakeRect(0, 480, 320, 240)];
    activeUserVideo = [[ZoomSDKActiveVideoElement alloc] initWithFrame:NSMakeRect(320,0,960,720)];
    
    ZoomSDKVideoContainer* videoContainer = [[[ZoomSDK sharedSDK] getMeetingService] getVideoContainer];
    [videoContainer createVideoElement:&newUserVideo1];
    [videoContainer createVideoElement:&newUserVideo2];
    [videoContainer createVideoElement:&newUserVideo3];
   // [videoContainer createVideoElement:&activeUserVideo];
    [_wndCtrl.window.contentView addSubview:[newUserVideo1 getVideoView]];
    [_wndCtrl.window.contentView addSubview:[newUserVideo2 getVideoView]];
    [_wndCtrl.window.contentView addSubview:[newUserVideo3 getVideoView]];
   //[_wndCtrl.window.contentView addSubview:[activeUserVideo getVideoView]];
    [_wndCtrl showWindow:nil];
}

- (void)onZoomSDKLogin:(ZoomSDKLoginStatus)loginStatus failReason:(NSString *)reason
{
    switch (loginStatus) {
        case ZoomSDKLoginStatus_Processing:
            [_connectLabel setStringValue:@"Start Logining..."];
            [self switchToConnectingTab];
            break;
        case ZoomSDKLoginStatus_Success:
        {
            ZoomSDKPremeetingService* premeeting = [[ZoomSDK sharedSDK] getPremeetingService];
            premeeting.delegate = self;
            [_preMeetingButton setEnabled:YES];
            [_logoutButton setEnabled:YES];
            [self switchToMeetingTab];
            _hasLogined = YES;
        }
            break;
        case ZoomSDKLoginStatus_Failed:
        {
            [self switchToZoomUserTab];
            [_loginErrorField setHidden:NO];
            if ([_authResultField isHidden]) {
                [_loginErrorField setStringValue:@"Login Failed!"];
            }else{
                [_loginErrorField setStringValue:@"Auto Login Failed!"];
            }
        }
            break;
        default:
            break;
    }
}

- (void)onRemoteControlStatus:(ZoomSDKRemoteControlStatus)status User:(unsigned int)userID
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    if (!meetingService) {
        return;
    }
    NSString* info = @"";
    switch (status) {
        case ZoomSDKRemoteControlStatus_RequestFromWho:
        {
            info = [NSString stringWithFormat:@"User:%d is request Remote Control Now!", userID];
               [_revokeRemoteControl setEnabled:YES];
               [_declineRemoteControl setEnabled:YES];
      //      _userID = userID;
        }
           break;
        case ZoomSDKRemoteControlStatus_CanRequestFromWho:
        {
            info = [NSString stringWithFormat:@" Can Request Remote control Privilege from ID:%d", userID];
            _userID = userID;
        }
            break;
        case ZoomSDKRemoteControlStatus_DeclineByWho:
        {
            info = [NSString stringWithFormat:@" Your Remote control Request Privilege Declined by ID:%d", userID];
        }
            break;
        case ZoomSDKRemoteControlStatus_RemoteControlledByWho:
        {
            info = [NSString stringWithFormat:@" You are now controlled by ID:%d", userID];
        }
            break;
        case ZoomSDKRemoteControlStatus_StartRemoteControllWho:
        {
            info = [NSString stringWithFormat:@"Now U are controlling %d's Screen", userID];
        }
            break;
        case ZoomSDKRemoteControlStatus_EndRemoteControllWho:
        {
            info = [NSString stringWithFormat:@"Now U are not controlling %d's Screen", userID];
        }
            break;
        case ZoomSDKRemoteControlStatus_HasPrivilegeFromWho:
        {
            info = [NSString stringWithFormat:@"Now U has remote controll privilege of %d's Screen", userID];
        }
           break;
         case ZoomSDKRemoteControlStatus_LostPrivilegeFromWho:
        {
             info = [NSString stringWithFormat:@"Now U lost remote controll privilege of %d's Screen", userID];
        }
            break;
        default:
            break;
    }
    [_remoteControlMsgField setStringValue:info];
}


#pragma meetingservice delegate

- (void)onMeetingStatusChange:(ZoomSDKMeetingStatus)state meetingError:(ZoomSDKMeetingError)error EndReason:(EndMeetingReason)reason
{
    NSLog(@"MeetingStatus change %d", state);
    ZoomSDKVideoContainer* videoContainer = [[[ZoomSDK sharedSDK] getMeetingService] getVideoContainer];
    ZoomSDKShareContainer* shareContainer = [[[[ZoomSDK sharedSDK] getMeetingService] getASController] getShareContainer];
    switch (state) {
        case ZoomSDKMeetingStatus_Connecting:
        {
            //test new sdk preview
            /*[videoContainer createVideoElement:&previewElement];
            [_wndCtrl.window.contentView addSubview:[previewElement getVideoView] positioned:NSWindowAbove relativeTo:nil];*/
            if(previewElement)
                [previewElement startPreview:YES];
            [self drawUsersVideoView];
           // [_wndCtrl.window.contentView setNeedsDisplay:YES];
        }
            break;
        case ZoomSDKMeetingStatus_InMeeting:
        {
            //test new sdk preview stop
            if(previewElement)
            {
                [previewElement startPreview:NO];
                [videoContainer cleanVideoElement:previewElement];
                NSView* videoview = [previewElement getVideoView];
                [videoview removeFromSuperview];
                [previewElement release];
                previewElement = nil;
            }
            //need do sdk here
            ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
            if (!meetingService) {
                return;
            }
            
            [_chatButton setEnabled:YES];
            [_recordButton setEnabled:YES];
            [_shareButton setEnabled:YES];
            [_mainWindowButton setEnabled:YES];
            [_endMeeting setEnabled:YES];
            [_H323Button setEnabled:YES];
            [_waitingRoomButton setEnabled:YES];
            [_calloutButton setEnabled:YES];
            [_videoContainerButton setEnabled:YES];
            [_participantsButton setEnabled:YES];
            [_multiShareButton setEnabled:YES];
            [_WebinarControlButton setEnabled:YES];
            //[meetingService actionMeetingWithCmd:ActionMeetingCmd_MuteVideo userID:0];
             //move main video
             ZoomSDKMeetingUIController* UIController = [meetingService getMeetingUIController];
             if (!UIController) {
             return;
             }
            //test for setting camera list
            ZoomSDKSettingService* settingService = [[ZoomSDK sharedSDK] getSettingService];
            [[settingService getVideoSetting] enableBeautyFace:YES];
            if(![[settingService getVideoSetting] isMirrorEffectEnabled])
                [[settingService getVideoSetting] enableMirrorEffect:YES];
            NSArray* array =  [[settingService getVideoSetting] getCameraList];
            for(SDKDeviceInfo* info in array)
            {
                NSLog(@"App delegate camera list, deviceID:%@, deviceName:%@, isSelected:%d", [info getDeviceID], [info getDeviceName], [info isSelectedDevice]);
            }
            //h323 delegate
            ZoomSDKH323Helper* h323Helper = [meetingService getH323Helper];
            h323Helper.delegate = self;
            //Phone Helper
            ZoomSDKPhoneHelper* phoneHelper = [meetingService getPhoneHelper];
            phoneHelper.delegate = self;
            ZoomSDKASController* asController = [meetingService getASController];
            asController.delegate = self;
            ZoomSDKCustomizedAnnotationCtr* customizedAnnoCtr = [asController getCustomizedAnnotationCtr];
            customizedAnnoCtr.delegate = self;
            ZoomSDKRemoteControllerHelper* rchelper = [[meetingService getASController] getRemoteControllerHelper];
            rchelper.delegate = self;
            ZoomSDKMeetingRecordController* recordCtrl = [meetingService getRecordController];
            recordCtrl.delegate =self;
            [self updateWebinarUI];
        }
            break;
        case ZoomSDKMeetingStatus_Webinar_Promote:
        {
            NSLog(@"my role is changed to panelist!");
            if([_sdkSettingWindowController.window isVisible])
                [_sdkSettingWindowController close];
        }
            break;
        case ZoomSDKMeetingStatus_Webinar_Depromote:
        {
            NSLog(@"my role is changed to attendee!");
            if([_sdkSettingWindowController.window isVisible])
                [_sdkSettingWindowController close];
        }
            break;

        case ZoomSDKMeetingStatus_AudioReady:
        {
         
        }
            break;
        case ZoomSDKMeetingStatus_Failed:
        {
            if (error == ZoomSDKMeetingError_PasswordError) {
                NSLog(@"Password is Wrong!");
            }
        }
            break;
        case ZoomSDKMeetingStatus_Ended:
        {
            
           if(newUserVideo1)
            {
                [videoContainer cleanVideoElement:newUserVideo1];
                NSView* videoview = [newUserVideo1 getVideoView];
                [videoview removeFromSuperview];
                [newUserVideo1 release];
                newUserVideo1 = nil;
            }
            if(newUserVideo2)
            {
                [videoContainer cleanVideoElement:newUserVideo2];
                NSView* videoview = [newUserVideo2 getVideoView];
                [videoview removeFromSuperview];
                [newUserVideo2 release];
                newUserVideo2 = nil;
            }
            if(newUserVideo3)
            {
                [videoContainer cleanVideoElement:newUserVideo3];
                NSView* videoview = [newUserVideo3 getVideoView];
                [videoview removeFromSuperview];
                [newUserVideo3 release];
                newUserVideo3 = nil;
            }
            if(activeUserVideo)
            {
                [videoContainer cleanVideoElement:activeUserVideo];
                NSView* videoview = [activeUserVideo getVideoView];
                [videoview removeFromSuperview];
                [activeUserVideo release];
                activeUserVideo = nil;
            }
            
            [_wndCtrl.window orderOut:nil];
            
            if (_shareElement) {
                NSView* shareView = [_shareElement shareView];
                [shareView removeFromSuperview];
                [shareContainer cleanShareElement:_shareElement];
                [_shareCtrl.window orderOut:nil];
                [_shareElement release];
                _shareElement = nil;
            }
            [_shareCtrl.window orderOut:nil];
            switch (reason) {
                case EndMeetingReason_KickByHost:
                    NSLog(@"leave meeting kicked by host");
                    break;
                
                case EndMeetingReason_EndByHost:
                    NSLog(@"leave meeting end by host");
                    break;
                default:
                    break;
            }
            if([_sdkSettingWindowController.window isVisible])
                [_sdkSettingWindowController close];
            //[self joinMeeting:nil];
        }
        default:
        {
            [self switchToMeetingTab];
            [_chatButton setEnabled:NO];
            [_recordButton setEnabled:NO];
            [_shareButton setEnabled:NO];
            [_mainWindowButton setEnabled:NO];
            [_endMeeting setEnabled:NO];
            [_H323Button setEnabled:NO];
            [_waitingRoomButton setEnabled:NO];
            [_calloutButton setEnabled:NO];
            [_videoContainerButton setEnabled:NO];
            [_participantsButton setEnabled:NO];
            [_multiShareButton setEnabled:NO];
            [_WebinarControlButton setEnabled:NO];
        }
        break;
    }
}

- (void)onUserAudioStatusChange:(NSArray*)userAudioStatusArray
{
    NSString* userAudioString = @"";
    for (ZoomSDKUserAudioStauts* key in userAudioStatusArray) {
        unsigned int userID = [key getUserID];
        ZoomSDKAudioStatus status = [key getStatus];
        ZoomSDKAudioType type = [key getType];
        NSString* statuStr = @"";
        NSString* typeStr = @"";
        switch (status) {
            case ZoomSDKAudioStatus_None:
                statuStr = @"audio status none";
                break;
            case ZoomSDKAudioStatus_Muted:
                 statuStr = @"audio status muted by self";
                break;
            case ZoomSDKAudioStatus_UnMuted:
                statuStr = @"audio status unmuted by self";
                break;
            case ZoomSDKAudioStatus_UnMutedByHost:
                statuStr = @"audio status unmuted by host";
                break;
            case ZoomSDKAudioStatus_MutedByHost:
                statuStr = @"audio status muted by host";
                break;
            case ZoomSDKAudioStatus_MutedAllByHost:
                statuStr = @"audio status muted all by host";
                break;
            case ZoomSDKAudioStatus_UnMutedAllByHost:
                statuStr = @"audio status unmuted all by host";
                break;
            default:
                break;
        }
        switch (type) {
            case ZoomSDKAudioType_None:
                typeStr = @"audio type none";
                break;
            case ZoomSDKAudioType_Voip:
                typeStr = @"audio type computer audio";
                break;
            case ZoomSDKAudioType_Phone:
                typeStr = @"audio type phone";
                break;
            case ZoomSDKAudioType_Unknow:
                typeStr = @"audio type unknow";
                break;
            default:
                break;
        }
       NSLog(@"userID %d status:%d type:%d", userID, status, type);
       userAudioString = [userAudioString stringByAppendingString:[NSString stringWithFormat:@"user %d 's %@,%@ %C", userID, statuStr, typeStr,(unichar)NSParagraphSeparatorCharacter]];
    }
    _audioInfoView.string = userAudioString;
    _videoInfoView.string = userAudioString;
}

-(void)onWaitMeetingSessionKey:(NSData *)key
{
    NSLog(@"Huawei Session key:%@", key);
    ZoomSDKMeetingService* service = [[ZoomSDK sharedSDK] getMeetingService];
    NSString* testVideoSessionKey =@"abcdefghijkmnopr";
    ZoomSDKSecuritySessionKey* sessionkey = [[[ZoomSDKSecuritySessionKey alloc] init] autorelease];
    sessionkey.component = SecuritySessionComponet_Video;
    sessionkey.sessionKey = [NSData dataWithBytes:(const char*)testVideoSessionKey.UTF8String length:16];
    sessionkey.iv = nil;
    NSArray* array = [NSArray arrayWithObjects:sessionkey, nil];
    [service setSecuritySessionKey:array isLeaveMeeting:NO];
}

- (void)onUserJoin:(NSArray *)array{

    for (NSNumber* userid in array) {
        unsigned int user = [userid unsignedIntValue];
        ZoomSDKUserInfo* userInfo = [[[[ZoomSDK sharedSDK] getMeetingService] getMeetingActionController] getUserByUserID:user];
        NSLog(@"New user join, userid: %d, %@", user, [userInfo getUserName]);
    }
    [self updateWebinarUI];
}

- (void)onRecord2MP4Progressing:(int)percentage
{
    _recordIndicator.doubleValue = percentage;
}


-(void)onRecord2MP4Done:(BOOL)success Path:(NSString *)recordPath
{
    if (success) {
        [_recordConvertFinishLabel setHidden:NO];
        [_recordConvertFinishLabel setStringValue:[NSString stringWithFormat:@"Record Convert Success, File Path:%@", recordPath]];
    }
}

- (void)onChatMessageNotification:(ZoomSDKChatInfo *)chatInfo
{
    if (chatInfo) {
        NSString* sender = [chatInfo getSenderDisplayName];
        NSString* receiver = [chatInfo getReceiverDisplayName];
        NSString* content = [chatInfo getMsgContent];
        time_t sendtime = [chatInfo getTimeStamp];
        struct tm timeStruct;
        localtime_r(&sendtime, &timeStruct);
        char buffer[20];
        strftime(buffer, 20, "%d-%m-%Y %H:%M:%S", &timeStruct);
        NSString* sendTime = [NSString stringWithUTF8String:buffer];
        [_receivedMsgContent setStringValue:[NSString stringWithFormat:@"%@ send %@ to %@ at %@", sender, content, receiver, sendTime]];
        
    }
}

- (void)onZoomSDKLogout{
    [self switchToUserTab];
    [_preMeetingButton setEnabled:NO];
    [_logoutButton setEnabled:NO];
    _hasLogined = NO;
}

- (void)onNeedShowLeaveMeetingWindow{
    NSLog(@"Need draw leave meeting UI yourself!");
}
#pragma test share




-(IBAction)enterFullScreen:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
   ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller enterFullScreen:YES firstMonitor:YES DualMonitor:NO];
}
-(IBAction)exitFullScreen:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
    [controller enterFullScreen:NO firstMonitor:YES DualMonitor:NO];
}

//premeeting
-(IBAction)scheduleMeeting:(id)sender
{
    [_preMeetingError setHidden:YES];
    [_listMeetingError setHidden:YES];
    if (_scheduleEditWindow) {
        [_scheduleEditWindow release];
        _scheduleEditWindow = nil;
    }
    if ([_scheduleEditWindow.window isVisible]) {
        [_scheduleEditWindow close];
    }
    if (_scheduleEditWindow) {
        [_scheduleEditWindow release];
        _scheduleEditWindow = nil;
    }
    _scheduleEditWindow = [[ZoomSDKScheduleWindowCtr alloc] initWithUniqueID:0];
    [_scheduleEditWindow.window makeKeyAndOrderFront:nil];
   /* NSDate* now = [NSDate date];
    NSDate* startDate = [self getMeetingStartDateFromDate:now];
    time_t startTime  = (long)[startDate timeIntervalSince1970];
    ZoomSDKPremeetingService* premeetingService = [[ZoomSDK sharedSDK] getPremeetingService];
    ZoomSDKScheduleMeetingItem* scheduleItem = [[[ZoomSDKScheduleMeetingItem alloc]init] autorelease];
    */
    
}
-(IBAction)deleteMeeting:(id)sender
{
    [_preMeetingError setHidden:YES];
     [_listMeetingError setHidden:YES];
    ZoomSDKPremeetingService* premeetingService = [[ZoomSDK sharedSDK] getPremeetingService];
    [premeetingService deleteMeeting:[[_meetingNumber stringValue] longLongValue]];
}
-(IBAction)updateMeeting:(id)sender
{
    [_preMeetingError setHidden:YES];
    [_listMeetingError setHidden:YES];
    if ([_scheduleEditWindow.window isVisible]) {
        [_scheduleEditWindow close];
    }
    if (_scheduleEditWindow) {
        [_scheduleEditWindow release];
        _scheduleEditWindow = nil;
    }
    _scheduleEditWindow = [[ZoomSDKScheduleWindowCtr alloc] initWithUniqueID:_meetingNumber.stringValue.longLongValue];
    [_scheduleEditWindow.window makeKeyAndOrderFront:nil];
}
-(IBAction)listMeeting:(id)sender
{
    [_preMeetingError setHidden:YES];
     [_listMeetingError setHidden:YES];
     ZoomSDKPremeetingService* premeetingService = [[ZoomSDK sharedSDK] getPremeetingService];
    [premeetingService listMeeting];
}

-(IBAction)showScheduleWindow:(id)sender
{
     ZoomSDKPremeetingService* premeetingService = [[ZoomSDK sharedSDK] getPremeetingService];
    NSWindow* scheduleWindow = [[NSWindow alloc] init];
    ZoomSDKError error = ZoomSDKError_UnKnow;
    if ([[_meetingNumber stringValue] length] == 0) {
       error = [premeetingService showScheduleEditMeetingWindow:YES Window:&scheduleWindow MeetingID:0];
    }else{
       NSLog(@"Edit meeting ID:%lld",[[_meetingNumber stringValue] longLongValue]);
       error = [premeetingService showScheduleEditMeetingWindow:YES Window:&scheduleWindow MeetingID:[[_meetingNumber stringValue] longLongValue]];
    }
    if(ZoomSDKError_Success == error)
    {
        [scheduleWindow center];
    }
   // ;
}
-(void)onDeleteMeeting:(ZoomSDKPremeetingError)error
{
    [_preMeetingError setHidden:NO];
    if (error == ZoomSDKPremeetingError_Success) {
        [_preMeetingError setStringValue:@"Delete Meeting Success"];
    }else{
        [_preMeetingError setStringValue:[NSString stringWithFormat:@"Delete Meeting Error, Error Code:%d", error]];
    }
}
-(void)onScheduleOrEditMeeting:(ZoomSDKPremeetingError)error MeetingUniqueID:(long long)meetingUniqueID
{
    [_preMeetingError setHidden:NO];
    if (error == ZoomSDKPremeetingError_Success) {
        [_preMeetingError setStringValue:@"Scheduel or Edit Meeting Success"];
        [_meetingNumber setStringValue:[NSString stringWithFormat:@"%lld", meetingUniqueID]];
    }else{
         [_preMeetingError setStringValue:[NSString stringWithFormat:@"Scheduel or Edit Meeting Error, Error Code:%d", error]];
    }
}
- (void)onListMeeting:(ZoomSDKPremeetingError)error MeetingList:(NSArray *)meetingList
{
    [_listMeetingError setHidden:NO];
    NSMutableString* meetingListContent = [NSMutableString string];
     [_listMeeting setHidden:NO];
    if (error == ZoomSDKPremeetingError_Success) {
        int index = 1;
        for(ZoomSDKMeetingItem* item in meetingList)
        {
            
            time_t startTime = [[item getDateOption] getMeetingStartTime];
            NSString* topic = [[item getConfigOption] getMeetingTopic];
            NSString* password = [[item getConfigOption] getMeetingPassword];
            time_t duration = [[item getDateOption] getMeetingDuration];
            long long meetingNumber = [item getMeetingUniqueID];
        
            struct tm timeStruct;
            localtime_r(&startTime, &timeStruct);
            char buffer[20];
            strftime(buffer, 20, "%d-%m-%Y %H:%M:%S", &timeStruct);
            NSString* start = [NSString stringWithUTF8String:buffer];
            NSString* content = [NSString stringWithFormat:@"%d. Meeting Number:%lld Topic:%@ Password:%@ StartTime:%@ Duration:%ld %C",index, meetingNumber, topic, password, start, duration, (unichar)NSParagraphSeparatorCharacter];
            NSLog(@"Meeting List each Content:%@", content);
            [meetingListContent appendString:content];
            index++;
        }
        NSLog(@"Meeting List Content:%@", meetingListContent);
        [_meetingListContent setString:meetingListContent];
        [_listMeetingError setStringValue:@"List Meeting Success"];
    }else{
        [_listMeetingError setStringValue:[NSString stringWithFormat:@"List Meeting Error, Error Code:%d", error]];
    }
}

- (NSDate *)getMeetingStartDateFromDate:(NSDate *)currentDate
{
    
    NSDateComponents *time = [[NSCalendar currentCalendar]
                              components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
                              fromDate:currentDate];
    [time setMinute:-[time minute]];
    [time setSecond:-[time second]];
    [time setHour:2];
    
    return [[NSCalendar currentCalendar] dateByAddingComponents:time toDate:currentDate options:0];
}

//H323 support
- (IBAction)sendPairCode:(id)sender
{
    ZoomSDKMeetingService* meetingSevice = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingSevice getH323Helper] sendMeetingPairingCode:[_pairCode stringValue] meetingNum:[[_meetingNum stringValue] longLongValue]];
}
- (IBAction)getH323DeviceAddress:(id)sender
{
    ZoomSDKMeetingService* meetingSevice = [[ZoomSDK sharedSDK] getMeetingService];
    NSArray* addressArray = [[meetingSevice getH323Helper] getH323DeviceAddress];
    //test
    NSArray* array = [[meetingSevice getPhoneHelper] getCallInNumberInfo];
    if([array count] > 0)
    {
        for (ZoomSDKCallInPhoneNumInfo* info in array) {
            NSLog(@"phone number info name:%@, ip:%@", [info getName], [info getNumber]);
        }
    }
 
    NSString* info = @"";
    for (int i = 0; i < [addressArray count]; i++) {
        NSString* address = [NSString stringWithFormat:@"%@%C", [addressArray objectAtIndex:i], (unichar)NSParagraphSeparatorCharacter];
       info = [info stringByAppendingString:address];
    }
    [_deviceAddress setString:info];
}
- (IBAction)calloutDevice:(id)sender
{
    H323DeviceInfo* info = [[[H323DeviceInfo alloc] init] autorelease];
    info.name = _deviceName.stringValue;
    info.ip = _deviceIP.stringValue;
    info.e164num = _deviceE164Num.stringValue;
    info.type= _selectDeviceType;
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKError result = [[meetingService getH323Helper] calloutH323Device:info];
    if (result != ZoomSDKError_Success) {
        NSLog(@"Call out device failed!");
    }
    
}
- (IBAction)cancelCalloutDevice:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [[meetingService getH323Helper] cancelCallOutH323];
}


//Participants
-(IBAction)getParticipantsList:(id)sender
{
    
    /*NSString *mailtoStr = [NSString stringWithFormat:@"mailto:?subject=%@&body=%@", @"test", @"totti"];
    NSURL* theURL = nil;
    if(mailtoStr && mailtoStr.length>0)
        theURL = [NSURL URLWithString:mailtoStr];
    if(theURL)
        [[NSWorkspace sharedWorkspace] openURL:theURL];*/
    
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    NSArray* participantsList = [[meetingService getMeetingActionController] getParticipantsList];
    NSString* listInfo = @"";
   //test for huawei getmeetingid
   // listInfo = [meetingService getMeetingProperty:MeetingPropertyCmd_MeetingID];
   for (NSNumber* user in participantsList) {
        ZoomSDKUserInfo* userInfo = [[meetingService getMeetingActionController] getUserByUserID:[user unsignedIntValue]];
        NSString* userName = [userInfo getUserName];
        NSString* userString = [NSString stringWithFormat:@"%@ %@ %C", userName, [user stringValue], (unichar)NSParagraphSeparatorCharacter];
        listInfo = [listInfo stringByAppendingString:userString];
    }
    _participantsListView.string = listInfo;
    _waitingRoomUserInfo.string = listInfo;
}
//Spotlight Video
- (IBAction)spotLightVideo:(id)sender
{
    
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    NSString* selectedUser = [_selectedUserID stringValue];
    unsigned int userid =(unsigned int)[selectedUser intValue];
    [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_SpotlightVideo userID:userid onScreen:ScreenType_First];

}
- (IBAction)pinVideo:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    NSString* selectedUser = [_selectedUserID stringValue];
    unsigned int userid =(unsigned int)[selectedUser intValue];
     //test assign cohost
    /*[[meetingService getMeetingActionController] assignCoHost:userid];
    [[meetingService getMeetingActionController] actionMeetingWithCmd:ActionMeetingCmd_PinVideo userID:userid onScreen:_screenType];*/
    [[meetingService getMeetingActionController] makeHost:userid];
}

- (IBAction)getSharerList:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    NSArray* participantsList = [asController getShareSourceList];
    NSString* listInfo = @"";
    for (NSNumber* user in participantsList) {
        ZoomSDKUserInfo* userInfo = [[meetingService getMeetingActionController] getUserByUserID:[user unsignedIntValue]];
        ZoomSDKShareSource* sharesource = [asController getShareSourcebyUserId:[user unsignedIntValue]];
        NSString* userName = [userInfo getUserName];
        BOOL inFirstScreen = [sharesource isShowInFirstScreen];
        BOOL inSecondScreen = [sharesource isShowInSecondScreen];
        BOOL canbeRemoteContrller = [sharesource canBeRemoteControl];
        NSString* userString = [NSString stringWithFormat:@"%@ %@ inFirstScreen:%d inSecondScreen:%d canbeRemoteControll:%d %C", userName, [user stringValue],inFirstScreen, inSecondScreen,canbeRemoteContrller, (unichar)NSParagraphSeparatorCharacter];
        listInfo = [listInfo stringByAppendingString:userString];
    }
    _sharerListView.string = listInfo;
}

- (IBAction)viewShare:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    unsigned int userid =(unsigned int)[_sharerUserID intValue];
    ZoomSDKASController* asController = [meetingService getASController];
    [asController viewShare:userid onScreen:_screenType];
}

//H323 Helper delegate

- (void) onCalloutStatusReceived:(H323CalloutStatus)calloutStatus
{
    NSString* errorString = @"";
    switch (calloutStatus) {
        case H323CalloutStatus_Unknown:
            errorString = @"call out device error unknow";
            break;
        case H323CalloutStatus_Success:
            errorString = @"call out device successfully";
            break;
        case H323CalloutStatus_Timeout:
            errorString = @"call out device time out";
            break;
        case H323CalloutStatus_Failed:
            errorString = @"call out device failed";
            break;
        case H323CalloutStatus_Ring:
            errorString = @"call out device is ringing";
            break;
        default:
            break;
    }
    [_deviceAddress setString:errorString];
}

- (void) onPairCodeResult:(H323PairingResult)pairResult
{
    NSString* errorString = @"";
    switch (pairResult) {
        case H323PairingResult_Unknown:
            errorString = @"pair meeting unknow";
            break;
        case H323PairingResult_Success:
            errorString = @"pair meeting successfully";
            break;
        case H323PairingResult_Meeting_Not_Exist:
            errorString = @"pair meeting error for meeting not exist";
            break;
        case H323PairingResult_Paringcode_Not_Exist:
            errorString = @"pair meeting error for pair code not exist";
            break;
        case H323PairingResult_No_Privilege:
            errorString = @"pair meeting error for u haven't privilege";
            break;
        case H323PairingResult_Other_Error:
            errorString = @"pair meeting error for other error";
            break;
        default:
            break;
    }
    [_deviceAddress setString:errorString];
}

-(void)onH323DeviceTypeSelect:(id)sender
{
    NSString* title = [sender title];
    if ([title isEqualToString:@"H323"]) {
        _selectDeviceType = H323DeviceType_H323;
    }else if([title isEqualToString:@"SIP"]){
        _selectDeviceType = H323DeviceType_SIP;
    }else{
        _selectDeviceType = H323DeviceType_Unknown;
    }
}

-(void)onScreenTypeSelected:(id)sender
{
    NSString* title = [sender title];
    if ([title isEqualToString:@"First"]) {
        _screenType = ScreenType_First;
    }else if([title isEqualToString:@"Second"]){
        _screenType = ScreenType_Second;
    }
}
// share delegate
- (void)onSharingStatus:(ZoomSDKShareStatus)status User:(unsigned int)userID
{
    ZoomSDKShareContainer* container = [[[[ZoomSDK sharedSDK] getMeetingService] getASController] getShareContainer];
    NSString* info = @"";
    switch (status) {
        case ZoomSDKShareStatus_SelfBegin:
            info = @"I start share myself";
            break;
        case ZoomSDKShareStatus_SelfEnd:
            info = @"I end share myself";
            break;
        case ZoomSDKShareStatus_OtherBegin:
        {
            //this will show waiting share view tip first
             info = [NSString stringWithFormat:@"%d start his share now", userID];
            NSRect contentRect = [_shareCtrl.window contentRectForFrameRect:NSMakeRect(0, 0, 1280, 720)];
            NSLog(@"Demo share window content frame:%@", NSStringFromRect(contentRect));
            [_shareCtrl.window makeKeyAndOrderFront:nil];
            _shareElement = [[ZoomSDKShareElement alloc] initWithFrame:contentRect];
            [container createShareElement:&_shareElement];
            _shareElement.userId = userID;
            _shareElement.viewMode = ViewShareMode_LetterBox;
            [_shareElement ShowShareRender:YES];
            NSView* shareView = [_shareElement shareView];
            ShareContentView* contentView = [[ShareContentView alloc] initWithFrame:contentRect];
            _shareCtrl.window.contentView = contentView;
            contentView.shareView = shareView;
            NSLog(@"Demo share view frame:%@", NSStringFromRect([shareView frame]));
            contentView.userid = userID;
            [contentView addSubview:shareView];
            [_shareCtrl showWindow:nil];
        }
           
            break;
        case ZoomSDKShareStatus_OtherEnd:
        {
            info = [NSString stringWithFormat:@"%d end his share now", userID];
            if(_shareElement.userId == userID)
            {
                [_shareElement ShowShareRender:NO];
                NSView* shareView = [_shareElement shareView];
                [shareView removeFromSuperview];
                [container cleanShareElement:_shareElement];
                [_shareCtrl.window orderOut:nil];
                [_shareElement release];
                _shareElement = nil;
                [_shareCtrl.window orderOut:nil];
            }
        }
            break;
        case ZoomSDKShareStatus_ViewOther:
        {
            //this will make waiting share view tip disappear and run into view share
            info = [NSString stringWithFormat:@"now u can view %d's share", userID];
             [_shareElement ShowShareRender:YES];
        }
            break;
        case ZoomSDKShareStatus_Pause:
            info = [NSString stringWithFormat:@"%d pause his share now", userID];
            break;
        case ZoomSDKShareStatus_Resume:
             info = [NSString stringWithFormat:@"%d resume his share now", userID];
            break;
        case ZoomSDKShareStatus_None:
            break;
        default:
            break;
    }
   // _shareStatusMsgView.string = info;
    
}

-(void)onShareContentChanged:(ZoomSDKShareInfo *)shareInfo
{
    ZoomSDKShareContentType type = [shareInfo getShareType];
    NSString* info = @"";
    if (ZoomSDKShareContentType_DS == type) {
        CGDirectDisplayID displayID = 0;
        if (ZoomSDKError_Success == [shareInfo getDisplayID:&displayID]) {
             info = [NSString stringWithFormat:@"Share content Change to Destop, display ID:%d", displayID];
        }
    }else if(ZoomSDKShareContentType_AS == type || ZoomSDKShareContentType_WB == type)
    {
        CGWindowID windowID = 0;
        if (ZoomSDKError_Success == [shareInfo getWindowID:&windowID]) {
            info = [NSString stringWithFormat:@"Share content change to Application or Whiteboard, window ID:%d", windowID];
        }

    }
    _shareStatusMsgView.string = info;
}

- (void)onToolbarInviteButtonClick
{
    NSLog(@"Invite Button Clicked by User, Do something!!!");
}


#pragma mark - Waiting Room
- (IBAction)getWaitingRoomUsers:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWaitingRoomController* waitController = [meetingService getWaitingRoomController];
    NSArray* waitUserArray = [waitController getWaitRoomUserList];
    if (!waitUserArray || waitUserArray.count == 0)
        return;
    NSString* userString = @"";
    for (int i=0;i< waitUserArray.count;i++) {
        NSNumber* userNum = [waitUserArray objectAtIndex:i];
        userString = [userString stringByAppendingString:[NSString stringWithFormat:@"%@ %C", [userNum stringValue], (unichar)NSParagraphSeparatorCharacter]];
    }
    _waitingRoomUserInfo.string = userString;
}

- (IBAction)admitToMeeting:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWaitingRoomController* waitController = [meetingService getWaitingRoomController];
    if ([_selectedWaitingUser.stringValue isEqualToString:@""]) {
        return;
    }
    [waitController admitToMeeting: [[_selectedWaitingUser stringValue] intValue]];
}

- (IBAction)putIntoWaitingRoom:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWaitingRoomController* waitController = [meetingService getWaitingRoomController];
    if ([_selectedWaitingUser.stringValue isEqualToString:@""]) {
        return;
    }
    [waitController putIntoWaitingRoom: [[_selectedWaitingUser stringValue] intValue]];
}

#pragma mark - Waiting Room Delegate
-(void)onUserJoinWaitingRoom:(unsigned int)userid
{
    NSString* statusInfo = [NSString stringWithFormat:@"%d, %@", userid,@"Join Waiting Room"];
    [_waitingRoomStatusInfo setString:statusInfo];
    [self updateWebinarUI];
}

-(void)onUserLeftWaitingRoom:(unsigned int)userid
{
    NSString* statusInfo = [NSString stringWithFormat:@"%d, %@", userid,@"Left Waiting Room"];
    [_waitingRoomStatusInfo setString:statusInfo];
    [self updateWebinarUI];
}

//Phone Call Out
- (IBAction)callOutInviteUser:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKPhoneHelper* phoneHelper = [meetingService getPhoneHelper];
    if (![_countryCode stringValue].length ||![_phoneNumber stringValue].length ||![_userName stringValue].length)
        return;
    [phoneHelper inviteCalloutUser:[_userName stringValue] PhoneNumber:[_phoneNumber stringValue] CountryCode:[_countryCode stringValue]];
    
}
- (IBAction)cancelCallOut:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKPhoneHelper* phoneHelper = [meetingService getPhoneHelper];
    [phoneHelper cancelCalloutUser];
}

//Phone Helper Delegate
- (void)onInviteCalloutUserStatus:(PhoneStatus)status FailedReason:(PhoneFailedReason)reason
{
    NSString* phoneStatusString =@"";
    NSString* failedString = @"";
    switch (status) {
        case PhoneStatus_Accepted:
            phoneStatusString = @"Phone Call Accepted!";
            break;
        case PhoneStatus_Calling:
            phoneStatusString = @"Phone Call is Calling!";
            break;
        case PhoneStatus_Canceled:
            phoneStatusString = @"Phone Call Canceled";
            break;
        case PhoneStatus_Cancel_Failed:
            phoneStatusString = @"Phone Call Cancel Failed!";
            break;
        case PhoneStatus_Ringing:
            phoneStatusString = @"Phone Call is Ringing!";
            break;
        case PhoneStatus_Canceling:
            phoneStatusString = @"Phone Call is Canceling!";
            break;
        case PhoneStatus_Timeout:
            phoneStatusString = @"Phone Call Time Out!";
            break;
        case PhoneStatus_Success:
            phoneStatusString = @"Phone Call Success!";
        case PhoneStatus_Failed:
        {
            switch (reason) {
                case PhoneFailedReason_Block_High_Rate:
                    failedString = @"Failed: High Rate";
                    break;
                case PhoneFailedReason_Block_No_Host:
                    failedString = @"Failed: Block No Host";
                    break;
                case PhoneFailedReason_Busy:
                    failedString = @"Failed: Busy";
                    break;
                case PhoneFailedReason_No_Answer:
                    failedString = @"Failed: No Answer";
                    break;
                case PhoneFailedReason_Block_Too_Frequent:
                    failedString = @"Failed: Too Frequent";
                    break;
                case PhoneFailedReason_Not_Available:
                    failedString = @"Failed: Not Available";
                    break;
                case PhoneFailedReason_Other_Fail:
                    failedString = @"Failed: Other Fail";
                    break;
                case PhoneFailedReason_User_Hangup:
                    failedString = @"Failed: User Hangup";
                    break;
                default:
                    break;
            }
        }
            break;
        default:
            break;
    }
    
    NSString* info = [phoneStatusString stringByAppendingString:failedString];
    _calloutStatusInfo.string = info;
}

-(NSString*)getScreenDisplayID
{
    NSString* displayScreenStr = @"";
    NSArray* allScreens = [NSScreen screens];
    if(!allScreens || allScreens.count<=0)
        return nil;
    for (int i = 0; i< allScreens.count; i++ ) {
        NSScreen* theScreen = [allScreens objectAtIndex:i];
        NSDictionary *screenDescription = [theScreen deviceDescription];
        NSNumber* screenIDNumber = [screenDescription objectForKey:@"NSScreenNumber"];
        displayScreenStr = [displayScreenStr stringByAppendingString:[NSString stringWithFormat:@"%d, %@ %C", i, [screenIDNumber stringValue],(unichar)NSParagraphSeparatorCharacter]];
    }
    // NSLog(@"First screen display ID:%d", tmpDisplayId);
    return displayScreenStr;
}

#pragma mark - network service delegate
- (void)onProxySettingNotification:(ZoomSDKProxySettingHelper*)proxyHelper
{
    ZoomSDKProxySettingHelper* helper = proxyHelper;
    NSString* host = [helper getProxyHost];
    NSString* desc = [helper getProxyDescription];
    int port = [helper getProxyPort];
    NSLog(@"Proxy setting, Host:%@, description:%@, port:%d", host, desc, port);
    [helper proxyAuth:@"kelvin" password:@"hello"];
    
}



#pragma mark - window delegate
-(void)windowWillClose:(NSNotification *)notification
{
    NSAlert* alert = [NSAlert alertWithMessageText:@"Do U want to quit the ZoomSDK Sample"
                                     defaultButton:@"Quit"
                                   alternateButton:@"Cancel"
                                       otherButton:@""
                         informativeTextWithFormat:@""];
    alert.icon = [[NSBundle mainBundle] imageForResource:@"ZoomLogo"];
    [alert beginSheetModalForWindow:nil
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:(void*)100];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if(1 == returnCode)
        [[NSApplication sharedApplication] terminate:nil];
    else
        [_mainWindow makeKeyAndOrderFront:nil];
}

#pragma mark - new sdk feature

- (void)onVideoStatusChange:(BOOL)videoOn UserID:(unsigned int)userID
{
    ZoomSDKUserInfo* userInfo = [[[[ZoomSDK sharedSDK] getMeetingService] getMeetingActionController] getUserByUserID:userID];
    /*if ([userInfo isMySelf]) {
        //newUserVideo1.userid = userID; */
        
    if(newUserVideo1.userid == 0 || newUserVideo1.userid == userID)
    {
         newUserVideo1.userid = userID;
    }else if(newUserVideo2.userid == 0 || newUserVideo2.userid == userID)
    {
        newUserVideo2.userid = userID;
    }else if(newUserVideo3.userid == 0 || newUserVideo3.userid == userID)
    {
        newUserVideo3.userid = userID;
    }
}




- (IBAction)subscribeUser:(id)sender
{
    if([_joinUserName.stringValue isEqualToString:@"1"])
        [newUserVideo1 subscribeVideo:YES];
    else if([_joinUserName.stringValue isEqualToString:@"2"])
        [newUserVideo2 subscribeVideo:YES];
    else
        [newUserVideo3 subscribeVideo:YES];
}
- (IBAction)unSubscribeUser:(id)sender
{
    if([_joinUserName.stringValue isEqualToString:@"1"])
        [newUserVideo1 subscribeVideo:NO];
    else if([_joinUserName.stringValue isEqualToString:@"2"])
        [newUserVideo2 subscribeVideo:NO];
    else
        [newUserVideo3 subscribeVideo:NO];
}
- (IBAction)hideVideoRender:(id)sender
{
    if([_joinUserName.stringValue isEqualToString:@"1"])
         [newUserVideo1 showVideo:NO];
    else if([_joinUserName.stringValue isEqualToString:@"2"])
         [newUserVideo2 showVideo:NO];
    else
        [newUserVideo3 showVideo:NO];
}
- (IBAction)showVideoRender:(id)sender
{
    if([_joinUserName.stringValue isEqualToString:@"1"])
        [newUserVideo1 showVideo:YES];
    else if([_joinUserName.stringValue isEqualToString:@"2"])
        [newUserVideo2 showVideo:YES];
    else
        [newUserVideo3 showVideo:YES];
}

- (IBAction)viewNewShare:(id)sender
{
    //   unsigned int userid =(unsigned int)[_sharerUserID intValue];
    
}

#pragma mark - window delegate
- (void)windowDidResize:(NSNotification *)notification
{
    /*  if (_shareElement)
     {
     [_shareElement resize:NSMakeRect(0, 0, _shareCtrl.window.frame.size.width,  _shareCtrl.window.frame.size.height)];
     }
     */
}

#pragma mark - customized annotation
- (void)onAnnotationStatusChanged:(ZoomSDKShareElement *)element Status:(AnnotationStatus)status
{
    NSLog(@"annotation status: %d", status);
     if(status == AnnotationStatus_Ready){
     ZoomSDKCustomizedAnnotationCtr* cusAnnoCtr = [[[[ZoomSDK sharedSDK] getMeetingService] getASController] getCustomizedAnnotationCtr];
     ZoomSDKCustomizedAnnotation* annotation = [[ZoomSDKCustomizedAnnotation alloc] init];
     [cusAnnoCtr createCustomizedAnnotation:&annotation ShareElement:element];
     [annotation setTool:AnnotationToolType_Pen];
     }
}

#pragma mark - customized record
- (void)onCustomizedRecordingSourceReceived:(CustomizedRecordingLayoutHelper*)helper
{
    CustomizedRecordingLayoutHelper* recordLayout = helper;
    if(helper)
    {
        int supportLayout = [recordLayout getSupportLayoutMode];
        BOOL haveActiveVideo = [recordLayout haveActiveVideoSource];
        NSLog(@"support layout mode is: %u, %d", supportLayout, haveActiveVideo);
        NSArray* videoSource = [recordLayout getValidVideoSource];
        NSArray* shareSource = [recordLayout getValidRecivedShareSource];
        /*test video wall record start
         for (NSNumber* user in videoSource) {
         NSLog(@"valid user id: %u", [user unsignedIntValue]);
         [recordLayout selectRecordingLayoutMode:RecordingLayoutMode_VideoWall];
         //  if(haveActiveVideo)
         // [recordLayout selectActiveVideoSource];
         [recordLayout addVideoSourceToResArray:[user unsignedIntValue]];
         }
         // test video wall record end */
        
        /*test active video
         if(haveActiveVideo)
         {
         [recordLayout selectRecordingLayoutMode:RecordingLayoutMode_ActiveVideoOnly];
         [recordLayout selectActiveVideoSource];
         }
         */
        
        /* test share that is only one user sending share
         [recordLayout selectRecordingLayoutMode:RecordingLayoutMode_OnlyShare];
         for (NSNumber* shareuser in shareSource) {
         [recordLayout selectShareSource:[shareuser unsignedIntValue]];
         }*/
        
        //test share and video only one user sending share
        [recordLayout selectRecordingLayoutMode:RecordingLayoutMode_VideoShare];
        for (NSNumber* shareuser in shareSource) {
            [recordLayout selectShareSource:[shareuser unsignedIntValue]];
        }
        for (NSNumber* user in videoSource) {
            NSLog(@"valid user id: %u", [user unsignedIntValue]);
            [recordLayout addVideoSourceToResArray:[user unsignedIntValue]];
        }
        
    }
}

- (void)onOutlookPluginNeedLoginRequest{
    NSLog(@"request login from outlookplugin!");
}

- (void)onOutlookPluginScheduleMeetingRequest
{
    NSLog(@"request schedule from outlookplugin!");
}

- (void)onOutlookPluginDefaultMeetingTopicRequest:(NSString *)scheduleForEmail DefaultMeetingTopic:(NSString **)topic
{
    *topic = @"Test By TOTTI";
  //  NSLog(@"default topic come from outlookplugin!, scheduleForEmail:%@, default topic:%@", scheduleForEmail, *topic);
}

- (IBAction)startDS:(id)sender
{
    ZoomSDKDirectShareHelper* helper = [[[ZoomSDK sharedSDK] getPremeetingService] getDirectShareHelper];
    if(helper)
    {
        ZoomSDKError can = [helper canDirectShare];
        NSLog(@"CAN start direct share %d", can);
        if(ZoomSDKError_Success == can)
            [helper startDirectShare];
    }
    
}
- (IBAction)stopDS:(id)sender
{
    ZoomSDKDirectShareHelper* helper = [[[ZoomSDK sharedSDK] getPremeetingService] getDirectShareHelper];
    if(helper)
        [helper stopDirectShare];
}
- (IBAction)cancelDS:(id)sender
{
    //test input meeting number
    if(_dsHandler)
       // [_dsHandler inputMeetingNumber:_meetingNumber.stringValue];
        [_dsHandler inputSharingKey:_meetingNumber.stringValue];
    
 /*  ZoomSDKDirectShareHelper* helper = [[[ZoomSDK sharedSDK] getPremeetingService] getDirectShareHelper];
    if(helper)
        [helper canDirectShare];*/
}

- (void)onDirectShareStatusReceived:(DirectShareStatus)status DirectShareReceived:(ZoomSDKDirectShareHandler *)handler
{
    NSLog(@"direct share status: %d", status);
    if(handler)
    {
        _dsHandler = handler;
    }
}

-(void)onUserLeft:(NSArray *)array
{
    [self updateWebinarUI];
    ZoomSDKVideoContainer* videoContainer = [[[ZoomSDK sharedSDK] getMeetingService] getVideoContainer];
    if([array count] > 0)
    {
        for (NSNumber* userid in array) {
            unsigned int user = [userid unsignedIntValue];
            if(newUserVideo1.userid == user)
            {
                [videoContainer cleanVideoElement:newUserVideo1];
                NSView* videoview = [newUserVideo1 getVideoView];
                [videoview removeFromSuperview];
                [newUserVideo1 release];
                newUserVideo1 = nil;
            }
            if(newUserVideo2.userid == user)
            {
                [videoContainer cleanVideoElement:newUserVideo2];
                NSView* videoview = [newUserVideo2 getVideoView];
                [videoview removeFromSuperview];
                [newUserVideo2 release];
                newUserVideo2 = nil;
            }
            if(newUserVideo3.userid == user)
            {
                [videoContainer cleanVideoElement:newUserVideo3];
                NSView* videoview = [newUserVideo3 getVideoView];
                [videoview removeFromSuperview];
                [newUserVideo3 release];
                newUserVideo3 = nil;
            }
        }
    }
}

- (ZoomSDKError)onWebinarNeedRegisterResponse:(ZoomSDKWebinarRegisterHelper*)webinarRegisterHelper
{
    NSLog(@"[AppDelegat onWebinarNeedRegisterResponse:]");
    WebinarRegisterType type = [webinarRegisterHelper getWebinarRegisterType];
    if(![[ZoomSDK sharedSDK] needCustomizedUI])
        return ZoomSDKError_Failed;
    if(WebinarRegisterType_URL == type)
    {
        NSURL* url = [webinarRegisterHelper getWebinarRegisterURL];
        if(url)
            NSLog(@"%@", url);
        [[NSWorkspace sharedWorkspace] openURL:url];
        return ZoomSDKError_Success;
    }
    else if(WebinarRegisterType_Email == type)
    {
        NSString* email = @"deraintest@zoom.us";
        NSString* displayName = @"test Webinar Register";
        [webinarRegisterHelper inputEmail:email screenName:displayName];
        return ZoomSDKError_Success;
    }
    return ZoomSDKError_Failed;
}
-(void)updateWebinarUI
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    if (!meetingService) {
        return;
    }
    [_promoteAttendee2Panelist setEnabled:NO];
    [_depromotePanelist2Attendee setEnabled:NO];
    [_allowAttendeeTalk setEnabled:NO];
    [_disallowAttendeeTalk setEnabled:NO];
    [_allowPanelistStartVideo setEnabled:NO];
    [_disallowPanelistStartVideo setEnabled:NO];
    [_allowAttendeeChat setEnabled:NO];
    [_disallowAttendeeChat setEnabled:NO];
    
    if(MeetingType_Webinar == [meetingService getMeetingType])
    {
        [_tabView selectTabViewItemWithIdentifier:@"WebinarContainer"];
        ZoomSDKWebinarController *webinarController = [meetingService getWebinarController];
        webinarController.delegate = self;
        
        NSString* listInfo = @"";
        NSArray* userlist = [[meetingService getMeetingActionController] getParticipantsList];
        ZoomSDKUserInfo *myself = nil;
        for (NSNumber*user in userlist)
        {
            NSLog(@"user list:%d", [user unsignedIntValue]);
            ZoomSDKUserInfo* userInfo = [[meetingService getMeetingActionController] getUserByUserID:[user unsignedIntValue]];
            
            NSString* userName = [userInfo getUserName];
            NSString* userString = [NSString stringWithFormat:@"%@   %u   %C", userName, [userInfo getUserID], (unichar)NSParagraphSeparatorCharacter];
            listInfo = [listInfo stringByAppendingString:userString];
            if([userInfo isMySelf])
                myself = userInfo;
            if ([userInfo isHost] && [userInfo isMySelf])
            {
                [_promoteAttendee2Panelist setEnabled:YES];
                [_depromotePanelist2Attendee setEnabled:YES];
                [_allowAttendeeTalk setEnabled:YES];
                [_disallowAttendeeTalk setEnabled:YES];
                [_allowPanelistStartVideo setEnabled:YES];
                [_disallowPanelistStartVideo setEnabled:YES];
                [_allowAttendeeChat setEnabled:YES];
                [_disallowAttendeeChat setEnabled:YES];
            }
        }
        _panelistListView.string = listInfo;
        [_panelistListView setEditable:NO];
        NSArray* attendeelist = [webinarController getAttendeeList];
        NSString* attendeeListInfo = @"";
        for (int i=0;i< attendeelist.count;i++)
        {
            NSNumber* userNum = [attendeelist objectAtIndex:i];
            ZoomSDKUserInfo* userInfo = [[[[ZoomSDK sharedSDK] getMeetingService] getMeetingActionController] getUserByUserID:[userNum unsignedIntValue]];
            NSString* userName = [userInfo getUserName];
            NSString* userString = [NSString stringWithFormat:@"%@   %@   %C", userName, [userNum stringValue], (unichar)NSParagraphSeparatorCharacter];
            attendeeListInfo = [attendeeListInfo stringByAppendingString:userString];
            
        }
        _attendeeListView.string = attendeeListInfo;
        [_attendeeListView setEditable:NO];
        NSLog(@"_attendeeListView: %@", _attendeeListView.string);
        
        ZoomSDKWaitingRoomController* waitController = [meetingService getWaitingRoomController];
        waitController.delegate = self;
        NSArray* waitUserArray = [waitController getWaitRoomUserList];
        
        NSString* userString = @"";
        for (int i=0;i< waitUserArray.count;i++) {
            NSNumber* userNum = [waitUserArray objectAtIndex:i];
            ZoomSDKUserInfo* userInfo = [[[[ZoomSDK sharedSDK] getMeetingService] getMeetingActionController] getUserByUserID:[userNum unsignedIntValue]];
            NSString* userName = [userInfo getUserName];
            userString = [userString stringByAppendingString:[NSString stringWithFormat:@"%@   %@   %C", userName, [userNum stringValue], (unichar)NSParagraphSeparatorCharacter]];
        }
        _waitingRoomListView.string = userString;
        [_waitingRoomListView setEditable:NO];
        NSLog(@"_waitingRoomListView: %@", _waitingRoomListView.string);
        
        [_isSupportAttendeeTalk setState:[[webinarController getZoomSDKWebinarMeetingStatus] isSupportAttendeeTalk]];
        [_isAllowAttendeeChat setState:[[webinarController getZoomSDKWebinarMeetingStatus] isAllowAttendeeChat]];
        [_isAllowPanelistStartVideo setState:[[webinarController getZoomSDKWebinarMeetingStatus] isAllowPanellistStartVideo]];
        [_isSupportAttendeeTalk setEnabled:NO];
        [_isAllowAttendeeChat setEnabled:NO];
        [_isAllowPanelistStartVideo setEnabled:NO];
        
        if(myself && (UserRole_Attendee == [myself getUserRole]))
        {
            _panelistListView.string = @"Attendee can't get user list";
            _attendeeListView.string = @"Attendee can't get attendee list";
            _waitingRoomListView.string = @"Attendee can't get waiting list";
        }
    }
}
-(IBAction)navigatorToWebinarControTab:(id)sender
{
    [_tabView selectTabViewItemWithIdentifier:@"WebinarContainer"];
}
-(IBAction)refreshUserList:(id)sender
{
    [self updateWebinarUI];
}
//webinar
- (IBAction)putOnHold:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWaitingRoomController* waitController = [meetingService getWaitingRoomController];
    if ([_selectedUser.stringValue isEqualToString:@""]) {
        return;
    }
    NSString* selectedUser = [_selectedUser stringValue];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    NSNumber * number = [formatter numberFromString:selectedUser];
    unsigned int userid = [number unsignedIntValue];
    [formatter release];
    [waitController putIntoWaitingRoom:userid];
}
- (IBAction)putIntoMeeting:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWaitingRoomController* waitController = [meetingService getWaitingRoomController];
    if ([_selectedUser.stringValue isEqualToString:@""]) {
        return;
    }
    NSString* selectedUser = [_selectedUser stringValue];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    NSNumber * number = [formatter numberFromString:selectedUser];
    unsigned int userid = [number unsignedIntValue];
    [formatter release];
    [waitController admitToMeeting:userid];
}
-(IBAction)promoteAttendee2Panelist:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWebinarController* webinarController = [meetingService getWebinarController];
    if(webinarController)
    {
        NSString* selectedUser = [_selectedUser stringValue];
        NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
        NSNumber * number = [formatter numberFromString:selectedUser];
        unsigned int userid = [number unsignedIntValue];
        [formatter release];
        [webinarController PromoteAttendee2Panelist:userid];
    }
}
-(IBAction)depromotePanelist2Attendee:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWebinarController* webinarController = [meetingService getWebinarController];
    if(webinarController)
    {
        NSString* selectedUser = [_selectedUser stringValue];
        NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
        NSNumber * number = [formatter numberFromString:selectedUser];
        unsigned int userid = [number unsignedIntValue];
        [formatter release];
        [webinarController DepromotePanelist2Attendee:userid];
    }
}
-(IBAction)allowAttendeeTalk:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWebinarController* webinarController = [meetingService getWebinarController];
    if(webinarController)
    {
        NSString* selectedUser = [_selectedUser stringValue];
        NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
        NSNumber * number = [formatter numberFromString:selectedUser];
        unsigned int userid = [number unsignedIntValue];
        [formatter release];
        [webinarController AllowAttendeeTalk:userid];
    }
}
-(IBAction)disallowAttendeeTalk:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWebinarController* webinarController = [meetingService getWebinarController];
    if(webinarController)
    {
        NSString* selectedUser = [_selectedUser stringValue];
        NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
        NSNumber * number = [formatter numberFromString:selectedUser];
        unsigned int userid = [number unsignedIntValue];
        [formatter release];
        [webinarController DisallowAttendeeTalk:userid];
    }
}
-(IBAction)allowPanelistStartVideo:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWebinarController* webinarController = [meetingService getWebinarController];
    if(webinarController)
    {
        [webinarController AllowPanelistStartVideo];
    }
}
-(IBAction)disallowPanelistStartVideo:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWebinarController* webinarController = [meetingService getWebinarController];
    if(webinarController)
    {
        [webinarController DisallowPanelistStartVideo];
    }
}
-(IBAction)allowAttendeeChat:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWebinarController* webinarController = [meetingService getWebinarController];
    if(webinarController)
    {
        [webinarController AllowAttendeeChat];
    }
}
-(IBAction)disallowAttendeeChat:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKWebinarController* webinarController = [meetingService getWebinarController];
    if(webinarController)
    {
        [webinarController DisallowAttendeeChat];
    }
}
-(IBAction)onShowCustomizedSetting:(id)sender
{
    if (self.sdkSettingWindowController)
    {
        NSArray* subviews = _sdkSettingWindowController.window.contentView.subviews;
        for (NSView* item in subviews) {
            NSLog(@"%@", item.className);
        }
        
        [self.sdkSettingWindowController showWindow:nil];
        [self.sdkSettingWindowController relayoutWindowPosition];
    }
}
-(IBAction)onShareCamera:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    if(!asController)
        return;
    
    ZoomSDKVideoSetting* _videoSetting = [[[ZoomSDK sharedSDK] getSettingService] getVideoSetting];
    NSArray* cameraList = [_videoSetting getCameraList];
    NSUInteger count = cameraList.count;
    if(count <= 0)
        return;
    SDKDeviceInfo* selectedDevice = nil;
    for(SDKDeviceInfo* info in cameraList)
    {
        if(!info)
            continue;
        if(info.isSelectedDevice)
            selectedDevice = info;
    }
    /****for share customized camera window begin****/
    _shareCameraWindowCtrl = [[ZoomSDKWindowController alloc] init];
    [_shareCameraWindowCtrl.window setFrame:NSMakeRect(300, 300, 800, 720) display:YES];
    [_shareCameraWindowCtrl.window setTitle:@"Share Camera"];
    [_wndCtrl.window orderOut:nil];
    /****for share customized camera window end****/
    
    [_shareCameraWindowCtrl showWindow:nil];
    [asController startShareCamera:[selectedDevice getDeviceID] displayWindow:_shareCameraWindowCtrl.window];
}
- (void)showMeetingMainWindow
{
    [_wndCtrl.window orderFront:nil];
}

- (IBAction)startShareWhiteBoard:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    [asController startWhiteBoardShare];
}
- (IBAction)startShareFrame:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    [asController startFrameShare];
}
- (IBAction)startShareAudio:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    [asController startAudioShare];
}
- (IBAction)stopShare:(id)sender
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKASController* asController = [meetingService getASController];
    [asController stopShare];
    if(_shareCameraWindowCtrl)
       [_shareCameraWindowCtrl.window close];
}
@end
