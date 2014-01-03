# Imports the monkeyrunner modules used by this program
from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
from time import sleep

# Connects to the current device, returning a MonkeyDevice object
device = MonkeyRunner.waitForConnection()


# sets a variable with the package's internal name
package = 'com.android.gallery3d'

# sets a variable with the name of an Activity in the package
activity = 'com.android.camera.CameraLauncher'

sleep(2)
# sets the name of the component to start
runComponent = package + '/' + activity

# Runs the component
device.startActivity(component=runComponent)
sleep(5)

for i in range(0, int(raw_input('please input times:'))):
    device.press('KEYCODE_CAMERA')
    sleep(2)
    print 'NO.%s'%i

print 'work done'
device.press('KEYCODE_BACK')

