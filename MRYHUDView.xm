#import "13HUD.h"
#import "MRYHUDView.h"

#define expandedCornerRadius 17.
#define collapseAnimDuration 0.3

static CGFloat currentCornerRadius = expandedCornerRadius;

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
		arg1 = currentCornerRadius;
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
%hook CCUIContentModuleContext
+(void)performWithoutAnimationWhileHidden:(void(^)(void))arg1
{
	if ([(SBHUDController*)[%c(SBHUDController) sharedHUDController] isHUDVisible])
		arg1();
	else
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

		[self.containerView addSubview:self.sliderVC.view];

		//add as subview:
		[self addSubview:self.containerView];

		//set corner radius:
		[self setCornerRadius:expandedCornerRadius];

		//gesture recognizer for touches began and ended:
		UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panStateChanged:)];
		[self addGestureRecognizer:panGesture];
	}
	return self;
}

-(void)setCornerRadius:(CGFloat)arg1
{
	currentCornerRadius = arg1;
	//container:
	self.containerView.layer.cornerRadius = arg1;
	//fill layer:
	CCUIVolumeSliderView* slider = MSHookIvar<CCUIVolumeSliderView*>([self.sliderVC contentViewController], "_sliderView");
	slider.continuousSliderCornerRadius = arg1;
	//background:
	[self.sliderVC.contentContainerView _setContinuousCornerRadius:arg1];
	//force update:
	[slider setNeedsLayout];
	[slider layoutIfNeeded];
}

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
			self.containerView.frame = f;
			slider.glyphVisible = NO;
			[self setCornerRadius:radius];
			[self.containerView layoutIfNeeded];
		} completion:^(BOOL finished){
			self.frame = collapsedF;
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
		self.frame = expandedF;
		[UIView animateWithDuration:duration animations:^{
			self.containerView.frame = f;
			self.sliderVC.view.frame = f;
			[self setCornerRadius:radius];
			slider.glyphVisible = YES;
			[self.containerView layoutIfNeeded];
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