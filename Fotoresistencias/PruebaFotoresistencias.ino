
/*
 * Prueba de cuatro fotoresistencias (LDR)
 * Sistema de seguimiento de fuente luminosa
 *
 * S1 -> A0
 * S2 -> A1
 * S3 -> A2
 * S4 -> A3
 *
 * La condicion CENTRO se mide 4 veces.
 */

const int sensores[4] = {A0, A1, A2, A3};

const int NUM_MEDICIONES = 20;
const int NUM_MUESTRAS = 10;
const int REPETICIONES_CENTRO = 4;

const unsigned long INTERVALO = 250;
const unsigned long ESTABILIZACION = 5000;

const char* condiciones[] = {
  "OSCURIDAD",
  "ILUMINACION_AMBIENTAL",
  "LED_INFRARROJO",
  "LINTERNA_LED"
};

const int NUM_CONDICIONES = 4;

// --------------------------------------------------
// Configuracion inicial
// --------------------------------------------------

void setup() {

  Serial.begin(9600);

  Serial.println();
  Serial.println("==================================");
  Serial.println(" PRUEBA DE FOTORESISTENCIAS");
  Serial.println("==================================");

  Serial.println();
  Serial.println("Sensores configurados:");
  Serial.println("S1 -> A0");
  Serial.println("S2 -> A1");
  Serial.println("S3 -> A2");
  Serial.println("S4 -> A3");

  Serial.println();
  Serial.println("Se realizaran 20 mediciones");
  Serial.println("por cada condicion.");

  Serial.println("La condicion CENTRO se medira 4 veces.");

  Serial.println();
}

// --------------------------------------------------
// Promedio de lecturas de cada sensor
// --------------------------------------------------

float leerSensor(int pin) {

  long suma = 0;

  for (int i = 0; i < NUM_MUESTRAS; i++) {

    suma += analogRead(pin);

    delay(2);
  }

  return (float)suma / NUM_MUESTRAS;
}

// --------------------------------------------------
// Esperar el caracter de inicio
// --------------------------------------------------

void esperarInicio() {

  while (true) {

    if (Serial.available() > 0) {

      char entrada = Serial.read();

      if (entrada == '1') {
        return;
      }
    }
  }
}

// --------------------------------------------------
// Realizar mediciones de una condicion
// --------------------------------------------------

void realizarMediciones(int condicion, int repeticion) {

  Serial.println();
  Serial.println("==================================");

  Serial.print("CONDICION: ");
  Serial.println(condiciones[condicion]);

  if (condicion == 2) {
    Serial.println("Nota: prueba con LED infrarrojo.");
  }

  if (condicion == 3) {
    Serial.println("Nota: prueba con linterna LED.");
  }

  if (condicion == 2 || condicion == 3) {
    Serial.println("Mantener la fuente en la posicion establecida.");
  }

  if (condicion == 1) {
    Serial.println("Medicion de iluminacion ambiental.");
  }

  if (condicion == 0) {
    Serial.println("Medicion en oscuridad.");
  }

  if (condicion == 2 || condicion == 3) {
    Serial.println();
  }

  if (condicion == 4) {
    Serial.println("Condicion centro.");
  }

  if (condicion == 2) {
    Serial.println(" ");
  }

  if (condicion == 3) {
    Serial.println(" ");
  }

  if (condicion == 0) {
    Serial.println(" ");
  }

  if (condicion == 1) {
    Serial.println(" ");
  }

  if (condicion == 2) {
    Serial.println(" ");
  }

  if (condicion == 3) {
    Serial.println(" ");
  }

  if (condicion == 4) {

    Serial.print("REPETICION CENTRO: ");
    Serial.print(repeticion);
    Serial.print(" DE ");
    Serial.println(REPETICIONES_CENTRO);
  }

  Serial.println();
  Serial.println("Envia 1 para iniciar las mediciones...");

  esperarInicio();

  Serial.println();
  Serial.println("Inicio recibido.");
  Serial.println("Preparando medicion...");
  Serial.println("Tiempo de estabilizacion: 5 segundos");

  delay(ESTABILIZACION);

  Serial.println();
  Serial.println("INICIO DE MEDICIONES");
  Serial.println("N,S1,S2,S3,S4");

  for (int n = 1; n <= NUM_MEDICIONES; n++) {

    float S1 = leerSensor(sensores[0]);
    float S2 = leerSensor(sensores[1]);
    float S3 = leerSensor(sensores[2]);
    float S4 = leerSensor(sensores[3]);

    Serial.print(n);
    Serial.print(",");

    Serial.print(S1, 2);
    Serial.print(",");

    Serial.print(S2, 2);
    Serial.print(",");

    Serial.print(S3, 2);
    Serial.print(",");

    Serial.println(S4, 2);

    delay(INTERVALO);
  }

  Serial.println();
  Serial.println("FIN DE LA CONDICION");

  Serial.println();
  Serial.println("==================================");
}

// --------------------------------------------------
// Programa principal
// --------------------------------------------------

void loop() {

  for (int i = 0; i < NUM_CONDICIONES; i++) {

    if (i == 2) {

      // Medir CENTRO 4 veces
      for (int r = 1; r <= REPETICIONES_CENTRO; r++) {

        realizarMediciones(4, r);
      }

    } else {

      realizarMediciones(i, 0);
    }
  }

  Serial.println();
  Serial.println("TODAS LAS MEDICIONES HAN FINALIZADO.");

  // Detener ejecucion
  while (true) {
    delay(1000);
  }
}

