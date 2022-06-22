//
//  Video.m
//  opentok_flutter
//
//  Created by Ayon Das on 20/06/22.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "Video.h"

@implementation OpenTokVideoContainer

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  [self setAutoresizesSubviews:true];
  [self setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
}

@end

@implementation OpentokVideoPlatformView
OpenTokVideoContainer *videoContainer;

- (instancetype)initWithFrame:(CGRect)frame {
  videoContainer = [[OpenTokVideoContainer alloc] initWithFrame:frame];
  self = [super init];
  return self;
}

- (nonnull UIView *)view {
  return videoContainer;
}

- (void) addSubscriberView : (UIView *) view {
  [videoContainer insertSubview:view atIndex:0];
  [view setFrame:videoContainer.bounds];
}

- (void) addPublisherView : (UIView *) view {
  [videoContainer addSubview:view];
  [view setFrame:CGRectMake(videoContainer.bounds.size.width - 120 - 20, videoContainer.bounds.size.height - 160 - 70, 120, 160)];
}

@end

@implementation OpentokVideoFactory
@synthesize subscriberView = _subscriberView;
@synthesize publisherView = _publisherView;

- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger {
  self = [super init];
  if (self) {
    _binaryMessenger = binaryMessenger;
  }
  return self;
}

- (OpentokVideoPlatformView *)getViewInstance:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args messenger:(id<FlutterBinaryMessenger>)binaryMessenger {
  if (_view == nil) {
    _view = [[OpentokVideoPlatformView alloc] initWithFrame:frame];
    if (_subscriberView != nil) {
      [_view addSubscriberView:_subscriberView];
    }
    if (_publisherView != nil) {
      [_view addPublisherView:_publisherView];
    }
  }
  return _view;
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args { 
  return [self getViewInstance:frame viewIdentifier:viewId arguments:args messenger:_binaryMessenger];
}

@end
