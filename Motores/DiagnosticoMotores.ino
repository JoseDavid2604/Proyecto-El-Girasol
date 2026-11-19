
#include <ax12.h>
#include <BioloidController.h>

BioloidController bioloid = BioloidController(1000000);

const int SERVO_1 = 1;
const int SERVO_2 = 2;

void setup() {
  Serial.begin(9600);
  delay(1500);

  Serial.println("LECTURA DE POSICION AX-12A");

  int posicion1 = GetPosition(SERVO_1);
  int posicion2 = GetPosition(SERVO_2);

  Serial.print("Posicion servo 1: ");
  Serial.println(posicion1);

  Serial.print("Posicion servo 2: ");
  Serial.println(posicion2);
}

void loop() {
}

