import java.util.*;

int keySize = 50;
String typedText = "";
String targetText = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG"; // Set the target text for accuracy measurement
String[] keys = {
  "QWERTYUIOP",
  "ASDFGHJKL",
  "ZXCVBNM"
};

Map<Character, Integer[]> keyPositions = new HashMap<>();
Map<Character, Character[]> keySuggestions = new HashMap<>();

// Global variables for suggestions
Character[] currentSuggestions = null;
char lastPressedKeyChar = '\0';
int lastPressedKeyX, lastPressedKeyY;
int suggestionKeySize = 40;
int suggestionSpacing = 5;
float suggestionKeySizeHoverFactor = 1.5; // How much bigger suggestions get on hover
boolean hoverSuggestion;

// Case toggle variables
boolean isUpperCase = false;  // Start in lowercase mode
boolean hasEnteredToggleArea = false;  // Track if mouse has ever entered toggle area
int caseToggleX = 650;  // Position of the case toggle button
int caseToggleY = 200;
int caseToggleSize = 80;

boolean timing = false;
long startTime, endTime;

void setup() {
  size(800, 400);

  // letter suggestions for each character
  keySuggestions.put('A', new Character[] {'N', 'L', 'S', 'T'});
  keySuggestions.put('B', new Character[] {'E', 'L', 'R', 'A'});
  keySuggestions.put('C', new Character[] {'H', 'O', 'E', 'A'});
  keySuggestions.put('D', new Character[] {'E', 'I', 'A', 'R'});
  keySuggestions.put('E', new Character[] {'R', 'S', 'D', 'N'});
  keySuggestions.put('F', new Character[] {'O', 'R', 'I', 'L'});
  keySuggestions.put('G', new Character[] {'H', 'E', 'R', 'A'});
  keySuggestions.put('H', new Character[] {'E', 'I', 'A', 'O'});
  keySuggestions.put('I', new Character[] {'N', 'S', 'T', 'C'});
  keySuggestions.put('J', new Character[] {'U', 'A', 'O', 'E'});
  keySuggestions.put('K', new Character[] {'E', 'I', 'A', 'L'});
  keySuggestions.put('L', new Character[] {'E', 'L', 'Y', 'I'});
  keySuggestions.put('M', new Character[] {'E', 'A', 'I', 'O'});
  keySuggestions.put('N', new Character[] {'E', 'T', 'D', 'G'});
  keySuggestions.put('O', new Character[] {'N', 'U', 'R', 'F'});
  keySuggestions.put('P', new Character[] {'R', 'E', 'L', 'A'});
  keySuggestions.put('Q', new Character[] {'U', 'A', 'E', 'I'});
  keySuggestions.put('R', new Character[] {'E', 'A', 'I', 'O'});
  keySuggestions.put('S', new Character[] {'T', 'E', 'H', 'I'});
  keySuggestions.put('T', new Character[] {'H', 'E', 'I', 'A'});
  keySuggestions.put('U', new Character[] {'R', 'S', 'N', 'T'});
  keySuggestions.put('V', new Character[] {'E', 'I', 'A', 'O'});
  keySuggestions.put('W', new Character[] {'A', 'I', 'E', 'H'});
  keySuggestions.put('X', new Character[] {'P', 'T', 'C', 'A'});
  keySuggestions.put('Y', new Character[] {'S', 'E', 'O', 'T'});
  keySuggestions.put('Z', new Character[] {'E', 'A', 'O', 'I'});

  // map the location for each character
  for (int row = 0; row < keys.length; row++) {
    for (int col = 0; col < keys[row].length(); col++) {
      // drawKey(keys[row].charAt(col), 100 + col * keySize + (row * keySize / 2), 100 + row * keySize);
    }
  }
}

void draw() {
  background(240);

  fill(100, 0, 0);
  textSize(24);
  textAlign(LEFT);
  text("Target: " + targetText, 50, 40);

  fill(0);
  textAlign(LEFT);
  text("Typed: " + typedText, 50, 70);

  // Draw keyboard
  for (int row = 0; row < keys.length; row++) {
    for (int col = 0; col < keys[row].length(); col++) {
      char keyChar = keys[row].charAt(col);
      // Convert to lowercase if not in uppercase mode
      if (!isUpperCase) {
        keyChar = Character.toLowerCase(keyChar);
      }
      drawKey(keyChar, 100 + col * keySize + (row * keySize / 2), 100 + row * keySize);
    }
  }

  drawKey('_', 350, 250);
  drawKey('<', 400, 250);
  drawKey('⏎', 450, 250);

  // Draw case toggle button
  drawCaseToggleButton();

  if (currentSuggestions != null) {
    float actualSuggestionKeySizeHover = suggestionKeySize * suggestionKeySizeHoverFactor;
    float keyCenterX = lastPressedKeyX + keySize / 2.0f;
    float keyCenterY = lastPressedKeyY + keySize / 2.0f;

    // Calculate the bounding box that includes all keys and their hover areas
    float minX = lastPressedKeyX - suggestionSpacing - suggestionKeySize;
    float maxX = lastPressedKeyX + keySize + suggestionSpacing + suggestionKeySize;
    float minY = lastPressedKeyY - suggestionSpacing - suggestionKeySize;
    float maxY = lastPressedKeyY + keySize + suggestionSpacing + suggestionKeySize;

    // Check if mouse is within the bounding box
    boolean mouseInBounds = (mouseX >= minX && mouseX <= maxX &&
                           mouseY >= minY && mouseY <= maxY);

    if (mouseInBounds) {
      drawSuggestionKeys();
    } else {
      currentSuggestions = null;
    }
  }
}

void drawKey(char label, int x, int y) {
  if (mouseOverKey(x, y, keySize)) {
    fill(100);
  } else {
    fill(200);
  }
  rect(x, y, keySize, keySize, 5);

  fill(0);
  textSize(20);
  textAlign(CENTER, CENTER);
  text(label, x + keySize / 2, y + keySize / 2);
}

void drawCaseToggleButton() {
  // Check if mouse is over the case toggle button
  boolean mouseOverToggle = (mouseX >= caseToggleX && mouseX <= caseToggleX + caseToggleSize &&
                           mouseY >= caseToggleY && mouseY <= caseToggleY + caseToggleSize);

  // Draw button with color based on state
  fill(isUpperCase ? 150 : 180);
  rect(caseToggleX, caseToggleY, caseToggleSize, caseToggleSize, 10);

  // Draw text
  fill(0);
  textSize(20);
  textAlign(CENTER, CENTER);
  text(isUpperCase ? "ABC" : "abc", caseToggleX + caseToggleSize/2, caseToggleY + caseToggleSize/2);
}

void drawSuggestionKeys() {
  if (currentSuggestions == null || currentSuggestions.length == 0) {
    return;
  }

  float actualSuggestionKeySizeHover = suggestionKeySize * suggestionKeySizeHoverFactor;

  float keyCenterX = lastPressedKeyX + keySize / 2.0f;
  float keyCenterY = lastPressedKeyY + keySize / 2.0f;

  // Define base positions (Top, Right, Bottom, Left)
  float[] baseXs = new float[4];
  float[] baseYs = new float[4];

  // Top
  baseXs[0] = keyCenterX - suggestionKeySize / 2.0f;
  baseYs[0] = lastPressedKeyY - suggestionSpacing - suggestionKeySize;
  // Right
  baseXs[1] = lastPressedKeyX + keySize + suggestionSpacing;
  baseYs[1] = keyCenterY - suggestionKeySize / 2.0f;
  // Bottom
  baseXs[2] = keyCenterX - suggestionKeySize / 2.0f;
  baseYs[2] = lastPressedKeyY + keySize + suggestionSpacing;
  // Left
  baseXs[3] = lastPressedKeyX - suggestionSpacing - suggestionKeySize;
  baseYs[3] = keyCenterY - suggestionKeySize / 2.0f;

  for (int i = 0; i < currentSuggestions.length && i < 4; i++) {
    if (currentSuggestions[i] == null) continue;
    char suggestionChar = currentSuggestions[i];
    float baseX = baseXs[i];
    float baseY = baseYs[i];

    float currentDrawSize = suggestionKeySize;
    float drawX = baseX;
    float drawY = baseY;

    float baseKeyCenterX = baseX + suggestionKeySize / 2.0f;
    float baseKeyCenterY = baseY + suggestionKeySize / 2.0f;

    hoverSuggestion = (mouseX >= baseKeyCenterX - actualSuggestionKeySizeHover / 2.0f &&
                         mouseX <= baseKeyCenterX + actualSuggestionKeySizeHover / 2.0f &&
                         mouseY >= baseKeyCenterY - actualSuggestionKeySizeHover / 2.0f &&
                         mouseY <= baseKeyCenterY + actualSuggestionKeySizeHover / 2.0f);


    if (hoverSuggestion) {
      currentDrawSize = actualSuggestionKeySizeHover;
      drawX = baseKeyCenterX - currentDrawSize / 2.0f;
      drawY = baseKeyCenterY - currentDrawSize / 2.0f;
      fill(120); // Highlight for hovered suggestion key
    } else {
      fill(220); // Default color for suggestion key
    }
    rect(drawX, drawY, currentDrawSize, currentDrawSize, 100);

    fill(0);
    textSize(currentDrawSize * 0.6f); // Scale text size
    textAlign(CENTER, CENTER);
    text(suggestionChar, baseKeyCenterX, baseKeyCenterY); // Text centered on original base key center
  }
}

void mousePressed() {
  // Remove case toggle button click handling since it's now hover-based

  // 1. Handle Suggestion Key Clicks first
  if (currentSuggestions != null) {
    float actualSuggestionKeySizeHover = suggestionKeySize * suggestionKeySizeHoverFactor;
    float keyCenterX = lastPressedKeyX + keySize / 2.0f;
    float keyCenterY = lastPressedKeyY + keySize / 2.0f;

    float[] baseXs = new float[4];
    float[] baseYs = new float[4];
    baseXs[0] = keyCenterX - suggestionKeySize / 2.0f;
    baseYs[0] = lastPressedKeyY - suggestionSpacing - suggestionKeySize;
    baseXs[1] = lastPressedKeyX + keySize + suggestionSpacing;
    baseYs[1] = keyCenterY - suggestionKeySize / 2.0f;
    baseXs[2] = keyCenterX - suggestionKeySize / 2.0f;
    baseYs[2] = lastPressedKeyY + keySize + suggestionSpacing;
    baseXs[3] = lastPressedKeyX - suggestionSpacing - suggestionKeySize;
    baseYs[3] = keyCenterY - suggestionKeySize / 2.0f;

    for (int i = 0; i < currentSuggestions.length && i < 4; i++) {
      if (currentSuggestions[i] == null) continue;

      float baseX = baseXs[i];
      float baseY = baseYs[i];
      float baseKeyCenterX = baseX + suggestionKeySize / 2.0f;
      float baseKeyCenterY = baseY + suggestionKeySize / 2.0f;

      // Check click against the (potentially larger) hovered area
      boolean isClicked = (mouseX >= baseKeyCenterX - actualSuggestionKeySizeHover / 2.0f &&
                           mouseX <= baseKeyCenterX + actualSuggestionKeySizeHover / 2.0f &&
                           mouseY >= baseKeyCenterY - actualSuggestionKeySizeHover / 2.0f &&
                           mouseY <= baseKeyCenterY + actualSuggestionKeySizeHover / 2.0f);

      if (isClicked) {
        char clickedChar = currentSuggestions[i];
        // Apply case based on global state
        clickedChar = isUpperCase ? Character.toUpperCase(clickedChar) : Character.toLowerCase(clickedChar);
        typedText += clickedChar;
        currentSuggestions = keySuggestions.get(Character.toUpperCase(clickedChar));
        lastPressedKeyChar = Character.toUpperCase(clickedChar);
        if (!timing && typedText.length() > 0) {
          startTime = millis();
          timing = true;
        }
        return;
      }
    }
  }

  // 2. Handle Main QWERTY Key Clicks
  for (int row = 0; row < keys.length; row++) {
    for (int col = 0; col < keys[row].length(); col++) {
      int x = 100 + col * keySize + (row * keySize / 2);
      int y = 100 + row * keySize;
      if (mouseOverKey(x, y, keySize)) {
        if (!timing) {
          startTime = millis();
          timing = true;
        }
        char typedChar = keys[row].charAt(col);
        // Apply case based on global state
        typedChar = isUpperCase ? typedChar : Character.toLowerCase(typedChar);
        typedText += typedChar;
        lastPressedKeyChar = Character.toUpperCase(keys[row].charAt(col));
        lastPressedKeyX = x;
        lastPressedKeyY = y;
        currentSuggestions = keySuggestions.get(Character.toUpperCase(keys[row].charAt(col)));
        return;
      }
    }
  }

  // 3. Handle Space Key
  if (mouseOverKey(350, 250, keySize)) {
    typedText += " ";
    currentSuggestions = null;
    if (!timing && typedText.trim().length() > 0) {
      startTime = millis();
      timing = true;
    } else if (typedText.trim().isEmpty()) {
      timing = false;
    }
    return;
  }

  // 4. Handle Backspace Key
  if (mouseOverKey(400, 250, keySize) && typedText.length() > 0) {
    typedText = typedText.substring(0, typedText.length() - 1);
    currentSuggestions = null;
    if (typedText.length() == 0) {
      timing = false;
    }
    return;
  }

  // 5. Handle Enter Key
  if (mouseOverKey(450, 250, keySize)) {
    if (timing) {
      endTime = millis();
      evaluatePerformance();
    }
    timing = false;
    typedText = "";
    currentSuggestions = null;
  }
}

boolean mouseOverKey(int x, int y, int size) {
  return mouseX > x && mouseX < x + size && mouseY > y && mouseY < y + size;
}

void evaluatePerformance() {
  if (startTime == 0) return; // Avoid issues if enter is pressed before typing
  int timeTaken = (int) ((endTime - startTime) / 1000.0);
  int correctChars = 0;
  int minLen = min(typedText.length(), targetText.length());

  for (int i = 0; i < minLen; i++) {
    if (typedText.charAt(i) == targetText.charAt(i)) {
      correctChars++;
    }
  }

  float accuracy = 0;
  if (targetText.length() > 0) {
    accuracy = (correctChars / (float) targetText.length()) * 100;
  }
  println("Time taken: " + timeTaken + "s, Accuracy: " + nf(accuracy, 0, 2) + "%");
  startTime = 0; // Reset startTime for the next round
}

void mouseMoved() {
  // Check if mouse is over the case toggle button
  boolean mouseOverToggle = (mouseX >= caseToggleX && mouseX <= caseToggleX + caseToggleSize &&
                           mouseY >= caseToggleY && mouseY <= caseToggleY + caseToggleSize);

  // Toggle case each time mouse enters the area
  if (mouseOverToggle && !hasEnteredToggleArea) {
    isUpperCase = !isUpperCase;  // Toggle the case
    hasEnteredToggleArea = true;
  } else if (!mouseOverToggle) {
    hasEnteredToggleArea = false;  // Reset the flag when mouse leaves
  }
}
