//
//  GalleryCollectionView.m
//  tapVideoForPicture
//
//  Created by Jacobson on 2/23/15.
//  Copyright (c) 2015 Alex Jacobson. All rights reserved.
//

#import "GalleryCollectionView.h"
#import "CollectionViewCell.h"

@interface GalleryCollectionView ()<UICollectionViewDataSource,UICollectionViewDelegate>

@end

@implementation GalleryCollectionView
@synthesize imageArray;
static NSString *const reuseIdentifier = @"image";
static int screenHeight = 0, screenWidth = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    else
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    screenHeight = [[UIScreen mainScreen] bounds].size.height;
    screenWidth  = [[UIScreen mainScreen] bounds].size.width;
    [self.collection reloadData];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return imageArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    UIImage *image           = [imageArray objectAtIndex:indexPath.row];
    cell.cellImage.image     = image;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *image = [imageArray objectAtIndex:indexPath.row];
    
    float cellWidth;
    if ((int)image.size.width < (int)image.size.height)
        cellWidth = (screenWidth/2) - 20;
    else if ((int)image.size.width > (int)image.size.height)
        cellWidth = screenWidth;
    else
        cellWidth = (screenWidth/3) - 30;

    float aspectRatio = image.size.height / image.size .width;
    float cellHeight  = cellWidth * (aspectRatio);

    return CGSizeMake(cellWidth, cellHeight);
}

@end
