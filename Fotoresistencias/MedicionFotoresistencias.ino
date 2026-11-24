
/*
 * Caracterizacion de cuatro fotoresistencias (LDR)
 * Proyecto: El Girasol
 *
 * Distribucion de sensores:
 *
 * S1 -> A0 -> Superior izquierda
 * S2 -> A1 -> Superior derecha
 * S3 -> A2 -> Inferior izquierda
 * S4 -> A3 -> Inferior derecha
 *
 * Divisor de tension:
 * +5V -> LDR -> nodo de medicion -> 10k -> GND
 *
 * Caracterizacion angular:
 * Se realizaron desplazamientos aproximados de 10 grados
 * por cada posicion.
 *
 * Izquierda: -10, -20 y -30 grados
 * Derecha:   +10, +20 y +30 grados
 * Arriba:    +10, +20 y +30 grados
 * Abajo:     -10, -20 y -30 grados
 *
 * Nota:
 * Los angulos son aproximados y corresponden al
 * desplazamiento fisico realizado durante las pruebas.
 *
 * Las mediciones originales se realizaron con:
 * - 20 mediciones por posicion
 * - 10 muestras promediadas por sensor
 * - 250 ms entre mediciones
 * - 2 segundos de estabilizacion
 */

const int sensores[4] = {A0, A1, A2, A3};

const int NUM_MEDICIONES = 20;
const int NUM_MUESTRAS = 10;

const unsigned long INTERVALO = 250;
const unsigned long ESTABILIZACION = 2000;

// --------------------------------------------------
// Posiciones de prueba
// --------------------------------------------------

const char* posiciones[] = {

  "OSCURIDAD",
  "ILUMINACION_AMBIENTAL",
  "CENTRO_0",

  "IZQUIERDA_10",
  "IZQUIERDA_20",
  "IZQUIERDA_30",

  "DERECHA_10",
  "DERECHA_20",
  "DERECHA_30",

  "ARRIBA_10",
  "ARRIBA_20",
  "ARRIBA_30",

  "ABAJO_10",
  "ABAJO_20",
  "ABAJO_30"
};

const int NUM_POSICIONES = 15;

// --------------------------------------------------
// Configuracion inicial
// --------------------------------------------------

void setup() {

  Serial.begin(9600);

  Serial.println();
  Serial.println("======================================");
  Serial.println(" CARACTERIZACION DE FOTORESISTENCIAS");
  Serial.println("======================================");

  Serial.println();
  Serial.println("S1 -> A0 -> Superior izquierda");
  Serial.println("S2 -> A1 -> Superior derecha");
  Serial.println("S3 -> A2 -> Inferior izquierda");
  Serial.println("S4 -> A3 -> Inferior derecha");

  Serial.println();
  Serial.println("Desplazamientos angulares aproximados:");
  Serial.println("Izquierda: 10, 20 y 30 grados");
  Serial.println("Derecha:   10, 20 y 30 grados");
  Serial.println("Arriba:    10, 20 y 30 grados");
  Serial.println("Abajo:     10, 20 y 30 grados");

  Serial.println();
  Serial.println("Cada posicion requiere enviar 1.");
  Serial.println("Se realizaran 20 mediciones.");
  Serial.println();
}

// --------------------------------------------------
// Lectura promedio de un sensor
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
// Esperar caracter de inicio
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
// Adquisicion de una posicion
// --------------------------------------------------

void medirPosicion(int indice) {

  Serial.println();
  Serial.println("======================================");

  Serial.print("POSICION: ");
  Serial.println(posiciones[indice]);

  Serial.println();
  Serial.println("Coloca la fuente en la posicion indicada.");
  Serial.println("Envia 1 para iniciar.");

  esperarInicio();

  Serial.println();
  Serial.println("Inicio recibido.");
  Serial.println("Estabilizando durante 2 segundos...");

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

  Serial.println("FIN DE LA POSICION");
  Serial.println("======================================");
}

// --------------------------------------------------
// Programa principal
// --------------------------------------------------

void loop() {

  for (int i = 0; i < NUM_POSICIONES; i++) {

    medirPosicion(i);
  }

  Serial.println();
  Serial.println("TODAS LAS POSICIONES HAN FINALIZADO.");

  // Detener ejecucion
  while (true) {
    delay(1000);
  }
}

