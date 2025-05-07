int keySize = 50;
String typedText = "";
String targetText = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG"; // Set the target text for accuracy measurement
String[] keys = {
  "QWERTYUIOP",
  "ASDFGHJKL",
  "ZXCVBNM"
};
boolean timing = false;
long startTime, endTime;

// location and shape for pointer
int pointerX = 400;
int pointerY = 200;
int pointerSize = 10;

void setup() {
  size(800, 400);
}

void draw() {
  background(240);

  // Display target text
  fill(100, 0, 0);
  textSize(24);
  textAlign(LEFT);
  text("Target: " + targetText, 50, 40);

  // Display typed text
  fill(0);
  textAlign(LEFT);
  text("Typed: " + typedText, 50, 70);

  // Draw keyboard
  for (int row = 0; row < keys.length; row++) {
    for (int col = 0; col < keys[row].length(); col++) {
      drawKey(keys[row].charAt(col), 100 + col * keySize + (row * keySize / 2), 100 + row * keySize);
    }
  }

  // Space key
  drawKey('_', 350, 250); // '_' represents backspace

  // Backspace key
  drawKey('<', 400, 250); // '<' represents backspace

  // Enter key
  drawKey('⏎', 450, 250);


  // TODO: Display a Pointer
  rect(pointerX, pointerY, pointerSize, pointerSize, 90);
}

void drawKey(char label, int x, int y) {
  fill(200);
  rect(x, y, keySize, keySize, 5);

  fill(0);
  textSize(20);
  textAlign(CENTER, CENTER);
  text(label, x + keySize / 2, y + keySize / 2);
}

void mousePressed() {
  for (int row = 0; row < keys.length; row++) {
    for (int col = 0; col < keys[row].length(); col++) {
      int x = 100 + col * keySize + (row * keySize / 2);
      int y = 100 + row * keySize;

      if (mouseOverKey(x, y)) {
        if (!timing) {
          startTime = millis();
          timing = true;
        }
        typedText += keys[row].charAt(col);
      }
    }
  }

  // Backspace key
  if (mouseOverKey(350, 250) && typedText.length() > 0) {
    typedText += " ";
  }

  // Backspace key
  if (mouseOverKey(400, 250) && typedText.length() > 0) {
    typedText = typedText.substring(0, typedText.length() - 1);
  }

  // Enter key
  if (mouseOverKey(460, 250)) {
    endTime = millis();
    timing = false;
    evaluatePerformance();
    typedText = ""; // Reset for next input
  }
}



boolean mouseOverKey(int x, int y) {
  return mouseX > x && mouseX < x + keySize && mouseY > y && mouseY < y + keySize;
}

void evaluatePerformance() {
  int timeTaken = (int) ((endTime - startTime) / 1000.0); // Convert to seconds
  int correctChars = 0;
  int minLen = min(typedText.length(), targetText.length());

  for (int i = 0; i < minLen; i++) {
    if (typedText.charAt(i) == targetText.charAt(i)) {
      correctChars++;
    }
  }

  float accuracy = (correctChars / (float) targetText.length()) * 100;
  println("Time taken: " + timeTaken + "s, Accuracy: " + accuracy + "%");
}