# OSEbuild Application Beta

#### This compilation is only for testing and may contain errors!
#### Use it at your own risk!

### cam.apk 
*Version:* ***19.07***

*127.0.0.1:8888*

*Compatible with Android 4.1 and above.*

```
android.permission.INTERNET
android.permission.RECEIVE_BOOT_COMPLETED
android.permission.WRITE_EXTERNAL_STORAGE
android.permission.READ_EXTERNAL_STORAGE
android.permission.WAKE_LOCK
android.permission.ACCESS_SUPERUSER ("pcscd is installed or root access is enabled")
```
---
*Create a file and activate Superuser;*
* */storage/OSEbuild/OSCam/oscam.root*
---
*Create a folder and activate log;*
* */storage/OSEbuild/log*
* */storage/OSEbuild/Pcsc/log* (pcscd is installed)
---

### tvh.apk

#### Network tuners do not require a root system.
#### USB tuners are supported if rooted and enable storage access, but this is not guaranteed.

#### I do not recommend rooting most people. Maybe you lose the guarantee and your system crashes!

*Version:* ***19.07***

*127.0.0.1:9981*

*Compatible with Android 4.1 and above.*

```
android.permission.INTERNET
android.permission.RECEIVE_BOOT_COMPLETED
android.permission.WRITE_EXTERNAL_STORAGE
android.permission.READ_EXTERNAL_STORAGE
android.permission.ACCESS_SUPERUSER ("USB tuners or root access is enabled")
```
---
*Create a folder and activate log;*
* */storage/OSEbuild/log*
---
#### installation:

```sh
cp /storage/OSEbuild/installation/"files-CPU/ABI".zip"
```
---
