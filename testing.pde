/**
 *
 *  TESTING CODE
 *    Handles testing of the devices.
 *
 *  @author dhahaj
 */

private boolean failed=false;
private volatile boolean waiting=false, testing=false;

/**
 *  testProcess
 *   Runs the testing process.
 */
synchronized void testProcess() {

  // Make sure a device has been selected
  if (currentDevice==null) {
    testTimer.stop();
    showDialog("Select a device before testing!");
    testing=false;
    return;
  }

  // Make sure arduino has been instantiated
  else if (arduino == null) {
    testTimer.stop();
    showDialog("Cannot communicate with tester!");
    testing=false;
    return;
  }

  boolean done=false;
  testing=true;

  //  arduino.digitalWrite(QWRelay,Arduino.LOW);
  com.detex.Utils.utils.cleanGarbage();

  /*******************  EAX-300/500 Testing  **********************/

  if (currentDevice.getDevices()==Devices.EAX300 || currentDevice.getDevices()==Devices.EAX500) {
    switch (state)
    {
    case 0:
      arduino.digitalWrite(testJumper, Arduino.HIGH);
      arduino.digitalWrite(battPower, Arduino.HIGH);
      arduino.digitalWrite(testLED, Arduino.HIGH);
      sBuffer = new StringBuffer("****Starting EAX-300/500 test****");
      break;
    case 1:
      newLine(" - DC Power ON");
      break;
    case 2:
      state++;
    case 3:
      newLine(" - Starting Low Battery Test    LED's should blink alternately");
      arduino.digitalWrite(battPower, Arduino.HIGH);

      break;
    case 4:
      newLine("    Stopping Low Battery Test    LED's turn OFF");
      arduino.digitalWrite(lowBattery, Arduino.LOW);
      break;
    case 5:
      newLine("\nDo the following and press space bar when done:"
        + "\n - Press the key switch    both LED's should blink"
        + "\n - Release the key switch    both LED's should turn OFF"
        + "\n - Press the OKC switch    the siren should sound"
        + "\n - Release the OKC switch    the siren should silence"
        + "\n - Position a magnet to the right side reed switch\n       the green LED turns ON"
        + "\n - Position a magnet to the left side reed switch\n       the red LED turns ON");
      break;
    case 6:
      // Stay here until space is pressed
      testTimer.setDelay(100); // Speed up the delay time
      testTimer.stop();
      waiting=true;
      break;
    case 7:
      testTimer.setDelay(1750); // Wait for the chirps
      newLine("\n ** Clearing magnet handing memory ** ");
      arduino.digitalWrite(battPower, Arduino.LOW);
      break;
    case 8:
      newLine("     LED's Flash and Siren chirps");
      arduino.digitalWrite(battPower, Arduino.HIGH);
      arduino.digitalWrite(testJumper, Arduino.LOW);
      testTimer.setDelay(250);
      break;
    case 9:
      newLine("\n   Testing completed!");
      break;
    case 11:
      done=true;
      testTimer.setDelay(sdr1.getValue()); // Restore the delay time
      log.info("EAX-300/500 tested \t");
      break;
    default:
      break;
    }
  }


  /*******************  EAX-2500 Testing  **********************/

  else if (currentDevice.getDevices()==Devices.EAX2500) {
    switch (state)
    {
    case 0:
      sBuffer = new StringBuffer("****Starting EAX-2500 test****");
      arduino.digitalWrite(testLED, Arduino.HIGH);
      state++;
    case 1:
      newLine(" - DC Power ON    Red & Green LEDs turn ON");
      arduino.digitalWrite(testJumper, Arduino.HIGH);
      arduino.digitalWrite(battPower, Arduino.HIGH);
      break;
    case 2:
      state++;
    case 3:
      state++;
    case 4:
      arduino.digitalWrite(PAD, Arduino.HIGH);
      arduino.digitalWrite(lowBattery, Arduino.HIGH);
      newLine(" - Starting Low Battery Test    Red & Green LED's blink alternately");
      break;
    case 5:
      state++;
    case 6:
      state++;
    case 7:
      newLine(" - AC Power ON");
      arduino.digitalWrite(ACPwr, Arduino.HIGH);
      state++;
    case 8:
      arduino.digitalWrite(lowBattery, Arduino.LOW);
      arduino.digitalWrite(OKC, Arduino.HIGH);
      newLine(" - Sending the call signal    Red & Green LED's blink in unison");
      break;
    case 9:
      state++;
    case 10:
      state++;
    case 11:
      state++;
    case 12:
      arduino.digitalWrite(OKC, Arduino.LOW);
      arduino.digitalWrite(PAD, Arduino.LOW);
      newLine(" - Turning ON Door switch signal    Red LED turns ON");
      testTimer.setDelay(50);
      break;
    case 13:
      state++;
    case 14:
      state++;
    case 15:
      // Verify that the relay state is low
      //      if ( arduino.digitalRead(relayIn) == Arduino.HIGH ) {
      //        newLine("   Relay output is already active!");
      //done=true;
      //failed=true;
      //break;
      //      }
      arduino.digitalWrite(PAD, Arduino.HIGH);
      newLine(" - Press the key switch    The siren sounds...\n    waiting for relay to change states...");
      state++;
      //      break;
    case 16:
      boolean relayOK = false;
      final long startTime = millis();
      while (millis () - startTime < 5000 ) {
        int val = arduino.digitalRead(relayIn);
        // println(val);
        if ( val == Arduino.LOW) {
          line(" relay OK.");
          relayOK=true;
          break;
        } else {
          delay(50);
        }
      }
      // Restore the delay time
      testTimer.setDelay(sdr1.getValue());

      // Fail if relay did not change states
      if (!relayOK) {
        newLine("   Relay failed. \n Continuing test!");
        //failed=true;
      }
      break;
    case 17:
      //      if (failed)
      //        break;
      state++;
    case 18:
      //      if (failed) {
      //        done=true;
      //        break;
      //      }
      state++;
    case 19:
      newLine("\n Perform the following:");
      state++;
    case 20:
      arduino.digitalWrite(PAD, Arduino.HIGH);
      newLine(" - Push the slide tab in" +  "\n       Red & Green LED's turn ON");
      state++;
    case 21:
      newLine(" - Pull the slide tab out"
        +  "\n       Red & Green LED's continue to blink");
      state++;
    case 22:
      arduino.digitalWrite(lowBattery, Arduino.HIGH);
      newLine(" - Flip the Low Battery Slide Switch to ON\n       Red & Green LED's turn OFF");
      state++;
    case 23:
      newLine(" - Flip the Low Battery Slide Switch to OFF\n       Red & Green LED's blink alternately"
        + "\n\n Press space bar when finished...");
      testTimer.setDelay(200);  // Speed up the delay to improve the responsivness
      state++;
      // break;
    case 24:
      // Wait here for the space bar to be pressed
      waiting=true;
      testTimer.stop();
      break;
      // return;
    case 25:
      newLine("   Testing completed!");
      try {
        Thread.currentThread().sleep(1000);
      }
      catch(InterruptedException ie) {
        println("delay error");
      }
      state++;
    case 26:
      // Complete the testing some short time later
      log.info("EAX-2500 tested \t"); // Log the testing
      testTimer.setDelay(sdr1.getValue()); // Restore the original delay
      done=true;
      break;
    default:
      break;
    }
  }


  /*******************  V40 Testing  **********************/

  else if (currentDevice.getDevices()==Devices.V40) {

    switch (state)
    {
    case 0:
      sBuffer = new StringBuffer("****Starting V40 " + currentDevice.getModelName() + " test****");
      arduino.digitalWrite(testLED, Arduino.HIGH);
      arduino.digitalWrite(testJumper, Arduino.HIGH);
      state++;

    case 1:
      // Power on DC Power if applicable
      if (currentDevice.getModel().hasDC) {
        arduino.digitalWrite(battPower, Arduino.HIGH);
        newLine(" - DC Power ON     LEDs flash once");
        break;
      }
      state++;

    case 2:
      // Check Low Battery if applicable
      if (currentDevice.getModel().hasDC) {
        arduino.digitalWrite(lowBattery, Arduino.HIGH);
        newLine(" - Testing Low Battery Mode     LEDs blinks alternately");
        break;
      }
      state++;

    case 3:
      // Turn Off Low Battery if applicable
      if (currentDevice.getModel().hasDC) {
        arduino.digitalWrite(lowBattery, Arduino.LOW);
        newLine("      Low Battery OFF - LEDs turn OFF");
      }
      // Switch over to AC Power if applicable
      if (currentDevice.getModel().hasAC) {
        arduino.digitalWrite(ACPwr, Arduino.HIGH);
        arduino.digitalWrite(lowBattery, Arduino.LOW);
        newLine(" - AC Power ON / Low Battery OFF - LEDs turn OFF");
      }
      break;

    case 4:
      // Check the on-board pad connection
      arduino.digitalWrite(PAD, Arduino.HIGH);
      newLine(" - Sending Pad Signal     Red & Green LEDs are ON");
      break;

    case 5:
      arduino.digitalWrite(PAD, Arduino.LOW);
      newLine(" - Pad Signal OFF     Red & Green LEDs are OFF");
      break;

    case 6:
      // Check the on-board OKC connection
      arduino.digitalWrite(OKC, Arduino.HIGH);
      newLine(" - Sending OKC Signal     Red & Green LEDs blink in unison");
      break;

    case 7:
      arduino.digitalWrite(OKC, Arduino.LOW);
      newLine(" - OKC Signal OFF     Red & Green LEDs turn OFF");
      break;

    case 8:
      if (currentDevice.getModel().hasWires) {
        // Check the remote connection on wire leads
        arduino.digitalWrite(remote, Arduino.HIGH);
        newLine(" - Remote Signal ON     Red & Green LEDs blink in unison");
        break;
      }
      state++; // No wire leads continue on

    case 9:
      if (currentDevice.getModel().hasWires) {
        arduino.digitalWrite(remote, Arduino.LOW);
        newLine(" - Remote Signal OFF     Red & Green LEDs turn OFF");
        break;
      }
      state++;

    case 10:
      // Turn off DC power to ensure that the AC power is working
      if (currentDevice.getModel().hasAC) {
        arduino.digitalWrite(battPower, Arduino.LOW);
        newLine(" - DC Power OFF     LEDs will flash");
        break;
      }
      state++;

    case 11:
      // Check the relay if applicable
      testTimer.setDelay(100);
      if (currentDevice.getModel().hasRelay && !currentDevice.getModel().hasWires) {
        newLine("Press the key switch (white wires)     Siren sounds and relay activates\nChecking relay now...\n");
      }
      break;

    case 12:
      if (currentDevice.getModel().hasRelay && !currentDevice.getModel().hasWires) {
        long startTime = millis();
        while (millis () - startTime < 5000) {
          if (arduino.digitalRead(relayIn) == Arduino.LOW) {
            line("   Relay OK. Release the key switch");
            state++;
            return;
          }
        }
        newLine("   relay failed. \n Continuing test!");
        //failed = true;
        break;
      } else { // No relay, check the key switch anyways
        newLine("   Press the key switch (white wires) now - Siren sounds.");
        state++;
      }

    case 13:
      if (failed) { // Means the relay check has failed!
        done = true;
        break;
      }
      state++;

    case 14:
      newLine("Press the Pad switch (Blue Wires) - Both LEDs turn ON");
      state++;

    case 15:
      newLine(" **Press the space bar when finished");
      state++;

    case 16:
      testTimer.stop(); // Wait here for spacebar
      waiting = true;
      break;

    case 17:
      testTimer.setDelay(sdr1.getValue());
      newLine("   Testing Completed!");
      log.info("V40 tested \t");
      done = true;
      break;

    default:
      break;
    }
  }


  /*******************  EAX-3500 Testing  ================= */

  else if (currentDevice.getDevices()==Devices.EAX3500) {
    newLine("\nEAX-3500 testing not available!\n");
    testTimer.stop(); // Stop the timer
    done=true;
    return;
  } else {
    newLine("\nError running test");
    testTimer.stop();
  }

  if ( done ) { // Testing Finished

    testTimer.stop(); // Stop the timer

    if (!failed)
      ConfirmPass();
    else
      user.getUser().incrementCount(LoginThread.FAILED_CNT);

    // Turn off all outputs
    for (int i=0; i<outputs.length; i++) {
      if (outputs[i] == heartBeatPin) // Skip the COM LED
        continue;
      arduino.digitalWrite(outputs[i], Arduino.LOW);
    }

    arduino.pinMode(inputs[0], Arduino.INPUT);
    state=0;
    try {
      Thread.currentThread().sleep(750);
    }
    catch(Exception ie) {
    }
    sBuffer = new StringBuffer(currentDevice.getTestingSetup());
    testing=false;
    failed=false;
    waiting=false;
    return;
  }

  state++;
}

/**
 *  ConfirmPass
 *
 *  @description Displays a dialog for the user to confirm a pass or fail.
 */
public void ConfirmPass() {
  Runnable doConfirmPass = new Runnable() {
    public void run() {
      Object[] options = {
        "PASSED", "FAILED", "Cancel"
      };
      int exitChoice = javax.swing.JOptionPane.showOptionDialog(frame, "Please select an option below", "Confirm", 
      javax.swing.JOptionPane.YES_NO_OPTION, javax.swing.JOptionPane.PLAIN_MESSAGE, 
      null, options, options[0]);

      switch(exitChoice) {
      case javax.swing.JOptionPane.YES_OPTION:
        user.getUser().incrementCount(LoginThread.PASSED_CNT);
        user.getUser().incrementCount(LoginThread.TOTAL_CNT);
        break;
      case javax.swing.JOptionPane.NO_OPTION:
        user.getUser().incrementCount(LoginThread.FAILED_CNT);
        user.getUser().incrementCount(LoginThread.TOTAL_CNT);
        break;
      default:
        break;
      }
    }
  };
  SwingUtilities.invokeLater(doConfirmPass);
}

/**
 *  newLine
 *    appends a String to the testing console display.
 */
public void newLine(String string) {
  line("\n" + string);
}

/**
 *  See newline
 */
public void line(String string) {
  sBuffer.append(string);
}

