# 📐 Modelo Matemático y Simulaciones – El Girasol

## 1. Modelo del sistema

El sistema de seguimiento infrarrojo **El Girasol** está constituido por un mecanismo robótico de dos grados de libertad, encargado de orientar un cabezal sensor hacia una fuente de luz infrarroja.

El sistema opera sobre dos ejes angulares principales:

- **PAN (\(\theta_x\)):** ángulo de giro horizontal o azimut.
- **TILT (\(\theta_y\)):** ángulo de inclinación vertical o elevación.

Las entradas del sistema corresponden a los comandos de posición objetivo de cada eje:

- \(u_x\): comando de posición objetivo del eje horizontal.
- \(u_y\): comando de posición objetivo del eje vertical.

La planta mecánica está compuesta por dos servomotores inteligentes **DYNAMIXEL AX-12A**, acoplados ortogonalmente. Debido a que estos actuadores integran un controlador interno de posición, su comportamiento se aproxima mediante sistemas dinámicos equivalentes de segundo orden.

## 2. Modelado dinámico de los servomotores

Cada eje se representa mediante una función de transferencia de segundo orden:

\[
G_x(s)=\frac{\Theta_x(s)}{U_x(s)}
=\frac{K_x\omega_{nx}^{2}}
{s^2+2\zeta_x\omega_{nx}s+\omega_{nx}^{2}}
\]

\[
G_y(s)=\frac{\Theta_y(s)}{U_y(s)}
=\frac{K_y\omega_{ny}^{2}}
{s^2+2\zeta_y\omega_{ny}s+\omega_{ny}^{2}}
\]

Donde:

- \(K_x, K_y\): ganancias estáticas.
- \(\zeta_x, \zeta_y\): coeficientes de amortiguamiento.
- \(\omega_{nx}, \omega_{ny}\): frecuencias naturales.
- \(\Theta_x(s), \Theta_y(s)\): posiciones angulares reales.
- \(U_x(s), U_y(s)\): comandos de posición.

Para ambos ejes, el modelo matricial desacoplado se expresa como:

\[
\begin{bmatrix}
\Theta_x(s)\\
\Theta_y(s)
\end{bmatrix}
=
\begin{bmatrix}
G_x(s)&0\\
0&G_y(s)
\end{bmatrix}
\begin{bmatrix}
U_x(s)\\
U_y(s)
\end{bmatrix}
\]

## 3. Funciones de transferencia identificadas experimentalmente

A partir de las mediciones de respuesta al escalón de los servomotores DYNAMIXEL AX-12A y el procesamiento de los datos en MATLAB, se identificaron los siguientes modelos experimentales.

### 3.1. Eje horizontal – PAN

\[
G_{PAN}(s)=
\frac{\Theta_x(s)}{U_x(s)}
=
\frac{632.5}{s^2+25.33s+641.1}
\]

### 3.2. Eje vertical – TILT

\[
G_{TILT}(s)=
\frac{\Theta_y(s)}{U_y(s)}
=
\frac{627.3}{s^2+25.10s+633.8}
\]

### 3.3. Modelo promedio de los actuadores

Debido a la similitud dinámica observada entre ambos ejes, se obtiene un modelo promedio para realizar análisis preliminares:

\[
G(s)=
\frac{629.7}{s^2+25.22s+637.4}
\]

Este modelo unificado permite realizar análisis y diseños de control base antes de ajustar cada eje por separado.

## 4. Parámetros dinámicos experimentales

Los parámetros identificados mediante MATLAB se resumen en la siguiente tabla:

| Parámetro | PAN | TILT |
|---|---:|---:|
| Ganancia estática (K) | 0.98669 | 0.98970 |
| Coeficiente de amortiguamiento (\(\zeta\)) | 0.50026 | 0.49847 |
| Frecuencia natural (\(\omega_n\)) | 25.31960 rad/s | 25.17597 rad/s |
| Frecuencia amortiguada (\(\omega_d\)) | 21.92364 rad/s | 21.82524 rad/s |
| Tiempo de establecimiento (\(t_s\)) | 0.31580 s | 0.31874 s |
| Polos dominantes | \(-12.6663 \pm j21.9236\) | \(-12.5494 \pm j21.8252\) |

Los resultados muestran un comportamiento subamortiguado, con coeficientes de amortiguamiento cercanos a 0.5 en ambos ejes.

## 5. Modelo de percepción óptica

El subsistema de percepción utiliza un arreglo simétrico de cuatro fototransistores montados sobre el cabezal sensor.

La distribución de los sensores es:

| Sensor | Ubicación |
|---|---|
| S1 | Superior izquierdo |
| S2 | Superior derecho |
| S3 | Inferior izquierdo |
| S4 | Inferior derecho |

Las señales eléctricas medidas se representan mediante \(V_i(t)\) y se normalizan utilizando:

\[
S_i(t)=
\frac{V_i(t)-V_{i,\min}}
{V_{i,\max}-V_{i,\min}}
\]

Donde \(S_i(t)\) representa la señal normalizada de cada fototransistor.

A partir de las sumas de iluminación por cuadrantes se definen:

\[
S_L=S_1+S_3
\]

\[
S_R=S_2+S_4
\]

\[
S_U=S_1+S_2
\]

\[
S_D=S_3+S_4
\]

Los errores normalizados de orientación se calculan mediante:

\[
e_x=
\frac{S_L-S_R}
{S_L+S_R+\varepsilon}
\]

\[
e_y=
\frac{S_U-S_D}
{S_U+S_D+\varepsilon}
\]

Donde \(\varepsilon\) es una constante positiva pequeña que evita divisiones entre cero.

La relación aproximada entre los errores ópticos y las desviaciones angulares se expresa como:

\[
e_x\approx K_{sx}\Delta\theta_x
\]

\[
e_y\approx K_{sy}\Delta\theta_y
\]

Donde \(K_{sx}\) y \(K_{sy}\) representan las sensibilidades angulares del arreglo óptico.

## 6. Modelo del controlador y banda muerta

Se propone un controlador proporcional incremental para actualizar continuamente las posiciones objetivo de los motores a partir de los errores de orientación detectados por los sensores.

Las ecuaciones de actualización son:

\[
\theta_{x,r}(k+1)=
\theta_{x,r}(k)+K_{px}e_x^*(k)
\]

\[
\theta_{y,r}(k+1)=
\theta_{y,r}(k)+K_{py}e_y^*(k)
\]

Donde:

- \(K_{px}\): ganancia proporcional del eje horizontal.
- \(K_{py}\): ganancia proporcional del eje vertical.
- \(\theta_{x,r}\): posición objetivo del eje PAN.
- \(\theta_{y,r}\): posición objetivo del eje TILT.
- \(e_x^*\), \(e_y^*\): errores después de aplicar la banda muerta.

La banda muerta se define para el eje horizontal como:

\[
e_x^*=
\begin{cases}
0, & |e_x|\leq\delta_x\\
e_x, & |e_x|>\delta_x
\end{cases}
\]

De manera equivalente, para el eje vertical:

\[
e_y^*=
\begin{cases}
0, & |e_y|\leq\delta_y\\
e_y, & |e_y|>\delta_y
\end{cases}
\]

Esta estrategia busca reducir las correcciones innecesarias causadas por ruido eléctrico o pequeñas variaciones en las lecturas de los sensores.

## 7. Representación en espacio de estados

Para representar el comportamiento dinámico de cada actuador se define el vector de estados:

\[
x(t)=
\begin{bmatrix}
\theta(t)\\
\dot{\theta}(t)
\end{bmatrix}
\]

La representación general en espacio de estados es:

\[
\dot{x}=Ax+Bu
\]

\[
y=Cx+Du
\]

Para el modelo de segundo orden, las matrices generales son:

\[
A=
\begin{bmatrix}
0&1\\
-\omega_n^2&-2\zeta\omega_n
\end{bmatrix}
\]

\[
B=
\begin{bmatrix}
0\\
K\omega_n^2
\end{bmatrix}
\]

\[
C=
\begin{bmatrix}
1&0
\end{bmatrix}
\]

\[
D=0
\]

### 7.1. Modelo en espacio de estados – PAN

\[
A_{PAN}=
\begin{bmatrix}
0&1\\
-641.1&-25.33
\end{bmatrix}
\]

\[
B_{PAN}=
\begin{bmatrix}
0\\
632.5
\end{bmatrix}
\]

\[
C_{PAN}=
\begin{bmatrix}
1&0
\end{bmatrix},
\qquad D_{PAN}=0
\]

### 7.2. Modelo en espacio de estados – TILT

\[
A_{TILT}=
\begin{bmatrix}
0&1\\
-633.8&-25.10
\end{bmatrix}
\]

\[
B_{TILT}=
\begin{bmatrix}
0\\
627.3
\end{bmatrix}
\]

\[
C_{TILT}=
\begin{bmatrix}
1&0
\end{bmatrix},
\qquad D_{TILT}=0
\]

## 8. Metodología de identificación experimental

La identificación experimental de los servomotores se realizó mediante pruebas de respuesta al escalón.

El procedimiento descrito en el informe contempla:

1. Aplicar cambios de posición objetivo a los servomotores AX-12A.
2. Registrar la posición real reportada por la retroalimentación interna.
3. Realizar el muestreo de las respuestas cada 50 ms.
4. Exportar los datos obtenidos en formato CSV.
5. Procesar las mediciones mediante MATLAB.
6. Identificar los parámetros dinámicos y obtener las funciones de transferencia.

Las mediciones permiten caracterizar el comportamiento transitorio de los ejes PAN y TILT.

## 9. Organización de archivos

Esta carpeta reúne los documentos y archivos relacionados con el análisis matemático y las simulaciones del proyecto.

- `Modelo_Matematico/`: desarrollo de ecuaciones y descripción del sistema.
- `Funciones_de_Transferencia/`: modelos experimentales de los ejes PAN y TILT.
- `Simulaciones/`: archivos de MATLAB y Simulink utilizados para el análisis.
- `Resultados/`: gráficas, tablas y resultados obtenidos durante la identificación y simulación.

## 10. Referencia

La información presentada corresponde al informe técnico **Sistema de Seguimiento Infrarrojo: El Girasol**, desarrollado para el curso **EL5409 – Laboratorio de Control Automático**, octubre de 2026.
