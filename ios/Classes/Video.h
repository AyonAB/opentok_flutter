//
//  Video.h
//  opentok_flutter
//
//  Created by Ayon Das on 20/06/22.
//

#import <Flutter/Flutter.h>

@interface OpenTokVideoContainer : UIView
@end

@interface OpentokVideoPlatformView : NSObject<FlutterPlatformView>
- (void) addSubscriberView : (UIView *) view;
- (void) addPublisherView : (UIView *) view;
@end

@interface OpentokVideoFactory : NSObject<FlutterPlatformViewFactory>
@property OpentokVideoPlatformView *view;
@property(nonatomic, strong) NSObject<FlutterBinaryMessenger> *binaryMessenger;
@property(nonatomic) UIView *subscriberView;
@property(nonatomic) UIView *publisherView;
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger;
@end
