//
//  AppDelegate.m
//  Parrot Status
//
//  Created by Vincent Le Normand on 29/10/2014.
//  Copyright (c) 2014 Vincent Le Normand. All rights reserved.
//

#import "AppDelegate.h"
#import <IOBluetooth/IOBluetooth.h>
#import <Sparkle/Sparkle.h>
#import "PFMoveApplication.h"
#import <Quartz/Quartz.h>
#import "MediaKey.h"

typedef NS_ENUM(NSInteger, PSState) {
    PSAskingStateInit,
    PSAskingStateConnected,
};

typedef enum {
    NOISE_CONTROL_NOISE_CANCELLING_MAX,
    NOISE_CONTROL_NOISE_CANCELLING,
    NOISE_CONTROL_OFF,
    NOISE_CONTROL_STREET_MODE,
    NOISE_CONTROL_STREET_MODE_MAX,
} NOISE_CONTROL_STATE;

#define GET(API) [NSString stringWithFormat:@"GET %@", API]
#define SET(API, value) [NSString stringWithFormat:@"@SET %@?arg=%@", API, value]


// API
static NSString *const ACCOUNT_USERNAME_GET = @"/api/account/username/get";
static NSString *const ACCOUNT_USERNAME_SET = @"/api/account/username/set";
static NSString *const APPLI_VERSION_SET = @"/api/appli_version/set";
static NSString *const AUDIO_NOISE_GET = @"/api/audio/noise/get";
static NSString *const AUDIO_PARAM_EQ_VALUE_SET = @"/api/audio/param_equalizer/value/set";
static NSString *const AUDIO_PRESET_ACTIVATE = @"/api/audio/preset/activate";
static NSString *const AUDIO_PRESET_BYPASS_GET = @"/api/audio/preset/bypass/get";
static NSString *const AUDIO_PRESET_BYPASS_SET = @"/api/audio/preset/bypass/set";
static NSString *const AUDIO_PRESET_CLEAR_ALL = @"/api/audio/preset/clear_all";
static NSString *const AUDIO_PRESET_COUNTER_GET = @"/api/audio/preset/counter/get";
static NSString *const AUDIO_PRESET_CURRENT_GET = @"/api/audio/preset/current/get";
static NSString *const AUDIO_PRESET_DOWNLOAD = @"/api/audio/preset/download";
static NSString *const AUDIO_PRESET_PRODUCER_CANCEL = @"/api/audio/preset/cancel_producer";
static NSString *const AUDIO_PRESET_REMOVE = @"/api/audio/preset/remove";
static NSString *const AUDIO_PRESET_SAVE = @"/api/audio/preset/save";
static NSString *const AUDIO_PRESET_SYNCHRO_START = @"/api/audio/preset/synchro/start";
static NSString *const AUDIO_PRESET_SYNCHRO_STOP = @"/api/audio/preset/synchro/stop";
static NSString *const AUDIO_SMART_TUNE_GET = @"/api/audio/smart_audio_tune/get";
static NSString *const AUDIO_SMART_TUNE_SET = @"/api/audio/smart_audio_tune/set";
static NSString *const AUDIO_SOURCE_GET = @"/api/audio/source/get";
static NSString *const AUDIO_TRACK_METADATA_GET = @"/api/audio/track/metadata/get";
static NSString *const BATTERY_GET = @"/api/system/battery/get";
static NSString *const CONCERT_HALL_ANGLE_GET = @"/api/audio/sound_effect/angle/get";
static NSString *const CONCERT_HALL_ANGLE_SET = @"/api/audio/sound_effect/angle/set";
static NSString *const CONCERT_HALL_ENABLED_GET = @"/api/audio/sound_effect/enabled/get";
static NSString *const CONCERT_HALL_ENABLED_SET = @"/api/audio/sound_effect/enabled/set";
static NSString *const CONCERT_HALL_GET = @"/api/audio/sound_effect/get";
static NSString *const CONCERT_HALL_ROOM_GET = @"/api/audio/sound_effect/room_size/get";
static NSString *const CONCERT_HALL_ROOM_SET = @"/api/audio/sound_effect/room_size/set";
static NSString *const EQUALIZER_ENABLED_GET = @"/api/audio/equalizer/enabled/get";
static NSString *const EQUALIZER_ENABLED_SET = @"/api/audio/equalizer/enabled/set";
static NSString *const FRIENDLY_NAME_GET = @"/api/bluetooth/friendlyname/get";
static NSString *const FRIENDLY_NAME_SET = @"/api/bluetooth/friendlyname/set";
static NSString *const NOISE_CONTROL_ENABLED_GET = @"/api/audio/noise_control/enabled/get";
static NSString *const NOISE_CONTROL_ENABLED_SET = @"/api/audio/noise_control/enabled/set";
static NSString *const NOISE_CONTROL_GET = @"/api/audio/noise_control/get";
static NSString *const NOISE_CONTROL_SET = @"/api/audio/noise_control/set";
static NSString *const SOFTWARE_DOWNLOAD_SIZE_SET = @"/api/software/download_size/set";
static NSString *const SOFTWARE_TTS_DISABLE = @"/api/software/tts/disable";
static NSString *const SOFTWARE_TTS_ENABLE = @"/api/software/tts/enable";
static NSString *const SOFTWARE_TTS_GET = @"/api/software/tts/get";
static NSString *const SOFTWARE_VERSION_SIP6_GET = @"/api/software/version/get";
static NSString *const SYSTEM_ANC_PHONE_MODE_GET = @"/api/system/anc_phone_mode/enabled/get";
static NSString *const SYSTEM_ANC_PHONE_MODE_SET = @"/api/system/anc_phone_mode/enabled/set";
static NSString *const SYSTEM_AUTO_CONNECTION_GET = @"/api/system/auto_connection/enabled/get";
static NSString *const SYSTEM_AUTO_CONNECTION_SET = @"/api/system/auto_connection/enabled/set";
static NSString *const SYSTEM_AUTO_POWER_OFF_GET = @"/api/system/auto_power_off/get";
static NSString *const SYSTEM_AUTO_POWER_OFF_LIST_GET = @"/api/system/auto_power_off/presets_list/get";
static NSString *const SYSTEM_AUTO_POWER_OFF_SET = @"/api/system/auto_power_off/set";
static NSString *const SYSTEM_BT_ADDRESS_GET = @"/api/system/bt_address/get";
static NSString *const SYSTEM_COLOR_GET = @"/api/system/color/get";
static NSString *const SYSTEM_DEVICE_PI = @"/api/system/pi/get";
static NSString *const SYSTEM_FLIGHT_MODE_DISABLE = @"/api/flight_mode/disable";
static NSString *const SYSTEM_FLIGHT_MODE_ENABLE = @"/api/flight_mode/enable";
static NSString *const SYSTEM_FLIGHT_MODE_GET = @"/api/flight_mode/get";
static NSString *const SYSTEM_HEAD_DETECTION_ENABLED_GET = @"/api/system/head_detection/enabled/get";
static NSString *const SYSTEM_HEAD_DETECTION_ENABLED_SET = @"/api/system/head_detection/enabled/set";
static NSString *const SYSTEM__DEVICE_TYPE_GET = @"/api/system/device_type/get";
static NSString *const THUMB_EQUALIZER_VALUE_GET = @"/api/audio/thumb_equalizer/value/get";
static NSString *const THUMB_EQUALIZER_VALUE_SET = @"/api/audio/thumb_equalizer/value/set";


@interface AppDelegate ()

@property(weak) IBOutlet NSWindow *advancedBatteryWindow;
@property(weak) IBOutlet SUUpdater *updater;
@property id eventMonitor;

@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) IOBluetoothRFCOMMChannel *mRfCommChannel;
@property(nonatomic) PSState state;

// State
@property(nonatomic) int batteryLevel;
@property(nonatomic) BOOL isBatteryCharging;
@property(nonatomic, copy) NSString *version;
@property(nonatomic, copy) NSString *name;
@property(nonatomic) NOISE_CONTROL_STATE noiseControlState;
@property(nonatomic) BOOL autoConnectionEnabled;
@property(nonatomic) BOOL ancPhoneMode;
@property(nonatomic) BOOL noiseControlEnabled;
@property(nonatomic) BOOL equalizerEnabled;
@property(nonatomic) BOOL concertHallEnabled;
@property(nonatomic) BOOL headDetectionEnabled;
@property(nonatomic) NSInteger currentPresetId;
@property(nonatomic) NSInteger presetCounter;

@property(nonatomic) CFAbsoluteTime showUntilDate;

@property(nonatomic) CFMachPortRef eventTap;
@end

@interface AppDelegate (SharedFileListExample)
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString *)appPath;

- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString *)appPath;

- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString *)appPath;
@end

@implementation AppDelegate {
    BluetoothRFCOMMChannelID channelId;
}

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
            @"ShowBatteryNotifications" : @YES,
            @"ShowBatteryAboutToDieNotifications" : @YES,
            @"BatteryNotificationLevels" : @[@"20%", @"10%"],
            @"ShowBatteryPercentage" : @NO,
            @"ShowBatteryIcon" : @YES,
            @"HiddenWhenDisconnected" : @NO,
            @"MapMediaKeys" : @NO
    }];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    PFMoveToApplicationsFolderIfNecessary();
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    if (loginItems) {
        [self enableLoginItemWithLoginItemsReference:loginItems forPath:appPath];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MapMediaKeys"]) {
        [self setupMediaKeyMapping];
    }
}

- (void)setupMediaKeyMapping {
    [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:@[@"unload", @"/System/Library/LaunchAgents/com.apple.rcd.plist"]];
    self.eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSKeyDownMask | NSSystemDefinedMask) handler:^(NSEvent *event) {
        NSInteger keyCode = (([event data1] & 0xFFFF0000) >> 16);

        NSInteger keyFlags = ([event data1] & 0x0000FFFF);

        int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;

        if (keyCode == 10 && keyFlags == 6972) {

            switch ([event data2]) {
                case 786608: // Play / Pause on OS < 10.10 Yosemite
                case 786637: // Play / Pause on OS >= 10.10 Yosemite
                    NSLog(@"Play/Pause bluetooth keypress detected...sending corresponding media key event");
                    [MediaKey send:NX_KEYTYPE_PLAY];
                    break;
                case 786611: // Next
                    NSLog(@"Next bluetooth keypress detected...sending corresponding media key event");
                    [MediaKey send:NX_KEYTYPE_NEXT];
                    break;
                case 786612: // Previous
                    NSLog(@"Previous bluetooth keypress detected...sending corresponding media key event");
                    [MediaKey send:NX_KEYTYPE_PREVIOUS];
                    break;
                case 786613: // Fast-forward
                    NSLog(@"Fast-forward bluetooth keypress detected...sending corresponding media key event");
                    [MediaKey send:NX_KEYTYPE_FAST];
                    break;
                case 786614: // Rewind
                    NSLog(@"Rewind bluetooth keypress detected...sending corresponding media key event");
                    [MediaKey send:NX_KEYTYPE_REWIND];
                    break;
                default:
                    // TODO make this popup a message in the UI (with a link to submit the issue and a "don't show this message again" checkbox)
                    NSLog(@"Unknown bluetooth key received.  Please visit https://github.com/jguice/mac-bt-headset-fix/issues and submit an issue describing what you expect the key to do (include the following data): keyCode:%li keyFlags:%li keyState:%i %li", keyCode, keyFlags, keyState, (long) [event data2]);
                    break;
            }
        }
    }];
}

- (void)disableMediaKeyMapping {
    [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:@[@"load", @"/System/Library/LaunchAgents/com.apple.rcd.plist"]];
    [NSEvent removeMonitor:self.eventMonitor];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HiddenWhenDisconnected"] && self.state != PSAskingStateConnected) {
        self.showUntilDate = CFAbsoluteTimeGetCurrent() + 30.;
        [self updateStatusItem];
        [self.statusItem popUpStatusItemMenu:self.statusItem.menu];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (31 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateStatusItem];
        });
    }
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupStatusItem];
    [IOBluetoothDevice registerForConnectNotifications:self selector:@selector(connected:fromDevice:)];
}

- (void)setupStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [self updateStatusItem];
    self.statusItem.highlightMode = YES;
    NSMenu *myMenu = [[NSMenu alloc] initWithTitle:@"Test"];
    myMenu.delegate = self;
    self.statusItem.menu = myMenu;
    if ([self.statusItem respondsToSelector:@selector(button)]) {
        self.statusItem.button.appearsDisabled = YES;
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    if (loginItems) {
        [self disableLoginItemWithLoginItemsReference:loginItems forPath:appPath];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MapMediaKeys"]) {
        [self disableMediaKeyMapping];
    }
}

- (void)updateStatusItem {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HiddenWhenDisconnected"]) {
        if (self.state != PSAskingStateConnected && self.showUntilDate < CFAbsoluteTimeGetCurrent()) {
            [self.statusItem.statusBar removeStatusItem:self.statusItem];
            self.statusItem = nil;
            return;
        }
        else {
            if (self.statusItem == nil) {
                [self setupStatusItem];
            }
        }
    }
    NSImage *image = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBatteryIcon"]) {
        CGFloat imageWidth = (self.state == PSAskingStateConnected) ? 22 : 16;
        image = [NSImage imageWithSize:NSMakeSize(imageWidth, 16) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
            [[NSColor colorWithDeviceWhite:0.0 alpha:0.9] set];
            NSBezierPath *headset = [NSBezierPath bezierPath];
            [headset moveToPoint:NSMakePoint(1.5, 4.5)];
            [headset curveToPoint:NSMakePoint(9.5, 4.5) controlPoint1:NSMakePoint(4.5, 16.5) controlPoint2:NSMakePoint(6.5, 16.5)];
            [headset appendBezierPathWithOvalInRect:NSMakeRect(1.5, 0.5, 2, 6)];
            [headset appendBezierPathWithOvalInRect:NSMakeRect(7.5, 0.5, 2, 6)];
            [headset setLineWidth:2.5];
            [headset stroke];
            if (self.state == PSAskingStateConnected) {
                [[NSColor blackColor] set];
                NSRect batteryRect = NSMakeRect(11.5, 0.5, 6, 13);
                [[NSBezierPath bezierPathWithRect:batteryRect] stroke];
                [[NSBezierPath bezierPathWithRect:NSMakeRect(NSMidX(batteryRect) - 2., NSMaxY(batteryRect), 4., 2.)] fill];
                batteryRect = NSInsetRect(batteryRect, 1, 1);

                if (self.isBatteryCharging) {
                    NSRect lightningRect = NSInsetRect(batteryRect, 1, 1);
                    NSBezierPath *lightning = [NSBezierPath bezierPath];
                    [lightning moveToPoint:NSMakePoint(NSMaxX(lightningRect), NSMaxY(lightningRect))];
                    [lightning lineToPoint:NSMakePoint(NSMinX(lightningRect), NSMidY(lightningRect) - 1.)];
                    [lightning lineToPoint:NSMakePoint(NSMaxX(lightningRect), NSMidY(lightningRect) + 1.)];
                    [lightning lineToPoint:NSMakePoint(NSMinX(lightningRect), NSMinY(lightningRect))];
                    [lightning stroke];
                }


                batteryRect.size.height *= ((CGFloat) self.batteryLevel) / 100.0;
                [[NSBezierPath bezierPathWithRect:batteryRect] fill];
            }
            //		NSRectFill(dstRect);
            return YES;
        }];
        [image setTemplate:YES];
    }
    else {
        image = nil;
    }
    if ([self.statusItem respondsToSelector:@selector(button)]) {
        self.statusItem.button.image = image;
    }
    else {
        self.statusItem.image = image;
    }

    NSString *title = nil;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBatteryPercentage"]) {
        if (self.state == PSAskingStateConnected) {
            title = self.isBatteryCharging ? [NSString stringWithFormat:NSLocalizedString(@"Charging (%i%%)", @""), self.batteryLevel] : [NSString stringWithFormat:NSLocalizedString(@"%i%%", @""), self.batteryLevel];
        }
        else {
            title = NSLocalizedString(@"-", @"");
        }
        self.statusItem.length = NSVariableStatusItemLength;
    }
    else {
        title = nil;
        self.statusItem.length = NSSquareStatusItemLength;
    }

    if ([self.statusItem respondsToSelector:@selector(button)]) {
        self.statusItem.title = title;
        self.statusItem.button.appearsDisabled = self.state != PSAskingStateConnected;
        self.statusItem.button.imagePosition = NSImageRight;
    }
    else {
        self.statusItem.title = title;
        self.statusItem.enabled = self.state == PSAskingStateConnected;
    }
}

CGEventRef modifiersChanged(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (CGEventGetType(event) != kCGEventFlagsChanged) {
        return NULL;
    }
    AppDelegate *myself = (__bridge AppDelegate *) (refcon);
    [myself menuNeedsUpdate:myself.statusItem.menu event:[NSEvent eventWithCGEvent:event]];
    [myself.statusItem.menu update];
    return NULL;
}

- (void)menuWillOpen:(NSMenu *)menu {
    self.eventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, CGEventMaskBit(kCGEventFlagsChanged), &modifiersChanged, (__bridge void *) (self));
    CFRunLoopSourceRef eventSrc = CFMachPortCreateRunLoopSource(NULL, self.eventTap, 0);
    if (eventSrc) {
        CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], eventSrc, kCFRunLoopCommonModes);
        CFRelease(eventSrc);
        CGEventTapEnable(self.eventTap, true);
    }
}

- (void)menuDidClose:(NSMenu *)menu {
    CGEventTapEnable(self.eventTap, false);
    self.eventTap = NULL;
}

- (void)menuNeedsUpdate:(NSMenu *)menu event:(NSEvent *)event {
    [menu removeAllItems];
    if (self.state == PSAskingStateConnected) {
        [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Connected to %@", @""), self.name] action:NULL keyEquivalent:@""];
        [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Version %@", @""), self.version] action:NULL keyEquivalent:@""];
        NSMenuItem *batteryMenuItem = nil;
        NSMenu *batteryMenu = [[NSMenu alloc] initWithTitle:@""];
        if (self.isBatteryCharging) {
            batteryMenuItem = [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Battery level: Charging (%i%%)", @""), self.batteryLevel] action:NULL keyEquivalent:@""];
        }
        else {
            batteryMenuItem = [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Battery level: %i%%", @""), self.batteryLevel] action:NULL keyEquivalent:@""];
        }
        batteryMenuItem.submenu = batteryMenu;

        BOOL showBatteryPercentage = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBatteryPercentage"];
        BOOL showBatteryIcon = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBatteryIcon"];

        [[batteryMenu addItemWithTitle:NSLocalizedString(@"Show Battery Icon Only", @"") action:@selector(showBatteryIconOnly:) keyEquivalent:@""] setState:(showBatteryIcon && !showBatteryPercentage) ? NSOnState : NSOffState];
        [[batteryMenu addItemWithTitle:NSLocalizedString(@"Show Battery Icon And Percentage", @"") action:@selector(showBatteryIconAndText:) keyEquivalent:@""] setState:(showBatteryIcon && showBatteryPercentage) ? NSOnState : NSOffState];
        [[batteryMenu addItemWithTitle:NSLocalizedString(@"Show Battery Percentage Only", @"") action:@selector(showBatteryTextOnly:) keyEquivalent:@""] setState:(!showBatteryIcon && showBatteryPercentage) ? NSOnState : NSOffState];

        [menu addItem:[NSMenuItem separatorItem]];

        [[menu addItemWithTitle:NSLocalizedString(@"Noise control", @"") action:@selector(toggleNoiseCancellation:) keyEquivalent:@""] setState:self.noiseControlEnabled ? NSOnState : NSOffState];
        NSMenuItem *noiseControlMenuItem = nil;
        noiseControlMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Noise control Settings", @"") action:NULL keyEquivalent:@""];
        NSMenu *noiseControlMenu = [[NSMenu alloc] initWithTitle:@""];
        noiseControlMenuItem.enabled = self.noiseControlEnabled;
        noiseControlMenuItem.submenu = noiseControlMenu;
        [[noiseControlMenu addItemWithTitle:NSLocalizedString(@"Noise Cancelling (max)", @"") action:@selector(setNoiseCancellingMax:) keyEquivalent:@""] setState:self.noiseControlState == NOISE_CONTROL_NOISE_CANCELLING_MAX ? NSOnState : NSOffState];
        [[noiseControlMenu addItemWithTitle:NSLocalizedString(@"Noise Cancelling", @"") action:@selector(setNoiseCancelling:) keyEquivalent:@""] setState:self.noiseControlState == NOISE_CONTROL_NOISE_CANCELLING ? NSOnState : NSOffState];
//        [[noiseControlMenu addItemWithTitle:NSLocalizedString(@"Off", @"") action:@selector(setNoiseCancellingOff:) keyEquivalent:@""] setState:self.noiseControlState == NOISE_CONTROL_OFF ? NSOnState : NSOffState];
        [[noiseControlMenu addItemWithTitle:NSLocalizedString(@"Street mode", @"") action:@selector(setStreetMode:) keyEquivalent:@""] setState:self.noiseControlState == NOISE_CONTROL_STREET_MODE ? NSOnState : NSOffState];
        [[noiseControlMenu addItemWithTitle:NSLocalizedString(@"Street mode (max)", @"") action:@selector(setStreetModeMax:) keyEquivalent:@""] setState:self.noiseControlState == NOISE_CONTROL_STREET_MODE_MAX ? NSOnState : NSOffState];


        [menu addItem:[NSMenuItem separatorItem]];

        NSMenuItem *presetsMenuItem = nil;
        presetsMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Presets", @"") action:NULL keyEquivalent:@""];
        NSMenu *presetsMenu = [[NSMenu alloc] initWithTitle:@""];
        presetsMenuItem.enabled = self.presetCounter > 0;
        presetsMenuItem.submenu = presetsMenu;
        for (int i = 0; i < self.presetCounter; ++i) {
            [[presetsMenu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Preset %i", @""), i + 1] action:@selector(selectPreset:) keyEquivalent:@""] setState:self.currentPresetId == i + 1 ? NSOnState : NSOffState];
        }

        [menu addItem:[NSMenuItem separatorItem]];

        [[menu addItemWithTitle:NSLocalizedString(@"Equalizer", @"") action:@selector(toggleEqualizer:) keyEquivalent:@""] setState:self.equalizerEnabled ? NSOnState : NSOffState];
        [[menu addItemWithTitle:NSLocalizedString(@"Bluetooth auto-connection", @"") action:@selector(toggleAutoConnect:) keyEquivalent:@""] setState:self.autoConnectionEnabled ? NSOnState : NSOffState];
        [[menu addItemWithTitle:NSLocalizedString(@"Presence sensor", @"") action:@selector(toggleHeadDetection:) keyEquivalent:@""] setState:self.headDetectionEnabled ? NSOnState : NSOffState];
        [[menu addItemWithTitle:NSLocalizedString(@"Concert hall mode", @"") action:@selector(toggleConcertHall:) keyEquivalent:@""] setState:self.concertHallEnabled ? NSOnState : NSOffState];

        [menu addItem:[NSMenuItem separatorItem]];
        [[menu addItemWithTitle:NSLocalizedString(@"Touch control support for all Apps", @"") action:@selector(toggleMediaKeys:) keyEquivalent:@""] setState:[[NSUserDefaults standardUserDefaults] boolForKey:@"MapMediaKeys"] ? NSOnState : NSOffState];
    }
    else {
        NSMenuItem *notConnected = [menu addItemWithTitle:NSLocalizedString(@"Not connected", @"") action:NULL keyEquivalent:@""];
        notConnected.submenu = [[NSMenu alloc] initWithTitle:@""];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HiddenWhenDisconnected"]) {
            [notConnected.submenu addItemWithTitle:NSLocalizedString(@"Show when disconnected", @"") action:@selector(showWhenDisconnected:) keyEquivalent:@""];
        }
        else {
            [notConnected.submenu addItemWithTitle:NSLocalizedString(@"Hide when disconnected", @"") action:@selector(hideWhenDisconnected:) keyEquivalent:@""];
        }
    }
    if ([event modifierFlags] & NSAlternateKeyMask) {
        [menu addItemWithTitle:NSLocalizedString(@"Battery notifications…", @"") action:@selector(showAdvancedBatteryOptions:) keyEquivalent:@""];
    }
    else {
        [[menu addItemWithTitle:NSLocalizedString(@"Battery notifications", @"") action:@selector(toogleBatteryNotifications:) keyEquivalent:@""] setState:[[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBatteryNotifications"] ? NSOnState : NSOffState];
    }

    [menu addItem:[NSMenuItem separatorItem]];
    if ([event modifierFlags] & NSAlternateKeyMask) {
        NSMenuItem *checkForUpdates = [menu addItemWithTitle:NSLocalizedString(@"Check For Updates…", @"") action:@selector(about:) keyEquivalent:@""];
        [checkForUpdates setTarget:self.updater];
        [checkForUpdates setAction:@selector(checkForUpdates:)];
    }
    else {
        [menu addItemWithTitle:NSLocalizedString(@"About", @"") action:@selector(about:) keyEquivalent:@""];
    }

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:NSLocalizedString(@"Quit", @"") action:@selector(terminate:) keyEquivalent:@""];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [self menuNeedsUpdate:menu event:[NSApp currentEvent]];
}

#pragma mark -
#pragma mark IOBluetoothUserNotification

static NSArray *uuidServices = nil;
static NSArray *uuidServicesZik2 = nil;

- (void)connected:(IOBluetoothUserNotification *)note fromDevice:(IOBluetoothDevice *)device {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //0ef0f502-f0ee-46c9-986c-54ed027807fb Zik 1
        //8b6814d3-6ce7-4498-9700-9312c1711f63 Zik 2
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"0ef0f502-f0ee-46c9-986c-54ed027807fb"];
        uuid_t uuidbuf;
        [uuid getUUIDBytes:uuidbuf];
        IOBluetoothSDPUUID *uuidBlutooth = [IOBluetoothSDPUUID uuidWithBytes:uuidbuf length:16];
        uuidServices = @[uuidBlutooth];

        NSUUID *uuidZik2 = [[NSUUID alloc] initWithUUIDString:@"8b6814d3-6ce7-4498-9700-9312c1711f63"];
        uuid_t uuidZik2buf;
        [uuidZik2 getUUIDBytes:uuidZik2buf];
        IOBluetoothSDPUUID *uuidZik2Blutooth = [IOBluetoothSDPUUID uuidWithBytes:uuidZik2buf length:16];
        uuidServicesZik2 = @[uuidZik2Blutooth];
    });
    NSArray *services = device.services;
    for (IOBluetoothSDPServiceRecord *service in services) {
        if ([service matchesUUIDArray:uuidServices]
                || [service matchesUUIDArray:uuidServicesZik2]) {
            IOReturn res = [service getRFCOMMChannelID:&channelId];
            if (res != kIOReturnSuccess) {
                NSLog(@"Failed to connect to %@", device.nameOrAddress);
            }
            else {
                NSLog(@"Connected to %@", device.nameOrAddress);
                IOBluetoothRFCOMMChannel *rfCommChannel;
                res = [device openRFCOMMChannelSync:&rfCommChannel withChannelID:channelId delegate:self];
                self.mRfCommChannel = rfCommChannel;
                NSAssert(res == kIOReturnSuccess, @"Failed to open channel");
                unsigned char buffer[] = {0x00, 0x03, 0x00};
                self.state = PSAskingStateInit;
                res = [rfCommChannel writeSync:buffer length:3];
                NSAssert(res == kIOReturnSuccess, @"Failed to send init");
                [device registerForDisconnectNotification:self selector:@selector(disconnected:fromDevice:)];
            }
        }
    }
}

- (void)disconnected:(IOBluetoothUserNotification *)note fromDevice:(IOBluetoothDevice *)device {
    NSArray *services = device.services;
    for (IOBluetoothSDPServiceRecord *service in services) {
        if ([service matchesUUIDArray:uuidServices]
                || [service matchesUUIDArray:uuidServicesZik2]) {
            NSLog(@"Disconnected from %@", device.nameOrAddress);
            self.state = PSAskingStateInit;
            [self updateStatusItem];
        }
    }
}

- (void)sendRequest:(NSString *)request {
    NSString *requestString = request;
    NSMutableData *requestData = [NSMutableData data];
    NSUInteger buffer = 0;
    [requestData appendBytes:&buffer length:1];
    buffer = [requestString lengthOfBytesUsingEncoding:NSASCIIStringEncoding] + 3;
    [requestData appendBytes:&buffer length:1];
    buffer = 0x80;
    [requestData appendBytes:&buffer length:1];
    [requestData appendData:[requestString dataUsingEncoding:NSASCIIStringEncoding]];
//	IOReturn res = [mRfCommChannel writeSync:(void *)[requestData bytes] length:[requestData length]];
    IOReturn res = [self.mRfCommChannel writeAsync:(void *) [requestData bytes] length:(UInt16) [requestData length] refcon:NULL];
    NSAssert(res == kIOReturnSuccess, @"Failed to send %@", request);
}

- (void)handleAnswer:(NSXMLDocument *)xmlDocument {
    NSString *path = [[[xmlDocument rootElement] attributeForName:@"path"] stringValue];
//	NSLog(@"answer for path:%@ : %@",path,xmlDocument);
    if ([path isEqualToString:SOFTWARE_VERSION_SIP6_GET]) {
        self.version = [[[[xmlDocument nodesForXPath:@"//software" error:NULL] lastObject] attributeForName:@"version"] stringValue];
        if (self.version == nil)
            //Zik 2
            self.version = [[[[xmlDocument nodesForXPath:@"//software" error:NULL] lastObject] attributeForName:@"sip6"] stringValue];
    }
    else if ([path isEqualToString:FRIENDLY_NAME_GET]) {
        self.name = [[[[xmlDocument nodesForXPath:@"//bluetooth" error:NULL] lastObject] attributeForName:@"friendlyname"] stringValue];
    }
    else if ([path isEqualToString:BATTERY_GET]) {
        int newBatteryLevel = [[[[[xmlDocument nodesForXPath:@"//battery" error:NULL] lastObject] attributeForName:@"level"] stringValue] intValue];
        if (newBatteryLevel == '\0')
            //Zik 2
            newBatteryLevel = [[[[[xmlDocument nodesForXPath:@"//battery" error:NULL] lastObject] attributeForName:@"percent"] stringValue] intValue];
        self.isBatteryCharging = [[[[[xmlDocument nodesForXPath:@"//battery" error:NULL] lastObject] attributeForName:@"state"] stringValue] isEqualToString:@"charging"];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBatteryNotifications"] && !self.isBatteryCharging) {
            NSUserNotification *userNotification = nil;
            NSArray *notificationLevels = [[NSUserDefaults standardUserDefaults] arrayForKey:@"BatteryNotificationLevels"];
            NSMutableArray *sortedNotificationLevels = [NSMutableArray array];
            for (NSString *currentLevel in notificationLevels) {
                [sortedNotificationLevels addObject:@([currentLevel intValue])];
            }
            [sortedNotificationLevels sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [obj2 compare:obj1];
            }];
            for (NSString *currentLevel in sortedNotificationLevels) {
                if (self.batteryLevel > [currentLevel intValue] && newBatteryLevel <= [currentLevel intValue]) {
                    userNotification = [[NSUserNotification alloc] init];
                    userNotification.title = NSLocalizedString(@"Parrot Zik Battery Notification", @"");
                    userNotification.subtitle = [NSString stringWithFormat:NSLocalizedString(@"%i%% of battery remaining", @""), [currentLevel intValue]];
                    break;
                }
            }
            if (!userNotification && [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBatteryAboutToDieNotifications"] && self.batteryLevel >= 2 && newBatteryLevel < 2) {
                userNotification = [[NSUserNotification alloc] init];
                userNotification.title = NSLocalizedString(@"Parrot Zik Battery Low", @"");
                userNotification.subtitle = NSLocalizedString(@"Recharge the battery soon", @"");
            }

            if ((self.batteryLevel == 100 && newBatteryLevel == 0) || (newBatteryLevel > self.batteryLevel)) {
                userNotification = nil; // Fix wrong notification when disconnecting recharge cable
            }

            if (userNotification) {
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
            }
        }

        self.batteryLevel = newBatteryLevel;
        [self updateStatusItem];
    }
    else if ([path isEqualToString:AUDIO_PRESET_CURRENT_GET]) {
        NSArray *node = [xmlDocument nodesForXPath:@"//preset" error:NULL];
        NSString *presetId = [[[[xmlDocument nodesForXPath:@"//preset" error:NULL] lastObject] attributeForName:@"id"] stringValue];
        self.currentPresetId = [presetId integerValue];
    }
    else if ([path isEqualToString:AUDIO_PRESET_COUNTER_GET]) {
        NSArray *node = [xmlDocument nodesForXPath:@"//preset" error:NULL];
        NSString *counter = [[[[xmlDocument nodesForXPath:@"//preset" error:NULL] lastObject] attributeForName:@"counter"] stringValue];
        self.presetCounter = [counter integerValue];
    }
    else if ([path isEqualToString:SYSTEM_AUTO_POWER_OFF_LIST_GET]) {
        NSArray *node = [xmlDocument nodesForXPath:@"//auto_power_off" error:NULL];
        NSString *type = [[[[xmlDocument nodesForXPath:@"//preset" error:NULL] lastObject] attributeForName:@"type"] stringValue];
    }
    else if ([path isEqualToString:NOISE_CONTROL_GET]) {
        NSArray *node = [xmlDocument nodesForXPath:@"//noise_control" error:NULL];
        NSString *type = [[[[xmlDocument nodesForXPath:@"//noise_control" error:NULL] lastObject] attributeForName:@"type"] stringValue];
        NSString *value = [[[[xmlDocument nodesForXPath:@"//noise_control" error:NULL] lastObject] attributeForName:@"value"] stringValue];
        if ([type isEqualToString:@"anc"] && [value isEqualToString:@"2"]) {
            self.noiseControlState = NOISE_CONTROL_NOISE_CANCELLING_MAX;
        } else if ([type isEqualToString:@"anc"] && [value isEqualToString:@"1"]) {
            self.noiseControlState = NOISE_CONTROL_NOISE_CANCELLING;
        } else if ([type isEqualToString:@"off"]) {
            self.noiseControlState = NOISE_CONTROL_OFF;
        } else if ([type isEqualToString:@"aoc"] && [value isEqualToString:@"1"]) {
            self.noiseControlState = NOISE_CONTROL_STREET_MODE;
        } else if ([type isEqualToString:@"aoc"] && [value isEqualToString:@"2"]) {
            self.noiseControlState = NOISE_CONTROL_STREET_MODE_MAX;
        } else {
            NSLog(@"Unknown NC state: type:%@ value:%@", type, value);
        }
    }
    else if ([path isEqualToString:NOISE_CONTROL_ENABLED_GET]) {
        self.noiseControlEnabled = [[[[[xmlDocument nodesForXPath:@"//noise_control" error:NULL] lastObject] attributeForName:@"enabled"] stringValue] isEqualToString:@"true"];
    }
    else if ([path isEqualToString:EQUALIZER_ENABLED_GET]) {
        self.equalizerEnabled = [[[[[xmlDocument nodesForXPath:@"//equalizer" error:NULL] lastObject] attributeForName:@"enabled"] stringValue] isEqualToString:@"true"];
    }
    else if ([path isEqualToString:SYSTEM_AUTO_CONNECTION_GET]) {
        self.autoConnectionEnabled = [[[[[xmlDocument nodesForXPath:@"//auto_connection" error:NULL] lastObject] attributeForName:@"enabled"] stringValue] isEqualToString:@"true"];
    }
    else if ([path isEqualToString:SYSTEM_HEAD_DETECTION_ENABLED_GET]) {
        self.headDetectionEnabled = [[[[[xmlDocument nodesForXPath:@"//head_detection" error:NULL] lastObject] attributeForName:@"enabled"] stringValue] isEqualToString:@"true"];
    }
    else if ([path isEqualToString:CONCERT_HALL_ENABLED_GET]) {
        self.concertHallEnabled = [[[[[xmlDocument nodesForXPath:@"//sound_effect" error:NULL] lastObject] attributeForName:@"enabled"] stringValue] isEqualToString:@"true"];
    }
    else if ([path hasSuffix:@"/set?arg"]) {}
    else {
        NSLog(@"Unknown answer : %@ %@ ", path, xmlDocument);
    }
    [self menuNeedsUpdate:self.statusItem.menu];
    [self.statusItem.menu update];
}

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength {
    NSData *data = [NSData dataWithBytes:dataPointer length:dataLength];
    UInt16 messageLen = 0;
    [data getBytes:&messageLen range:NSMakeRange(0, 2)];
    unsigned char magic = 0;
    [data getBytes:&magic range:NSMakeRange(2, 1)];
    switch (magic) {
        case 128: {
            NSData *xmlData = nil;
            if (data.length > 7)
                xmlData = [data subdataWithRange:NSMakeRange(7, [data length] - 7)];
            NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithData:xmlData options:0 error:NULL];
            NSString *rootName = [[xmlDocument rootElement] name];
            if ([rootName isEqualToString:@"answer"]) {
                [self handleAnswer:xmlDocument];
            }
            else if ([rootName isEqualToString:@"notify"]) {
                NSString *path = [[[xmlDocument rootElement] attributeForName:@"path"] stringValue];
                [self sendRequest:[NSString stringWithFormat:@"GET %@", path]];
            }
            else {
                NSLog(@"Unknown callback %@", xmlDocument);
            }
            break;
        }
        default:
            if (self.state == PSAskingStateInit) {
                self.state = PSAskingStateConnected;
                unsigned char buffer[] = {0x00, 0x03, 0x02};
                BOOL success = [data isEqualToData:[NSData dataWithBytes:buffer length:3]];
                NSAssert(success, @"Received unknown init data");
                [self sendRequest:GET(SOFTWARE_VERSION_SIP6_GET)];
                [self sendRequest:GET(FRIENDLY_NAME_GET)];
                [self sendRequest:GET(BATTERY_GET)];
                [self sendRequest:GET(AUDIO_PRESET_CURRENT_GET)];
                [self sendRequest:GET(AUDIO_PRESET_COUNTER_GET)];
                [self sendRequest:GET(SYSTEM_AUTO_POWER_OFF_LIST_GET)];
                [self sendRequest:GET(NOISE_CONTROL_ENABLED_GET)];
                [self sendRequest:GET(NOISE_CONTROL_GET)];
                [self sendRequest:GET(EQUALIZER_ENABLED_GET)];
                [self sendRequest:GET(SYSTEM_HEAD_DETECTION_ENABLED_GET)];
                [self sendRequest:GET(SYSTEM_AUTO_CONNECTION_GET)];
                [self sendRequest:GET(CONCERT_HALL_ENABLED_GET)];
            }
            break;
    }
}

//- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error {
//	NSLog(@"%s",__FUNCTION__);
//}
//- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel {
//	NSLog(@"%s",__FUNCTION__);
//}
//- (void)rfcommChannelControlSignalsChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel {
//	NSLog(@"%s",__FUNCTION__);
//}
//- (void)rfcommChannelFlowControlChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel {
//	NSLog(@"%s",__FUNCTION__);
//}
//- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error {
//	NSLog(@"%s",__FUNCTION__);
//}
//- (void)rfcommChannelQueueSpaceAvailable:(IOBluetoothRFCOMMChannel*)rfcommChannel {
//	NSLog(@"%s",__FUNCTION__);
//}

#pragma mark NSTokenField delegate

// For advanced battery settings
- (NSArray *)tokenField:(NSTokenField *)tokenField
       shouldAddObjects:(NSArray *)tokens
                atIndex:(NSUInteger)index {
    NSMutableArray *validatedTokens = [NSMutableArray array];
    NSArray *notificationLevels = [[NSUserDefaults standardUserDefaults] arrayForKey:@"BatteryNotificationLevels"];
    for (NSString *currentToken in tokens) {
        int currentIntValue = [currentToken intValue];
        if (currentIntValue <= 2 || currentIntValue > 99) {
            NSBeep();
            continue;
        }
        NSString *newValue = [NSString stringWithFormat:@"%i%%", currentIntValue];
        if ([notificationLevels containsObject:newValue]) {
            NSBeep();
            continue;
        }
        if ([validatedTokens containsObject:newValue]) {
            NSBeep();
            continue;
        }
        [validatedTokens addObject:newValue];
    }
    return validatedTokens;
}

#pragma mark Actions

- (IBAction)toogleBatteryNotifications:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:![userDefaults boolForKey:@"ShowBatteryNotifications"] forKey:@"ShowBatteryNotifications"];
}

- (void)toggleMediaKeys:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:![userDefaults boolForKey:@"MapMediaKeys"] forKey:@"MapMediaKeys"];
    if ([userDefaults boolForKey:@"MapMediaKeys"]) {
        [self setupMediaKeyMapping];
    }
    else {
        [self disableMediaKeyMapping];
    }
}

- (IBAction)toggleNoiseCancellation:(id)sender {
    [self sendRequest:SET(NOISE_CONTROL_ENABLED_SET, self.noiseControlEnabled ? @"false" : @"true")];
    [self sendRequest:GET(NOISE_CONTROL_ENABLED_GET)];
}

- (IBAction)setNoiseCancellingMax:(id)sender {
    [self sendRequest:SET(NOISE_CONTROL_SET, @"anc&value=2")];
    [self sendRequest:GET(NOISE_CONTROL_GET)];
}

- (IBAction)setNoiseCancelling:(id)sender {
    [self sendRequest:SET(NOISE_CONTROL_SET, @"anc&value=1")];
    [self sendRequest:GET(NOISE_CONTROL_GET)];
}

- (IBAction)setNoiseCancellingOff:(id)sender {
    [self sendRequest:SET(NOISE_CONTROL_SET, @"off&value=0")];
    [self sendRequest:GET(NOISE_CONTROL_GET)];
}

- (IBAction)setStreetMode:(id)sender {
    [self sendRequest:SET(NOISE_CONTROL_SET, @"aoc&value=1")];
    [self sendRequest:GET(NOISE_CONTROL_GET)];
}

- (IBAction)setStreetModeMax:(id)sender {
    [self sendRequest:SET(NOISE_CONTROL_SET, @"aoc&value=2")];
    [self sendRequest:GET(NOISE_CONTROL_GET)];
}

- (IBAction)selectPreset:(id)sender {
    NSMenuItem *menuItem = sender;
    NSString *presetIndex = [menuItem.title componentsSeparatedByString:@" "][1];
    NSString *parameters = [NSString stringWithFormat:@"?id=%@&enable=1",presetIndex];
    [self sendRequest:[NSString stringWithFormat:@"%@%@", AUDIO_PRESET_ACTIVATE, parameters]];
    [self sendRequest:GET(AUDIO_PRESET_CURRENT_GET)];
}

- (IBAction)toggleEqualizer:(id)sender {
    [self sendRequest:SET(EQUALIZER_ENABLED_SET, self.equalizerEnabled ? @"false" : @"true")];
    [self sendRequest:GET(EQUALIZER_ENABLED_GET)];
}

- (IBAction)toggleHeadDetection:(id)sender {
    [self sendRequest:SET(SYSTEM_HEAD_DETECTION_ENABLED_SET, self.headDetectionEnabled ? @"false" : @"true")];
    [self sendRequest:GET(SYSTEM_HEAD_DETECTION_ENABLED_GET)];
}

- (IBAction)toggleAutoConnect:(id)sender {
    [self sendRequest:SET(SYSTEM_AUTO_CONNECTION_SET, self.autoConnectionEnabled ? @"false" : @"true")];
    [self sendRequest:GET(SYSTEM_AUTO_CONNECTION_GET)];
}

- (IBAction)toggleConcertHall:(id)sender {
    [self sendRequest:SET(CONCERT_HALL_ENABLED_SET, self.concertHallEnabled ? @"false" : @"true")];
    [self sendRequest:GET(CONCERT_HALL_ENABLED_GET)];
}

- (IBAction)about:(id)sender {
    [NSApp orderFrontStandardAboutPanel:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showAdvancedBatteryOptions:(id)sender {
    [self.advancedBatteryWindow makeKeyAndOrderFront:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showBatteryIconOnly:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowBatteryPercentage"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowBatteryIcon"];
    [self updateStatusItem];
}

- (IBAction)showBatteryIconAndText:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowBatteryPercentage"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowBatteryIcon"];
    [self updateStatusItem];
}

- (IBAction)showBatteryTextOnly:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowBatteryPercentage"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowBatteryIcon"];
    [self updateStatusItem];
}

- (IBAction)hideWhenDisconnected:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Parrot Status will be hidden when device is disconnected", @"");
    alert.informativeText = NSLocalizedString(@"To show menu when the device is disconnected, you will have to launch the app again.", @"");
    [alert addButtonWithTitle:NSLocalizedString(@"Hide", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    NSModalResponse response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HiddenWhenDisconnected"];
        [self updateStatusItem];
    }
}

- (IBAction)showWhenDisconnected:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"HiddenWhenDisconnected"];
    [self updateStatusItem];
}

@end


@implementation AppDelegate (SharedFileListExample)
// See https://github.com/justin/Shared-File-List-Example/blob/master/Controller.m

/*
 
 The MIT License
 
 Copyright (c) 2010 Justin Williams, Second Gear
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */


- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString *)appPath {
    // We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
    CFURLRef url = (__bridge CFURLRef) [NSURL fileURLWithPath:appPath];
    LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
    if (item) {
        CFRelease(item);
    }
}

- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString *)appPath {
    UInt32 seedValue;
    CFURLRef thePath = NULL;
    // We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
    // and pop it in an array so we can iterate through it to find our item.
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
    for (id item in (__bridge NSArray *) loginItemsArray) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef) item;
        if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef *) &thePath, NULL) == noErr) {
            if ([[(__bridge NSURL *) thePath path] hasPrefix:appPath]) {
                LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
            }
            // Docs for LSSharedFileListItemResolve say we're responsible
            // for releasing the CFURLRef that is returned
            if (thePath != NULL) {
                CFRelease(thePath);
            }
        }
    }
    if (loginItemsArray != NULL) {
        CFRelease(loginItemsArray);
    }
}

- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs forPath:(NSString *)appPath {
    BOOL found = NO;
    UInt32 seedValue;
    CFURLRef thePath = NULL;

    // We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
    // and pop it in an array so we can iterate through it to find our item.
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
    for (id item in (__bridge NSArray *) loginItemsArray) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef) item;
        if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef *) &thePath, NULL) == noErr) {
            if ([[(__bridge NSURL *) thePath path] hasPrefix:appPath]) {
                found = YES;
                break;
            }
            // Docs for LSSharedFileListItemResolve say we're responsible
            // for releasing the CFURLRef that is returned
            if (thePath != NULL) {
                CFRelease(thePath);
            }
        }
    }
    if (loginItemsArray != NULL) {
        CFRelease(loginItemsArray);
    }

    return found;
}

@end
