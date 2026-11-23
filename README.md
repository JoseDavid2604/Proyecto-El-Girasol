# EL GIRASOL
## Sistema de Seguimiento Automático de una Fuente Infrarroja

**Curso:** EL5409 – Laboratorio de Control Automático  
**Institución:** Instituto Tecnológico de Costa Rica  
**Sede:** Centro Académico de Alajuela  
**Fecha de inicio:** 8 de septiembre de 2026

## 1. Descripción del proyecto

El Girasol consiste en el desarrollo de un sistema robótico de dos grados de libertad capaz de detectar y seguir automáticamente una fuente de luz infrarroja.

El sistema utiliza cuatro fototransistores para determinar la dirección de la fuente luminosa y dos servomotores inteligentes DYNAMIXEL AX-12A para realizar los movimientos de orientación horizontal (PAN) y vertical (TILT).

La tarjeta ArbotiX-M se encarga de procesar las señales de los sensores, ejecutar el algoritmo de control y enviar las posiciones objetivo a los servomotores.

El sistema está diseñado para operar de manera autónoma y sin conexión física a una computadora durante su funcionamiento, mediante alimentación por batería.

## 2. Objetivo general

Diseñar, modelar e implementar un sistema de control de dos grados de libertad capaz de ubicar y seguir una fuente de luz infrarroja mediante un arreglo de fototransistores y servomotores DYNAMIXEL AX-12A.

## 3. Hardware utilizado

- 2 servomotores DYNAMIXEL AX-12A.
- 1 tarjeta controladora ArbotiX-M.
- 4 fototransistores infrarrojos PT1302B/C2 (selección propuesta).
- Resistencias para acondicionamiento de señales.
- Batería y elementos de alimentación.
- Estructura mecánica del brazo robótico.

También se consideran fotoresistencias 9P5-A para pruebas comparativas de detección luminosa.

## 4. Desarrollo del proyecto

El trabajo se divide en las siguientes etapas:

1. Identificación y revisión de la planta física.
2. Investigación de los componentes electrónicos.
3. Modelado matemático de los actuadores.
4. Identificación experimental de la planta.
5. Diseño y simulación del controlador.
6. Configuración de la tarjeta ArbotiX-M.
7. Implementación y calibración de los sensores infrarrojos.
8. Integración de hardware y software.
9. Pruebas experimentales y validación.
10. Documentación y presentación final.

## 5. Organización del repositorio

- `01_Informe/`: informe.
- `02_Motores/`: códigos fuente y algoritmos de control.
- `03_/Modelo`: ecuaciones, funciones de transferencia y modelos.
- `04_Simulaciones/`: simulaciones, datos y gráficas experimentales.
- `05_Evidencias/`: fotografías y videos.

## 6. Tecnologías y herramientas

- Arduino IDE.
- Lenguaje C/C++.
- MATLAB (identificación y simulación).
- ArbotiX-M.
- Servomotores DYNAMIXEL AX-12A.
- Git y GitHub.

## 7. Integrantes

- Anthony Artavia Salazar.
- Kevin Joseph Berrocal Rodríguez.
- José David Luna Herrera.
- William Andrés Sánchez Ramírez.
- Luis Pablo Vargas Muñoz.

## 8. Estado del proyecto

El proyecto se encuentra en desarrollo. Se dispone de documentación, EL modelado matemático y una estructura de identificación de los actuadores. Se continúa con la configuración de hardware, implementación del control e integración del sistema.

## 9. Documentación

Consultar las carpetas para acceder al informe técnico, la bitácora de trabajo.
