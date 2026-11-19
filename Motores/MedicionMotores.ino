
#include <ax12.h>
#include <BioloidController.h>

// =====================================================
// CONFIGURACION DE COMUNICACION
// =====================================================

BioloidController bioloid = BioloidController(1000000);

const int SERVO_PAN  = 1;
const int SERVO_TILT = 2;

// =====================================================
// PARAMETROS DEL EXPERIMENTO
// =====================================================

const int POS_1 = 412;
const int POS_2 = 512;
const int POS_3 = 612;

const unsigned long TIEMPO_ESTABILIZACION = 1500;
const unsigned long TIEMPO_MEDICION = 3000;
const unsigned long INTERVALO_MUESTREO = 50;

// =====================================================
// CONFIGURACION INICIAL
// =====================================================

void setup() {
  Serial.begin(9600);
  delay(1500);

  Serial.println();
  Serial.println("======================================");
  Serial.println(" IDENTIFICACION EXPERIMENTAL AX-12A");
  Serial.println("======================================");

  Serial.println();
  Serial.println("Verificando comunicacion...");

  verificarServo(SERVO_PAN);
  verificarServo(SERVO_TILT);

  Serial.println();
  Serial.println("Seleccione el eje que desea identificar:");
  imprimirMenu();
}

// =====================================================
// BUCLE PRINCIPAL
// =====================================================

void loop() {

  if (Serial.available() > 0) {

    char opcion = Serial.read();

    switch (opcion) {

      case '1':
        ejecutarIdentificacion(SERVO_PAN, "PAN");
        imprimirMenu();
        break;

      case '2':
        ejecutarIdentificacion(SERVO_TILT, "TILT");
        imprimirMenu();
        break;

      case '3':
        SetPosition(SERVO_PAN, 512);
        SetPosition(SERVO_TILT, 512);

        Serial.println("Ambos motores enviados al centro.");
        break;

      case 'M':
      case 'm':
        imprimirMenu();
        break;
    }
  }
}

// =====================================================
// VERIFICACION DE COMUNICACION
// =====================================================

void verificarServo(int id) {

  int modelo = ax12GetRegister(id, AX_MODEL_NUMBER_L, 2);
  int posicion = GetPosition(id);

  Serial.print("Servo ID ");
  Serial.print(id);

  if (modelo == 12 && posicion >= 0 && posicion <= 1023) {
    Serial.println(" - Comunicacion OK");
  }
  else {
    Serial.println(" - Error de comunicacion");
  }
}

// =====================================================
// MENU
// =====================================================

void imprimirMenu() {

  Serial.println();
  Serial.println("--------------------------------------");
  Serial.println(" 1 - Identificar eje PAN");
  Serial.println(" 2 - Identificar eje TILT");
  Serial.println(" 3 - Centrar ambos motores");
  Serial.println(" M - Mostrar menu");
  Serial.println("--------------------------------------");
}

// =====================================================
// IDENTIFICACION DEL MOTOR SELECCIONADO
// =====================================================

void ejecutarIdentificacion(int id, const char* eje) {

  Serial.println();
  Serial.println("======================================");
  Serial.print("INICIANDO IDENTIFICACION: ");
  Serial.println(eje);
  Serial.println("======================================");

  // Secuencia de escalones:
  // 412 -> 512 -> 612 -> 512 -> 412

  medirEscalon(id, eje, POS_1, POS_2, 1);
  medirEscalon(id, eje, POS_2, POS_3, 2);
  medirEscalon(id, eje, POS_3, POS_2, 3);
  medirEscalon(id, eje, POS_2, POS_1, 4);

  Serial.println();
  Serial.print("IDENTIFICACION DEL EJE ");
  Serial.print(eje);
  Serial.println(" FINALIZADA.");
}

// =====================================================
// MEDICION DE RESPUESTA AL ESCALON
// =====================================================

void medirEscalon(
  int id,
  const char* eje,
  int posicionInicial,
  int posicionObjetivo,
  int numeroPrueba
) {

  Serial.println();
  Serial.println("--------------------------------------");

  Serial.print("# Eje: ");
  Serial.println(eje);

  Serial.print("# Prueba: ");
  Serial.println(numeroPrueba);

  Serial.print("# Posicion inicial: ");
  Serial.println(posicionInicial);

  Serial.print("# Posicion objetivo: ");
  Serial.println(posicionObjetivo);

  // Llevar el motor a la posicion inicial
  SetPosition(id, posicionInicial);

  Serial.println("# Estabilizando posicion inicial...");

  delay(TIEMPO_ESTABILIZACION);

  // Verificar posicion real antes del escalon
  int posicionReal = GetPosition(id);

  if (posicionReal < 0 || posicionReal > 1023) {

    Serial.println("# ERROR: No se puede leer la posicion inicial.");
    return;
  }

  Serial.print("# Posicion real inicial: ");
  Serial.println(posicionReal);

  // Aplicar el escalon
  SetPosition(id, posicionObjetivo);

  Serial.println("# ESCALON APLICADO");

  Serial.println("tiempo_ms,objetivo,posicion_real");

  unsigned long tiempoInicio = millis();
  unsigned long tiempoAnterior = tiempoInicio;

  while (millis() - tiempoInicio <= TIEMPO_MEDICION) {

    unsigned long tiempoActual = millis();

    if (tiempoActual - tiempoAnterior >= INTERVALO_MUESTREO) {

      tiempoAnterior = tiempoActual;

      int posicion = GetPosition(id);

      if (posicion >= 0 && posicion <= 1023) {

        Serial.print(tiempoActual - tiempoInicio);
        Serial.print(",");
        Serial.print(posicionObjetivo);
        Serial.print(",");
        Serial.println(posicion);
      }
      else {
        Serial.print(tiempoActual - tiempoInicio);
        Serial.println(",ERROR_LECTURA");
      }
    }
  }

  Serial.println("# FIN DE PRUEBA");

  // Dar tiempo para que termine de estabilizarse
  delay(1000);
}
