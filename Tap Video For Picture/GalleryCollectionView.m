//
//  GalleryCollectionView.m
//  tapVideoForPicture
//
//  Created by Jacobson on 2/23/15.
//  Copyright (c) 2015 Alex Jacobson. All rights reserved.
//
//  Software written for the expressed purpose of evaluating
//  Alex Jacobson's software programing skills.
//
//  Any commercial use of this software without the expressed written
//  concent of Alex Jacobson is strictly forbidden
//
// contact: ajacobson50@gmial.com

#define FONT(s) [UIFont fontWithName:@"BrushHandNew" size:s]

#import "GalleryCollectionView.h"
#import "ReviewCollectionCell.h"
#import "HomeViewController.h"

@interface GalleryCollectionView ()<UICollectionViewDataSource,UICollectionViewDelegate,UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collection;
@property (strong, nonatomic) IBOutlet UIButton *homeButton;
@property (strong,nonatomic) UIImageView *bigImage;
@end

@implementation GalleryCollectionView

@synthesize imageArray,bigImage,homeButton,collection,allVideos;

static NSString *const reuseIdentifier = @"image";
static int screenHeight = 0, screenWidth = 0;
static bool loadInstructions = NO;
static float scrollDistance;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defults = [NSUserDefaults standardUserDefaults];            // displays instructs for the first 2 times
    NSInteger count = [defults integerForKey:@"loadCount"];
    if (count < 2) {
        count++;
        [defults setInteger:count forKey:@"loadCount"];
        loadInstructions = YES;
        [defults synchronize];
    }
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) // hides status bar
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    else
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    screenHeight             = [[UIScreen mainScreen] bounds].size.height;      // sets screen height
    screenWidth              = [[UIScreen mainScreen] bounds].size.width;       // sets screen width
    bigImage                 = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    bigImage.contentMode     = UIViewContentModeScaleAspectFit;
    bigImage.backgroundColor = [UIColor blackColor];
    [self.view addSubview:bigImage];
    
    homeButton.titleLabel.font = FONT(26);                                      // sets home button font
    
    [self.collection reloadData];
}

- (BOOL)prefersStatusBarHidden {                                                // called to hide status bar
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    scrollDistance = (scrollView.contentOffset.y < 0) ? 0 : scrollView.contentOffset.y;
}

-(void)longPressHandler : (UILongPressGestureRecognizer*) gesture {             // long press handler to animate image to full screen
    ReviewCollectionCell *cell  = (ReviewCollectionCell *)gesture.view;
    CGRect cellFrame            = CGRectMake(cell.frame.origin.x, (cell.frame.origin.y + collection.frame.origin.y) - scrollDistance, cell.frame.size.width, cell.frame.size.height);
    cell.pressDiscription.alpha = 0;
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.2 animations:^(){
            bigImage.frame = cellFrame;
        }completion:^(BOOL finished){
            if (finished) {
                bigImage.frame = CGRectMake(0, 0, 0, 0);
            }
        }];
    }else
    if (gesture.state == UIGestureRecognizerStateBegan){
        bigImage.frame = cellFrame;
        bigImage.image = cell.cellImage.image;
        [UIView animateWithDuration:0.2 animations:^(){
            bigImage.frame = CGRectMake(0, 0, screenWidth, screenHeight);
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {          // send video array to next view
    HomeViewController *vc = [segue destinationViewController];
    vc.allVideos           = allVideos;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {// only one section
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return imageArray.count;                                                    // images to be displayed caount
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ReviewCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    UIImage *image             = [imageArray objectAtIndex:indexPath.row];        // cell builder
    cell.cellImage.image       = image;
    
    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
    longpressGesture.minimumPressDuration = 0.1;
    [longpressGesture setDelegate:self];
    [cell addGestureRecognizer:longpressGesture];
    
    cell.pressDiscription.font = FONT(20);                                      // sets instructions font
    
    if (loadInstructions) {                                                     // animates the disappering instuctions after 2 seconds
        [UIView animateWithDuration:1.0 delay:2 options:UIViewAnimationOptionTransitionNone animations:^(){
            cell.pressDiscription.alpha = 0.0;
        }completion:^(BOOL finished){}];
    }else 
        cell.pressDiscription.alpha = 0.0;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{                                                                               // dynamically set cell sizes based on different image aspect ratios
    UIImage *image = [imageArray objectAtIndex:indexPath.row];
    
    float cellWidth;
    if ((int)image.size.width < (int)image.size.height)
        cellWidth = (screenWidth/2) - 20;
    else if ((int)image.size.width > (int)image.size.height)
        cellWidth = screenWidth;
    else
        cellWidth = (screenWidth/2) - 20;

    float aspectRatio = image.size.height / image.size .width;
    float cellHeight  = cellWidth * (aspectRatio);

    return CGSizeMake(cellWidth, cellHeight);
}

@end
