
%% ============================================================
% IDENTIFICACION EXPERIMENTAL DE SERVOMOTORES AX-12A
% Ejes PAN y TILT
%
% Modelo de segundo orden:
% G(s) = K*wn^2 / (s^2 + 2*zeta*wn*s + wn^2)
%
% Metodo de ajuste: fminsearch
%% ============================================================

clc;
clear;
close all;

%% 1. CARGA DE DATOS

%% Lectura de archivos CSV

% Archivo PAN
opcionesPAN = detectImportOptions('PAN.csv', ...
    'Delimiter', ',');

PAN = readtable('PAN.csv', opcionesPAN);

% Archivo TILT
opcionesTILT = detectImportOptions('TILT.csv', ...
    'Delimiter', '\t');

TILT = readtable('TILT.csv', opcionesTILT);

%% Verificacion de datos importados

disp('Columnas del archivo PAN:');
disp(PAN.Properties.VariableNames);

disp(head(PAN));

disp('Columnas del archivo TILT:');
disp(TILT.Properties.VariableNames);

disp(head(TILT));

%% Conversion de tiempo a segundos

PAN.tiempo_s = PAN.tiempo_ms / 1000;
TILT.tiempo_s = TILT.tiempo_ms / 1000;

%% 2. IDENTIFICACION DE PARAMETROS

% Parametros iniciales:
% wn = 20 rad/s
% zeta = 0.5
% K = 1

parametrosIniciales = [log(20), 0, 0];

opciones = optimset( ...
    'Display', 'off', ...
    'MaxIter', 10000, ...
    'MaxFunEvals', 20000, ...
    'TolX', 1e-9, ...
    'TolFun', 1e-9);

% Ajuste del eje PAN
paramPAN = fminsearch( ...
    @(p) errorModelo(p, PAN), ...
    parametrosIniciales, opciones);

% Ajuste del eje TILT
paramTILT = fminsearch( ...
    @(p) errorModelo(p, TILT), ...
    parametrosIniciales, opciones);

% Transformacion a parametros fisicos
[K_PAN, zeta_PAN, wn_PAN] = transformarParametros(paramPAN);
[K_TILT, zeta_TILT, wn_TILT] = transformarParametros(paramTILT);

%% 3. CALCULO DE PARAMETROS ADICIONALES

wd_PAN = wn_PAN * sqrt(1 - zeta_PAN^2);
wd_TILT = wn_TILT * sqrt(1 - zeta_TILT^2);

polos_PAN = roots([1, 2*zeta_PAN*wn_PAN, wn_PAN^2]);
polos_TILT = roots([1, 2*zeta_TILT*wn_TILT, wn_TILT^2]);

ts_PAN = 4 / (zeta_PAN * wn_PAN);
ts_TILT = 4 / (zeta_TILT * wn_TILT);

%% 4. PRESENTACION DE RESULTADOS

fprintf('\n============================================\n');
fprintf('       RESULTADOS DE IDENTIFICACION\n');
fprintf('============================================\n');

fprintf('\nEJE PAN\n');
fprintf('Ganancia K:                 %.5f\n', K_PAN);
fprintf('Amortiguamiento zeta:       %.5f\n', zeta_PAN);
fprintf('Frecuencia natural wn:      %.5f rad/s\n', wn_PAN);
fprintf('Frecuencia amortiguada wd:  %.5f rad/s\n', wd_PAN);
fprintf('Tiempo de establecimiento: %.5f s (aprox.)\n', ts_PAN);
fprintf('Polos:\n');
disp(polos_PAN);

fprintf('\nEJE TILT\n');
fprintf('Ganancia K:                 %.5f\n', K_TILT);
fprintf('Amortiguamiento zeta:       %.5f\n', zeta_TILT);
fprintf('Frecuencia natural wn:      %.5f rad/s\n', wn_TILT);
fprintf('Frecuencia amortiguada wd:  %.5f rad/s\n', wd_TILT);
fprintf('Tiempo de establecimiento: %.5f s (aprox.)\n', ts_TILT);
fprintf('Polos:\n');
disp(polos_TILT);

%% 5. FUNCION DE TRANSFERENCIA

s = tf('s');

G_PAN = (K_PAN * wn_PAN^2) / ...
    (s^2 + 2*zeta_PAN*wn_PAN*s + wn_PAN^2);

G_TILT = (K_TILT * wn_TILT^2) / ...
    (s^2 + 2*zeta_TILT*wn_TILT*s + wn_TILT^2);

fprintf('\nFUNCION DE TRANSFERENCIA PAN:\n');
G_PAN

fprintf('\nFUNCION DE TRANSFERENCIA TILT:\n');
G_TILT

%% 6. GRAFICAS DE RESPUESTAS EXPERIMENTALES Y MODELOS

graficarResultados(PAN, K_PAN, zeta_PAN, wn_PAN, 'PAN');
graficarResultados(TILT, K_TILT, zeta_TILT, wn_TILT, 'TILT');

%% ============================================================
% FUNCIONES LOCALES
%% ============================================================

function J = errorModelo(p, datos)

    [K, zeta, wn] = transformarParametros(p);

    tiempo = datos.tiempo_s;
    inicial = datos.posicion_inicial;
    objetivo = datos.posicion_objetivo;
    real = datos.posicion_real;

    estimado = modeloSegundoOrden( ...
        tiempo, inicial, objetivo, K, zeta, wn);

    % Error cuadratico medio
    residuos = real - estimado;
    J = mean(residuos.^2);

    if ~isfinite(J)
        J = 1e20;
    end
end

function [K, zeta, wn] = transformarParametros(p)

    % Parametros positivos y amortiguamiento entre 0 y 1
    wn = exp(p(1));
    zeta = 1 / (1 + exp(-p(2)));
    K = exp(p(3));
end

function y = modeloSegundoOrden(t, y0, objetivo, K, zeta, wn)

    wd = wn * sqrt(1 - zeta^2);

    respuesta = 1 - exp(-zeta*wn.*t) .* ...
        (cos(wd.*t) + ...
        (zeta/sqrt(1-zeta^2))*sin(wd.*t));

    y = y0 + K .* (objetivo-y0) .* respuesta;
end

function graficarResultados(datos, K, zeta, wn, nombreEje)

    pruebas = unique(datos.prueba);

    figure('Name', ['Identificacion ' nombreEje]);

    tiledlayout(2,2);

    for i = 1:length(pruebas)

        siguiente = pruebas(i);
        indices = datos.prueba == siguiente;

        tiempo = datos.tiempo_s(indices);
        real = datos.posicion_real(indices);
        objetivo = datos.posicion_objetivo(indices);
        inicial = datos.posicion_inicial(indices);

        % Ordenar las muestras por tiempo
        [tiempo, orden] = sort(tiempo);
        real = real(orden);
        objetivo = objetivo(orden);
        inicial = inicial(orden);

        % Curva ajustada
        tModelo = linspace(0, max(tiempo), 500)';

        yModelo = modeloSegundoOrden( ...
            tModelo, inicial(1), objetivo(1), K, zeta, wn);

        % Grafica
        nexttile;

        plot(tiempo, real, 'o', ...
            'DisplayName', 'Datos experimentales');

        hold on;

        plot(tModelo, yModelo, '-', ...
            'LineWidth', 1.5, ...
            'DisplayName', 'Modelo de segundo orden');

        yline(objetivo(1), '--', ...
            'DisplayName', 'Posicion objetivo');

        grid on;

        xlabel('Tiempo (s)');
        ylabel('Posicion (unidades)');

        title(['Prueba ' num2str(siguiente)]);

        legend('Location', 'best');
    end

    sgtitle(['Identificacion experimental - Eje ' nombreEje]);
end
