
MenuBar myMenu;
final Menu deviceDisplay = new Menu(" :::  No Device Selected");
Menu topDeviceMenu, eax300Menu, eax500Menu, eax2500Menu, v40Menu;
JCheckBox dcBtn, acBtn, testBtn, lbBtn, pad_drBtn, remoteBtn, qwBtn, callBtn;
myMenuListener menuListen;
CheckboxMenuItem manualTest, autoTest;
String timingString  = "";
// boolean specialFirmware = false;
MenuItem showPrefs;
MenuItem displaySize;

void createMenus() { // Creates the top menus

    menuListen = new myMenuListener();
  myMenu = new MenuBar();

  //create the top level button
  topDeviceMenu = new Menu("Device");
  topDeviceMenu.setShortcut(new MenuShortcut(java.awt.event.KeyEvent.VK_D));
  topDeviceMenu.setShortcut(new MenuShortcut(java.awt.event.KeyEvent.VK_UP));

  String[] devices = Device.getStrings();

  eax300Menu = new Menu(devices[0]);
  eax500Menu = new Menu(devices[1]);
  eax2500Menu = new Menu(devices[2]);
  v40Menu = new Menu(devices[3]);
  //  eax3500Menu = new Menu(devices[4]);

  for (Programs p : Programs.values ()) {

    MenuItem item = new MenuItem(p.toString());
    item.setLabel(p.toString());
    item.setActionCommand(p.device.toString());
    item.addActionListener(menuListen);

    switch(p.device) {
    case EAX300:
      eax300Menu.add(item);
      break;
    case EAX500:
      eax500Menu.add(item);
      break;
    case EAX2500:
      eax2500Menu.add(item);
      break;
      //    case EAX3500:
      //      eax3500Menu.add(item);
      //      break;
    case V40:
      v40Menu.add(item);
      break;
    }
  }

  String[] programList = Programs.getProgramList(Devices.EAX300);

  //  topDeviceMenu.add(eax500Menu);
  topDeviceMenu.add(eax2500Menu);
  //  topDeviceMenu.add(v40Menu);
  //  topDeviceMenu.add(eax300Menu);
  //  topDeviceMenu.add(eax3500Menu);

  Menu fileMenu = new Menu("File");
  MenuItem logoutItem = new MenuItem("Log Out");
  logoutItem.addActionListener(menuListen);
  MenuItem Quit = new MenuItem("Quit");
  Quit.addActionListener(menuListen);
  fileMenu.add(logoutItem);
  fileMenu.addSeparator();
  fileMenu.add(Quit);
  myMenu.add(fileMenu);

  Menu actionMenu = new Menu("Action");
  MenuItem test = new MenuItem("Test Device");
  test.addActionListener(menuListen);
  MenuItem program = new MenuItem("Program Device");
  program.addActionListener(menuListen);
  MenuItem advanced = new MenuItem("Advanced");
  advanced.addActionListener(menuListen);
  actionMenu.add(test);
  actionMenu.add(program);
  actionMenu.addSeparator();
  actionMenu.add(advanced);
  myMenu.add(actionMenu);

  //add the menus to the menu bar
  myMenu.add(topDeviceMenu);

  Menu configMenu = new Menu("Config");
  MenuItem configFile = new MenuItem("Open Config");
  configFile.addActionListener(menuListen);
  MenuItem devMgmt = new MenuItem("Open Device Mgr");
  devMgmt.addActionListener(menuListen);
  MenuItem dataFolder = new MenuItem("Open Data Folder");
  dataFolder.addActionListener(menuListen);
  configMenu.add(configFile);
  configMenu.add(devMgmt);
  configMenu.add(dataFolder);
  configMenu.addSeparator();

  Menu adminMenu = new Menu("Admin");

  MenuItem qwLocation = new MenuItem("Select QW Location");
  qwLocation.addActionListener(new ActionListener() {

    @Override
      public void actionPerformed(ActionEvent e) {
      if (user.isAdmin()==false) {
        showAdminDialog("Only Admins Can Configure Settings");
        return;
      }

      Runnable runnable = new Runnable() {
        @Override
          public void run() {
          String path = Keys.getString("QW_PATH"); //(String)Keys.QW_PATH.value();
          final JFileChooser fc = new JFileChooser(path);
          fc.setDialogTitle("Select file");
          int returnVal = fc.showOpenDialog(tester_project_F1_1.this);
          if (returnVal != JFileChooser.APPROVE_OPTION)
            return;
          File file = fc.getSelectedFile();
          if (!file.isFile() || !file.getName().contains(".exe")) {
            showAdminDialog("Incorrect file: " + file.getName());
            return;
          }
          // String newPath = file.getPath();
          Keys.QW_PATH.setPref(file.getPath());
          showAdminDialog("QW Path changed to: " + Keys.QW_PATH.value());
          // println(file.getParent());
          // println(newPath);
        }
      };
      mInvokeLater(runnable);
    }
  }
  );

  adminMenu.add(qwLocation);

  MenuItem eax300_config = new MenuItem("Change Device Firmware File");
  eax300_config.addActionListener(new ActionListener() {
    //        @Override
    public void actionPerformed(ActionEvent e) {

      if (user.isAdmin()==false) {
        showAdminDialog("Only Admins Can Configure Settings");
        return;
      }

      SwingUtilities.invokeLater(new Runnable() {
        public void run() {
          final Object[] possibles = {
            "EAX300", "EAX500", "EAX2500", "EAX3500", "V40"
          };
          final JComboBox jcb = new JComboBox(possibles);

          final JPanel panel = new JPanel();
          panel.add(new JLabel("Devices: "));
          panel.add(jcb);

          final int selectedValue =
            JOptionPane.showConfirmDialog(frame, panel, 
          "Select A Device", JOptionPane.OK_CANCEL_OPTION);

          if ( selectedValue < 0) // Cancelled operation
          return;

          final Devices selectedDevice = Devices.valueOf((String)jcb.getSelectedItem());

          try {
            // Open a dialog to choose the file
            final JFileChooser fc = new JFileChooser();
            fc.setDialogTitle("Select " + selectedDevice + " file");
            String dir = Keys.getString("FIRMWARE_FOLDER"); //(String)Keys.FIRMWARE_FOLDER.value();

            fc.setCurrentDirectory(new File(dir));
            int returnVal = fc.showOpenDialog(tester_project_F1_1.this);
            if (returnVal != JFileChooser.APPROVE_OPTION)
              return;
            File file = fc.getSelectedFile();

            final String path = file.getPath();

            final String name = file.getName();
            final String folder = path.substring(0, path.lastIndexOf(File.separator));
            String ext = name.substring(name.indexOf("_"), name.length());

            final String msg =
              "Change values for "     + selectedDevice
              + " to:"
              + "\nPath: "           + path
              + "\nFolder: "         + folder
              + "\nFile: "           + name
              + "\nExtension: "     + ext;

            if (JOptionPane.showConfirmDialog(frame, msg) != JOptionPane.OK_OPTION )
              return;

            // Change the firmware folder
            Keys.FIRMWARE_FOLDER.setPref(folder);

            // Apply the data for the selected device
            switch(selectedDevice) {
            case EAX300:
              Keys.EAX300_PATH.setPref(path);
              Keys.EAX300_FILE.setPref(name);
              Keys.EAX300_EXT.setPref(ext);
              break;
            case EAX500:
              Keys.EAX500_PATH.setPref(path);
              Keys.EAX500_FILE.setPref(name);
              Keys.EAX500_EXT.setPref(ext);
              break;
            case EAX2500:
              Keys.EAX2500_PATH.setPref(path);
              Keys.EAX2500_FILE.setPref(name);
              Keys.EAX2500_EXT.setPref(ext);
              break;
            case EAX3500:
              Keys.EAX3500_PATH.setPref(path);
              Keys.EAX3500_FILE.setPref(name);
              Keys.EAX3500_EXT.setPref(ext);
              break;
            case V40:
              Keys.V40_PATH.setPref(path);
              Keys.V40_FILE.setPref(name);
              Keys.V40_EXT.setPref(ext);
              break;
            }
            JOptionPane.showMessageDialog(frame, "Settings Applied!", null, JOptionPane.INFORMATION_MESSAGE);
          }
          catch (Exception exc) {
            exc.printStackTrace();
          }
        }
      }
      );
    }
  }
  );

  adminMenu.add(eax300_config);

  displaySize = new MenuItem("Change display size");

  displaySize.addActionListener(new ActionListener() {

    @Override
      public void actionPerformed(ActionEvent e) {

      SwingUtilities.invokeLater(new Runnable() {
        public void run() {
          final JDialog dialog = new JDialog(frame, "Display Scale");
          final JTextField widthTextField = new JTextField( Keys.getString("WIDTH_SCALER")/*((Integer)Keys.WIDTH_SCALER.value()).toString()*/, 10);
          final JTextField heightTextField = new JTextField(  Keys.getString("HEIGHT_SCALER")/*((Integer)Keys.HEIGHT_SCALER.value()).toString()*/, 10);
          final JButton okBtn = new JButton("Save");
          Object[] array = {
            "Display Width(%)", widthTextField, "Display Height(%)", heightTextField
          };
          Object[] options = {
            okBtn
          };

          JOptionPane optionPane = new JOptionPane(array, JOptionPane.QUESTION_MESSAGE, 
          JOptionPane.YES_NO_OPTION, null, options, options[0]);

          dialog.setContentPane(optionPane);
          dialog.addComponentListener(new ComponentAdapter() {
            public void componentShown(ComponentEvent ce) {
              widthTextField.requestFocusInWindow();
            }
          }
          );

          okBtn.addActionListener(new ActionListener() {
            //                        @Override
            public void actionPerformed(ActionEvent e) {
              println(e.getActionCommand());
              int width = Integer.valueOf(widthTextField.getText());
              int height = Integer.valueOf(heightTextField.getText());
              if (width>100||height>100)
                JOptionPane.showMessageDialog(frame, "Values must be between 0-100!", "Error", JOptionPane.OK_OPTION);
              else {
                Keys.WIDTH_SCALER.setPref(width);
                Keys.HEIGHT_SCALER.setPref(height);
                JOptionPane.showMessageDialog(frame, "Values saved!\nRestart Software to apply new settings", null, JOptionPane.INFORMATION_MESSAGE);
                dialog.dispose();
              }
            }
          }
          );
          dialog.pack();
          dialog.setLocation(frame.getLocation());
          dialog.setVisible(true);
        }
      }
      );
    }
  }
  );
  adminMenu.add(displaySize);

  MenuItem comPort = new MenuItem("Select COM Port");
  comPort.addActionListener(new ActionListener() {
    @Override
      public void actionPerformed(ActionEvent e) {
      if (user.isAdmin()==false) {
        showAdminDialog("Only Admins Can Configure Settings");
        return;
      }

      SwingUtilities.invokeLater(new Runnable() {
        public void run() {
          JComboBox jcb = new JComboBox(Arduino.list());

          JPanel panel = new JPanel();
          panel.add(new JLabel("Available Ports"));
          panel.add(jcb);

          int action = JOptionPane.showConfirmDialog(frame, panel, "Select COM", JOptionPane.OK_CANCEL_OPTION);
          if (action == JOptionPane.OK_OPTION) {
            Keys.COM_PORT.setPref((String) jcb.getSelectedItem());
            JOptionPane.showMessageDialog(frame, "Values saved!\nRestart Software to apply new settings", null, JOptionPane.INFORMATION_MESSAGE);
          }
        }
      }
      );
    }
  }
  );
  adminMenu.add(comPort);

  MenuItem clearPrefs = new MenuItem("Restore Default Settings");

  clearPrefs.addActionListener(new ActionListener() {

    @Override
      public void actionPerformed(ActionEvent e) {

      Runnable runnable = new Runnable() {
        @Override
          public void run() {
          int action = JOptionPane.showConfirmDialog(frame, "Reset all prefrences?", "Confim", JOptionPane.YES_NO_OPTION);
          if (action == JOptionPane.YES_OPTION) {
            Keys.clearAllPrefs();
            showAdminDialog("Settings restored to default!");
          }
        }
      };
      mInvokeLater(runnable);
    }
  }
  );

  adminMenu.add(clearPrefs);

  showPrefs = new MenuItem("Show Settings");
  showPrefs.addActionListener(new ActionListener() {
    @Override
      public void actionPerformed(ActionEvent e) {

      Runnable runnable = new Runnable() {
        @Override
          public void run() {
          ArrayList<String> list = new ArrayList<String>();
          String s = Keys.readPrefs();
          final String str = list.toString().replaceAll(", ", "\n");
          showDialog(s);
        }
      };
      mInvokeLater(runnable);
    }
  }
  );
  adminMenu.add(showPrefs);

  MenuItem addUser = new MenuItem("Add User");
  addUser.addActionListener(new ActionListener() {
    @Override
      public void actionPerformed(ActionEvent e) {
      if (!user.isAdmin()) {
        showAdminDialog("Only Admins Can Add Users!");
        return;
      }

      SwingUtilities.invokeLater(new Runnable() {
        public void run() {
          final JDialog dialog = new JDialog(frame, "New User");
          final JTextField nameTextField = new JTextField("", 10);
          final JTextField passTextField = new JTextField("", 10);
          final JCheckBox cb = new JCheckBox("Admin");
          final JButton okBtn = new JButton("Save");
          Object[] array = {
            "User Name", nameTextField, "Password", passTextField
          };
          Object[] options = {
            cb, okBtn
          };

          JOptionPane optionPane = new JOptionPane(array, JOptionPane.QUESTION_MESSAGE, 
          JOptionPane.YES_NO_OPTION, null, options, options[0]);

          dialog.setContentPane(optionPane);
          dialog.addComponentListener(new ComponentAdapter() {
            public void componentShown(ComponentEvent ce) {
              nameTextField.requestFocusInWindow();
            }
          }
          );

          okBtn.addActionListener(new ActionListener() {
            @Override
              public void actionPerformed(ActionEvent e) {
              String name = nameTextField.getText().trim().toUpperCase();
              String pass = passTextField.getText().trim();
              if (name.length() < 1 || pass.length() < 1) {
                showAdminDialog("fields cannot be blank!");
                return;
              } else if (user.getUserNames().contains(name)) {
                showAdminDialog("User Name already exsists!");
                return;
              }
              boolean admin = cb.isSelected();
              user.addNewUser(name, pass, admin);
              showAdminDialog("User "+name+" Added!");
              //              debug((user.getUserNames()));
              dialog.dispose();
            }
          }
          );
          dialog.pack();
          dialog.setLocation(frame.getLocation());
          dialog.setVisible(true);
        }
      }
      );
    }
  }
  );

  adminMenu.add(addUser);

  MenuItem removeUser = new MenuItem("Remove User");
  removeUser.addActionListener(new ActionListener() {

    @Override
      public void actionPerformed(ActionEvent e) {

      if (!user.isAdmin()) {
        showAdminDialog("Only Admins Can Remove Users!");
        return;
      }

      Runnable runnable = new Runnable() {
        @Override
          public void run() {
          final JDialog dialog = new JDialog(frame, "Remove User");
          ArrayList<String> users = user.getUserNames();
          JComboBox jcb = new JComboBox(users.toArray(new String[users.size()]));

          JPanel panel = new JPanel();
          panel.add(new JLabel("User"));
          panel.add(jcb);

          int action = JOptionPane.showConfirmDialog(frame, panel, "Select User", JOptionPane.OK_CANCEL_OPTION);
          if (action==JOptionPane.OK_OPTION) {
            int index = jcb.getSelectedIndex();
            String selection = (String)jcb.getSelectedItem(); // Get the logged in user
            if (selection.equals(user.getUsername())) {
              // The user to be removed is currently logged in!
              // Log the user out, then perform the action.
              JOptionPane.showMessageDialog(frame, "User " + user.removeUser(selection) + " removed", null, JOptionPane.INFORMATION_MESSAGE);
              user.logout();
              return;
            }
            String removedUser = user.removeUser(selection);
            JOptionPane.showMessageDialog(frame, "User "+removedUser+" removed", null, JOptionPane.INFORMATION_MESSAGE);
            return;
          }
        }
      };
      mInvokeLater(runnable);
    }
  }
  );
  adminMenu.add(removeUser);

  MenuItem setSerial = new MenuItem("Set Serial Number");
  setSerial.addActionListener(new ActionListener() {

    @Override
      public void actionPerformed(ActionEvent e) {
      if (!user.isAdmin()) {
        showAdminDialog("Must be an admin!");
        return;
      }

      Runnable runnable = new Runnable() {
        public void run() {
          final JDialog dialog = new JDialog(frame, "Change Serial Number");
          final JTextField serialTextField = new JTextField( Keys.getString("LAST_SERIAL")/*((Integer)Keys.LAST_SERIAL.value()).toString()*/, 10);
          final JButton okBtn = new JButton("Save");
          Object[] array = {
            "Serial Number", serialTextField
          };
          Object[] options = {
            okBtn
          };

          JOptionPane optionPane = new JOptionPane(array, JOptionPane.QUESTION_MESSAGE, 
          JOptionPane.YES_NO_OPTION, null, options, options[0]);

          dialog.setContentPane(optionPane);

          okBtn.addActionListener(new ActionListener() {
            // @Override
            public void actionPerformed(ActionEvent e) {
              try {
                int newSerial = -1;
                // Get the new serial number
                try {
                  newSerial = Integer.valueOf(serialTextField.getText().trim());
                }
                catch (NumberFormatException nfe) {
                  // Non-numeric char was entered
                  throw new Exception("Enter decimal numbers only!");
                }

                // Make sure the new serial is within the range
                if (newSerial >= 0xFFFF || newSerial < 0)
                  throw new Exception("Must be between 0-");

                // Save the new serial number
                Keys.LAST_SERIAL.setPref((int)newSerial);

                showMsg("New Serial Number = "+newSerial+" (0x"+hex(newSerial, 4)+")", "Success", 0);
                dialog.dispose();
              }
              catch (Exception e11) {
                // Display the error
                showMsg(e11.getMessage(), "Error", -1);
                return;
              }
            }
          }
          );
          dialog.pack();
          dialog.setLocation(frame.getLocation());
          dialog.setVisible(true);
        }

        private void showMsg(String msg, String title, int type) {
          if (type<0)
            type = JOptionPane.ERROR_MESSAGE;
          else
            type = JOptionPane.INFORMATION_MESSAGE;
          JOptionPane.showMessageDialog(frame, msg, title, type);
        }
      };
      mInvokeLater(runnable);
    }
  }
  );
  adminMenu.add(setSerial);

  MenuItem connect = new MenuItem("Connect Tester");
  connect.addActionListener(menuListen);
  configMenu.add(connect);

  MenuItem disconnect = new MenuItem("Disconnect Tester");
  disconnect.addActionListener(menuListen);
  configMenu.add(disconnect);

  configMenu.add(adminMenu);

  myMenu.add(configMenu);

  Menu helpMenu = new Menu("Help");
  MenuItem helpInst = new MenuItem("Instructions");
  helpInst.addActionListener(menuListen);
  helpMenu.add(helpInst);
  myMenu.add(helpMenu);
  myMenu.setFont(new Font("Cambria", Font.PLAIN, 13));

  // MenuBar mb = frame.getMenuBar();
  // deviceDisplay.setFont(new Font(mb.getFont().getName(), Font.BOLD, mb.getFont().getSize()));
  deviceDisplay.setFont(new Font("Calibri", Font.BOLD, 13));
  myMenu.add(deviceDisplay);

  //add the menu to the frame!
  frame.setMenuBar(myMenu);
}

private final void mInvokeLater(Runnable runnable) {
  SwingUtilities.invokeLater(runnable);
}

private final void showAdminDialog(final String msg) {
  mInvokeLater(new Runnable() {
    @Override
      public void run() {
      JOptionPane.showMessageDialog(frame, msg, null, JOptionPane.INFORMATION_MESSAGE);
    }
  }
  );
}

class myMenuListener implements ActionListener, ItemListener {

  int deviceIndex=-1;

  myMenuListener() {
  }

  public void actionPerformed(ActionEvent e) {
    println("Menu Action Performed");
    MenuItem source = (MenuItem)(e.getSource());

    if (source.getLabel().equals("Log Out")) {
      user.logout();
      //user.quit();
      //      user = new LoginThread(log);
      //      LoginThread.f = frame;
      //      user.start();
      return;
    } else if (source.getLabel().equals("Quit")) {
      ConfirmExit();
      return;
    } else if (source.getLabel().equals("Test Device")) {
      // Make sure a device has been selected
      // if(deviceIndex<0) {
      // javax.swing.JOptionPane.showMessageDialog(frame, "Select a device before testing!", "Error", javax.swing.JOptionPane.ERROR_MESSAGE );
      // return;
      // }
      // Stop testing if timer is already running
      if (testTimer.isRunning()) {
        testTimer.stop();
        // Turn all the outputs off
        for (int k=0; k<outputs.length; k++)
          arduino.digitalWrite(outputs[k], Arduino.LOW);
        sBuffer.append("\n\nTesting cancelled!");
        return;
      }
      state = 0;  // reset the counter to start new test process
      testTimer.start(); // Start the timer
    } else if (source.getLabel().equals("Program Device")) {
      Program();
    } else if (source.getLabel().equals("Open Config")) {
      String[] params = {
        "write", dataPath("prefs.xml")
        };
        open(params);
      sBuffer.append("\nConfiguration file opened.\nReload the software to apply any changes.");
    } else if (source.getLabel().equals("Open Device Mgr")) {
      open("devmgmt.msc"); // Open the device manager
      sBuffer.append("\nDevice Manager opened.\nReload the software to apply any changes.");
    } else if (source.getLabel().equals("Open Data Folder")) {
      String[] params = {
        "explorer", dataPath("")
        };
        open(params);
    } else if (source.getLabel().equals("Advanced")) {
      JFrame jf = new JFrame("Advanced");
      JPanel panel = new JPanel( new GridLayout(5, 1) );
      dcBtn = new JCheckBox("DC Power");
      acBtn = new JCheckBox("AC Power");
      testBtn = new JCheckBox("Test Mode");
      lbBtn = new JCheckBox("Low Battery Mode");
      pad_drBtn = new JCheckBox("Pad/Door Switch");
      remoteBtn = new JCheckBox("Remote Signal");
      qwBtn = new JCheckBox("Quickwriter Power");
      callBtn = new JCheckBox("Call Button");
      panel.add(dcBtn);
      panel.add(acBtn);
      panel.add(lbBtn);
      panel.add(testBtn);
      panel.add(pad_drBtn);
      panel.add(remoteBtn);
      panel.add(qwBtn);
      panel.add(callBtn);
      pad_drBtn.addItemListener(menuListen);
      dcBtn.addItemListener(menuListen);
      acBtn.addItemListener(menuListen);
      testBtn.addItemListener(menuListen);
      lbBtn.addItemListener(menuListen);
      remoteBtn.addItemListener(menuListen);
      qwBtn.addItemListener(menuListen);
      callBtn.addItemListener(menuListen);
      // jf.setUndecorated(true);
      jf.add(panel);
      jf.setSize(290, 185);
      jf.setResizable(false);
      // jf.pack();
      jf.setLocation((int)(frame.getLocation().getX() + (frame.getSize().getWidth()/2)), (int)(frame.getLocation().y + (frame.getSize().getHeight()/2))); // frame.getLocation());
      jf.setVisible(true);
      jf.addWindowListener(new WindowAdapter() {
        public void windowClosing(WindowEvent we) {
          close(we.getWindow());
        }
        public void windowDeactivated(WindowEvent we) {
          close(we.getWindow());
        }

        private void close(Window w) {
          if (dcBtn.isSelected()) dcBtn.doClick();
          if (acBtn.isSelected()) acBtn.doClick();
          if (testBtn.isSelected()) testBtn.doClick();
          if (lbBtn.isSelected()) lbBtn.doClick();
          if (pad_drBtn.isSelected()) pad_drBtn.doClick();
          if (remoteBtn.isSelected()) remoteBtn.doClick();
          if (callBtn.isSelected()) callBtn.doClick();
          w.dispose();
        }
      }
      );
    } else if (source.getLabel().equals("Instructions")) {
      open(dataPath("software_instructions.pdf"));
    } else if (source.getLabel().equals("Connect Tester")) {
      if (arduino==null) {
        try {
          arduino = new Arduino(tester_project_F1_1.this, Arduino.list()[Keys.getInt("COM")/*(Integer)Keys.COM.value()*/], 57600);
        }
        catch(Exception a1) {
          a1.printStackTrace();
          arduino = null;
        }
      }
    } else if (source.getLabel().equals("Disconnect Tester")) {
      try {
        arduino.dispose();
        arduino = null;
      }
      catch(Exception a) {
        a.printStackTrace();
      }
    } else { // Device selection
      currentDevice = new Device(source.getActionCommand(), source.getLabel());
      deviceDisplay.setLabel(" :::  " + currentDevice.getProgram().toString());

      if (currentDevice.getDevices() == Devices.V40) {
        SwingUtilities.invokeLater( new Runnable() {
          public void run() {
            while (currentDevice.getV40ModelDialog ()!=true);
            sBuffer = currentDevice.getTestingSetup();
            deviceDisplay.setLabel(" :::  " + currentDevice.getProgram().toString() + ", " + currentDevice.getTiming());
          }
        }
        );
      }
      sBuffer = currentDevice.getTestingSetup();
    }
  }

  public void itemStateChanged(ItemEvent e) {
    debug("item state triggered");
    Object source = e.getItemSelectable();
    debug(utils.getClassName(source));

    // String label = source.getLabel();
    if (utils.getClassName(source).equals("JCheckBox")) {
      pause();
      Object item = e.getItem();
      int pin;
      if (item.equals(dcBtn)) pin=battPower;
      else if (item.equals(acBtn)) pin=ACPwr;
      else if (item.equals(testBtn)) pin=testJumper;
      else if (item.equals(lbBtn)) pin=lowBattery;
      else if (item.equals(pad_drBtn)) pin=PAD;
      else if (item.equals(remoteBtn)) pin=remote;
      else if (item.equals(callBtn)) pin=OKC;
      else pin=0;

      if (e.getStateChange()==ItemEvent.SELECTED)
        arduino.digitalWrite(pin, Arduino.HIGH);
      else
        arduino.digitalWrite(pin, Arduino.LOW);
    }
  }
}


synchronized void handleSliderEvents(GSlider slider) {
  timeDelay = slider.getValue();
  testTimer.setDelay(timeDelay);
}

//static class miscStuff {
//
//  static String testingTotals(String path) {
//    String logs = miscStuff.getFile(path);
//    String[] splitLogs = logs.split("\n");
//    String[] lines = new String[0];
//
//    for (int i=0; i<splitLogs.length; i++) {
//      splitLogs[i] = splitLogs[i].trim();
//      if (splitLogs[i].startsWith("*total devices")) {
//        String s = splitLogs[i].substring( splitLogs[i].length()-3 );
//        if (s.startsWith(":"))
//          s = s.substring(s.length()-2);
//        lines = append(lines, s.trim());
//      }
//    }
//    int sum = 0;
//    Integer i;
//    for (int j=0; j<lines.length; j++) {
//      i = new Integer(lines[j]);
//      sum += i.intValue();
//    }
//    i = new Integer(sum);
//    return i.toString();
//  }
//
//  static int stringToPosInt(String number) {
//    return Integer.parseInt(number);
//  }
//
//  static String[] removeFirst(String[] array) {  // Removes first row of an array
//    String[] temp = new String[array.length - 1];
//    arrayCopy(array, 1, temp, 0, temp.length);
//    return temp;
//  }

//  static String getFile(String path) { // reads a file and returns as a string
//    FileInputStream fIn;
//    FileChannel fChan;
//    long fSize;
//    MappedByteBuffer mBuf;
//    String s;
//    try {
//      // First, open a file for input.
//      fIn = new FileInputStream(path);
//      // Next, obtain a channel to that file.
//      fChan = fIn.getChannel();
//      // Get the size of the file.
//      fSize = fChan.size();
//      // Now, map the file into a buffer.
//      mBuf = fChan.map(FileChannel.MapMode.READ_ONLY, 0, fSize);
//      char[] c = new char[(int)fSize];
//      // Read bytes from the buffer.
//      for (int i=0; i < fSize; i++) {
//        c[i]=(char)mBuf.get();
//      }
//      fChan.close(); // close channel
//      fIn.close(); // close file
//      s = new String(c);
//      // return s; // return the String
//    }
//    catch (Exception exc) {
//      System.out.println(exc);
//      s = "error loading file";
//    }
//    return s;
//  }

//}d853

