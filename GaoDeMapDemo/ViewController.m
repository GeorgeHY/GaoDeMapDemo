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

@interface ViewController () <MAMapViewDelegate,AMapSearchDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@property (nonatomic,strong) MAMapView * mapView;
@property (nonatomic,strong) AMapSearchAPI * mapSearch;
@property (nonatomic, strong)CLLocation * currentLocation;
@property (nonatomic, strong) NSArray * poisArr;
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray * annotations;
@property (nonatomic,strong) UITextField * tf;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createUI];
    
    [self initAttributes];
}
- (void)createUI{
    
    [MAMapServices sharedServices].apiKey = APIKey;
    //searchView
    UIView * searchView = [[UIView alloc]initWithFrame:CGRectMake(0, 20, 320, 40)];
    searchView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:searchView];
    
    //textfield
    self.tf = [[UITextField alloc]initWithFrame:CGRectMake(60, 5, 200, 30)];
    self.tf.backgroundColor = [UIColor whiteColor];
    self.tf.delegate = self;
    [searchView addSubview:self.tf];
    
    //searchBtn
    UIButton * searchBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.tf.frame)+10, 5, 40, 30)];
    [searchBtn setTitle:@"搜索" forState:UIControlStateNormal];
    searchBtn.backgroundColor = [UIColor lightGrayColor];
    [searchBtn addTarget:self action:@selector(searchAction:) forControlEvents:UIControlEventTouchUpInside];
    [searchView addSubview:searchBtn];
    
    
    
    self.mapView = [[MAMapView alloc]initWithFrame:CGRectMake(0, 60, 320, 200)];
    [self.view addSubview:self.mapView];
    self.mapView.delegate = self;
    self.mapView.compassOrigin = CGPointMake(self.mapView.compassOrigin.x, 20);
    self.mapView.scaleOrigin = CGPointMake(self.mapView.scaleOrigin.x, 20);
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MAUserTrackingModeFollow;
    
    //点位btn
    UIButton * userLocal = [[UIButton alloc]initWithFrame:CGRectMake(10, 5, 40, 30)];
    [searchView addSubview:userLocal];
    [userLocal setTitle:@"定位" forState:UIControlStateNormal];
    userLocal.backgroundColor = [UIColor redColor];
    [userLocal addTarget:self action:@selector(userLocalAction:) forControlEvents:UIControlEventTouchUpInside];
    //mapsearch
    self.mapSearch = [[AMapSearchAPI alloc]initWithSearchKey:APIKey Delegate:self];
    
    //搜索结果tv
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.mapView.frame), 320, 568- CGRectGetMaxY(self.mapView.frame))];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)initAttributes
{
    self.annotations = [NSMutableArray array];
    self.poisArr = nil;
}

#pragma mark - Action
- (void)searchAction:(UIButton *)btn
{
    NSLog(@"搜索");
    if (self.currentLocation == nil || self.mapSearch == nil) {
        NSLog(@"搜索失败");
        return;
    }
    AMapPlaceSearchRequest * request = [[AMapPlaceSearchRequest alloc]init];
    request.searchType = AMapSearchType_PlaceAround;
    request.location = [AMapGeoPoint locationWithLatitude:self.currentLocation.coordinate.latitude longitude:self.currentLocation.coordinate.longitude];
    if (self.tf.text.length > 0) {
        request.keywords = self.tf.text;
    }else{
        request.keywords = nil;
    }
    
    [self.mapSearch AMapPlaceSearch:request];
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

- (MAAnnotationView*)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString * reuseIdentifier = @"annotationReuseIdentifier";
        MAPinAnnotationView * annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];
        if (!annotationView) {
            annotationView = [[MAPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        }
        
        annotationView.canShowCallout = YES;
        return annotationView;
    }
    return nil;
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
- (void)onPlaceSearchDone:(AMapPlaceSearchRequest *)request response:(AMapPlaceSearchResponse *)response
{
    NSLog(@"request = %@",request);
    NSLog(@"response = %@",response);
    
    if (response.pois.count > 0) {
        self.poisArr = response.pois;
        [self.tableView reloadData];
        
        //清空标注
        [self.mapView removeAnnotations:self.annotations];
        [self.annotations removeAllObjects];
        
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return self.poisArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    AMapPOI * poi = self.poisArr[indexPath.row];
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    return cell;
}
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //为点击的poi点添加标注
    AMapPOI * poi = self.poisArr[indexPath.row];
    MAPointAnnotation * annotation = [[MAPointAnnotation alloc]init];
    annotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
    annotation.title = poi.name;
    annotation.subtitle = poi.address;
    [self.annotations addObject:annotation];
    [self.mapView addAnnotation:annotation];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
