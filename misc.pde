/**
 *  getContents
 *  
 *  @param [in] aFile A file object to read.
 *  @return String The string of the text file.
 */
static public String getContents(File aFile) {
  //...checks on aFile are elided
  StringBuilder contents = new StringBuilder();

  try {
    //use buffering, reading one line at a time
    //FileReader always assumes default encoding is OK!
    BufferedReader input =  new BufferedReader(new FileReader(aFile));
    try {
      String line = null; //not declared within while loop
      /*
          * readLine is a bit quirky :
       *  - it returns the content of a line MINUS the newline.
       *  - it returns null only for the END of the stream.
       *  - it returns an empty String if two newlines appear in a row.
       */
      while ( (line = input.readLine ()) != null) {
        contents.append(line);
        contents.append(System.getProperty("line.separator"));
      }
    }
    finally {
      input.close();
    }
  }
  catch (IOException ex) {
    ex.printStackTrace();
  }
  return contents.toString();
}

/**
 *  @brief Returns a StringBuilder instance for a file object.
 *  
 *  @param [in] File A file object to read.
 *  @return StringBuilder 
 */
static public StringBuilder getContentsBuilder(File aFile) {
  return new StringBuilder(getContents(aFile));
}

static public void setContents(File aFile, String aContents)
throws FileNotFoundException, IOException {
  if (aFile == null) {
    throw new IllegalArgumentException("File should not be null.");
  }
  if (!aFile.exists()) {
    throw new FileNotFoundException ("File does not exist: " + aFile);
  }
  if (!aFile.isFile()) {
    throw new IllegalArgumentException("Should not be a directory: " + aFile);
  }
  if (!aFile.canWrite()) {
    throw new IllegalArgumentException("File cannot be written: " + aFile);
  }

  //use buffering
  Writer output = new BufferedWriter(new FileWriter(aFile));
  try {
    //FileWriter always assumes default encoding is OK!
    output.write( aContents );
  }
  finally {
    output.close();
  }
}

static public String replaceChars(String source, String replacement, int startPoint) {
  StringBuilder src = new StringBuilder(source);
  char[] rplChars = new char[replacement.length()];
  replacement.getChars(0, replacement.length(), rplChars, 0);
  for (int i = startPoint; i< (rplChars.length+startPoint); i++) {
    src.setCharAt(i, rplChars[i-startPoint]);
  }
  return src.toString();
}

/**
 *  @brief Converts a string of characters into a hex string.
 *  
 *  @param [in] String Character string.
 *  @return String Converted string
 */
static public String toHex(String orig) {
  byte[] bytes = orig.getBytes();
  String hexString = "";
  for (int i=0; i<bytes.length; i++)
    hexString += hex(bytes[i], 4);
  return hexString;
}

static public void debug(String msg) {
  if (DEBUG) println(msg);
}

public static String strToHex(String arg) {
  String s = String.format("%04x", new BigInteger(1, arg.getBytes(defaultCharset())));
  return s;
}

/**
 * Returns a string of the combination of the date, the current user
 *  and the serial numbner. This is used for storing info into the EE
 *  data section of the mictrocontroller.
 */
public static String parseHex(User u, int serialNum) {
  SimpleDateFormat sdf = new SimpleDateFormat("MMdd");
  String date = sdf.format(Calendar.getInstance().getTime());

  String userName = u.getName();
  if (userName.length() > 2) {
    userName = userName.substring(0, 1) + userName.substring(2, 3);
  }
  String eeString = userName + date + serialNum;
  // Convert to a charactar array
  char[] origChars = eeString.toCharArray();
  // Flip the charactars in the array
  char[] newChars = reverse(origChars);
  // Rejoin the chars to make a String
  String newEEData = join(str(newChars), "");
  debug("Original string: " + eeString);
  debug("Flipped charactars: " + newEEData);
  // Convert to hex string
  String user_date_hex = strToHex(newEEData);
  debug("String converted to hex: " + user_date_hex);
  return user_date_hex;
}
