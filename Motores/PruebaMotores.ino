#include <ax12.h>
#include <BioloidController.h>

// Initialize Dynamixel communication at 1 Mbps
BioloidController bioloid = BioloidController(1000000);

// ============================================================
// SERVO CONFIGURATION
// ============================================================

const int SERVO_1 = 1;
const int SERVO_2 = 2;

// Position limits
const int CENTER_POSITION = 512;
const int LEFT_POSITION   = 312;
const int RIGHT_POSITION  = 712;

// Delay between movements
const int MOVEMENT_DELAY = 1000;

// Continuous movement control
boolean continuousMovement = true;

// ============================================================
// SETUP
// ============================================================

void setup() {

  Serial.begin(9600);
  delay(5000);

  Serial.println("================================");
  Serial.println("  AX-12A CONTINUOUS MOVEMENT");
  Serial.println("================================");

  Serial.println("Checking servos...");

  checkServo(SERVO_1);
  checkServo(SERVO_2);

  Serial.println("Moving servos to center...");

  moveBoth(CENTER_POSITION);

  delay(1500);

  Serial.println("Continuous movement started.");

  printMenu();
}

// ============================================================
// MAIN LOOP
// ============================================================

void loop() {

  // Check serial commands
  if (Serial.available() > 0) {

    char option = Serial.read();

    switch (option) {

      case '1':
        continuousMovement = true;
        Serial.println("Continuous movement STARTED.");
        break;

      case '0':
        continuousMovement = false;
        Serial.println("Continuous movement STOPPED.");
        moveBoth(CENTER_POSITION);
        break;

      case '2':
        continuousMovement = false;
        Serial.println("Relaxing both servos...");
        Relax(SERVO_1);
        Relax(SERVO_2);
        break;

      case '3':
        continuousMovement = false;
        Serial.println("Moving both servos to center...");
        moveBoth(CENTER_POSITION);
        break;

      case 'm':
      case 'M':
        printMenu();
        break;
    }
  }

  // Continuous movement
  if (continuousMovement) {

    moveBoth(LEFT_POSITION);
    waitForMovement();

    moveBoth(RIGHT_POSITION);
    waitForMovement();

  }
}

// ============================================================
// CHECK SERVO COMMUNICATION
// ============================================================

void checkServo(int servoID) {

  int modelNumber = ax12GetRegister(servoID, 0, 2);

  Serial.print("Servo ID: ");
  Serial.print(servoID);

  if (modelNumber == 12) {

    Serial.println(" - Communication OK");

  } else {

    Serial.println(" - Communication error!");
  }

  delay(100);
}

// ============================================================
// MOVE BOTH SERVOS
// ============================================================

void moveBoth(int targetPosition) {

  SetPosition(SERVO_1, targetPosition);
  SetPosition(SERVO_2, targetPosition);
}

// ============================================================
// WAIT WHILE CHECKING SERIAL COMMANDS
// ============================================================

void waitForMovement() {

  unsigned long startTime = millis();

  while (millis() - startTime < MOVEMENT_DELAY) {

    if (Serial.available() > 0) {

      char option = Serial.read();

      if (option == '0') {

        continuousMovement = false;
        moveBoth(CENTER_POSITION);

        Serial.println("Continuous movement STOPPED.");
        return;
      }

      if (option == '2') {

        continuousMovement = false;

        Relax(SERVO_1);
        Relax(SERVO_2);

        Serial.println("Servos relaxed.");
        return;
      }
    }
  }
}

// ============================================================
// SERIAL MENU
// ============================================================

void printMenu() {

  Serial.println();
  Serial.println("================================");
  Serial.println("             MENU");
  Serial.println("================================");

  Serial.println("1 - Start continuous movement");
  Serial.println("0 - Stop and center servos");
  Serial.println("2 - Relax both servos");
  Serial.println("3 - Center both servos");
  Serial.println("M - Show menu");

  Serial.println("================================");
}
