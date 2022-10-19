_autoconf.hideCategoryPanels()
if antigrav ~= nil then antigrav.hideWidget() end
if warpdrive ~= nil then warpdrive.hideWidget() end
if gyro ~= nil then gyro.hideWidget() end
core.hideWidget()
unit.switchOffHeadlights()


screenMain.setRenderScript([[local rslib = require('rslib')
rslib.drawQuickImage("assets.prod.novaquark.com/59180/6a32114c-7e2c-4159-b445-d04a0fd343af.jpg")]])
