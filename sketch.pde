import java.util.*;
import java.io.*;
int trialCount = 1;
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

        text = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG THR";
        // String[] lines = loadStrings("sample.txt");
        // String[] lines = loadStrings("eng-uk_web-public_2018_10K-sentences.txt");
        // String[] lines = loadStrings("eng_news_2024_30K-sentences.txt");
        String[] lines = loadStrings("pg1342.txt");
        text = String.join(" ", lines);

        // Convert all text to uppercase and filter to only letters and spaces
        StringBuilder filteredText = new StringBuilder();
        for (char c : text.toUpperCase().toCharArray()) {
            if (Character.isLetter(c) || c == ' ') {
                filteredText.append(c);
            }
        }
        text = filteredText.toString();

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
          char lastChar = context.charAt(context.length() - 1);
          return keySuggestions.get(Character.toUpperCase(lastChar));
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

int keySize = 100;  // Doubled from 50
String typedText = "";
String targetText = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG";
String[] keys = {
  "QWERTYUIOP",
  "ASDFGHJKL",
  "ZXCVBNM"
};

Map<Character, Character[]> keySuggestions = new HashMap<>();

// Create n-gram predictor
NgramPredictor predictor;

// Global variables for suggestions
Character[] currentSuggestions = null;
char lastPressedKeyChar = '\0';
int lastPressedKeyX, lastPressedKeyY;
int suggestionKeySize = 100;  // Doubled from 50
int suggestionSpacing = 20;  // Doubled from 10
float suggestionKeySizeHoverFactor = 1.5;

// Case toggle variables
boolean isUpperCase = false;  // Start in lowercase mode
boolean hasEnteredToggleArea = false;  // Track if mouse has ever entered toggle area
int caseToggleX = 1400;  // Position in bottom right corner
int caseToggleY = 550;   // Moved up 150 pixels from 700
int caseToggleSize = 160;  // Doubled from 80

boolean timing = false;
long startTime, endTime;
int numMistakes;
int numCharTyped;

void setup() {
  size(1600, 800);  // Doubled from 800, 400

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

  predictor = new NgramPredictor(4);  // Using 4-grams
  numMistakes = 0;
  numCharTyped = 0;
}

void draw() {
  background(240);

  fill(100, 0, 0);
  textSize(48);  // Doubled from 24
  textAlign(LEFT);
  text("Target: " + targetText, 100, 80);  // Doubled from 50, 40

  fill(0);
  textAlign(LEFT);
  text("Typed: " + typedText, 100, 140);  // Doubled from 50, 70

  // Draw keyboard
  for (int row = 0; row < keys.length; row++) {
    for (int col = 0; col < keys[row].length(); col++) {
      char keyChar = keys[row].charAt(col);
      // Convert to lowercase if not in uppercase mode
      if (!isUpperCase) {
        keyChar = Character.toLowerCase(keyChar);
      }
      drawKey(keyChar, 200 + col * keySize + (row * keySize / 2), 300 + row * keySize);
    }
  }

  // Draw backspace key (after P)
  drawKey('<', 200 + 10 * keySize + (0 * keySize / 2), 300, keySize * 2);

  // Draw enter key (after L)
  drawEnterKey(200 + 9 * keySize + (1 * keySize / 2), 300 + keySize, keySize * 2);

  // Draw space key (4x width)
  drawKey(' ', 400, 600, keySize * 4);

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
  drawKey(label, x, y, keySize);
}

void drawKey(char label, int x, int y, int width) {
  // Check if mouse is over any suggestion key first
  boolean mouseOverSuggestion = false;
  if (currentSuggestions != null) {
    int hoveredIndex = getHoveredSuggestionIndex();
    if (hoveredIndex != -1) {
      mouseOverSuggestion = true;
    }
  }

  // Only highlight regular key if mouse is not over any suggestion
  if (mouseOverKey(x, y, width, keySize) && !mouseOverSuggestion) {
    fill(150);
  } else {
    fill(200);
  }
  rect(x, y, width, keySize, 5);

  fill(0);
  textSize(40);
  textAlign(CENTER, CENTER);
  text(label, x + width / 2, y + keySize / 2);
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
  textSize(40);  // Doubled from 20
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

  int hoveredIndex = getHoveredSuggestionIndex();

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

    boolean isHovered = (i == hoveredIndex);

    if (isHovered) {
      currentDrawSize = actualSuggestionKeySizeHover;
      drawX = baseKeyCenterX - currentDrawSize / 2.0f;
      drawY = baseKeyCenterY - currentDrawSize / 2.0f;
      fill(170); // Highlight for hovered suggestion key
    } else {
      fill(220); // Default color for suggestion key
    }
    rect(drawX, drawY, currentDrawSize, currentDrawSize, 100);

    fill(0);
    textSize(currentDrawSize * 0.6f); // Scale text size
    textAlign(CENTER, CENTER);
    // Display underscore for space character, but keep the original character for functionality
    char displayChar = suggestionChar == ' ' ? '_' : suggestionChar;
    text(displayChar, baseKeyCenterX, baseKeyCenterY); // Text centered on original base key center
  }
}

/**
 * Returns the index of the hovered suggestion key (0-3), or -1 if none hovered.
 */
int getHoveredSuggestionIndex() {
  if (currentSuggestions == null) return -1;

  float actualSuggestionKeySizeHover = suggestionKeySize * suggestionKeySizeHoverFactor;

  float keyCenterX = lastPressedKeyX + keySize / 2.0f;
  float keyCenterY = lastPressedKeyY + keySize / 2.0f;

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

  int hoveredIndex = -1;
  float closestDist = Float.MAX_VALUE;

  for (int i = 0; i < currentSuggestions.length && i < 4; i++) {
    if (currentSuggestions[i] == null) continue;

    float baseKeyCenterX = baseXs[i] + suggestionKeySize / 2.0f;
    float baseKeyCenterY = baseYs[i] + suggestionKeySize / 2.0f;

    // Check if mouse is within the hover bounding box
    if (mouseX >= baseKeyCenterX - actualSuggestionKeySizeHover / 2.0f &&
        mouseX <= baseKeyCenterX + actualSuggestionKeySizeHover / 2.0f &&
        mouseY >= baseKeyCenterY - actualSuggestionKeySizeHover / 2.0f &&
        mouseY <= baseKeyCenterY + actualSuggestionKeySizeHover / 2.0f) {

      // Calculate distance from mouse to key center
      float dx = mouseX - baseKeyCenterX;
      float dy = mouseY - baseKeyCenterY;
      float dist = dx * dx + dy * dy; // squared distance is enough

      if (dist < closestDist) {
        closestDist = dist;
        hoveredIndex = i;
      }
    }
  }
  return hoveredIndex;
}

void drawEnterKey(int x, int y) {
  drawEnterKey(x, y, keySize);
}

void drawEnterKey(int x, int y, int width) {
  // Check if mouse is over the enter key
  boolean mouseOverEnter = mouseOverKey(x, y, width);

  // Draw key with color based on hover
  if (mouseOverEnter) {
    fill(100);
  } else {
    fill(200);
  }
  rect(x, y, width, keySize, 5);

  // Draw text
  fill(0);
  textSize(24);  // Smaller text size to fit the word
  textAlign(CENTER, CENTER);
  text("ENTER", x + width/2, y + keySize/2);
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
    int hoveredIndex = getHoveredSuggestionIndex();

    if (hoveredIndex != -1 && currentSuggestions[hoveredIndex] != null) {
      char clickedChar = currentSuggestions[hoveredIndex];
      clickedChar = isUpperCase ? Character.toUpperCase(clickedChar) : Character.toLowerCase(clickedChar);
      typedText += clickedChar;
      numCharTyped++;
      checkMistake(clickedChar, typedText.length() - 1);
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

  // 2. Handle Main QWERTY Key Clicks
  for (int row = 0; row < keys.length; row++) {
    for (int col = 0; col < keys[row].length(); col++) {
      int x = 200 + col * keySize + (row * keySize / 2);
      int y = 300 + row * keySize;
      if (mouseOverKey(x, y, keySize)) {
        if (!timing) {
          startTime = millis();
          timing = true;
        }
        char typedChar = keys[row].charAt(col);
        typedChar = isUpperCase ? typedChar : Character.toLowerCase(typedChar);
        typedText += typedChar;
        numCharTyped++;
        checkMistake(typedChar, typedText.length() - 1);
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
  if (mouseOverKey(400, 600, keySize * 4, keySize)) {
    typedText += " ";
    numCharTyped++;
    checkMistake(' ', typedText.length() - 1);
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
  if (mouseOverKey(200 + 10 * keySize + (0 * keySize / 2), 300, keySize * 2, keySize) && typedText.length() > 0) {
    typedText = typedText.substring(0, typedText.length() - 1);
    currentSuggestions = null;
    if (typedText.length() == 0) {
      timing = false;
    }
    return;
  }

  // 5. Handle Enter Key
  if (mouseOverKey(200 + 9 * keySize + (1 * keySize / 2), 300 + keySize, keySize * 2)) {
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
  return mouseOverKey(x, y, size, size);
}

boolean mouseOverKey(int x, int y, int width, int height) {
  return mouseX > x && mouseX < x + width && mouseY > y && mouseY < y + height;
}

void checkMistake(char input, int index) {
  if (targetText.length() - 1 < index || input != targetText.charAt(index) ) {
    numMistakes++;
  }
}

float calculateWPM(int timeInSeconds, int correctChars) {
  // Standard WPM calculation: (characters / 5) / (minutes)
  float words = (float) correctChars / 5.0;
  float minutes = (float) timeInSeconds / 60.0;
  float wpm = minutes > 0 ? words / minutes : 0;
  return wpm;
}

int minimumStringDistance(String s1, String s2) {
  int[][] dp = new int[s1.length() + 1][s2.length() + 1];

  for (int i = 0; i <= s1.length(); i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j <= s2.length(); j++) {
    dp[0][j] = j;
  }

  for (int i = 1; i <= s1.length(); i++) {
    for (int j = 1; j <= s2.length(); j++) {
      if (s1.charAt(i-1) == s2.charAt(j-1)) {
        dp[i][j] = dp[i-1][j-1];
      } else {
        dp[i][j] = 1 + min(dp[i-1][j-1], min(dp[i-1][j], dp[i][j-1]));
      }
    }
  }
  return dp[s1.length()][s2.length()];
}

void savePerformanceData(String typedText, String targetText, long startTime, long endTime,
                        int timeTaken, float accuracy, float wpm, float awpm, int totalCorrectChars,
                        int totalIncorrectChars, int distance) {
  try {
    PrintWriter output = createWriter("typing_performance.txt");
    output.println("Timestamp: " + new Date().toString());
    output.println("Target Text: " + targetText);
    output.println("Typed Text: " + typedText);
    output.println("Start Time: " + startTime);
    output.println("End Time: " + endTime);
    output.println("Time Taken (seconds): " + timeTaken);
    output.println("Accuracy: " + nf(accuracy, 0, 2) + "%");
    output.println("Words Per Minute: " + nf(wpm, 0, 2));
    output.println("Adjusted Words Per Minute: " + nf(awpm, 0, 2));
    output.println("Number of Correct Characters: " + totalCorrectChars);
    output.println("Number of Incorrect Characters: " + totalIncorrectChars);
    output.println("Minimum String Distance: " + distance);
    output.println("----------------------------------------");
    output.flush();
    output.close();
  } catch (Exception e) {
    println("Error saving performance data: " + e.getMessage());
  }
}

void savePerformanceToTextFile(String logEntry) {
  PrintWriter output = createWriter("performance_log.txt");
  String[] existing = {};
  if (dataFile("performance_log.txt").exists()) {
    existing = loadStrings("performance_log.txt");
  }
  output = createWriter("performance_log.txt");
  for (String line : existing) {
    output.println(line);
  }
  output.println(logEntry);
  output.flush();
  output.close();
}

void evaluatePerformance() {
  if (startTime == 0) return; // Avoid issues if enter is pressed before typing
  int timeTaken = (int) ((endTime - startTime) / 1000.0);
  int totalCorrectChars = 0;
  int totalIncorrectChars = 0;

  // Calculate correct and incorrect characters
  int minLen = min(typedText.length(), targetText.length());
  for (int i = 0; i < minLen; i++) {
    if (typedText.charAt(i) == targetText.charAt(i)) {
      totalCorrectChars++;
    } else {
      totalIncorrectChars++;
    }
  }

  // Add remaining characters as incorrect
  if (typedText.length() > targetText.length()) {
    totalIncorrectChars += (typedText.length() - targetText.length());
  }

  int fixedMistakes = numMistakes - totalIncorrectChars;


  float accuracy = 0;
  if (targetText.length() > 0) {
    accuracy = (totalCorrectChars / (float) targetText.length()) * 100;
  }

  // Calculate (A)WPM and Minimum String distance
  float wpm = calculateWPM(timeTaken, numCharTyped);
  float awpmAccuracy = (1.0 - (fixedMistakes / (float) typedText.length()));
  float awpm = wpm * awpmAccuracy;
  int distance = minimumStringDistance(typedText, targetText);
  // Print performance metrics
  println("Trial: " + trialCount);
  trialCount++;
  println("Time taken: " + timeTaken + "s");
  println("Accuracy: " + nf(accuracy, 0, 2) + "%");

  println("Words Per Minute: " + nf(wpm, 0, 2));
  println("Adjusted Words Per Minute: " + nf(awpm, 0, 2));
  println("Total Correct Characters: " + totalCorrectChars);
  println("Total Incorrect Characters: " + totalIncorrectChars);
  println("Minimum String Distance: " + distance);
  println(""); // Empty line for spacing
  

  // Save performance data to file
  savePerformanceData(typedText, targetText, startTime, endTime, timeTaken, accuracy, wpm, awpm, totalCorrectChars, totalIncorrectChars,distance);

  startTime = 0; // Reset startTime for the next round
  numMistakes = 0;
  numCharTyped = 0;
  
  String logEntry = "Trial: " + trialCount + "\n"
  + "Time taken: " + timeTaken + "s\n"
  + "Accuracy: " + nf(accuracy, 0, 2) + "%\n"
  + "Words Per Minute: " + nf(wpm, 0, 2) + "\n"
  + "Adjusted Words Per Minute: " + nf(awpm, 0, 2) + "\n"
  + "Total Correct Characters: " + totalCorrectChars + "\n"
  + "Total Incorrect Characters: " + totalIncorrectChars + "\n"
  + "Minimum String Distance: " + distance + "\n"
  + "Typed Text: " + typedText + "\n"
  + "Target Text: " + targetText + "\n"
  + "---------------------------------------";

  savePerformanceToTextFile(logEntry);

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