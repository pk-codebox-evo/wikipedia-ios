
#import "WMFHomeNearbyCell.h"
#import "WMFSaveableTitleCollectionViewCell+Subclass.h"

// Views
#import "WMFCompassView.h"

// Frameworks
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"
#import <Masonry/Masonry.h>


// Model
#import "WMFNearbyViewModel.h"
#import "MWKLocationSearchResult.h"
#import "WMFLocationSearchResults.h"

// Utils
#import "WMFMath.h"
#import "NSString+WMFDistance.h"


static CGFloat const WMFTextPadding    = 8.0;
static CGFloat const WMFDistanceHeight = 20.0;

static CGFloat const WMFImageSize    = 104;
static CGFloat const WMFImagePadding = 8.0;

@interface WMFHomeNearbyCell ()

- (void)setDistance:(CLLocationDistance)distance;

- (void)setBearing:(CLLocationDegrees)bearing;

- (void)setCompassHidden:(BOOL)compassHidden;

@property (strong, nonatomic) IBOutlet WMFCompassView* compassView;
@property (strong, nonatomic) IBOutlet UIView* distanceLabelBackground;
@property (strong, nonatomic) IBOutlet UILabel* distanceLabel;

@property (nonatomic, copy) NSString* descriptionText;

@property (strong, nonatomic) MWKLocationSearchResult* locationSearchResult;

@end

@implementation WMFHomeNearbyCell
@synthesize locationSearchResult = _locationSearchResult;

- (void)dealloc {
    [self unobserveResult];
}

+ (NSString*)defaultImageName {
    return @"logo-placeholder-nearby.png";
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setLocationSearchResult:nil withTitle:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.image                            = [UIImage imageNamed:@"logo-placeholder-nearby.png"];
    self.imageView.layer.cornerRadius               = self.imageView.bounds.size.width / 2;
    self.imageView.layer.borderWidth                = 1.0 / [UIScreen mainScreen].scale;
    self.imageView.layer.borderColor                = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
    self.distanceLabelBackground.layer.cornerRadius = 2.0;
}

- (UICollectionViewLayoutAttributes*)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes {
    self.titleLabel.preferredMaxLayoutWidth = layoutAttributes.size.width - WMFImageSize - WMFImagePadding - WMFImagePadding;
    UICollectionViewLayoutAttributes* preferredAttributes = [layoutAttributes copy];
    CGFloat height                                        = MAX(120, self.titleLabel.intrinsicContentSize.height + WMFTextPadding + WMFTextPadding + WMFDistanceHeight + WMFTextPadding);
    preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, height);
    return preferredAttributes;
}

#pragma mark - Compass

- (void)setBearing:(CLLocationDegrees)bearing {
    self.compassView.angleRadians = DEGREES_TO_RADIANS(bearing);
}

- (void)setCompassHidden:(BOOL)compassHidden {
    self.compassView.hidden = compassHidden;
}

#pragma mark - Result

- (void)setLocationSearchResult:(MWKLocationSearchResult*)locationSearchResult withTitle:(MWKTitle*)title {
    if (WMF_EQUAL(self.locationSearchResult, isEqual:, locationSearchResult)
        && WMF_EQUAL(self.title, isEqualToTitle:, title)) {
        return;
    }

    [self unobserveResult];

    _locationSearchResult = locationSearchResult;

    // !!! Set title _after_ the description to ensure the label updates properly.
    self.descriptionText = self.locationSearchResult.wikidataDescription;
    self.title           = title;

    self.distance = self.locationSearchResult.distanceFromQueryCoordinates;
    self.imageURL = self.locationSearchResult.thumbnailURL;

    [self observeResult];
}

- (void)observeResult {
    if (!self.locationSearchResult) {
        return;
    }
    [self.KVOControllerNonRetaining
     observe:self.locationSearchResult
     keyPath:WMF_SAFE_KEYPATH(self.locationSearchResult, bearingToLocation)
     options:NSKeyValueObservingOptionInitial
       block:^(WMFHomeNearbyCell* cell, MWKLocationSearchResult* result, NSDictionary* _) {
        [cell setBearing:result.bearingToLocation];
        [cell setCompassHidden:NO];
    }];
    [self.KVOControllerNonRetaining
     observe:self.locationSearchResult
     keyPath:WMF_SAFE_KEYPATH(self.locationSearchResult, distanceFromUser)
     options:NSKeyValueObservingOptionInitial
       block:^(WMFHomeNearbyCell* cell, MWKLocationSearchResult* result, NSDictionary* _) {
        cell.distance = result.distanceFromUser;
    }];
}

- (void)unobserveResult {
    if (!self.locationSearchResult) {
        return;
    }
    [self.KVOControllerNonRetaining unobserve:self.locationSearchResult
                                      keyPath:WMF_SAFE_KEYPATH(self.locationSearchResult, bearingToLocation)];
    [self.KVOControllerNonRetaining unobserve:self.locationSearchResult
                                      keyPath:WMF_SAFE_KEYPATH(self.locationSearchResult, distanceFromUser)];
}

#pragma mark - Title/Description

- (void)updateTitleLabel {
    NSMutableAttributedString* text = [NSMutableAttributedString new];

    NSAttributedString* titleText = [self attributedTitleText];
    if ([titleText length] > 0) {
        [text appendAttributedString:titleText];
    }

    NSAttributedString* descriptionText = [self attributedDescriptionText];
    if ([descriptionText length] > 0) {
        [text appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
        [text appendAttributedString:descriptionText];
    }

    self.titleLabel.attributedText = text;
}

- (NSAttributedString*)attributedTitleText {
    if ([self.title.text length] == 0) {
        return nil;
    }

    return [[NSAttributedString alloc] initWithString:self.title.text attributes:
            @{
                NSFontAttributeName: [UIFont systemFontOfSize:17.0f],
                NSForegroundColorAttributeName: [UIColor blackColor]
            }];
}

- (NSAttributedString*)attributedDescriptionText {
    if ([self.descriptionText length] == 0) {
        return nil;
    }

    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = 2.0;

    return [[NSAttributedString alloc] initWithString:self.descriptionText attributes:
            @{
                NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                NSForegroundColorAttributeName: [UIColor grayColor],
                NSParagraphStyleAttributeName: paragraphStyle
            }];
}

#pragma mark - Distance

- (void)setDistance:(CLLocationDistance)distance {
    self.distanceLabel.text = [NSString wmf_localizedStringForDistance:distance];
}

@end
