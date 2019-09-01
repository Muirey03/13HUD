#import "13HUD.h"
#import "MRYHUDView.h"

#define screenHeight [UIScreen mainScreen].bounds.size.height
#define screenWidth [UIScreen mainScreen].bounds.size.width
#define animDuration 0.2

//prefs:
#define kUseCustomYPadding PreferencesBool(@"kUseCustomYPadding", NO)
#define kYPadding PreferencesFloat(@"kYPadding", 75.)
#define kUseCustomHeight PreferencesBool(@"kUseCustomHeight", NO)
#define kHeight PreferencesFloat(@"kHeight", 150.)
#define kWidth PreferencesFloat(@"kWidth", 50.)
#define kHideRinger PreferencesBool(@"kHideRinger", NO)
#define dismissDelay PreferencesFloat(@"kTimeout", 1.5)
#define collapseDelay PreferencesFloat(@"kCollapseTimeout", 1.)

#define HUDXPadding 15.
#define HUDHeightMultiplier 0.22
#define HUDYMultiplier 0.22
#define HUDCollapsedWidth 12.
CGRect expandedFrame()
{
	UIInterfaceOrientation orientation = [(SpringBoard*)[UIApplication sharedApplication] activeInterfaceOrientation];
	BOOL landscape = UIInterfaceOrientationIsLandscape(orientation);

	CGFloat yPadding;
	CGFloat height;
	CGFloat xPadding = HUDXPadding;

	if (!landscape)
	{
		height = kUseCustomHeight ? kHeight : (screenHeight * HUDHeightMultiplier);
		yPadding = kUseCustomYPadding ? kYPadding : ((screenHeight * HUDYMultiplier) - (height / 2));
	}
	else
	{
		height = screenWidth * 1./3.;
		yPadding = (screenWidth - height) / 2;

		if (orientation == UIInterfaceOrientationLandscapeRight)
		{
			xPadding = screenHeight - kWidth - HUDXPadding;
		}
	}
	
	//round height to nearest multiple of 2
	height = round(height);
	if (((int)height % 2) != 0)
		height++;
	
	return CGRectMake(xPadding, yPadding, kWidth, height);
}
CGRect startFrame()
{
	CGRect f = expandedFrame();
	CGFloat xPosition = f.size.width * -1.;
	UIInterfaceOrientation orientation = [(SpringBoard*)[UIApplication sharedApplication] activeInterfaceOrientation];
	if (orientation == UIInterfaceOrientationLandscapeRight)
	{
		xPosition = screenWidth + f.size.width;
	}
	return CGRectMake(xPosition, f.origin.y, f.size.width, f.size.height);
}
CGRect collapsedFrame()
{
	CGRect f = expandedFrame();
	CGFloat xPosition = f.origin.x;
	UIInterfaceOrientation orientation = [(SpringBoard*)[UIApplication sharedApplication] activeInterfaceOrientation];
	if (orientation == UIInterfaceOrientationLandscapeRight)
	{
		xPosition = screenHeight - HUDXPadding - HUDCollapsedWidth;
	}
	return CGRectMake(xPosition, f.origin.y, HUDCollapsedWidth, f.size.height);
}

//prefs:
#define domain @"com.muirey03.13hud"
BOOL PreferencesBool(NSString* key, BOOL fallback)
{
	id val = [[NSUserDefaults standardUserDefaults] objectForKey:key inDomain:domain];
	return val ? [val boolValue] : fallback;
}
CGFloat PreferencesFloat(NSString* key, CGFloat fallback)
{
	id val = [[NSUserDefaults standardUserDefaults] objectForKey:key inDomain:domain];
	return val ? [val floatValue] : fallback;
}

%hook SBHUDController
%property (nonatomic, retain) MRYHUDView* mryHUD;
%property (nonatomic, retain) NSTimer* displayTimer;
%property (nonatomic, retain) NSTimer* collapseTimer;

-(void)presentHUDView:(UIView*)oldHUD autoDismissWithDelay:(double)delay
{
	if (![oldHUD isKindOfClass:%c(SBRingerHUDView)])
	{
		delay = dismissDelay;

		//hide old HUD:
		oldHUD.hidden = YES;
		%orig;

		//invalidate old timer:
		if (self.displayTimer)
		{
			[self.displayTimer invalidate];
			self.displayTimer = nil;
		}

		//create new hide timer:
		self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:delay
								target:self
								selector:@selector(hideMRYHUD)
								userInfo:nil repeats:NO];
		
		void (^collapseBlock)(void) = ^{
			[self.mryHUD collapseAnimated:YES];
		};

		//collapse after a certain time
		if (!self.collapseTimer.valid)
		{
			self.collapseTimer = [NSTimer scheduledTimerWithTimeInterval:collapseDelay
									target:collapseBlock
									selector:@selector(invoke)
									userInfo:nil repeats:NO];
		}

		[self showMRYHUD];
	}
	else
	{
		//remove old HUD:
		if (kHideRinger)
			oldHUD = nil;
		%orig;
	}
}

-(void)_tearDown
{
	self.mryHUD = nil;
	%orig;
}

//create a brand new HUD
%new
-(void)createMRYHUD
{
	if (self.mryHUD.superview)
		[self.mryHUD removeFromSuperview];

	//get HUD window:
	UIWindow* hudWindow = MSHookIvar<UIWindow*>(self, "_hudWindow");

	//create new HUD:
	self.mryHUD = [[MRYHUDView alloc] initWithFrame:startFrame()];
	[hudWindow addSubview:self.mryHUD];
}

//show the HUD (animated)
%new
-(void)showMRYHUD
{
	if (!self.mryHUD || self.mryHUD.hidden)
	{
		//create HUD if it doesn't already exist:
		[self createMRYHUD];

		[self.mryHUD expandAnimated:NO];
		self.mryHUD.hidden = NO;
		[UIView animateWithDuration:animDuration animations:^{
			self.mryHUD.frame = expandedFrame();
		}];
	}
}

//hide the HUD (animated)
%new
-(void)hideMRYHUD
{
	if (!self.mryHUD.hidden)
	{
		[UIView animateWithDuration:animDuration animations:^{
			self.mryHUD.frame = startFrame();
		} completion:^(BOOL finished){
			self.mryHUD.hidden = YES;
		}];
	}
}

//is showing the MRYHUD
%new
-(BOOL)isHUDVisible
{
	return self.mryHUD && !self.mryHUD.hidden;
}
%end

//allow touches:
%hook SBHUDWindow
-(BOOL)_ignoresHitTest
{
	return NO;
}

-(id)hitTest:(CGPoint)arg1 withEvent:(id)arg2
{
	MRYHUDView* mryHUD = ((SBHUDController*)[%c(SBHUDController) sharedHUDController]).mryHUD;
	if (CGRectContainsPoint(mryHUD.frame, arg1))
	{
		CGPoint p = [(UIWindow*)self convertPoint:arg1 toView:mryHUD];
        return [mryHUD hitTest:p withEvent:arg2];
    }
	return %orig;
}
%end

//override corner radius of fill layer:
void (*oldSetCornerRadius)(CCUIVolumeSliderView* self, SEL _cmd, CGFloat arg1);
void newSetCornerRadius(CCUIVolumeSliderView* self, SEL _cmd, CGFloat arg1)
{
	if ([self.window isKindOfClass:%c(SBHUDWindow)])
		arg1 = 0.;
	(*oldSetCornerRadius)(self, _cmd, arg1);
}

//stop HUD from collapsing when being changed:
void (*oldHandleValueChanged)(CCUIVolumeSliderView* self, SEL _cmd, id arg1);
void newHandleValueChanged(CCUIVolumeSliderView* self, SEL _cmd, id arg1)
{
	(*oldHandleValueChanged)(self, _cmd, arg1);
	if ([self.window isKindOfClass:%c(SBHUDWindow)])
		[[[%c(SBHUDController) sharedHUDController] collapseTimer] invalidate];
}

%ctor
{
	//load bundles:
	NSArray* bundles = @[
		@"/System/Library/ControlCenter/Bundles/AudioModule.bundle",
		@"/System/Library/PrivateFrameworks/ControlCenterUIKit.framework",
		@"/System/Library/PrivateFrameworks/ControlCenterServices.framework",
		@"/System/Library/PrivateFrameworks/ControlCenterUI.framework"
	];

	for (NSString* bundlePath in bundles)
	{
		NSBundle* bundle = [NSBundle bundleWithPath:bundlePath];
		if (!bundle.loaded)
			[bundle load];
	}
	
	%init;
	//I couldn't get logos to work, so let's do it manually
	MSHookMessageEx(%c(CCUIVolumeSliderView), @selector(setContinuousSliderCornerRadius:), (IMP)&newSetCornerRadius, (IMP*)&oldSetCornerRadius);
	MSHookMessageEx(%c(CCUIVolumeSliderView), @selector(_handleValueChangeGestureRecognizer:), (IMP)&newHandleValueChanged, (IMP*)&oldHandleValueChanged);
}