--tickDisplay(TickRate:0.5)

--initalize
if not displayInit then
    displayInit = true
    fontSize = "2.1"
end

screenMain.setHTML([[

<div class="bootstrap">
    <table style="
        margin-top: auto;
        margin-left: auto;
        margin-right: auto;
        width: 100%;
        font-size: ]]..fontSize..[[em;">
            <tr style="
            	width: 50%;
            	background-color: White;
            	color: black;">
            	<th class="span" colspan="2">Autopilot State</th>
            </tr>
            <tr>
            	<th>currentAltitude</th>
            	<th>]]..round(ap.currentAltitude,2)..[[</th>
            </tr>
            <tr>
            	<th>Target Altitude</th>
            	<th>]]..ap.targetAltitude..[[</th>
            </tr>            
            <tr>
            	<th>PID output</th>
            	<th>]]..round(ap.altitudePID:get(),5)..[[</th>
            </tr>
            <tr>
            	<th>Autopolio Enabled</th>
            	<th>]]..tostring(ap.enabled)..[[</th>
            </tr>
                        <tr>
            	<th>thrustUp</th>
            	<th>]]..printNumericTable(ap.thrustUp,2)..[[</th>
            </tr>
            <tr>
            	<th>thrustDown</th>
            	<th>]]..printNumericTable(ap.thrustDown,2)..[[</th>
            </tr>
            <tr>
            	<th>thrustRight</th>
            	<th>]]..printNumericTable(ap.thrustRight,2)..[[</th>
            </tr>
            <tr>
            	<th>thrustLeft</th>
            	<th>]]..printNumericTable(ap.thrustLeft,2)..[[</th>
            </tr>
            <tr>
            	<th>thrustForwards</th>
            	<th>]]..printNumericTable(ap.thrustForwards,2)..[[</th>
            </tr>
            <tr>
            	<th>thrustBack</th>
            	<th>]]..printNumericTable(ap.thrustBack,2)..[[</th>
            </tr>
	</table>
        <table style="
        margin-top: auto;
        margin-left: auto;
        margin-right: auto;
        width: 100%;
        font-size: ]]..fontSize..[[em;">
            <tr style="
            	width: 100%;
            	background-color: White;
            	color: black;">
            	<th class="span" colspan="2">Elevator State</th>
            </tr>
            <tr>
            	<th>Brakes</th>
            	<th>]]..brakeInput..[[</th>
            </tr>
	</table>
</div>]])