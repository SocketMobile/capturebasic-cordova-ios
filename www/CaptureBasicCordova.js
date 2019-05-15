var exec = require('cordova/exec');

exports.useCaptureBasic = function(arg0, success, error) {
  exec(success, error, 'CaptureBasicCordova', 'useCaptureBasic', [arg0]);
};

exports.addListener = function(arg0, success, error) {
  exec(success, error, 'CaptureBasicCordova', 'addCaptureListener', [arg0]);
};

// exports.setProperty = function(arg0, success, error) {
//   exec(success, error, 'CaptureBasicCordova', 'setProperty', [arg0]);
// };
//
// exports.getProperty = function(arg0, success, error) {
//   exec(success, error, 'CaptureBasicCordova', 'getProperty', [arg0]);
// };
