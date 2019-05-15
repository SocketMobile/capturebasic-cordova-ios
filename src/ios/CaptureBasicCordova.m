/********* CaptureBasicCordova.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "SktCaptureHelper.h"

@interface ResponseBuilder: NSObject {
    NSMutableDictionary* response;
}
-(instancetype)init;
-(ResponseBuilder*)addResult:(long)result;
-(ResponseBuilder*)addResponseType:(NSString*)type;
-(ResponseBuilder*)addName:(NSString*)name;
-(ResponseBuilder*)addString:(NSString*)value withKey:(NSString*)key;
-(ResponseBuilder*)addLong:(long)value withKey:(NSString*)key;
-(ResponseBuilder*)addArray:(NSArray*)value withKey:(NSString*)key;
-(ResponseBuilder*)combineDictionary:(NSDictionary*)dictionary;
-(NSDictionary*)build;
@end

@implementation ResponseBuilder
- (instancetype)init
{
    self = [super init];
    if (self) {
        response = [NSMutableDictionary new];
    }
    return self;
}

-(ResponseBuilder*)addResult:(long)result {
    NSNumber* resultObj = [NSNumber numberWithLong:result];
    NSDictionary* error=[NSDictionary dictionaryWithObjectsAndKeys:
                         resultObj, @"result", nil];
    [response addEntriesFromDictionary:error];
    return self;
}

-(ResponseBuilder*)addResponseType:(NSString*)type {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                         type, @"type",nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)addName:(NSString*)name {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                name, @"name",nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)addString:(NSString*)value withKey:(NSString*)key {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                value, key, nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)addLong:(long)value withKey:(NSString*)key {
    NSNumber* valueObj = [NSNumber numberWithLong:value];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                         valueObj, key, nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)addArray:(NSArray*)value withKey:(NSString*)key {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                value, key, nil];
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(ResponseBuilder*)combineDictionary:(NSDictionary*)dictionary {
    [response addEntriesFromDictionary:dictionary];
    return self;
}

-(NSDictionary*)build {
    return self->response;
}

@end

@interface CaptureBasicCordova : CDVPlugin <SKTCaptureHelperDelegate> {
    // Member variables go here..
    NSString* _callbackId;
    SKTCaptureHelper* _capture;
    NSDictionary* _devices;
}

- (void)useCaptureBasic:(CDVInvokedUrlCommand*)command;
- (void)addCaptureListener:(CDVInvokedUrlCommand*)command;
- (void)getProperty:(CDVInvokedUrlCommand*)command;
- (void)setProperty:(CDVInvokedUrlCommand*)command;
@end

@implementation CaptureBasicCordova

- (void)useCaptureBasic:(CDVInvokedUrlCommand*)command
{
    NSDictionary* args = [command argumentAtIndex: 0];
    NSString* callbackId = command.callbackId;
    SKTAppInfo* appInfo = [SKTAppInfo new];
    if(args.count >= 3){
        appInfo.AppID = [args objectForKey: @"appId"];
        appInfo.AppKey = [args objectForKey: @"appKey"];
        appInfo.DeveloperID = [args objectForKey: @"developerId"];
        _capture = [SKTCaptureHelper sharedInstance];
        [_capture pushDelegate:self];
        [_capture openWithAppInfo:appInfo completionHandler:^(SKTResult result) {
            NSDictionary* response = [[[ResponseBuilder new]
                                       addResult:result]
                                      build];
            [self sendJsonFromDictionary:response withCallbackId:callbackId keepCallback:NO];
        }];
    }
    else {
        [self sendError:(long) SKTCaptureE_INVALIDPARAMETER withCallbackId:callbackId keepCallback:NO];
    }
}

- (void)addCaptureListener:(CDVInvokedUrlCommand*)command {
    self->_callbackId = command.callbackId;
}

- (void)getProperty:(CDVInvokedUrlCommand*)command {
    NSString* callbackId = command.callbackId;
    if(_capture != nil) {
        NSDictionary* args = [command argumentAtIndex: 0];
        SKTCaptureProperty* property = [self getCapturePropertyFromArgs: args];
        SKTCaptureHelperDevice* device = [self getDeviceFromArgs: args];
        if(device != nil) {
            [CaptureBasicCordova getProperty:property fromDevice:device];
        }
        else if([CaptureBasicCordova isCaptureProperty:property]){
            [CaptureBasicCordova getProperty:property];
        }
        else {
            //TODO: Error the property cannot be get, the device is not specified
        }
    }
    else {
        // return an error
        [self sendError:(long) SKTCaptureE_NOTINITIALIZED withCallbackId:callbackId  keepCallback:NO];
    }
}

- (void)setProperty:(CDVInvokedUrlCommand*)command {
    NSString* callbackId = command.callbackId;
    if(_capture != nil) {
        NSDictionary* args = [command argumentAtIndex: 0];
        SKTCaptureProperty* property = [self getCapturePropertyFromArgs: args];
        SKTCaptureHelperDevice* device = [self getDeviceFromArgs: args];
        if(device != nil) {
            [CaptureBasicCordova setProperty:property toDevice:device];
        }
        else if([CaptureBasicCordova isCaptureProperty:property]){
            [CaptureBasicCordova setProperty:property];
        }
        else {
            //TODO: Error the property cannot be set, the device is not specified
        }
    }
    else {
        // return an error
        [self sendError:(long) SKTCaptureE_NOTINITIALIZED withCallbackId:callbackId keepCallback:NO];
    }
}

-(SKTCaptureHelperDevice*)getDeviceFromArgs:(NSDictionary*)args {
    SKTCaptureHelperDevice* device = nil;
    return device;
}

-(SKTCaptureProperty*) getCapturePropertyFromArgs:(NSDictionary*) args {
    NSNumber* propId = [args objectForKey: @"propId"];
    NSNumber* propType = [args objectForKey: @"propType"];
    SKTCaptureProperty* property = [SKTCaptureProperty new];
    property.ID = (SKTCapturePropertyID)propId.longValue;
    property.Type = (enum SKTCapturePropertyType)propType.intValue;
    [self fillProperty:property fromArgs:args];
    return property;
}

-(SKTResult) fillProperty:(SKTCaptureProperty*) property
                 fromArgs:(NSDictionary*)args {

    SKTResult result = SKTCaptureE_NOERROR;
    switch(property.Type) {
        case SKTCapturePropertyTypeNone:
            break;
        case SKTCapturePropertyTypeByte:
            break;
        case SKTCapturePropertyTypeUlong:
            break;
        case SKTCapturePropertyTypeArray:
            break;
        case SKTCapturePropertyTypeString:
            break;
        case SKTCapturePropertyTypeVersion:
            break;
        case SKTCapturePropertyTypeDataSource:
            break;
        case SKTCapturePropertyTypeEnum:
            break;
        case SKTCapturePropertyTypeObject:
            break;
        case SKTCapturePropertyTypeLastType:
            break;
        case SKTCapturePropertyTypeNotApplicable:
            break;
    }
    return result;
}

- (void)sendError:(long) result
   withCallbackId:(NSString*) callbackId
     keepCallback:(BOOL) keep {
    NSDictionary* error=[[[[[ResponseBuilder new]
                           addResponseType:@"result"]
                          addName:@"onError"]
                         addResult:result]
                         build];
    [self sendJsonFromDictionary:error
                  withCallbackId:callbackId
                   keepCallback:keep];
}

-(void)sendJsonFromDictionary:(NSDictionary*)dictionary
               withCallbackId:(NSString*)callbackId
                 keepCallback:(BOOL) keep {
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];

    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [result setKeepCallbackAsBool:keep];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

-(SKTCaptureHelperDevice*)getDeviceFromHandle:(NSString*)handle {
    SKTCaptureHelperDevice* device = nil;
    if (_capture != nil) {
        NSArray* devices = [_capture getDevicesList];
        for (SKTCaptureHelperDevice* d in devices) {
            NSString* h = [CaptureBasicCordova getHandleFromDevice:d];
            if ([h containsString:handle]) {
                device = d;
                break;
            }
        }
    }
    return device;
}

+(NSString*)getHandleFromDevice:(SKTCaptureHelperDevice*)device {
    NSString* handle = [NSString stringWithFormat:@"%ld",(long)device];
    return handle;
}

+(void)getProperty:(SKTCaptureProperty*)property
    fromDevice:(SKTCaptureHelperDevice*)device {
    [device getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
        // TODO needs to report the result to the app
    }];
}

+(void)getProperty:(SKTCaptureProperty*)property {

}

+(void)setProperty:(SKTCaptureProperty*)property
        toDevice:(SKTCaptureHelperDevice*)device {

}

+(void)setProperty:(SKTCaptureProperty*)property {

}

+(BOOL)isCaptureProperty:(SKTCaptureProperty*)property {
    BOOL isCapture = FALSE;
    long propertyId = (long)property.ID;
    if ((propertyId & 0x80000000) == 0x80000000){
        isCapture = TRUE;
    }
    return isCapture;
}

#pragma  mark - CaptureBasicHelperDelegate
/**
 * called each time a device connects to the host
 * @param result contains the result of the connection
 * @param deviceInfo contains the device information
 */
-(void)didNotifyArrivalForDevice:(SKTCaptureHelperDevice *)device
                      withResult:(SKTResult)result{
    NSLog(@"didNotifyArrivalForDevice: %@ Result: %ld", device.friendlyName, result);
    NSString* callbackId = self->_callbackId;

    NSString* handle = [CaptureBasicCordova getHandleFromDevice:device];
    NSDictionary* deviceArrival =
        [[[[[[[[ResponseBuilder new]
                        addName:@"deviceArrival"]
                addResponseType:@"deviceType"]
                      addString:handle withKey:@"deviceHandle"]
                      addString:device.friendlyName withKey: @"deviceName"]
                        addLong:(long)device.deviceType withKey: @"deviceType"]
                        addResult:(long)result]
                                 build];

    [self sendJsonFromDictionary:deviceArrival withCallbackId:callbackId keepCallback:YES];
}

/**
 * called each time a device disconnect from the host
 * @param deviceRemoved contains the device information
 */
 -(void) didNotifyRemovalForDevice:(SKTCaptureHelperDevice*) deviceRemoved
                        withResult:(SKTResult)result {
    NSString* callbackId = self->_callbackId;
    NSString* handle = [CaptureBasicCordova getHandleFromDevice: deviceRemoved];
    NSDictionary* deviceRemoval =
        [[[[[[[[ResponseBuilder new]
        addName:@"deviceRemoval"]
        addResponseType:@"deviceType"]
        addString:deviceRemoved.friendlyName withKey:@"deviceName"]
        addLong:deviceRemoved.deviceType withKey:@"deviceType"]
        addString:handle withKey:@"deviceHandle"]
        addResult:(long)result]
        build ];

    [self sendJsonFromDictionary:deviceRemoval withCallbackId:callbackId keepCallback:YES];
}

/**
 * called each time CaptureBasic is reporting an error
 * @param result contains the error code
 */
-(void) didReceiveError:(SKTResult)error withMessage:(NSString *)message{
    NSLog(@"didReceiveError error: %ld", error);
    NSString* callbackId = self->_callbackId;
    NSDictionary* errorResult=
        [[[[[ResponseBuilder new]
            addResponseType:@"error"]
            addName:@"onError"]
            addResult:error]
            build];

    [self sendJsonFromDictionary:errorResult withCallbackId:callbackId keepCallback:YES];
}

/**
 * called when CaptureBasic initialization has been completed
 * @param result contains the initialization result
 */
-(void)listenerDidStart{
    NSString* callbackId = self->_callbackId;
    NSDictionary* initComplete =
        [[[[[ResponseBuilder new]
           addName:@"initializeComplete"]
           addResponseType:@"result"]
           addResult:(long)SKTCaptureE_NOERROR]
           build];
    [self sendJsonFromDictionary:initComplete withCallbackId:callbackId keepCallback:YES];
}

/**
 * called when CaptureBasic has been terminated. This will be
 * the last message received from CaptureBasic
 */
-(void) didTerminateWithResult:(SKTResult)result{
    NSString* callbackId = self->_callbackId;
    NSDictionary* captureTerminated =
    [[[[[ResponseBuilder new]
       addName:@"captureBasicTerminated"]
       addResponseType:@"result"]
       addResult:result]
     build];

    [self sendJsonFromDictionary:captureTerminated withCallbackId:callbackId keepCallback:YES];
}

/**
 * called each time CaptureBasic receives decoded data from scanner
 * @param result is ESKT_NOERROR when decodedData contains actual
 * decoded data. The result can be set to ESKT_CANCEL when the
 * end-user cancels a SoftScan operation
 * @param device contains the device information from which
 * the data has been decoded
 * @param decodedData contains the decoded data information
 */
-(void) didReceiveDecodedData:(SKTCaptureDecodedData *)decodedData
                   fromDevice:(SKTCaptureHelperDevice *)device
                   withResult:(SKTResult)result{
    NSString* callbackId = self->_callbackId;
    NSString* handle = [CaptureBasicCordova getHandleFromDevice: device];
    NSInteger len = (int)decodedData.DecodedData.length;
    const unsigned char* pData = decodedData.DecodedData.bytes;
    NSMutableArray* dataArray = [[NSMutableArray alloc]initWithCapacity:len];
    for(int i = 0; i< len; i++){
        NSNumber* num = [NSNumber numberWithUnsignedChar:(unsigned char)pData[i]];
        [dataArray addObject:num];
    }
    NSDictionary* decodedDataDictionary=[[[[[[[[[[ResponseBuilder new]
        addName:@"decodedData"]
        addResponseType:@"decodedData"]
        addString:device.friendlyName withKey:@"deviceName"]
        addLong:device.deviceType withKey:@"deviceType"]
        addString:handle withKey:@"deviceHandle"]
        addArray:dataArray withKey:@"decodedData"]
        addLong:decodedData.DataSourceID withKey:@"dataSourceId"]
        addString:decodedData.DataSourceName withKey:@"dataSourceName"]
        build];
    [self sendJsonFromDictionary:decodedDataDictionary withCallbackId:callbackId keepCallback:YES];
}


@end
