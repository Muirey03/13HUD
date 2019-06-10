#import "13HUD.h"
#import "MRYHUDView.h"

#define screenHeight [UIScreen mainScreen].bounds.size.height
#define animDuration 0.3
#define dismissDelay 1.5
#define collapseDelay 1.

//prefs:
#define kUseCustomYPadding PreferencesBool(@"kUseCustomYPadding", NO)
#define kYPadding PreferencesFloat(@"kYPadding", 75.)
#define kUseCustomHeight PreferencesBool(@"kUseCustomHeight", NO)
#define kHeight PreferencesFloat(@"kHeight", 150.)

#define HUDXPadding 15.
#define HUDHeightMultiplier 0.22
#define HUDYMultiplier 0.22
#define HUDWidth 60.
#define HUDCollapsedWidth 15.
CGRect expandedFrame()
{
	//round height to nearest multiple of 2
	CGFloat height = kUseCustomHeight ? kHeight : (screenHeight * HUDHeightMultiplier);
	height = round(height);
	if (((int)height % 2) != 0)
		height++;
	CGFloat yPadding = kUseCustomYPadding ? kYPadding : ((screenHeight * HUDYMultiplier) - ((screenHeight * HUDHeightMultiplier) / 2));
	return CGRectMake(HUDXPadding, yPadding, HUDWidth, height);
}
CGRect startFrame()
{
	CGRect f = expandedFrame();
	return CGRectMake(f.size.width * -1., f.origin.y, f.size.width, f.size.height);
}
CGRect collapsedFrame()
{
	CGRect f = expandedFrame();
	return CGRectMake(f.origin.x, f.origin.y, HUDCollapsedWidth, f.size.height);
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
		%orig;
	}
}

-(void)_tearDown
{
	self.mryHUD = nil;
	%orig;
}

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

%new
-(BOOL)isHUDVisible
{
	return !self.mryHUD.hidden;
}
%end

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

%ctor
{
	//load volume module:
	NSString* bundlePath = @"/System/Library/ControlCenter/Bundles/AudioModule.bundle";
	NSBundle* volumeBundle = [NSBundle bundleWithPath:bundlePath];
	if (!volumeBundle.loaded)
		[volumeBundle load];
	%init;
}