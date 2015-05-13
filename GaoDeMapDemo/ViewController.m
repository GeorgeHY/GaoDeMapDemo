//
//  ViewController.m
//  GaoDeMapDemo
//
//  Created by 韩扬 on 15/5/13.
//  Copyright (c) 2015年 iwind. All rights reserved.
//

#import "ViewController.h"
#import "MAMapKit.h"
#import "AMapSearchAPI.h"

#define APIKey @"5b6b161c2062e43dee547b9be1862f5e"

@interface ViewController () <MAMapViewDelegate,AMapSearchDelegate>

@property (nonatomic,strong) MAMapView * mapView;
@property (nonatomic,strong) AMapSearchAPI * mapSearch;
@property (nonatomic, strong)CLLocation * currentLocation;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createUI];
    
}
- (void)createUI{
    
    [MAMapServices sharedServices].apiKey = APIKey;
    self.mapView = [[MAMapView alloc]initWithFrame:CGRectMake(0, 0, 320, 200)];
    [self.view addSubview:self.mapView];
    self.mapView.delegate = self;
    self.mapView.compassOrigin = CGPointMake(self.mapView.compassOrigin.x, 20);
    self.mapView.scaleOrigin = CGPointMake(self.mapView.scaleOrigin.x, 20);
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MAUserTrackingModeFollow;
    
    //点位btn
    UIButton * userLocal = [[UIButton alloc]initWithFrame:CGRectMake(20, 400, 40, 40)];
    [self.view addSubview:userLocal];
    [userLocal setTitle:@"定位" forState:UIControlStateNormal];
    userLocal.backgroundColor = [UIColor redColor];
    [userLocal addTarget:self action:@selector(userLocalAction:) forControlEvents:UIControlEventTouchUpInside];
    //mapsearch
    self.mapSearch = [[AMapSearchAPI alloc]initWithSearchKey:APIKey Delegate:self];
}
- (void)userLocalAction:(UIButton *)btn
{
    if (self.mapView.userTrackingMode != MAUserTrackingModeFollow) {
        [self.mapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];
    }
}

- (void)reGeoAction
{
    if (self.currentLocation) {
        AMapReGeocodeSearchRequest * request = [[AMapReGeocodeSearchRequest alloc]init];
        request.location = [AMapGeoPoint locationWithLatitude:self.currentLocation.coordinate.latitude longitude:self.currentLocation.coordinate.longitude];
        [self.mapSearch AMapReGoecodeSearch:request];
    }
}

#pragma mark - MAMapViewDelegate
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    self.currentLocation = userLocation.location;
    NSLog(@"%@",self.currentLocation);
}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view
{
    if ([view.annotation isKindOfClass:[MAUserLocation class]]) {
        [self reGeoAction];
    }
}
#pragma mark - AMapSearchDelegate
- (void)searchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"错误");
}
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    NSLog(@"------ response = %@",response);
    NSString * title = response.regeocode.addressComponent.city;
    if (title.length == 0) {
        title = response.regeocode.addressComponent.province;
    }
    self.mapView.userLocation.title = title;
    self.mapView.userLocation.subtitle = response.regeocode.formattedAddress;
}

@end
