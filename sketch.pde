import java.util.*;
import java.io.*;

// N-gram predictor class
class NgramPredictor {
    private int n;
    private String text;
    private Map<String, String> seeds;  // Maps n-1 length sequences to possible next chars
    private String currentSeed;
    private boolean initialized;

    public NgramPredictor(int n) {
        if (n <= 0) {
            throw new RuntimeException("n needs to be at least 1");
        }
        this.n = n;
        this.seeds = new HashMap<>();
        this.initialized = false;
        loadCorpus();
    }

    private void loadCorpus() {
        // Load text from file
        System.out.println("hi");

        text = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG THR";
        // String[] lines = loadStrings("sample.txt");
        // String[] lines = loadStrings("eng-uk_web-public_2018_10K-sentences.txt");
        // String[] lines = loadStrings("eng_news_2024_30K-sentences.txt");
        String[] lines = loadStrings("pg1342.txt");
        text = String.join(" ", lines);
        // Convert all text to uppercase
        text = text.toUpperCase();

        if (text.length() < n) {
            throw new RuntimeException("text size is less than n");
        }

        // Build seeds map
        if (n != 1) {
            for (int i = 0; i <= text.length() - n; i++) {
                String temp = text.substring(i, i + n - 1);
                String nextChar = text.substring(i + n - 1, i + n);
                if (!seeds.containsKey(temp)) {
                    seeds.put(temp, nextChar);
                } else {
                    seeds.put(temp, seeds.get(temp) + nextChar);
                }
            }
            // Set initial seed
            int startIndex = (int)(Math.random() * (text.length() - n + 1));
            currentSeed = text.substring(startIndex, startIndex + n - 1);
        }
        initialized = true;
    }

    public Character[] getPredictions(String context) {
        if (!initialized) {
            throw new RuntimeException("predictor has not been initialized");
        }

        // Convert context to uppercase
        context = context.toUpperCase();

        // Get the last n-1 characters from context, or pad with spaces if not enough
        String seed;
        if (context.length() < n-1) {
            seed = String.format("%" + (n-1) + "s", context).replace(' ', ' ');
        } else {
            seed = context.substring(context.length() - (n-1));
        }

        // Get possible next characters for this seed
        String possibleNext = seeds.get(seed);
        if (possibleNext == null || possibleNext.isEmpty()) {
            return new Character[0];
        }

        // Use a Set to track unique characters
        Set<Character> uniqueChars = new HashSet<>();
        for (char c : possibleNext.toCharArray()) {
            uniqueChars.add(c);
        }

        // Convert unique characters to array
        Character[] predictions = new Character[4];
        int i = 0;
        for (Character c : uniqueChars) {
            if (i >= 4) break;
            predictions[i++] = c;
        }

        // If we have fewer than 4 predictions, fill remaining slots with keySuggestions
        if (i < 4 && context.length() > 0) {
            char lastChar = context.charAt(context.length() - 1);
            Character[] defaultSuggestions = keySuggestions.get(Character.toUpperCase(lastChar));
            if (defaultSuggestions != null) {
                for (Character c : defaultSuggestions) {
                    if (i >= 4) break;
                    // Only add if not already in predictions
                    boolean alreadyExists = false;
                    for (int j = 0; j < i; j++) {
                        if (predictions[j] == c) {
                            alreadyExists = true;
                            break;
                        }
                    }
                    if (!alreadyExists) {
                        predictions[i++] = c;
                    }
                }
            }
        }

        return predictions;
    }
}

int keySize = 50;
String typedText = "";
String targetText = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG";
String[] keys = {
  "QWERTYUIOP",
  "ASDFGHJKL",
  "ZXCVBNM"
};

Map<Character, Integer[]> keyPositions = new HashMap<>();
Map<Character, Character[]> keySuggestions = new HashMap<>();

// Create n-gram predictor
NgramPredictor predictor;

// Global variables for suggestions
Character[] currentSuggestions = null;
char lastPressedKeyChar = '\0';
int lastPressedKeyX, lastPressedKeyY;
int suggestionKeySize = 50;
int suggestionSpacing = 10;
float suggestionKeySizeHoverFactor = 1.5;

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
  // Comment out old keySuggestions initialization

  keySuggestions.put('A', new Character[] {'S', 'W', 'E', 'D'});
  keySuggestions.put('B', new Character[] {'V', 'G', 'H', 'N'});
  keySuggestions.put('C', new Character[] {'X', 'D', 'F', 'V'});
  keySuggestions.put('D', new Character[] {'S', 'E', 'R', 'F'});
  keySuggestions.put('E', new Character[] {'W', 'S', 'D', 'R'});
  keySuggestions.put('F', new Character[] {'D', 'R', 'T', 'G'});
  keySuggestions.put('G', new Character[] {'F', 'T', 'Y', 'H'});
  keySuggestions.put('H', new Character[] {'G', 'Y', 'U', 'J'});
  keySuggestions.put('I', new Character[] {'U', 'J', 'K', 'O'});
  keySuggestions.put('J', new Character[] {'H', 'U', 'I', 'K'});
  keySuggestions.put('K', new Character[] {'J', 'I', 'O', 'L'});
  keySuggestions.put('L', new Character[] {'K', 'O', 'P', ';' });
  keySuggestions.put('M', new Character[] {'N', 'J', 'K', ',' });
  keySuggestions.put('N', new Character[] {'B', 'H', 'J', 'M'});
  keySuggestions.put('O', new Character[] {'I', 'K', 'L', 'P'});
  keySuggestions.put('P', new Character[] {'O', 'L', ';', '[' });
  keySuggestions.put('Q', new Character[] {'W', 'A', 'S', '1'});
  keySuggestions.put('R', new Character[] {'E', 'D', 'F', 'T'});
  keySuggestions.put('S', new Character[] {'A', 'W', 'E', 'D'});
  keySuggestions.put('T', new Character[] {'R', 'F', 'G', 'Y'});
  keySuggestions.put('U', new Character[] {'Y', 'H', 'J', 'I'});
  keySuggestions.put('V', new Character[] {'C', 'F', 'G', 'B'});
  keySuggestions.put('W', new Character[] {'Q', 'A', 'S', 'E'});
  keySuggestions.put('X', new Character[] {'Z', 'S', 'D', 'C'});
  keySuggestions.put('Y', new Character[] {'T', 'G', 'H', 'U'});
  keySuggestions.put('Z', new Character[] {'A', 'S', 'X', ' '});

  predictor = new NgramPredictor(4);  // Using 4-grams
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
      drawKey(keyChar, 100 + col * keySize + (row * keySize / 2), 150 + row * keySize);
    }
  }

  drawKey('_', 350, 300);
  drawKey('<', 400, 300);
  drawKey('⏎', 450, 300);

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
  // Check if mouse is over any suggestion key first
  boolean mouseOverSuggestion = false;
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

      if (mouseX >= baseKeyCenterX - actualSuggestionKeySizeHover / 2.0f &&
          mouseX <= baseKeyCenterX + actualSuggestionKeySizeHover / 2.0f &&
          mouseY >= baseKeyCenterY - actualSuggestionKeySizeHover / 2.0f &&
          mouseY <= baseKeyCenterY + actualSuggestionKeySizeHover / 2.0f) {
        mouseOverSuggestion = true;
        break;
      }
    }
  }

  // Only highlight regular key if mouse is not over any suggestion
  if (mouseOverKey(x, y, keySize) && !mouseOverSuggestion) {
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
    // Convert suggestion character to current case
    suggestionChar = isUpperCase ? Character.toUpperCase(suggestionChar) : Character.toLowerCase(suggestionChar);
    float baseX = baseXs[i];
    float baseY = baseYs[i];

    float currentDrawSize = suggestionKeySize;
    float drawX = baseX;
    float drawY = baseY;

    float baseKeyCenterX = baseX + suggestionKeySize / 2.0f;
    float baseKeyCenterY = baseY + suggestionKeySize / 2.0f;

    boolean isHovered = (mouseX >= baseKeyCenterX - actualSuggestionKeySizeHover / 2.0f &&
                         mouseX <= baseKeyCenterX + actualSuggestionKeySizeHover / 2.0f &&
                         mouseY >= baseKeyCenterY - actualSuggestionKeySizeHover / 2.0f &&
                         mouseY <= baseKeyCenterY + actualSuggestionKeySizeHover / 2.0f);

    if (isHovered) {
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
  // Clear suggestions if right mouse button is pressed
  if (mouseButton == RIGHT) {
    currentSuggestions = null;
    return;
  }

  // Check for case toggle button click first
  if (mouseX >= caseToggleX && mouseX <= caseToggleX + caseToggleSize &&
      mouseY >= caseToggleY && mouseY <= caseToggleY + caseToggleSize) {
    isUpperCase = !isUpperCase;
    return;
  }

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

      boolean isClicked = (mouseX >= baseKeyCenterX - actualSuggestionKeySizeHover / 2.0f &&
                           mouseX <= baseKeyCenterX + actualSuggestionKeySizeHover / 2.0f &&
                           mouseY >= baseKeyCenterY - actualSuggestionKeySizeHover / 2.0f &&
                           mouseY <= baseKeyCenterY + actualSuggestionKeySizeHover / 2.0f);

      if (isClicked) {
        char clickedChar = currentSuggestions[i];
        clickedChar = isUpperCase ? Character.toUpperCase(clickedChar) : Character.toLowerCase(clickedChar);
        typedText += clickedChar;
        // Update suggestions based on new context
        currentSuggestions = predictor.getPredictions(typedText);
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
      int y = 150 + row * keySize;
      if (mouseOverKey(x, y, keySize)) {
        if (!timing) {
          startTime = millis();
          timing = true;
        }
        char typedChar = keys[row].charAt(col);
        typedChar = isUpperCase ? typedChar : Character.toLowerCase(typedChar);
        typedText += typedChar;
        lastPressedKeyChar = Character.toUpperCase(keys[row].charAt(col));
        lastPressedKeyX = x;
        lastPressedKeyY = y;
        // Update suggestions based on new context
        currentSuggestions = predictor.getPredictions(typedText);
        return;
      }
    }
  }

  // 3. Handle Space Key
  if (mouseOverKey(350, 300, keySize)) {
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
  if (mouseOverKey(400, 300, keySize) && typedText.length() > 0) {
    typedText = typedText.substring(0, typedText.length() - 1);
    currentSuggestions = null;
    if (typedText.length() == 0) {
      timing = false;
    }
    return;
  }

  // 5. Handle Enter Key
  if (mouseOverKey(450, 300, keySize)) {
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
