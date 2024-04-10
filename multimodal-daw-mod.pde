import websockets.*; // Import Websockets library
import themidibus.*; // Import the MidiBus library
import processing.video.*; // Import Video library

WebsocketServer socket; // The WebsocketServer
MidiBus myBus; // the midibus
Capture video; // video input

color firstTrackColor; // first color to track
color secondTrackColor; // second color to track
float threshold = 20; // threshold for color recognition
int yellowX = 320; // sets color position to center as default
int yellowY = 180;
int redX = 320;
int redY = 180;
int activeMode = 0;
int activeTrack = 1;  // sets track 1 as default active channel
int activeComp = 0;   // sets track 1 as default active channel for compression, so values are updated according to the values in Logic Pro X
int[][] compList = {  {0,0,0,0},      // drums compression default settings
                      {0,0,0,0},      // kick compression default settings
                      {0,0,0,0},      // snare compression default settings
                      {0,0,0,0},      // tom compression default settings
                      {0,0,0,0},      // overheads compression default settings
                      {0,0,0,0},      // bass compression default settings
                      {0,0,0,0},      // guitar compression default settings
                      {0,0,0,0},      // acoustic guitar compression default settings
                      {0,0,0,0},      // dobro compression default settings
                      {0,0,0,0},      // electric guitar compression default settings
                      {0,0,0,0},      // fiddle compression default settings
                      {0,0,0,0},      // piano compression default settings
                      {0,0,0,0},  };  // vocals compression default settings


void setup() {
  socket = new WebsocketServer(this, 1337, "/p5websocket"); // connection to Google Chrome

  MidiBus.list(); // list all available midi-devices on STDOUT. This will show each device's index and name.
  myBus = new MidiBus(this, "Processing to DAW (bus 1)", "Processing to DAW (bus 1)"); // create a new MidiBus using the device names to select the Midi input and output devices respectively.

  size(640, 360);  // video input size
  String[] cameras = Capture.list();
  printArray(cameras);
  video = new Capture(this, cameras[3]);
  video.start();
  firstTrackColor = color(240, 240, 36); // first color set to yellow
  secondTrackColor = color(240, 43, 36); // first color set to red
}

void captureEvent(Capture video) { // capture video input
  video.read();
}

void draw() {
  video.loadPixels();
  image(video, 0, 0);
  findColors();
  if (activeMode == 1) {  // check if mode is activated and run desired function
    volumePanControl();
  } else if (activeMode == 2) {
    EQControl();
  } else if (activeMode == 3) {
    comp();
  } else if (activeMode == 4) {
    reverb();
  }
}

// WEBSOCKET EVENT INPUT & CONFIGURATION
void webSocketServerEvent(String msg){
  msg = trim(msg);  // removes spaces infront and after string
  msg = msg.toLowerCase(); // lowercase only
  println(msg);
  modeSelection(msg); // sends msg to check for mode selection & implementation
  trackSelection(msg); // sends msg to check for track selection & implementation
  markerSelection(msg); // sends msg to check for marker selection & implementation
  soloMute(msg); // sends msg to check for solo/mute prompt and implementation
  playPause(msg); // sends msg to check for play/pause prompt and implementation
  loop(msg); // sends msg to check for looped section & implementation
  barNavigation(msg); // sends msg to check for bar navigation & implementation
  startNavigation(msg); // sends msg to check for start/beginning navigation & implementation 
}

// FIND POSITION OF COLORS AND UPDATE VARIABLES
void findColors() {
  threshold = 80;  // sets color threshold
  
  float avgX = 0;  // XY coordinate of closest color
  float avgY = 0;
  float avgX2 = 0;
  float avgY2 = 0;
  int count = 0;
  int count2 = 0;
  
  for (int x = 0; x < video.width; x++ ) {   // begin loop to walk through every pixel
    for (int y = 0; y < video.height; y++ ) {
      int loc = x + y * video.width;
      
      color firstColor = video.pixels[loc];  // what is first color
      float r1 = red(firstColor);
      float g1 = green(firstColor);
      float b1 = blue(firstColor);
      float r2 = red(firstTrackColor);
      float g2 = green(firstTrackColor);
      float b2 = blue(firstTrackColor);
      
      color secondColor = video.pixels[loc];  // what is second color
      float r3 = red(secondColor);
      float g3 = green(secondColor);
      float b3 = blue(secondColor);
      float r4 = red(secondTrackColor);
      float g4 = green(secondTrackColor);
      float b4 = blue(secondTrackColor);
      float d = distSq(r1, g1, b1, r2, g2, b2); 
      float d2 = distSq(r3, g3, b3, r4, g4, b4);

      if (d < threshold*threshold) {
        stroke(255);
        strokeWeight(1);
        point(x, y);
        avgX += x;
        avgY += y;
        count++;
      } 
      
      if (d2 < threshold*threshold) {
        stroke(255);
        strokeWeight(1);
        point(x, y);
        avgX2 += x;
        avgY2 += y;
        count2++;
      } 
    }
  }
  
  if (count > 0) {  
    avgX = avgX / count;
    avgY = avgY / count;
    fill(255);  // draw a circle at the tracked pixel
    strokeWeight(4.0);
    stroke(0);
    ellipse(avgX, avgY, 24, 24);
    yellowX = int(avgX);  // store position in variables
    yellowY = int(avgY);
  } else {
    yellowX = 320;  // resets x-position to center if no input is detected
    yellowY = 180;  // resets y-position to center if no input is detected
  }
  
  if (count2 > 0) { 
    avgX2 = avgX2 / count2;
    avgY2 = avgY2 / count2;
    fill(255);  // draw a circle at the tracked pixel
    strokeWeight(4.0);
    stroke(0);
    ellipse(avgX2, avgY2, 24, 24);
    redX = int(avgX2);  // stores position in variable
    redY = int(avgY2);
  } else {
    redX = 320;    // resets x-position to center if no input is detected
    redY = 180;    // resets y-position to center if no input is detected
  }
}

float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

float distSq2(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d2 = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d2;
}

// KEY PRESSED OR RELEASED TO ENABLE/DISABLE WEBSOCKET INPUT
void keyPressed() {
  if (key == 'r') {
    socket.sendMessage("active"); // sends data to browser
  }
}

void keyReleased() {
  if (key == 'r') {
    socket.sendMessage("inactive"); // sends data to browser
  }
}

// CHECKS FOR MODE SELECTION
void modeSelection(String message) {
  switch(message) {      
    case "exit mode":               // exit mode
    case "exit":
    case "exceed":
    case "escape mode":
    case "luk equalizer":
    case "luk kompressor":
    case "luftkompressor":
    case "luk reverb":
    case "luk rumklang":
      activeMode = 0;
      break;
    case "balance":                 // balance mode
    case "volume":
    case "panorering":
      activeMode = 1;
      break;
    case "equalizer":               // equalizer mode
      activeMode = 2;
      break;
    case "compressor":              // compressor mode
    case "kompressor":
      activeMode = 3;
      break;
    case "rumklang":                // reverb mode
    case "reverb":
    case "rum tang":
    case "rumfang":
      activeMode = 4;
      break;
  }
}

// CHECKS FOR TRACK SELECTION 
void trackSelection(String message) {
  switch(message) {       
    case "drums":                 // drum group
    case "trommer":
      trackSelect(1);
      activeComp = 0;  // sets compression settings for active track
      break;
    case "kick":                 // kick drum
    case "kik":
    case "store tromme":
    case "tjek":
    case "kick drum":
      trackSelect(2);
      activeComp = 1;
      break;
    case "snare":                // snare drum
    case "snare drum":
    case "snerrer":
    case "lilletromme":
    case "snerle":
      trackSelect(3);
      activeComp = 2;
      break;
    case "tom":                  // tom
    case "tam":
      trackSelect(4);
      activeComp = 3;
      break;
    case "overheads":            // overheads
    case "overhead":
    case "oversæt":
      trackSelect(5);
      activeComp = 4;
      break;
    case "bass":                 // bass
    case "base":
    case "bas":
    case "beige":
      trackSelect(6);
      activeComp = 5;
      break;
    case "guitars":              // guitar group
    case "alle guitar":
    case "guitar":
    case "guitarer":
      trackSelect(7);
      activeComp = 6;
      break;
    case "acoustic guitar":      // acoustic guitar
    case "akustisk guitar":
    case "western guitar":
      trackSelect(8);
      activeComp = 7;
      break;
    case "dobro":                // dobro
    case "dobro guitar":
    case "borup":
    case "doro":
    case "gopro":
      trackSelect(9);
      activeComp = 8;
      break;
    case "electric guitar":      // electric guitar
    case "elektrisk guitar":
    case "elguitar":
    case "el guitar":
      trackSelect(10);
      activeComp = 9;
      break;
    case "fiddle":               // fiddle
    case "violin":
    case "fidel":
    case "vettel":
      trackSelect(11);
      activeComp = 10;
      break;
    case "piano":                // piano
    case "klaver":
      trackSelect(12);
      activeComp = 11;
      break;
    case "lead vocal":           // vocal
    case "vocal":
    case "forsanger":
    case "vokal":
    case "pokal":
      trackSelect(13);
      activeComp = 12;
      break;
  } 
}

// TRACK SELECTION & IMPLEMENTATION
void trackSelect(int selectedTrack) {
  if (selectedTrack > activeTrack) {
      for(int i = selectedTrack; i > activeTrack; activeTrack++) {
        int channel = 1;
        int number = 1;
        int value = 1; // select next track
        myBus.sendControllerChange(channel, number, value); // send a controllerChange
      }
  } else if (selectedTrack < activeTrack) {
      for(int i = selectedTrack; i < activeTrack; activeTrack--) {        
        int channel = 1;
        int number = 1;
        int value = 2; // select previous track
        myBus.sendControllerChange(channel, number, value); 
      }
  }
  activeTrack = selectedTrack;
}

// MARKER SELECTION & IMPLEMENTATION
void markerSelection(String message) {
   switch(message) {       
    case "intro":
      int channel = 1;
      int number = 1;
      int value = 3;
        myBus.sendControllerChange(channel, number, value);
        break;
    case "vers 1":
    case "hvad er ssid":
      channel = 1;
      number = 1;
      value = 4; 
        myBus.sendControllerChange(channel, number, value);
        break;
    case "vers 2":
      channel = 1;
      number = 1;
      value = 5; 
        myBus.sendControllerChange(channel, number, value);
        break;
    case "guitar solo":
      channel = 1;
      number = 1;
      value = 6; 
        myBus.sendControllerChange(channel, number, value);
        break;
    case "vers 3":
    case "spærtræ":
      channel = 1;
      number = 1;
      value = 7;
        myBus.sendControllerChange(channel, number, value);
        break;
    case "fiddle solo":
      channel = 1;
      number = 1;
      value = 8; 
        myBus.sendControllerChange(channel, number, value);
        break;
    case "vers 4":
    case "per ps4":
      channel = 1;
      number = 1;
      value = 9; 
        myBus.sendControllerChange(channel, number, value);
        break;
   }
}

// SOLO OR MUTE TRACK
void soloMute(String message) {
  switch(message) {       
    case "solo":
    case "unsolo":
    case "hon solo":
    case "non solo":
    case "han solo":
    case "on solo":
    case "om solo":
      int channel = 1;
      int number = 1;
      int value = 10; 
        myBus.sendControllerChange(channel, number, value);
        break;
    case "mute":
    case "unmute":
      channel = 1;
      number = 2;
      value = 1; // select previous track
        myBus.sendControllerChange(channel, number, value);
        break;
  }
}

// PLAY OR PAUSE PROJECT
void playPause(String message) {
  switch(message) {       
    case "play":
    case "start":
    case "afspil":
      int channel = 1;
      int number = 2;
      int value = 2; 
        myBus.sendControllerChange(channel, number, value);
        break;
    case "stop":
    case "pause":
      channel = 1;
      number = 2;
      value = 3; 
        myBus.sendControllerChange(channel, number, value);
        break;
  }
}

// LOOP MARKED SECTION OR EXIT LOOP
void loop(String message) {
  switch(message) {       
    case "loop":
      int channel = 1;
      int number = 2;
      int value = 4; 
        myBus.sendControllerChange(channel, number, value);
        break;
    case "cancel loop":
    case "afbryd loop":
    case "slet loop":
    case "fjern loop":
    case "delete loop":
    case "stop loop":
    case "unloop":
    case "on youtube":
      channel = 1;
      number = 2;
      value = 5; 
        myBus.sendControllerChange(channel, number, value);
        break;
  }
}

// BAR NAVIGATION
void barNavigation(String message) {
  String arr[] = message.split(" ", 2); // splits string to an array
  String direction = arr[0];  // stores the first word in var
  String barAmount = message.substring(message.lastIndexOf(" ")+1); // takes last word of string
  int amount = int(barAmount); // converts string into integer
  switch(direction) {       
    case "forward":      // go forth number of bars
    case "frem":
      int channel = 1;
      int number = 2;
      int value = 6;   
      for (int i = 0; i < amount; i++) {  // runs number of bars
        myBus.sendControllerChange(channel, number, value);
      }
        break;
    case "rewind":      // go back number of bars
    case "tilbage":
      channel = 1;
      number = 2;
      value = 7; 
      for (int i = 0; i < amount; i++) { // runs number of bars
        myBus.sendControllerChange(channel, number, value);
      }
        break;
  }
}

// GO TO BEGINNING AND PLAY FROM BEGINNING
void startNavigation(String message) {
  switch(message) {       
    case "back to start":  // go back to start
    case "til toppen":
    case "til start":
      int channel = 1;
      int number = 2;
      int value = 8; 
        myBus.sendControllerChange(channel, number, value);
        break;
    case "afspil fra begyndelsen":  // go back to start and play
    case "afspil fra toppen":
    case "afspil fra starten":
    case "play from beginning":
      channel = 1;
      number = 2;
      value = 9; 
        myBus.sendControllerChange(channel, number, value);
        break;
  }
}

// CONTROL PAN & VOLUME OF SELECTED TRACK
void volumePanControl() {
  if (yellowY <= 100 || redY <= 100) {
    int channel = 1;
    int number = 3;
    int value = 1;
      myBus.sendControllerChange(channel, number, value);
  } else if (yellowY >= 300 || redY >= 300) {
    int channel = 1;
    int number = 2;
    int value = 10;
      myBus.sendControllerChange(channel, number, value);
  } else if (yellowX <= 150 || redX <= 150) {
    int channel = 1;
    int number = 3;
    int value = 2;
      myBus.sendControllerChange(channel, number, value);  
  } else if (yellowX >= 490 || redX >= 490) {
    int channel = 1;
    int number = 3;
    int value = 3;
      myBus.sendControllerChange(channel, number, value);
  }
}

// EQUALIZER CONTROLS
void EQControl() {
  if (redX > 320 && yellowY <= 100) {        // turn EQ parameter upwards
    if (redY > 300) {                       // low shelf
      int channel = 1;
      int number = 3;
      int value = 5; 
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 240 && redY <= 300) { // peak 1
      int channel = 1;
      int number = 3;
      int value = 7;
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 180 && redY <= 240) { // peak 2
      int channel = 1;
      int number = 3;
      int value = 9;
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 120 && redY < 180) {  // peak 3 - take away = with 180, to make a safe zone, when redY is reset to 180, when color is not present                                                
      int channel = 1;
      int number = 4;
      int value = 1;
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 60 && redY <= 120) {  // peak 4
      int channel = 1;
      int number = 4;
      int value = 3;
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 0 && redY <= 60) {    // high shelf
      int channel = 1;
      int number = 4;
      int value = 5;
        myBus.sendControllerChange(channel, number, value);
    } 
  } else if (redX > 320 && yellowY >= 300) { // turn EQ parameter downwards
    if (redY > 300) {                       // low shelf
      int channel = 1;
      int number = 3;
      int value = 6; 
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 240 && redY <= 300) { // peak 1
      int channel = 1;
      int number = 3;
      int value = 8;
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 180 && redY <= 240) { // peak 2
      int channel = 1;
      int number = 3;
      int value = 10;
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 120 && redY < 180) {  // peak 3 - take away = with 180, to make a safe zone, when redY is reset to 180, when color is not present                                                
      int channel = 1;
      int number = 4;
      int value = 2;
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 60 && redY <= 120) {  // peak 4
      int channel = 1;
      int number = 4;
      int value = 4;
        myBus.sendControllerChange(channel, number, value);
    } else if (redY > 0 && redY <= 60) {    // high shelf
      int channel = 1;
      int number = 4;
      int value = 6;
        myBus.sendControllerChange(channel, number, value);
    } 
  }
}

// COMPRESSOR CONTROLS
void comp() {
  if (yellowX < 320) {  // check for yellow color
    float myx = map(yellowX, 319, 0, 0, 100);  // map to compressor value (threshold)
    int yellowXMapped = (int(myx)); // float to integer
      for (int i = yellowXMapped; i > compList[activeComp][0]; compList[activeComp][0]++) {  // use compression settings from active track
        int channel = 1;
        int number = 4;
        int value = 8; 
          myBus.sendControllerChange(channel, number, value);
        }
      for (int i = yellowXMapped; i < compList[activeComp][0]; compList[activeComp][0]--) {
        int channel = 1;
        int number = 4;
        int value = 7; 
          myBus.sendControllerChange(channel, number, value);
        }    
    float myy = map(yellowY, 360, 0, 0, 100);  // map to compressor value (attack)
    int yellowYMapped = (int(myy));
      for (int i = yellowYMapped; i > compList[activeComp][1]; compList[activeComp][1]++) {
        int channel = 1;
        int number = 4;
        int value = 9; 
          myBus.sendControllerChange(channel, number, value);
        }
      for (int i = yellowYMapped; i < compList[activeComp][1]; compList[activeComp][1]--) {
        int channel = 1;
        int number = 4;
        int value = 10; 
          myBus.sendControllerChange(channel, number, value);
        } 
      }
  if (redX > 320) {  // check for red color
    float mrx = map(redX, 321, 640, 0, 85);  // map to compressor value (ratio)
    int redXMapped = (int(mrx));
      for (int i = redXMapped; i > compList[activeComp][2]; compList[activeComp][2]++) {
        int channel = 1;
        int number = 5;
        int value = 1; 
          myBus.sendControllerChange(channel, number, value);
        }
      for (int i = redXMapped; i < compList[activeComp][2]; compList[activeComp][2]--) {
        int channel = 1;
        int number = 5;
        int value = 2; 
          myBus.sendControllerChange(channel, number, value);
        }      
    float mry = map(redY, 360, 0, 0, 118);  // map to compressor value (release)
    int redYMapped = (int(mry));
      for (int i = redYMapped; i > compList[activeComp][3]; compList[activeComp][3]++) {
        int channel = 1;
        int number = 5;
        int value = 3; 
          myBus.sendControllerChange(channel, number, value);
        }
      for (int i = redYMapped; i < compList[activeComp][3]; compList[activeComp][3]--) {
        int channel = 1;
        int number = 5;
        int value = 4; 
          myBus.sendControllerChange(channel, number, value);
        }    
    }
}

// REVERB CONTROLS
void reverb() {
  if (yellowY <= 100 || redY <= 100) {
      int channel = 1;
      int number = 5;
      int value = 5;
        myBus.sendControllerChange(channel, number, value);
    } else if (yellowY >= 300 || redY >= 300) {
      int channel = 1;
    int number = 5;
    int value = 6;
          myBus.sendControllerChange(channel, number, value);
    }
}
