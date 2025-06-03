import java.util.*;
import java.io.*;

// Trial management variables
int currentTrial = 0;
int totalTrials = 20;
boolean testComplete = false;
ArrayList<TrialResult> trialResults = new ArrayList<TrialResult>();

// Target sentences for the 20 trials
String[] targetSentences = {
  "She packed twelve blue pens in her small bag.",
  "Every bird sang sweet songs in the quiet dawn.",
  "They watched clouds drift across the golden sky.",
  "A clever mouse slipped past the sleepy cat.",
  "Green leaves danced gently in the warm breeze.",
  "He quickly wrote notes before the test began.",
  "The tall man wore boots made of soft leather.",
  "Old clocks ticked loudly in the silent room.",
  "She smiled while sipping tea on the front porch.",
  "We found a hidden path behind the old barn.",
  "Sunlight streamed through cracks in the ceiling.",
  "Dogs barked at shadows moving through the yard.",
  "Rain tapped softly against the window glass.",
  "Bright stars twinkled above the quiet valley.",
  "He tied the package with ribbon and string.",
  "A sudden breeze blew papers off the desk.",
  "The curious child opened every single drawer.",
  "Fresh apples fell from the heavy tree limbs.",
  "The artist painted scenes from her memory.",
  "They danced all night under the glowing moon."
};

// Class to store trial results
class TrialResult {
  int trialNumber;
  String targetText;
  String typedText;
  long timeTaken;
  float accuracy;
  float wpm;
  float awpm;
  int correctChars;
  int incorrectChars;
  int msd;
  
  TrialResult(int trial, String target, String typed, long time, float acc, float w, float aw, int correct, int incorrect, int distance) {
    trialNumber = trial;
    targetText = target;
    typedText = typed;
    timeTaken = time;
    accuracy = acc;
    wpm = w;
    awpm = aw;
    correctChars = correct;
    incorrectChars = incorrect;
    msd = distance;
  }
}

// N-gram predictor class
class NgramPredictor {
    private int n;
    private String text;
    private Map<String, String> seeds;
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
        text = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG THR";
        String[] lines = loadStrings("pg1342.txt");
        if (lines != null) {
          text = String.join(" ", lines);
        }

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
          if (context.length() > 0) {
            char lastChar = context.charAt(context.length() - 1);
            return keySuggestions.get(Character.toUpperCase(lastChar));
          }
          return new Character[4];
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
                        if (predictions[j] != null && predictions[j].equals(c)) {
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

int keySize = 100;
String typedText = "";
String targetText = "";
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
int suggestionKeySize = 100;
int suggestionSpacing = 20;
float suggestionKeySizeHoverFactor = 1.5;

// Case toggle variables
boolean isUpperCase = false;
boolean hasEnteredToggleArea = false;
int caseToggleX = 1400;
int caseToggleY = 550;
int caseToggleSize = 160;

boolean timing = false;
long startTime, endTime;
int numMistakes;
int numCharTyped;

void setup() {
  size(1600, 800);

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

  predictor = new NgramPredictor(4);
  numMistakes = 0;
  numCharTyped = 0;
  
  // Initialize first trial
  targetText = targetSentences[currentTrial];
}

void draw() {
  background(240);

  if (testComplete) {
    drawSummaryScreen();
    return;
  }

  // Draw trial counter
  fill(0, 0, 100);
  textSize(32);
  textAlign(LEFT);
  text("Trial " + (currentTrial + 1) + " of " + totalTrials, 100, 40);

  fill(100, 0, 0);
  textSize(48);
  textAlign(LEFT);
  text("Target: " + targetText, 100, 80);

  fill(0);
  textAlign(LEFT);
  text("Typed: " + typedText, 100, 140);

  // Draw keyboard
  for (int row = 0; row < keys.length; row++) {
    for (int col = 0; col < keys[row].length(); col++) {
      char keyChar = keys[row].charAt(col);
      if (!isUpperCase) {
        keyChar = Character.toLowerCase(keyChar);
      }
      drawKey(keyChar, 200 + col * keySize + (row * keySize / 2), 300 + row * keySize);
    }
  }

  // Draw backspace key
  drawKey('<', 200 + 10 * keySize + (0 * keySize / 2), 300, keySize * 2);

  // Draw enter key
  drawEnterKey(200 + 9 * keySize + (1 * keySize / 2), 300 + keySize, keySize * 2);

  // Draw space key
  drawKey(' ', 400, 600, keySize * 4);

  // Draw case toggle button
  drawCaseToggleButton();

  if (currentSuggestions != null) {
    float actualSuggestionKeySizeHover = suggestionKeySize * suggestionKeySizeHoverFactor;
    float keyCenterX = lastPressedKeyX + keySize / 2.0f;
    float keyCenterY = lastPressedKeyY + keySize / 2.0f;

    float minX = lastPressedKeyX - suggestionSpacing - suggestionKeySize;
    float maxX = lastPressedKeyX + keySize + suggestionSpacing + suggestionKeySize;
    float minY = lastPressedKeyY - suggestionSpacing - suggestionKeySize;
    float maxY = lastPressedKeyY + keySize + suggestionSpacing + suggestionKeySize;

    boolean mouseInBounds = (mouseX >= minX && mouseX <= maxX &&
                           mouseY >= minY && mouseY <= maxY);

    if (mouseInBounds) {
      drawSuggestionKeys();
    } else {
      currentSuggestions = null;
    }
  }
  
  boolean isHoveringShift = (mouseX >= caseToggleX && mouseX <= caseToggleX + caseToggleSize &&
                             mouseY >= caseToggleY && mouseY <= caseToggleY + caseToggleSize);
  
  if (isHoveringShift && !hasEnteredToggleArea) {
    // Just entered hover area → toggle
    isUpperCase = !isUpperCase;
    hasEnteredToggleArea = true;
  } else if (!isHoveringShift && hasEnteredToggleArea) {
    // Left hover area → allow re-toggle next time
    hasEnteredToggleArea = false;
  }
}

void drawSummaryScreen() {
  background(220, 230, 255);
  
  fill(0, 0, 150);
  textSize(64);
  textAlign(CENTER);
  text("Test Complete!", width/2, 80);
  
  textSize(32);
  text("Summary of All 20 Trials", width/2, 130);
  
  // Calculate overall statistics
  float totalAWPM = 0;
  float totalAccuracy = 0;
  int totalMSD = 0;
  long totalTime = 0;
  
  for (TrialResult result : trialResults) {
    totalAWPM += result.awpm;
    totalAccuracy += result.accuracy;
    totalMSD += result.msd;
    totalTime += result.timeTaken;
  }
  
  float avgAWPM = totalAWPM / trialResults.size();
  float avgAccuracy = totalAccuracy / trialResults.size();
  float avgMSD = (float)totalMSD / trialResults.size();
  float avgTime = (float)totalTime / trialResults.size();
  
  // Draw overall statistics
  fill(0);
  textSize(28);
  textAlign(LEFT);
  int yPos = 200;
  
  text("Overall Performance:", 100, yPos);
  yPos += 40;
  text("Average Adjusted WPM: " + nf(avgAWPM, 0, 2), 120, yPos);
  yPos += 35;
  text("Average Accuracy: " + nf(avgAccuracy, 0, 2) + "%", 120, yPos);
  yPos += 35;
  text("Average MSD: " + nf(avgMSD, 0, 2), 120, yPos);
  yPos += 35;
  text("Average Time: " + nf(avgTime/1000.0, 0, 2) + "s", 120, yPos);
  
  // Draw trial-by-trial results
  yPos += 60;
  textSize(24);
  text("Trial Results:", 100, yPos);
  yPos += 30;
  
  textSize(18);
  for (int i = 0; i < min(trialResults.size(), 10); i++) {
    TrialResult result = trialResults.get(i);
    String trialLine = "Trial " + (i+1) + ": AWPM=" + nf(result.awpm, 0, 1) + 
                      ", Acc=" + nf(result.accuracy, 0, 1) + "%, MSD=" + result.msd;
    text(trialLine, 120, yPos);
    yPos += 25;
  }
  
  if (trialResults.size() > 10) {
    text("... and " + (trialResults.size() - 10) + " more trials", 120, yPos);
  }
  
  // Instructions to restart
  fill(100, 0, 0);
  textSize(24);
  textAlign(CENTER);
  text("Press 'R' to restart the test", width/2, height - 50);
}

void drawKey(char label, int x, int y) {
  drawKey(label, x, y, keySize);
}

void drawKey(char label, int x, int y, int width) {
  boolean mouseOverSuggestion = false;
  if (currentSuggestions != null) {
    int hoveredIndex = getHoveredSuggestionIndex();
    if (hoveredIndex != -1) {
      mouseOverSuggestion = true;
    }
  }

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
  boolean mouseOverToggle = (mouseX >= caseToggleX && mouseX <= caseToggleX + caseToggleSize &&
                           mouseY >= caseToggleY && mouseY <= caseToggleY + caseToggleSize);

  fill(isUpperCase ? 150 : 180);
  rect(caseToggleX, caseToggleY, caseToggleSize, caseToggleSize, 10);

  fill(0);
  textSize(40);
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
      fill(170);
    } else {
      fill(220);
    }
    rect(drawX, drawY, currentDrawSize, currentDrawSize, 100);

    fill(0);
    textSize(currentDrawSize * 0.6f);
    textAlign(CENTER, CENTER);
    char displayChar = suggestionChar == ' ' ? '_' : suggestionChar;
    text(displayChar, baseKeyCenterX, baseKeyCenterY);
  }
}

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

    if (mouseX >= baseKeyCenterX - actualSuggestionKeySizeHover / 2.0f &&
        mouseX <= baseKeyCenterX + actualSuggestionKeySizeHover / 2.0f &&
        mouseY >= baseKeyCenterY - actualSuggestionKeySizeHover / 2.0f &&
        mouseY <= baseKeyCenterY + actualSuggestionKeySizeHover / 2.0f) {

      float dx = mouseX - baseKeyCenterX;
      float dy = mouseY - baseKeyCenterY;
      float dist = dx * dx + dy * dy;

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
  boolean mouseOverEnter = mouseOverKey(x, y, width);

  if (mouseOverEnter) {
    fill(100);
  } else {
    fill(200);
  }
  rect(x, y, width, keySize, 5);

  fill(0);
  textSize(24);
  textAlign(CENTER, CENTER);
  text("ENTER", x + width/2, y + keySize/2);
}

void mousePressed() {
  if (testComplete) {
    return; // Ignore mouse clicks on summary screen
  }

  if (mouseButton == RIGHT) {
    currentSuggestions = null;
    return;
  }

  // Handle Suggestion Key Clicks first
  if (currentSuggestions != null) {
    int hoveredIndex = getHoveredSuggestionIndex();

    if (hoveredIndex != -1 && currentSuggestions[hoveredIndex] != null) {
      char clickedChar = currentSuggestions[hoveredIndex];
      clickedChar = isUpperCase ? Character.toUpperCase(clickedChar) : Character.toLowerCase(clickedChar);
      typedText += clickedChar;
      numCharTyped++;
      checkMistake(clickedChar, typedText.length() - 1);
      currentSuggestions = predictor.getPredictions(typedText);
      lastPressedKeyChar = Character.toUpperCase(clickedChar);
      if (!timing && typedText.length() > 0) {
        startTime = millis();
        timing = true;
      }
      return;
    }
  }

  // Handle Main QWERTY Key Clicks
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
        currentSuggestions = predictor.getPredictions(typedText);
        return;
      }
    }
  }

  // Handle Space Key
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

  // Handle Backspace Key
  if (mouseOverKey(200 + 10 * keySize + (0 * keySize / 2), 300, keySize * 2, keySize) && typedText.length() > 0) {
    typedText = typedText.substring(0, typedText.length() - 1);
    currentSuggestions = null;
    if (typedText.length() == 0) {
      timing = false;
    }
    return;
  }

  // Handle Enter Key
  if (mouseOverKey(200 + 9 * keySize + (1 * keySize / 2), 300 + keySize, keySize * 2)) {
    if (timing) {
      endTime = millis();
      evaluatePerformance();
      moveToNextTrial();
    }
    return;
  }
}

void moveToNextTrial() {
  currentTrial++;
  
  if (currentTrial >= totalTrials) {
    testComplete = true;
    saveFinalResults();
  } else {
    // Reset for next trial
    targetText = targetSentences[currentTrial];
    typedText = "";
    timing = false;
    currentSuggestions = null;
    numMistakes = 0;
    numCharTyped = 0;
    startTime = 0;
  }
}

void keyPressed() {
  if (testComplete && (key == 'r' || key == 'R')) {
    // Restart the test
    currentTrial = 0;
    testComplete = false;
    trialResults.clear();
    targetText = targetSentences[currentTrial];
    typedText = "";
    timing = false;
    currentSuggestions = null;
    numMistakes = 0;
    numCharTyped = 0;
    startTime = 0;
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
      if (s1.charAt(i - 1) == s2.charAt(j - 1)) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 + myMin(
          dp[i - 1][j - 1], // substitution
          dp[i - 1][j],     // deletion
          dp[i][j - 1]      // insertion
        );
      }
    }
  }

  return dp[s1.length()][s2.length()];
}


int myMin(int a, int b, int c) {
  return min(a, min(b, c));  // Uses PApplet's min function
}

void evaluatePerformance() {
  if (startTime == 0) return;

  String typed = typedText.trim();
  String target = targetText.trim();
  int correctChars = 0;

  for (int i = 0; i < min(typed.length(), target.length()); i++) {
    if (typed.charAt(i) == target.charAt(i)) {
      correctChars++;
    }
  }

  int incorrectChars = typed.length() - correctChars;
  int msd = minimumStringDistance(target, typed);
  long timeTaken = endTime - startTime;
  float timeInSeconds = timeTaken / 1000.0f;
  float rawWPM = calculateWPM((int) timeInSeconds, typed.length());
  float accuracy = typed.length() > 0 ? ((float) correctChars / typed.length()) * 100 : 0;
  float adjustedWPM = rawWPM * (accuracy / 100.0f);

  TrialResult result = new TrialResult(
    currentTrial + 1,
    target,
    typed,
    timeTaken,
    accuracy,
    rawWPM,
    adjustedWPM,
    correctChars,
    incorrectChars,
    msd
  );
  trialResults.add(result);

  // Save immediately to file after each trial
  saveFinalResults();
}

void saveFinalResults() {
  String fullPath = dataPath("typing_performance.txt");
  PrintWriter output;

  try {
    File file = new File(fullPath);
    file.getParentFile().mkdirs();
    FileWriter fw = new FileWriter(file, true);
    output = new PrintWriter(fw);
  } catch (IOException e) {
    println("Error opening file for appending: " + e.getMessage());
    return;
  }

  TrialResult result = trialResults.get(trialResults.size() - 1);

  output.println("Trial " + result.trialNumber);
  output.println("Target   : " + result.targetText);
  output.println("Typed    : " + result.typedText);
  output.println("Accuracy : " + nf(result.accuracy, 0, 2) + "%");
  output.println("WPM      : " + nf(result.wpm, 0, 2));
  output.println("Adj WPM  : " + nf(result.awpm, 0, 2));
  output.println("MSD      : " + result.msd);
  output.println("Time     : " + result.timeTaken + " ms");
  output.println("----------------------------------------");

  output.flush();
  output.close();
}
