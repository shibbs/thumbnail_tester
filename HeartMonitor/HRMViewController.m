//
//  HRMViewController.m
//  HeartMonitor
//
//  Created by Main Account on 12/13/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.

//lots of code help from : http://www.raywenderlich.com/52080/introduction-core-bluetooth-building-heart-rate-monitor 

//

#import "HRMViewController.h"

@interface HRMViewController ()

@end

@implementation HRMViewController


CBCentralManager *centralManager;
CBCharacteristic *uart_in_Characteristic1;
CBCharacteristic *uart_in_Characteristic2;
CBCharacteristic *uart_in_Characteristic3;
CBCharacteristic *uart_in_Characteristic4;
CBCharacteristic *uart_in_Characteristic5;
CBCharacteristic *uart_in_Characteristic6;

CBCharacteristic *uart_out;

NSMutableData  *TotalInArray ;
int numPackets       = 9;   //number of packets sends to expect in this page
int numPages         = 12;   //number of pages to expect
int pageNumber       = 0;   //page number we're on now
int chunkNumber      = 0;    //chunk we're on now
const int pageLength = 1028;
int bytesReceived = 0;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    TotalInArray =  [[NSMutableData alloc] init];
 
	// Do any additional setup after loading the view, typically from a nib.
	self.polarH7DeviceData = nil;
	[self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
	[self.heartImage setImage:[UIImage imageNamed:@"HeartImage"]];
 

 
	// Create your Heart Rate BPM Label
	self.heartRateBPM = [[UILabel alloc] initWithFrame:CGRectMake(55, 30, 75, 50)];
	[self.heartRateBPM setTextColor:[UIColor whiteColor]];
	[self.heartRateBPM setText:[NSString stringWithFormat:@"%i", 0]];
	[self.heartRateBPM setFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:28]];
	[self.heartImage addSubview:self.heartRateBPM];
    [self.heartRateBPM setUserInteractionEnabled:NO];
 

    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    self.good_btn.hidden = YES;
    self.bad_btn.hidden = NO;
    self.alpine_peripheral = NULL; //null outt he alpine peripheral object
    
	self.centralManager = centralManager;
    NSLog(@"ed up");
 
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"got memory warning");
    [super didReceiveMemoryWarning];
}

#pragma mark - CBCentralManagerDelegate


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
    
    [centralManager stopScan];
    NSLog(@"%@", self.connected);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Connection lost! Going back into scan mode");
    [self.connection_info setText:@" Connection Lost"];
    
    if(  peripheral == self.alpine_peripheral ) {
        NSLog(@"DISCONNECTED FROM RADIAN!!!");
        self.alpine_peripheral = NULL; //null outt he alpine peripheral object
        self.good_btn.hidden = YES;
        self.bad_btn.hidden = NO;
        
        [centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}


// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI 
{
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    NSLog(@"Found the peripheral: %@", localName);
    if([localName  containsString:@"AlpLab"]) {
        NSLog(@"FOUND Test Device");
    
        if(self.alpine_peripheral != NULL){
            NSLog(@"FOUND ANOTHER Test Device ");
        }
        
        self.alpine_peripheral = peripheral;
        peripheral.delegate = self;
        
        self.good_btn.hidden = NO;
        self.bad_btn.hidden = YES;
        
        [self.connection_info setText:@" Connection Secured"];
        [centralManager connectPeripheral:peripheral options:nil];
       
    }

}




- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
//        NSArray *services = @[[CBUUID UUIDWithString:BLE_SM_UUID_SERVICE], [CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID]];
        
        [centralManager scanForPeripheralsWithServices:nil options:nil]; //search for all devices
        
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}


#pragma mark - CBPeripheralDelegate
 
// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error 
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];

    }
    
    
}
 
// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error 
{
    
    NSLog(@"found a service, Service ID is %@", service.UUID);
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_SERVICE]])  {  // 1
        
        NSLog(@"in the UART service");
        for (CBCharacteristic *aChar in service.characteristics)
        {
            NSLog(@"TL Service characteristic:%@", service.UUID);
            
            // uart characteristic
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR1]]) { // 2
                [self.alpine_peripheral setNotifyValue:YES forCharacteristic:aChar];
                uart_in_Characteristic1 = aChar;
                NSLog(@"Found uart in 1 packet characteristic");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR2]]) { // 2
                [self.alpine_peripheral setNotifyValue:YES forCharacteristic:aChar];
                uart_in_Characteristic2 = aChar;
                NSLog(@"Found uart in 2 packet characteristic");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR3]]) { // 2
                [self.alpine_peripheral setNotifyValue:YES forCharacteristic:aChar];
                uart_in_Characteristic3 = aChar;
                NSLog(@"Found uart in 3 packet characteristic");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR4]]) { // 2
                [self.alpine_peripheral setNotifyValue:YES forCharacteristic:aChar];
                uart_in_Characteristic4 = aChar;
                NSLog(@"Found uart in 4 packet characteristic");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR5]]) { // 2
                [self.alpine_peripheral setNotifyValue:YES forCharacteristic:aChar];
                uart_in_Characteristic5 = aChar;
                NSLog(@"Found uart in 5 packet characteristic");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR6]]) { // 2
                [self.alpine_peripheral setNotifyValue:YES forCharacteristic:aChar];
                uart_in_Characteristic6 = aChar;
                NSLog(@"Found uart in 6 packet characteristic");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_OUT]]) { // 2
                [self.alpine_peripheral setNotifyValue:NO forCharacteristic:aChar];
                uart_out = aChar;
                NSLog(@"Found uart out packet characteristic");
            }
        }
    }
}

bool chanHit[] = {false, false, false, false, false, false};
// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)aChar error:(NSError *)error
{
    bool sendAck = false;
    
    NSMutableData * data = [aChar.value mutableCopy];
    
    if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR1]]) {
        chanHit[0] = true;

        const char* array_in = (const char*)[data bytes];
        const char zero = 0, twelve = 12;
        
        if(pageNumber == 0 && chunkNumber == 0 ){ //do some overhead stuff ont he first page
                        //check if this is a legit first packet
            if(array_in[0] == zero && array_in[1] == twelve) {
                numPages = array_in[2];
                bytesReceived = 0; // Reset
                NSLog(@"numPages : %d", numPages);
            }
        
        }else if(chunkNumber == 0){ //for a new page
            if(array_in[1] == twelve && array_in[2] == numPages){
                if (pageNumber != array_in[0])
                    NSLog(@"pageNumber is wrong! [%d, %d]", pageNumber, array_in[0]);
            }else{
                NSLog(@"packetNumber is wrong! ");
            }
        }
        
        if(chunkNumber == 0){
            NSRange range = NSMakeRange(0, 3); // Strip the first three bytes off the start of the
            [data replaceBytesInRange:range withBytes:NULL length:0];
        }

    }
    else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR2]]){
        chanHit[1] = true;
    }
    else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR3]]){
        chanHit[2] = true;
    }
    else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR4]]){
        chanHit[3] = true;
    }
    else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR5]]){
        chanHit[4] = true;
    }
    else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_UART_IN_CHAR6]]){
        chanHit[5] = true;
        for(int channel = 0; channel < 6; channel++){
            if(!chanHit[channel]){
                NSLog(@"We didn't receive anything on channel %d.", channel+1);
            }
        }
        sendAck = true;
        
        NSLog(@"Finished Chunk %d. Sending Ack.", chunkNumber);
        chunkNumber++;
    }
    
    long length = aChar.value.length;
    
    bytesReceived += length;
    //NSLog(@"Bytes Received: %d", bytesReceived);
    
    [TotalInArray appendData:data];
    
    if(bytesReceived == pageLength){
        NSLog(@"Finished Page %d. Sending Ack.", pageNumber);
        sendAck = true;
        bytesReceived = 0;
        chunkNumber = 0;
        
        if(pageNumber == 0){ // Strip off the 12 bytes of junk + 1 byte of checksum on the first page
            [TotalInArray setLength:[TotalInArray length] - 13];
        }
        else
            [TotalInArray setLength:[TotalInArray length] - 1];
        
        pageNumber++;
        if(pageNumber == numPages)
        {
            pageNumber = 0;
            NSLog(@"Thumbnail transfer complete!");
            NSLog(@"\r\n%@", TotalInArray);
            

            UIImage *image = [UIImage imageWithData:TotalInArray];
            
            UIImageView *myImageView = [[UIImageView alloc] initWithImage:image];
            [self.view addSubview:myImageView];
        }
        
    }
    
    if(sendAck){
        unsigned char bytes[] = {0xff, 0x04};
        
        NSData* dataToWrite = [NSData dataWithBytes:bytes length:sizeof(bytes)];
        [self.alpine_peripheral writeValue:dataToWrite forCharacteristic:uart_out type :CBCharacteristicWriteWithResponse];
        
        sendAck = false;
        
        //Clear channel hits
        for(int channel = 0; channel < 6; channel++){
            chanHit[channel] = false;
        }
    }
    
    
    
}

 - (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
      NSLog(@"Error writing characteristic value: %@",[error localizedDescription]);
}
}


#pragma mark - CBCharacteristic helpers
 
// Instance method to get the heart rate BPM information
- (void) getHeartBPMData:(CBCharacteristic *)characteristic error:(NSError *)error 
{
}
// Instance method to get the manufacturer name of the device
- (void) getManufacturerName:(CBCharacteristic *)characteristic 
{
}
// Instance method to get the body location of the device
- (void) getBodyLocation:(CBCharacteristic *)characteristic 
{
}
// Helper method to perform a heartbeat animation
- (void)doHeartBeat {
}


- (IBAction)ShutterButtonTouched:(id)sender {
    static int val = 0;
    if(val ==0 ){
        val = 1;
        [self.deviceInfo setText:@" LED ON"];
    }
    else{
        val = 0;
        [self.deviceInfo setText:@" LED OFF"];
    }
    
    NSLog(@"SHUTTER BUTTON PRESSED");
    
    
  //  NSLog(@"Writing value for shutter characteristic");
    unsigned char bytes[] = {val};
//    NSData* dataToWrite = [NSData dataWithBytes:bytes length:sizeof(bytes)];
//    [self.alpine_peripheral writeValue:dataToWrite forCharacteristic:shutterCharacteristic type :CBCharacteristicWriteWithResponse];

}
- (void) sendTestTLPacket {
    //basic test packet
    NSLog(@"Attempting to send the TL Packet");
    unsigned char bytes[] = {241,1,60,80,50,0,1,8,0,0,100,0,80,0,0,0,0,50,0,0,100,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,242};
    NSData* dataToWrite = [NSData dataWithBytes:bytes length:sizeof(bytes)];
//    [self.alpine_peripheral writeValue:dataToWrite forCharacteristic:tl_data_Characteristic type :CBCharacteristicWriteWithoutResponse];
}

- (IBAction)TlButtonTouched:(id)sender {
        //basic test packet
    NSLog(@"Attempting to send the TL Packet");
    unsigned char bytes[] = {253,1,30,50,80,0,50,0,1,5,10,0,0,0,200,0,0,0,50,0,0,40,2,95,115,10,0,0,130,1,135,1,130,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,111,254};
 //   unsigned char bytes[] = {1}; //added tis to control for error a bit
    NSData* dataToWrite = [NSData dataWithBytes:bytes length:5];
    int temp;
    int pkt_size = 19; //size of packet data to send
    unsigned char send_arr[20] ;
    for (int i = 0; i < sizeof(bytes);i+=pkt_size){
        send_arr[0] = i/pkt_size; //add in packet #
        //NSLog(@"sending pkt# %d, vals: ", send_arr[0]);
        for( int j = 0; j < pkt_size;j++){
            send_arr[j+1] = bytes[j+i];
           // NSLog(@" %d,", send_arr[j+1]);
        }
        NSData* dataToWrite = [NSData dataWithBytes:send_arr length:pkt_size+1];
        
        NSLog(@"sending pkt, len: %d, vals: %@", dataToWrite.length , dataToWrite);
//        [self.alpine_peripheral writeValue:dataToWrite forCharacteristic:tl_data_Characteristic type :CBCharacteristicWriteWithResponse];
        NSLog(@"just sent # %d", send_arr[0]);
        sleep(.5);
      //  NSLog(@"done sleeping");
        
    }
    

}



@end
