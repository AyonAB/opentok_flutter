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
  [view setTranslatesAutoresizingMaskIntoConstraints: NO];
  NSLayoutConstraint *horizontal = [NSLayoutConstraint
                                    constraintWithItem:view
                                    attribute:NSLayoutAttributeLeading
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:videoContainer
                                    attribute:NSLayoutAttributeLeading
                                    multiplier:1.0
                                    constant:0];
  NSLayoutConstraint *vertical = [NSLayoutConstraint
                                    constraintWithItem:view
                                    attribute:NSLayoutAttributeTop
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:videoContainer
                                    attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                    constant:0];
  NSLayoutConstraint *width = [NSLayoutConstraint
                                    constraintWithItem:view
                                    attribute:NSLayoutAttributeWidth
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:videoContainer
                                    attribute:NSLayoutAttributeWidth
                                    multiplier:1.0
                                    constant:0];
  NSLayoutConstraint *height = [NSLayoutConstraint
                                    constraintWithItem:view
                                    attribute:NSLayoutAttributeHeight
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:videoContainer
                                    attribute:NSLayoutAttributeHeight
                                    multiplier:1.0
                                    constant:0];
  [videoContainer addConstraints:[NSArray arrayWithObjects:horizontal, vertical, width, height, nil]];
}

- (void) addPublisherView : (UIView *) view {
  [videoContainer addSubview:view];
  [view setTranslatesAutoresizingMaskIntoConstraints: NO];
  NSLayoutConstraint *horizontal = [NSLayoutConstraint
                                    constraintWithItem:view
                                    attribute:NSLayoutAttributeRight
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:videoContainer
                                    attribute:NSLayoutAttributeRight
                                    multiplier:1.0
                                    constant:-20];
  NSLayoutConstraint *vertical = [NSLayoutConstraint
                                    constraintWithItem:view
                                    attribute:NSLayoutAttributeBottom
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:videoContainer
                                    attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                    constant:-70];
  NSLayoutConstraint *width = [NSLayoutConstraint
                                    constraintWithItem:view
                                    attribute:NSLayoutAttributeWidth
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                    attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                    constant:120];
  NSLayoutConstraint *height = [NSLayoutConstraint
                                    constraintWithItem:view
                                    attribute:NSLayoutAttributeHeight
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                    attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                    constant:160];
  [videoContainer addConstraints:[NSArray arrayWithObjects:horizontal, vertical, width, height, nil]];
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
