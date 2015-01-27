//
//  ViewController.m
//  CoreBlueToothCentral
//
//  Created by 敬洁 on 15/1/27.
//  Copyright (c) 2015年 JingJ. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>


@property (nonatomic, strong) CBCentralManager *centralManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*
    启动一个Central端管理器对象
    搜索并连接正在广告的Peripheral设备
    在连接到Peripheral端后查询数据
    发送一个对特性值的读写请求到Peripheral端
    当Peripheral端特性值改变时接收通知
     */
    
    // 指定当前类为代理对象，所以其需要实现CBCentralManagerDelegate协议
    // 如果queue为nil，则Central管理器使用主队列来发送事件
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
//    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    
}

// 确保本地设备支持BLE
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Central Update State");
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn: {
            
            // 查找Peripheral设备
            // 如果第一个参数传递nil，则管理器会返回所有发现的Peripheral设备。
            // 通常我们会指定一个UUID对象的数组，来查找特定的设备
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
            NSLog(@"CBCentralManagerStatePoweredOn");
            break;
            
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            break;
            
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
            
        default:
            break;
    }
}

// 每次发现设备调用该代理方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discover name : %@", peripheral.name);
    
    
    // 连接Peripheral设备
    [self.centralManager connectPeripheral:peripheral options:nil];
    
    
    
    
}

// 连接Peripheral设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@"连接Peripheral设备失败");
    NSLog(@"%@", error.localizedDescription);
}

// 取消连接Peripheral设备
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@"取消连接Peripheral设备");
    NSLog(@"%@", error.localizedDescription);
}

// 连接Peripheral设备成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    peripheral.delegate = self;
    
    // 查找所连接Peripheral设备的服务
    // 参数传递nil可以查找所有的服务，但一般情况下我们会指定感兴趣的服务
    [peripheral discoverServices:nil];
    
    
    // 当我们查找到Peripheral端时，我们可以停止查找其它设备，以节省电量
    [self.centralManager stopScan];
    
    NSLog(@"Scanning stop");
}

// 找到peripheral中找到的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"Discover Service");
    
    for (CBService *service in peripheral.services)
    {
        NSLog(@"Discovered service %@", service);
        
        // 查找服务中的特性
        NSLog(@"Discovering characteristics for service %@", service);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// 找到服务特性
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Discover Characteristics");
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"Discovered characteristic %@", characteristic);
        
        // 获取特性的值
        NSLog(@"Reading value for characteristic %@", characteristic);
        [peripheral readValueForCharacteristic:characteristic];
        
        // 订阅感兴趣的特性的值
        // 虽然使用readValueForCharacteristic:方法读取特性值对于一些使用场景非常有效，但对于获取改变的值不太有效。对于大多数变动的值来讲，我们需要通过订阅来获取它们。当我们订阅特性的值时，在值改变时，我们会从peripheral对象收到通知。
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}

// 读取到特征的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData *data = characteristic.value;
    
    NSLog(@"Data = %@", data);
}

// 当我们尝试订阅特性的值时会调用下面回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error)
    {
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
    }
}


@end
