Socket Mobile Capture Basic iOS Cordova Plugin
==============================================

Introduction
------------
This Socket Mobile Capture Basic iOS Cordova plugin allows to use Socket Mobile
barcode scanners with a Cordova application.

This Cordova plugin supports only iOS at this time.

**NOTE** This code is subject to change. This should be considered as early beta.

**NOTE** A future installation will use Capture Cocoapods directly, which would make easier to include this SDK directly to your project, but this version does require a clone of the project and a and clone of Capture Cocoapods.
Make sure to watch this repository to be notified when such version will be made available.

Installation
------------
Clone this repository:
`git clone git@github.com:SocketMobile/capturebasic-cordova-ios.git`

Update the Capture Basic Cordova plugin with the Capture SDK files:
```
cd capturebasic-cordova-ios
updateCaptureSdk.sh
```

Once the Capture Basic Cordova plugin has been updated with the Capture SDK files then the plugin is now ready to be added to your Cordova application:

```
cordova plugin add /Users/me/documents/dev/github/capturebasic-cordova-ios
```

To remove the plugin from your Cordova application:

```
cordova plugin remove com-socketmobile-capturebasic-cordova
```


Using the SDK in a Cordova application
--------------------------------------

This current version of the Capture SDK for Cordova is limited to notifications coming from the Socket Mobile barcode scanner.

If the code of your application is written using Typescript, you may want to
declare the main object of the Capture Basic SDK as shown here:
```
declare let CaptureBasic: any;
```

The first thing is to set the callback function that will receive the Capture SDK events:

```
CaptureBasic.addListener('notifications', (success)=>{}, (error)=>{});
```

The success function should be modified to handle the various events coming from Capture such as `deviceArrival` when a scanner connects, `deviceRemoval` when the scanner disconnects and `decodedData` when the scanner reads a barcode.

Once the listener is setup then you need to register your application to Socket Mobile developer portal, by giving the app Bundle ID, your Socket Mobile developer ID and you'll retrieved a appKey.

The application is now ready to use Capture by calling this method:
```
const appInfo = {
  appId: 'ios:com.socketmobile.tribeca',
  developerId: 'bb57d8e1-f911-47ba-b510-693be162686a',
  appKey: 'MC0CFGtbOAKfL/vF7EAXHDhg3SM6CUj5AhUArb8NDQPgMZ4V4uHHvLcla0lq5jI='
};

CaptureBasic.useCaptureBasic(appInfo,(success)=>{
      console.log('useCaptureBasic returns: ', success);
    },(error)=>{
      console.log('useCaptureBasic returns an error: ', error);
    });
```

Adding the listener could look like this:
```
CaptureBasic.addListener('notifications', (success)=>{
  const notification = JSON.parse(success);
  if (notification.name === 'initializeComplete') {
    console.log('Capture initialization completed');
  }
  else if (notification.name === 'deviceArrival'){
    console.log('device arrival: ', notification.deviceName);
  }
  else if (notification.name === 'deviceRemoval'){
    console.log('no device connected');
  }
  else if (notification.name === 'decodedData') {
    const decodedData = notification.decodedData.map(c => String.fromCharCode(c)).join('');
    console.log('decodedData: ', decodedData);
  }
},(error)=>{
  console.log('notification error: ', error);
});
```

Possible events received from Capture
-------------------------------------

#### Device Arrival
Each time a scanner is connected and ready to be used then the device arrival event is generated to let the application know a new scanner is ready.

This event contains the information about the scanner such as its type and the friendly name associated to the scanner.
The device handle identifies the scanner in a unique fashion and changes each time the scanner connects.

Here is the json data received in the Capture callback:
```
{
	"deviceHandle": "10787750208",
	"deviceType": 196619,
	"name": "deviceArrival",
	"type": "deviceType",
	"deviceName": "Socket D740 [E537BA]"
}
```

#### Device Removal
The device removal event occurs each time the scanner disconnects from the host.
It holds the information about the scanner that has just disconnected.

```
{
	"deviceType": 196619,
	"deviceHandle": "10787750208",
	"name": "deviceRemoval",
	"type": "deviceType",
	"deviceName": "Socket D740 [E537BA]"
}
```

#### Decoded Data
Each time the scanner successfully scans a barcode, the decoded data event is generated holding the decoded data, the symbology ID and the symbology name as well as the scanner information from which the decoded data came from.

```
{
	"deviceHandle": "10787750208",
	"decodedData": [
		65,
		55,
		51,
		54,
		55,
		79,
		48,
		51,
		79,
		68
	],
	"deviceName": "Socket D740 [E537BA]",
	"deviceType": 196619,
	"dataSourceId": 11,
	"dataSourceName": "Code 39",
	"type": "decodedData",
	"name": "decodedData"
}
```

If the type of the decoded data is UTF8 based a simple conversion can reformat the decoded data as a string like this:
```
if (event.name === 'decodedData') {
  const decodedData = event.decodedData.map(c => String.fromCharCode(c)).join('');
  console.log('decodedData: ', decodedData);
}
```

#### Capture initialize Complete
When Capture is initialized for the first time, an event is generated to confirm the result of the initialization.

```
{
	"name": "initializeComplete",
	"type": "result",
	"result": 0
}
```

#### Capture Terminated
When ScanAPI is shutting down, a terminate event is sent to indicate to the application that it won't receive anymore notifications from Capture.

```
{
  "name" : "captureBasicTerminated"
  "type": "result",
	"result": 0
}
```

#### Error
If an error occurs, Capture will send an event that includes the error code.

```
{
  "type" : "error",
  "name" : "onError",
  "result" : -27
}
```
