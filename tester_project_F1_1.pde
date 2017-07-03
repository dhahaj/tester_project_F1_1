/*******************************************************************************************************************
 *******************************************************************************************************************
 **        Tester Interface Software                                                                              **
 **                                                                                                               **
 **  Changelog:                                                                                                   **
 **  E3.1 2/7/2014:                                                                                               **
 **      1) Relocated EAX-300 Menu                                                                                **
 **      2) Removed '5 Chirp' Verbage from EAX300/500 Test                                                        **
 **      3) Added new user - EMH                                                                                  **
 **       4) Added EAX2545                                                                                        **
 **                                                                                                               **
 **  E3.2 8/14/2014                                                                                               **
 **    1) Added EAX2505                                                                                           **
 **  E3.3 12/11/2014                                                                                              **
 **    1) Modified EAX2500 Testing Sequence                                                                       **
 **  E3.4 10/22/2015                                                                                              **
 **             1) Update V40 firmware version.                                                                   **
 **             2) Added V40 Silent Arming Firmware.                                                              **
 **  F1.0 10/26/2015                                                                                              **
 **             1) Modified V40 test procedure to match the updated software. (see "testing.pde" source code)     **
 **                                                                                                               **
 **  F1.1 5/11/2017                                                                                               **
 **        1) Performace enchancements (Less dependance on graphic prossesing power.                              **
 **        2) Modified Pinout to match the new controller board                                                   **
 **        3) Implementing GUI swing the Swing Framework for improved responsiveness                              **
 **                                                                                                               **
 **  F1.2 6/18/2017                                                                                               **
 **        1) Changed User setup to be configured from the user.json file in the data folder.                     **
 **        2) Moved Device.java, Programs.java, User.java to the com.detex package.                               **
 **        3) Created the class UserLoader for managing the users and configuration file.                         **
 **                                                                                                               **
 **                                                                                                               **
 *******************************************************************************************************************
 *******************************************************************************************************************/

import java.util.logging.*;
import java.util.prefs.*;
import java.util.*;
import guicomponents.*;
import processing.serial.*;
import cc.arduino.*;
import java.awt.event.*;
import java.awt.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.Timer;
import java.nio.*;
import java.nio.channels.*;
import java.io.*;
import java.lang.instrument.*;
import java.text.*;
import com.detex.Device.*;
import com.detex.User.*;
import com.detex.logging.*;
import com.detex.*;
import com.detex.Utils.*;
import static java.nio.charset.Charset.defaultCharset;
import java.math.*;

final static boolean DEBUG = false;
final static String WIN_TITLE = "Tester Interface - ver F1.2.0";

Device currentDevice = null;
GWSlider sdr1;
Arduino arduino = null;
PFont font, bfont;
Timer testTimer;
StringBuffer sBuffer;
PImage detexLogo;
LoginThread user = null;
static Logger log;
static String dpath;
Table table;

final int ACPwr = 9, lowBattery = 2, testJumper = 3, battPower = 4, relayIn = 7, 
testLED = 12, heartBeatPin = 13, remote = 5, PAD = 6, OKC = 8;

final int[] inputs = {
  relayIn
}
, outputs = {
  ACPwr, battPower, testJumper, PAD, OKC, /*QWRelay,*/ lowBattery, remote, testLED, heartBeatPin
};

int timeDelay, time = 0, state = 0, comPort;

boolean flag = false, running = false;

/**
 *  Customize the parent window
 *   Sets the window's title to show the software revision
 */
void init() {
  frame.removeNotify();
  frame.setTitle(WIN_TITLE);
  frame.setCursor(1);
  frame.addNotify();
  super.init();
}

/**
 *  ChangeWindowListener
 *   Needed to capture window events to perform various operations
 */
void ChangeWindowListener() {  // Needed for confirming an exit
  WindowListener[] wls = frame.getWindowListeners();
  frame.removeWindowListener(wls[0]); // Suppose there is only one...
  frame.addWindowListener( new WindowAdapter() {
    @Override
      public void windowClosing(WindowEvent we) {
      Logger.getLogger(this.getClass().getName()).entering(this.getClass().getName(), "windowClosing");
      ConfirmExit();
    }

    @Override
      public void windowActivated(WindowEvent e) {
      user.restartTimer();
    }
  }
  );
}

/**
 *  showDialog
 *   Helper method to show a JOptionPane dialog window. Invokes it on the EDT for thread safety.
 *
 *  @param [in] string The message to display.
 */
void showDialog(String s) { // Runs a swing error dialog
  final String msg = s;
  SwingUtilities.invokeLater( new Runnable() {
    public void run() {
      javax.swing.JOptionPane.showMessageDialog(frame, msg, "Error", javax.swing.JOptionPane.ERROR_MESSAGE );
    }
  }
  );
}

/**
 *  ConfirmExit
 *   Displays a dialog window before closing the software
 */
void ConfirmExit() {
  SwingUtilities.invokeLater( new Runnable() {
    @Override
      public void run() {
      int exitChoice = javax.swing.JOptionPane.showConfirmDialog(frame, 
      "Are you sure you want to exit?", "Confirm exit", javax.swing.JOptionPane.YES_NO_OPTION );

      if (exitChoice != javax.swing.JOptionPane.YES_OPTION)
        return;

      final User u = user.getUser();
      if (u!=null)
        log.info("\nUser " + u.getName()
        +" closed software\n\t*devices passed: " + u.getCount(LoginThread.PASSED_CNT)
        +"\n\t*devices failed: " + u.getCount(LoginThread.FAILED_CNT)
        +"\n\t*total devices tested: " + u.getCount(LoginThread.TOTAL_CNT)
        +"\n\t*devices programmed: " + u.getCount(LoginThread.PROG_CNT)
        +"\n\t*" );

      else log.info("Software closed");
      user.quit();
      System.exit(0);
    }
  }
  );
}


/*************  Programming Code  *****************/

/**
 *  Program
 *
 *  @brief Function which creates a new process for running the QW software
 */
void Program () {

  // Do not program the device while testing is active
  if (testTimer.isRunning() || waiting || testing) {
    showDialog("Testing is currently active!");
    return;
  } else if (currentDevice==null) {
    showDialog("Should probably choose the device you're testing before attempting to program it..");
    return;
  } else if (arduino==null) {
    arduino.digitalWrite(testJumper, Arduino.LOW);  // Remove test jumper from ground
    arduino.digitalWrite(battPower, Arduino.LOW);  // Make sure DC power is off before programming!
  }

  String location = Keys.getString("FIRMWARE_FOLDER") + File.separator + currentDevice.getProgram().toString();

  // Set the arguments from the stored settings
  final String[] qw_args = new String[4];
  qw_args[0] = Keys.getString("QW_PATH");
  qw_args[2] = Keys.getString("QW_ARUN") + " " + Keys.getString("QW_CHIP");
  qw_args[3] = Keys.getString("QW_AEXIT");

  String firmwareDirectory = dataPath("firmware");

  // Add the file extension to the location string
  switch(currentDevice.getDevices()) {
  case EAX300:
    location += Keys.getString("EAX300_EXT");
    break;
  case EAX500:
    location += Keys.getString("EAX500_EXT");
    break;
  case EAX2500:
    location += Keys.getString("EAX2500_EXT");
    break;
  case EAX3500:
    location += Keys.getString("EAX3500_EXT");
    break;
  case V40:
    location += Keys.getString("V40_EXT");
    break;
  }

  debug("hex file location: " + location);
  if (!(utils.dataFileExists(location))) {
    // Make sure you can access the target firmware
    showDialog("File not found:\n" + location);
    return;
  }

  // Path to the quickwriter control file
  final String ctrlFilePath = dataPath("QWControl.qwc");

  // Make sure the file exists
  if (!utils.dataFileExists(ctrlFilePath)) {
    showDialog("Could not find QuickWriter control file.");
    return;
  }

  // Load the control file
  final File ctrlFile = new File(ctrlFilePath);
  String[] ctrlStrings = getContents(ctrlFile).split("\n");

  // Get the serial number and make sure it is not greater than 100
  //  (QW EEData Limitations)
  int lastSerialNumber = Keys.getInt("LAST_SERIAL");
  if (lastSerialNumber % 100 ==0)
    lastSerialNumber = 0;

  final int newSerialNumber = lastSerialNumber + 1;

  // Create a hex formatted string
  String user_date_hex = parseHex(user.getUser(), newSerialNumber);

  for (int i=0; i<ctrlStrings.length; i++) {

    // Change the hex file location in the control file
    if (ctrlStrings[i].contains("HEXFILE")) {
      ctrlStrings[i] = "HEXFILE=" + location;
      continue;
    }

    // Ensure we manualy control the serial numbering
    else if (ctrlStrings[i].contains("Auto=1")) {
      ctrlStrings[i] = "Auto=0";
      continue;
    }

    // Set the hex string for the EE Data Section
    else if (ctrlStrings[i].contains("last_a")) {
      // Put the serial number in the control file (hex format)
      ctrlStrings[i] = "last_a=" + user_date_hex;
      debug("Appending to control file: " + ctrlStrings[i]);
    }
  }

  // Save the modified control file
  try {
    setContents(ctrlFile, join(ctrlStrings, "\n"));
  }
  catch(Exception e) {
    showDialog("Couldn't save the control file!");
    println(e);
    return;
  }

  // Put the arg in qoutes to handle any whitespaces chars
  qw_args[1] = '"' + ctrlFilePath + '"';

  debug("Programming Args:");
  debug(join(qw_args, " "));

  if (arduino!=null) {
    arduino.digitalWrite(testJumper, Arduino.LOW);  // Remove test jumper from ground
    arduino.digitalWrite(battPower, Arduino.LOW);  // Make sure DC power is off before programming!
  }

  // Open the QW Software and wait for an exit code
  // to determine if it programmed correctly
  Runnable runQuickWriter = new Runnable() {
    @Override
      public void run() {
      String args = join(qw_args, " ");
      debug("quickwriter args: " + args);
      Runtime r = Runtime.getRuntime();
      Process p = null;
      try {
        p = r.exec(args);
        p.waitFor();
      }
      catch(Exception e) {
        debug("error programming");
      }

      debug("QW return value: " + p.exitValue());
      short exitValue = (short)(p.exitValue());

      if (exitValue != 0) { // Returned with an error
        ByteBuffer b = ByteBuffer.allocate(4);
        b.putInt(exitValue);
        byte lowByte = b.get(3);
        String errMsg = null;
        switch(lowByte) {
        case 1:
          errMsg = "Error communicating with Port";
          break;
        case 2:
          errMsg = "Communication Timeout, Hardware not responding";
          break;
        case 4:
          errMsg = "Communication Error Detected, BAD data received";
          break;
        case 8:
          errMsg = "Current Programming Task Failed";
          break;
        case 10:
          errMsg = "Firmware update Required";
          break;
        case 20:
          errMsg = "Higher Transfer Speed Failed";
          break;
        case 40:
          errMsg = "User Aborted Task in progress";
          break;
        case 80:
        default:
          errMsg = "Unknown Error has Occurred";
          break;
        }

        byte highByte = b.get(2);
        debug("low byte = "+lowByte);
        debug("high byte = "+highByte);
        // byte[] result = b.array();
        // println(result);

        sBuffer.append("\nError: " + errMsg);
        log.warning("Error programming " + currentDevice.getProgram().toString()
          + ", " + errMsg);
        showDialog(errMsg);
      } else { // Programming was succesful

        sBuffer.append("\n\nProgramming Succesful! ");

        // Make a log entry
        log.info("Programming initiated by " + user.getUsername()
          + " -- " + currentDevice.getProgram().toString()
          + " Serial#:" + newSerialNumber + "(" + hex(newSerialNumber) + ")" );

        // Increment the user's programming count
        user.getUser().incrementCount(LoginThread.PROG_CNT);

        // Save the last used serial number
        Keys.LAST_SERIAL.setPref(newSerialNumber);
        debug("Saved serial number: " + Keys.getInt("LAST_SERIAL"));
      }
    }
  };
  runQuickWriter.run();
}

/**
 *  keyPressed
 *    Handles key press events
 */
void keyPressed() {

  if (key == ESC) {
    key=0;
    if (!user.loggedin()) return;
    // If not testing, then confirm exiting the software
    ConfirmExit();
  } else if (key=='p' || key=='P') {
    Program();
  } else if (key=='t' || key=='T') {
    if (!testTimer.isRunning() && !waiting) {
      testTimer.setDelay(sdr1.getValue()); // Restore the delay time
      testTimer.start();
    } else if (testing) {
      showDialog("Finish current test before starting a new one!");
    }
  }

  // "+" keys increase the slider value
  else if (keyCode==107 || keyCode==61) {
    sdr1.setValue(sdr1.getValue() + 100);
  }

  // "-" keys decrease the slider value
  else if (keyCode==109 || keyCode==45) {
    sdr1.setValue(sdr1.getValue() - 100);
  }

  // Finish testing by pressing the space bar
  else if ( keyCode == java.awt.event.KeyEvent.VK_SPACE && waiting) {
    testTimer.start();
    waiting=false;
    // state  ++;
  } else if ( key == '~') {
    println(testTimer.getDelay());
  } else if (keyCode==112) {
    open(dataPath("software_instructions.pdf"));
  } else if (keyCode==113) {
    showPrefs.getActionListeners()[0].actionPerformed(new java.awt.event.ActionEvent(this, 1, "Show Settings"));
  } else if (keyCode==114) {
    displaySize.getActionListeners()[0].actionPerformed(new java.awt.event.ActionEvent(this, 1, "Change display size"));
  } else if (keyCode==115) {
    
    //displaySize.getActionListeners()[0].actionPerformed(new java.awt.event.ActionEvent(this, 1, "Change display size"));
  } else {
    debug("key:"+key+" keyCode:"+keyCode);
  }

  //  else {
  //    debug(str(key) + "/" + str(keyCode));
  //  }
}

/**
 *  mouseMoved
 *    Resets the auto-logout timer while the user is active
 */
void mouseMoved() {
  user.restartTimer();
}

/**
 *  Class which allows only a single instance to run
 */
public class SingleInstance {

  private File f;
  private FileChannel channel;
  private FileLock lock;
  private boolean locked;
  private PApplet parent;

  public SingleInstance(PApplet parent) {
    this.parent = parent;
    locked=false;
  }

  public void start() {
    locked=false;
    try {
      f = new File(dataPath("RingOnRequest.lock"));

      // Check if the lock exist
      if (f.exists())
        f.delete(); // if exist try to delete it
      // Try to get the lock
      channel = new RandomAccessFile(f, "rw").getChannel();
      lock = channel.tryLock();

      if (lock == null)
      {
        // File is locked by other application
        channel.close();
        locked=true;
        // throw new RuntimeException("Only 1 instance of MyApp can run.");
      }
      // Add shutdown hook to release lock when application shutdown
      // ShutdownHook shutdownHook = new ShutdownHook();
      // Runtime.getRuntime().addShutdownHook(shutdownHook);

      //Your application tasks here..
      debug("Running");
    }
    catch(IOException e) {
      //throw new RuntimeException("Could not start process.", e);
    }
  }

  public boolean isLocked() {
    return locked;
  }

  /**
   *  unlockFile
   *
   *  @details Release and delete lock file.
   */
  public void unlockFile() {
    try {
      if (lock != null) {
        lock.release();
        channel.close();
        f.delete();
        debug("File Unlocked");
      }
    }
    catch(IOException e) {
      e.printStackTrace();
    }
  }
}

/**
 *  getSize
 *
 *  @param [in] sb The string buffer.
 *  @return int The size of the string buffer
 */
public int getSize(StringBuffer sb) {
  final char[] chars = new char[sb.length()];
  sb.getChars(0, sb.length(), chars, 0);
  int size = 0;
  for (int i=0; i<chars.length; i++)
    if (chars[i] == '\n') size++;
  return size;
}

/**
 *  trim
 *
 *  @param [in] sb The string to add to the buffer.
 *  @return StringBuffer
 *
 *  @description Trims the string buffer to keep the text display within the console frame.
 */
private StringBuffer trim(StringBuffer sb) {
  // Split the string by newline chars
  String[] string = split(sb.toString(), '\n');

  // Check the size of the array (for font size 20, there are 33 pix/line)
  if ( string.length > (int)(consoleScreenHeight/33) ) {
    StringBuffer buf = new StringBuffer();
    for (int i=1; i<string.length; i++)
      buf.append(string[i] + ((i==string.length-1) ? "" : "\n"));
    return buf;
  }
  return sb;
}

/**
 *  @brief setupArduino
 *
 *  @description Method which attempts to dynamically connect the tester
 */
public void setupArduino() {
  // Setup the Arduino: Get an ArrayList of the available COM Ports
  final ArrayList<String> al = new ArrayList<String>();
  for (int i = 0; i < Arduino.list ().length; i++)
    al.add(Arduino.list()[i]);

  // Look for the configured COM Port in the ArrayList
  final String com_port = Keys.getString("COM_PORT"); // (String)Keys.COM_PORT.value();
  int index = al.indexOf(com_port);
  debug("COM index = " + index);

  if (index>=0) {    // COM Port was found
    sBuffer.append("\nSERIAL PORT: " + com_port);
    try {
      arduino = new Arduino(this, Arduino.list()[index], 57600);
      for (int i=0; i<inputs.length; i++)
        arduino.pinMode(inputs[i], Arduino.INPUT);
      for (int i=0; i<outputs.length; i++)
        arduino.pinMode(outputs[i], Arduino.OUTPUT);
      arduino.digitalWrite(heartBeatPin, Arduino.HIGH); // turn on the heartBeat LED
    }
    catch(IllegalAccessError iae) {
      iae.printStackTrace();
      arduino = null;
      log.warning("Exception while attempting to connect to COM Port!");
      showDialog("Error Connecting to COM Port!\nPlease check connections.");
      sBuffer.append("\n" + com_port + " not found");
    }
  } else { // COM Port was not found
    log.warning("COM Port was not found!");
    showDialog("Error Connecting to COM Port: " + com_port + " not found!");
    arduino = null;
    sBuffer.append('\n' + com_port + " not found");
  }
}

/*************  Main Code  *****************/
int appWidth, appHeight, consoleScreenWidth, consoleScreenHeight;

public void setup() {

  /*table = loadTable("models.csv", "header");
   println(table.getRowCount() + " total rows in table");
   for (TableRow row : table.rows ()) {
   println(row.getString("device") + " => " + row.getString("models"));
   }*/

  // Create a filelock instance to allow only one instance of the software
  final SingleInstance sis = new SingleInstance(this);
  sis.start();

  if (sis.isLocked()) {
    debug("Program locked.");
    JOptionPane.showMessageDialog(frame, "Program already running!", "Error", JOptionPane.ERROR_MESSAGE );
    this.dispose();
    System.exit(0);
  }

  sBuffer = new StringBuffer();
  dpath = dataPath("");
  Device.instructionPath = dpath;
  // Initialize the Keys Enum which conatins the software configuration data
  // final Keys keys =
  //  println(Keys.LAST_USER);
  //  Keys keys = null;
  //  Keys.setLoggingClass(this.getClass());

  Preferences p = Preferences.userNodeForPackage(this.getClass());
  Keys.setPrefs(p);
  Keys.importPrefs(dpath + "\\prefs.xml");
  //println(Keys.readPrefs());

  sBuffer.append(WIN_TITLE);

  // Setup the Log Archive Folder
  MyLogger.FilePath = dpath + "\\Log";
  log = Logger.getLogger(this.getClass().toString());
  try {
    MyLogger.setup();
  }
  catch (Exception e) {
    e.printStackTrace();
  }
  finally {
    log.info("Program started @ " + month()+"/"+day()+"/"+year()+" "+hour()+":"+minute());
  }

  try { // Set the Look & Feel of the Swing Components
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
  }
  catch (Exception e) {
  }

  // Set the default firmware folder
  Keys.FIRMWARE_FOLDER.setPref( dpath + "\\firmware");

  final int displayWidth=1280, displayHeight=1024;
  // Apply the stored display configuration
  appWidth =  (int)(displayWidth * (Keys.getInt("WIDTH_SCALER")/100.0));   // ((Integer)Keys.WIDTH_SCALER.value())/100);
  appHeight = (int)(displayHeight * (Keys.getInt("HEIGHT_SCALER")/100.0));   // ((Integer)Keys.HEIGHT_SCALER.value())/100);
  debug(str(Keys.getInt("WIDTH_SCALER")/100.0));
  debug(str(appHeight));

  size(appWidth, appHeight);
  frameRate(30);

  // Start the login thread
  user = new LoginThread(this.log);

  consoleScreenWidth = (int)(appWidth-40);
  consoleScreenHeight = (int)(appHeight-90);

  if (utils.dataFileExists(dataPath("detex.jpg"))) {
    detexLogo = loadImage("detex.jpg");
    detexLogo.resize(0, 50);
    tint(85, 200);
  }

  // Customize the program icon
  if (utils.dataFileExists(dataPath("pde.png"))) {
    PImage iconImg = loadImage( dataPath("pde.png") );
    PGraphics icon = createGraphics(iconImg.width, iconImg.height, JAVA2D);
    for (int i=0; i < iconImg.height; i++) {
      for (int j=0; j < iconImg.width; j++) {
        color c = iconImg.get(i, j);
        icon.set(i, j, c);
      }
    }
    frame.setIconImage(icon.image);
  }

  // Load fonts
  font = loadFont("cambria.vlw");
  bfont = loadFont("Cambria-Bold.vlw");

  //  Create the timing slider
  sdr1 = new GWSlider(this, appWidth-390, appHeight-30, 200);
  sdr1.setRenderMaxMinLabel(false);
  sdr1.setLimits(100, 1200, 5000);
  //sdr1.setInertia(4);
  sdr1.setTickCount(100);
  sdr1.setStickToTicks(true);
  sdr1.setValue(Keys.getInt("LAST_DELAY"), true);
  debug("Slider Value = " + sdr1.getValue());

  // Initialize a timer which will be used for testing
  testTimer = new Timer(sdr1.getValue(), new ActionListener() {
    @Override
      public void actionPerformed(ActionEvent evt) {
      try {
        testProcess();
      }
      catch (Exception e) {
        sBuffer.append("\n Error: Cannot communicate with device.");
        //showDialog("Cannot communicate with device!");
        testing=false;
        testTimer.stop();
      }
    }
  }
  );
  testTimer.setActionCommand("testing timer");
  testTimer.setInitialDelay(10);

  // Create the menus
  createMenus();
  setupArduino();

  // Change the window listener and start the login service after the window has been created.
  SwingUtilities.invokeLater(new Runnable() {
    @Override
      public void run() {
      while (frame.getWindowListeners ().length == 0); // wait for it
      ChangeWindowListener(); // Change the window listener
      // Start the login
      LoginThread.f = frame;
      user.start();
    }
  }
  );

  // Add shutdown hook to perform actions upon closing the software
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    @Override
      public void run() {
      // sis.unlockFile();
      // Save the slider delay settings
      Keys.LAST_DELAY.setPref(sdr1.getValue());
      Keys.exportPrefs(dataPath("prefs.xml"));
      try {
        if (arduino!=null) arduino.digitalWrite(heartBeatPin, Arduino.LOW);
      }
      catch (Exception e) {
      }
      finally {
        debug("closing");
      }
    }
  }
  ));
}

void draw() {
  background(85, 400.0);
  strokeWeight(5);

  // Info display
  fill(#021AAF);
  rect(20, 20, consoleScreenWidth, consoleScreenHeight);

  // Check the vertical height of the console text and verify that it fits within the console display
  fill(color(255));
  textFont(font, 20);
  text((sBuffer = trim(sBuffer)).toString(), 35, 45);

  fill(85);
  noStroke();
  rect(0, consoleScreenHeight+25, appWidth, appHeight-consoleScreenHeight-15);
  stroke(0);

  image(detexLogo, appWidth-168, appHeight-55);

  fill(color(255));
  if (user.loggedin()) { // If logged in, display the current user on the window
    textFont(bfont, 18);
    text("Logged in as: " + user.getUsername(), 15, appHeight-32);
    // text("User Total Count: " + user.getUser().getCount(User.TOTAL_CNT), appWidth-500, 16);
  }

  // Display the date and time
  final Date date = Calendar.getInstance().getTime();
  final String todaysDate = DateFormat.getDateInstance(DateFormat.LONG).format(date);
  final String time = DateFormat.getTimeInstance(DateFormat.LONG).format(date);

  textFont(bfont, 20);
  text(todaysDate+"    "+time, 15, appHeight-7);

  text("+", appWidth-405, appHeight-20);
  text("-", appWidth-185, appHeight-20);

  // Display the selected firmware
  if (currentDevice!=null) {

    // Change the text color for non-standard programs
    if (!currentDevice.getProgram().isStandard()) {
      fill(#FF4629);
      if (frameCount%20==0)
        deviceDisplay.setEnabled(!deviceDisplay.isEnabled());
    } else if (!deviceDisplay.isEnabled()) {
      deviceDisplay.setEnabled(true);
    }

    // Include the firmware timing if device is a V40
    if (currentDevice.getDevices() == Devices.V40) {
      text("Selected device: " + currentDevice.getProgram().toString() + ", " + currentDevice.getTiming(), appWidth-500, 16);
      // deviceDisplay.setLabel(" :::  " + currentDevice.getProgram().toString() + ", " + currentDevice.getTiming());
    } else {
      text("Selected device: " + currentDevice.getProgram().toString(), appWidth-250, 16);
      // deviceDisplay.setLabel(" :::  " + currentDevice.getProgram().toString());
    }
  } else {
    text("Select a device to begin", appWidth-240, 16);
  }
}

