#import "13HUD.h"
#import "MRYHUDView.h"

#define expandedCornerRadius 17.
#define collapseAnimDuration 0.3

//stop slider overriding HUD:
%hook CCUIAudioModuleViewController
-(BOOL)isOnScreen
{
	if ([self.view.window isKindOfClass:%c(SBHUDWindow)])
		return NO;
	return %orig;
}
%end

//override corner radius of fill layer:
%hook CCUIVolumeSliderView
-(void)setContinuousSliderCornerRadius:(CGFloat)arg1
{
	if ([self.window isKindOfClass:%c(SBHUDWindow)])
		arg1 = 0.;
	%orig;
}

-(void)_handleValueChangeGestureRecognizer:(id)arg1
{
	%orig;
	if ([self.window isKindOfClass:%c(SBHUDWindow)])
		[[[%c(SBHUDController) sharedHUDController] collapseTimer] invalidate];
}
%end

//animate fill:
static BOOL finishedSetup = NO;
%hook CCUIContentModuleContext
+(void)performWithoutAnimationWhileHidden:(void(^)(void))arg1
{
	if (finishedSetup && [(SBHUDController*)[%c(SBHUDController) sharedHUDController] isHUDVisible])
	{
		arg1();
	}
	else
	{
		%orig;
	}
}
%end

//fix corner radius
%hook CABackdropLayer
-(void)setCornerRadius:(CGFloat)arg1
{
	UIView* owner = (UIView*)self.delegate;
	if ([owner.window isKindOfClass:%c(SBHUDWindow)] && [[owner _viewControllerForAncestor] isKindOfClass:%c(CCUIAudioModuleViewController)])
		arg1 = 0.;
	%orig;
}
%end

//stop PSUISoundsPrefController crashing out:
%hook SpringBoard
%new
-(id)rootController
{
	return [[UIApplication sharedApplication] keyWindow].rootViewController;
}
%end

//should volume buttons change ringtone?
BOOL useRingtoneCategory()
{
	return [[[%c(PSUISoundsPrefController) alloc] init] _canChangeRingtoneWithButtons];
}

@implementation MRYHUDView
{
	UIVisualEffectView* blurView;
}

-(instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		finishedSetup = NO;

		//start off hidden and expanded:
		self.hidden = YES;
		self.expanded = YES;

		//create container:
		self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
		self.containerView.clipsToBounds = YES;
		self.containerView.layer.continuousCorners = YES;

		//create blurred background for slider:
		UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
		blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		blurView.frame = self.containerView.bounds;
		blurView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[self.containerView addSubview:blurView];

		//create slider:
		self.audioModule = [[%c(CCUIAudioModule) alloc] init];
		self.sliderVC = [[%c(CCUIContentModuleContainerViewController) alloc] initWithModuleIdentifier:@"com.apple.control-center.AudioModule" contentModule:self.audioModule];
		self.sliderVC.view.frame = self.containerView.bounds;
		self.sliderVC.view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		
		if (useRingtoneCategory())
		{
			MPVolumeController* volControl = MSHookIvar<MPVolumeController*>(self.sliderVC.contentViewController, "_volumeController");
			volControl.volumeAudioCategory = @"Ringtone";
		}

		//rotate glyphs if landscape:
		CCUIVolumeSliderView* slider = MSHookIvar<CCUIVolumeSliderView*>(self.sliderVC.contentViewController, "_sliderView");
		UIView* glyph1 = MSHookIvar<UIView*>(slider, "_glyphPackageView");
		UIView* glyph2 = MSHookIvar<UIView*>(slider, "_compensatingGlyphPackageView");
		UIInterfaceOrientation orientation = [(SpringBoard*)[UIApplication sharedApplication] activeInterfaceOrientation];
		if (orientation == UIInterfaceOrientationLandscapeRight)
		{
			glyph1.transform = CGAffineTransformMakeRotation(90. * M_PI/180);
			glyph2.transform = CGAffineTransformMakeRotation(90. * M_PI/180);
		}
		else if (orientation == UIInterfaceOrientationLandscapeLeft)
		{
			glyph1.transform = CGAffineTransformMakeRotation(-90. * M_PI/180);
			glyph2.transform = CGAffineTransformMakeRotation(-90. * M_PI/180);
		}

		[self.containerView addSubview:self.sliderVC.view];

		//add as subview:
		[self addSubview:self.containerView];

		//set corner radius:
		[self setCornerRadius:expandedCornerRadius];

		//gesture recognizer for touches began and ended:
		UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panStateChanged:)];
		[self addGestureRecognizer:panGesture];

		//this is a hack...
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			finishedSetup = YES;
		});
	}
	return self;
}

-(void)setCornerRadius:(CGFloat)arg1
{
	//container:
	self.containerView.layer.cornerRadius = arg1;
	//fill layer:
	CCUIVolumeSliderView* slider = MSHookIvar<CCUIVolumeSliderView*>([self.sliderVC contentViewController], "_sliderView");
	slider.continuousSliderCornerRadius = 0.;
	UIView* bgView = MSHookIvar<UIView*>(slider, "_continuousValueBackgroundView");
	UIView* backdrop = MSHookIvar<UIView*>(bgView, "_backdropView");
	backdrop.layer.cornerRadius = 0.;
	//background:
	[self.sliderVC.contentContainerView _setContinuousCornerRadius:arg1];
}

//expand when you drag your finger, collapse when you release
-(void)panStateChanged:(UIPanGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateBegan)
	{
		[self expandAnimated:YES];
	}
	else if (sender.state == UIGestureRecognizerStateEnded)
	{
		[self collapseAnimated:YES];
	}
}

-(void)collapseAnimated:(BOOL)animated
{
	if (self.expanded)
	{
		self.expanded = NO;

		CGRect collapsedF = collapsedFrame();
		CGRect f = CGRectMake(0, 0, collapsedF.size.width, collapsedF.size.height);

		CCUIVolumeSliderView* slider = MSHookIvar<CCUIVolumeSliderView*>([self.sliderVC contentViewController], "_sliderView");

		CGFloat radius = f.size.width / 2.;
		CGFloat duration = animated ? collapseAnimDuration : 0.;
		[UIView animateWithDuration:duration animations:^{
			self.frame = collapsedF;
			self.containerView.frame = f;
			slider.glyphVisible = NO;
			[self setCornerRadius:radius];
			[self.containerView layoutIfNeeded];
			[self setCornerRadius:radius];
		}];
	}
}

-(void)expandAnimated:(BOOL)animated
{
	if (!self.expanded)
	{
		self.expanded = YES;

		CGRect expandedF = expandedFrame();
		CGRect f = CGRectMake(0, 0, expandedF.size.width, expandedF.size.height);

		CCUIVolumeSliderView* slider = MSHookIvar<CCUIVolumeSliderView*>([self.sliderVC contentViewController], "_sliderView");

		CGFloat radius = expandedCornerRadius;
		CGFloat duration = animated ? collapseAnimDuration : 0.;
		
		[UIView animateWithDuration:duration animations:^{
			self.frame = expandedF;
			self.containerView.frame = f;
			self.sliderVC.view.frame = f;
			slider.glyphVisible = YES;
			[self.containerView layoutIfNeeded];
			[self setCornerRadius:radius];
		}];
	}
}
@end

//update volumeValue when ringer volume changes:
#define kMRYRingerValueChanged @"com.muirey03.13hud.ringerchanged"
%hook MPVolumeController
-(id)init
{
	self = %orig;
	if (self)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateVolumeValue) name:kMRYRingerValueChanged object:nil];
	}
	return self;
}
%end

//post notifications when ringer volume changes:
%hook VolumeControl
-(void)_effectiveVolumeChanged:(NSNotification*)note
{
	%orig;
	[[NSNotificationCenter defaultCenter] postNotificationName:kMRYRingerValueChanged object:nil];
}
%end