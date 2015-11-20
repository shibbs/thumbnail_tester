//
//  HRMViewController.h
//  HeartMonitor
//
//  Created by Main Account on 12/13/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreBluetooth;
@import QuartzCore;


//Michron UUID : B602xxxx-7238-CA82-79C1-10010C1126B3
//Radian UUID : C871xxxx-891F-8535-FC3C-D1BE7A6D3E65

#define MICHRON_BLE_1_BASIC_SERVICE_UUID   @"180"
#define BLE_SM_UUID_SERVICE     @"1902"
#define BLE_SM_UUID_STATE_CHAR @"B6021524-7238-CA82-79C1-10010C1126B3"
#define BLE_SM_UUID_TIME_CHAR @"B6021525-7238-CA82-79C1-10010C1126B3"
#define BLE_SM_UUID_SHUTTER_CHAR @"B6021526-7238-CA82-79C1-10010C1126B3"
#define BLE_SM_UUID_TL_PKT_CHAR @"3012"

#define BLE_UART_SERVICE    @"1904"
#define BLE_UART_IN_CHAR1      @"3032"
#define BLE_UART_IN_CHAR2      @"3033"
#define BLE_UART_IN_CHAR3      @"3034"
#define BLE_UART_IN_CHAR4      @"3035"
#define BLE_UART_IN_CHAR5      @"3036"
#define BLE_UART_IN_CHAR6      @"3037"
#define BLE_UART_OUT      @"3030"



#define POLARH7_HRM_DEVICE_INFO_SERVICE_UUID @"180A"       
#define POLARH7_HRM_HEART_RATE_SERVICE_UUID @"180D"

#define POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID @"2A37"
#define POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID @"2A38"
#define POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID @"2A29"


@interface HRMViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral     *polarH7HRMPeripheral;
@property (nonatomic, strong) CBPeripheral    *alpine_peripheral; //alpine labs peripheral object



- (IBAction)ShutterButtonTouched:(id)sender;

// Properties for your Object controls
@property (nonatomic, strong) IBOutlet UIImageView *heartImage;
//@property (nonatomic, strong) IBOutlet UITextView  *deviceInfo;
@property (strong, nonatomic) IBOutlet UIView *bad_btn;
@property (nonatomic, strong) IBOutlet UITextView *deviceInfo;
@property (strong, nonatomic) IBOutlet UITextView *connection_info;
@property (strong, nonatomic) IBOutlet UIButton *good_btn;


// Properties to hold data characteristics for the peripheral device
@property (nonatomic, strong) NSString   *connected;
@property (nonatomic, strong) NSString   *bodyData;
@property (nonatomic, strong) NSString   *manufacturer;
@property (nonatomic, strong) NSString   *polarH7DeviceData;
@property (assign) uint16_t heartRate;
 
// Properties to handle storing the BPM and heart beat
@property (nonatomic, strong) UILabel    *heartRateBPM;
@property (nonatomic, retain) NSTimer    *pulseTimer;
 
// Instance method to get the heart rate BPM information
- (void) getHeartBPMData:(CBCharacteristic *)characteristic error:(NSError *)error;
 
// Instance methods to grab device Manufacturer Name, Body Location
- (void) getManufacturerName:(CBCharacteristic *)characteristic;
- (void) getBodyLocation:(CBCharacteristic *)characteristic;
 
// Instance method to perform heart beat animations
- (void) doHeartBeat;


@end
