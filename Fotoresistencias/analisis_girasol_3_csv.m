%% MODELO Y CALIBRACION DEL GIRASOL - PAN/TILT CON 4 SENSORES LDR
% El programa utiliza TRES archivos CSV:
%
% 0) oscuridad_ambiente.csv
%    Columnas: Condicion,N,S1,S2,S3,S4
%    Condiciones: OSCURIDAD y AMBIENTE (fuente apagada).
%
% 1) centro.csv
%    Columnas: Iteracion,N,S1,S2,S3,S4
%    Debe contener las cuatro repeticiones realizadas con el sistema
%    apuntando al centro. Cada repeticion puede tener varias muestras.
%
%    Ejemplo:
%    Iteracion,N,S1,S2,S3,S4
%    1,1,901,923,827,774
%    1,2,902,924,828,775
%    ...
%    2,1,922,939,841,786
%    ...
%    4,20,897,923,827,775
%
% 2) angulos.csv
%    Columnas: Condicion,Angulo_deg,Eje,N,S1,S2,S3,S4
%    Debe contener las mediciones de todas las posiciones angulares
%    (izquierda, derecha, arriba y abajo). Una fila por muestra.
%
%    Ejemplo:
%    CENTRO_0,0,CENTRO,1,...
%    IZQUIERDA_5,-10,PAN,1,820,850,760,710
%    IZQUIERDA_5,-10,PAN,2, ...
%    DERECHA_5,10,PAN,1, ...
%    ARRIBA_5,10,TILT,1, ...
%    ABAJO_5,-10,TILT,1, ...
%
% Convencion:
%   derecha = +Pan; izquierda = -Pan
%   arriba = +Tilt; abajo = -Tilt
%
% Se promedian las ultimas N_FINAL muestras de cada repeticion/posicion.
% No se generan archivos de resultados: las tablas se imprimen en consola
% y se conservan las tres graficas.

clear; clc; close all;

%% ---------------- CONFIGURACION ----------------
ARCHIVO_OA = 'oscuridad_ambiente.csv';
ARCHIVO_CENTRO = 'centro.csv';
ARCHIVO_ANGULOS = 'angulos.csv';

N_FINAL = 10;             % Muestras finales que se promedian
MOSTRAR_GRAFICAS = true;
EPSILON = 1e-9;

%% ---------------- LECTURA DE ARCHIVOS ----------------
if ~isfile(ARCHIVO_CENTRO)
    error('No se encontro el archivo: %s', ARCHIVO_CENTRO);
end
if ~isfile(ARCHIVO_ANGULOS)
    error('No se encontro el archivo: %s', ARCHIVO_ANGULOS);
end

if ~isfile(ARCHIVO_OA)
    error('No se encontro el archivo: %s',ARCHIVO_OA);
end
TO = readtable(ARCHIVO_OA);
TC = readtable(ARCHIVO_CENTRO);
TA = readtable(ARCHIVO_ANGULOS);

% Validar columnas requeridas
varsC = upper(string(TC.Properties.VariableNames));
varsA = upper(string(TA.Properties.VariableNames));

reqC = ["ITERACION","N","S1","S2","S3","S4"];
reqA = ["CONDICION","ANGULO_DEG","EJE","N","S1","S2","S3","S4"];

if ~all(ismember(reqC,varsC))
    error('centro.csv debe contener: Iteracion,N,S1,S2,S3,S4.');
end
if ~all(ismember(reqA,varsA))
    error(['angulos.csv debe contener: Condicion,Angulo_deg,Eje,N,' ...
           'S1,S2,S3,S4.']);
end

% Acceder a las columnas sin depender de mayusculas/minusculas
getCol = @(T,vars,nombre) T{:,find(vars==upper(string(nombre)),1)};

varsO = upper(string(TO.Properties.VariableNames));
if ~all(ismember(["CONDICION","N","S1","S2","S3","S4"],varsO))
    error('oscuridad_ambiente.csv debe contener Condicion,N,S1,S2,S3,S4.');
end
condOA = upper(strtrim(string(getCol(TO,varsO,'Condicion'))));
numOA = double(getCol(TO,varsO,'N'));
Xoa = double([getCol(TO,varsO,'S1'),getCol(TO,varsO,'S2'), ...
              getCol(TO,varsO,'S3'),getCol(TO,varsO,'S4')]);
refOA = nan(2,4);
stdOA = nan(2,4);
nOA = zeros(2,1);
labelsOA = ["OSCURIDAD","AMBIENTE"];
for k = 1:2
    idx = find(condOA==labelsOA(k) & isfinite(numOA) & all(isfinite(Xoa),2));
    if isempty(idx)
        error('Faltan muestras validas de %s.',labelsOA(k));
    end
    [~,orden] = sort(numOA(idx));
    idx = idx(orden);
    n = min(N_FINAL,numel(idx));
    Xf = Xoa(idx(end-n+1:end),:);
    refOA(k,:) = mean(Xf,1);
    stdOA(k,:) = std(Xf,0,1);
    nOA(k) = n;
end
Sosc = refOA(1,:);
Samb = refOA(2,:);
SambNeto = Samb-Sosc;
if any(SambNeto<0)
    warning('Algun sensor tiene menor lectura en ambiente que en oscuridad.');
end

iteraciones = double(getCol(TC,varsC,'Iteracion'));
Xcentro = double([getCol(TC,varsC,'S1'),getCol(TC,varsC,'S2'), ...
    getCol(TC,varsC,'S3'),getCol(TC,varsC,'S4')]);
if size(Xcentro,2) ~= 4
    error('No fue posible identificar las cuatro columnas de sensores en centro.csv.');
end

condiciones = upper(strtrim(string(getCol(TA,varsA,'Condicion'))));
angulos = double(getCol(TA,varsA,'Angulo_deg'));
ejes = upper(strtrim(string(getCol(TA,varsA,'Eje'))));
Xangulos = double([getCol(TA,varsA,'S1'),getCol(TA,varsA,'S2'), ...
    getCol(TA,varsA,'S3'),getCol(TA,varsA,'S4')]);

% Eliminar filas incompletas o no numericas
validC = isfinite(iteraciones) & all(isfinite(Xcentro),2);
iteraciones = iteraciones(validC);
Xcentro = Xcentro(validC,:);

validA = isfinite(angulos) & all(isfinite(Xangulos),2) & ...
         strlength(condiciones)>0 & strlength(ejes)>0;
condiciones = condiciones(validA);
angulos = angulos(validA);
ejes = ejes(validA);
Xangulos = Xangulos(validA,:);

if isempty(Xcentro) || isempty(Xangulos)
    error('Uno de los archivos no contiene mediciones validas.');
end

%% ---------------- PROMEDIOS DE LAS CUATRO REPETICIONES DEL CENTRO ----------------
idsIteracion = unique(iteraciones,'stable');
if numel(idsIteracion) ~= 4
    warning('Se esperaban 4 iteraciones de centro; se encontraron %d.',numel(idsIteracion));
end

promCentroRep = nan(numel(idsIteracion),4);
stdCentroRep = nan(numel(idsIteracion),4);
nCentroRep = zeros(numel(idsIteracion),1);

for k = 1:numel(idsIteracion)
    Xi = Xcentro(iteraciones==idsIteracion(k),:);
    n = min(N_FINAL,size(Xi,1));
    Xi = Xi(end-n+1:end,:);
    promCentroRep(k,:) = mean(Xi,1);
    stdCentroRep(k,:) = std(Xi,0,1);
    nCentroRep(k) = size(Xi,1);
end

% El centro de referencia es el promedio de las cuatro medias de repeticion.
ScentroRepRaw = mean(promCentroRep,1);
% Las cuatro repeticiones se conservan para evaluar repetibilidad.
% No se aplica una referencia ambiental de otra sesion a estas repeticiones.

%% ---------------- PROMEDIO DE CADA POSICION ANGULAR ----------------
nCond = numel(unique(condiciones,'stable'));
nombres = unique(condiciones,'stable');
medias = nan(nCond,4);
desvios = nan(nCond,4);
angCond = nan(nCond,1);
ejeCond = strings(nCond,1);
nMuestras = zeros(nCond,1);

for k = 1:nCond
    idx = condiciones==nombres(k);
    Xi = Xangulos(idx,:);
    n = min(N_FINAL,size(Xi,1));
    Xf = Xi(end-n+1:end,:);
    medias(k,:) = mean(Xf,1);
    desvios(k,:) = std(Xf,0,1);
    nMuestras(k) = size(Xf,1);

    a = unique(angulos(idx));
    e = unique(ejes(idx));
    if numel(a) ~= 1 || numel(e) ~= 1
        error('La condicion %s debe tener un unico angulo y eje.',nombres(k));
    end
    angCond(k) = a;
    ejeCond(k) = e;
end

% Validar que las condiciones pertenezcan a los ejes esperados
if any(~ismember(ejeCond,["PAN","TILT","CENTRO"]))
    error('La columna Eje debe contener PAN, TILT o CENTRO.');
end

% Usar el centro de la misma sesion angular para calibrar ganancias.
idxCentro = nombres=="CENTRO_0" & angCond==0;
if nnz(idxCentro) ~= 1
    error('Incluya CENTRO_0,0,CENTRO en angulos.csv (misma sesion angular).');
end
mediasRaw = medias;
ScentroRaw = mediasRaw(idxCentro,:);
medias = (mediasRaw-Sosc)-SambNeto;
Scentro = medias(idxCentro,:);
if any(medias(:)<0)
    warning('Hay incrementos ADC negativos tras restar ambiente; revise la referencia.');
end

%% ---------------- COMPENSACION ENTRE SENSORES ----------------
% Se normaliza cada sensor respecto a su lectura promedio en el centro.
% De esta forma se compensa el desequilibrio de lectura entre canales.
%
% G_i = promedio(Scentro) / Scentro_i
% U_i = G_i * S_i
%
% Luego se calculan las señales diferenciales normalizadas y se resta
% el valor diferencial del centro para que el error sea cero en el centro.

if any(Scentro <= 0)
    error('Las lecturas promedio del centro deben ser positivas.');
end

ganancias = mean(Scentro) ./ Scentro;
Ucentro = ganancias .* Scentro;

totalCentro = sum(Ucentro);
Dx0 = (Ucentro(1)+Ucentro(3)-Ucentro(2)-Ucentro(4))/totalCentro;
Dy0 = (Ucentro(1)+Ucentro(2)-Ucentro(3)-Ucentro(4))/totalCentro;

U = medias .* ganancias;
totales = sum(U,2);
Dx = nan(nCond,1);
Dy = nan(nCond,1);

for k=1:nCond
    if totales(k) > EPSILON && all(U(k,:)>=0)
        Dx(k) = (U(k,1)+U(k,3)-U(k,2)-U(k,4))/totales(k);
        Dy(k) = (U(k,1)+U(k,2)-U(k,3)-U(k,4))/totales(k);
    end
end

ex = Dx-Dx0;
ey = Dy-Dy0;

%% ---------------- AJUSTE DE MODELOS ANGULARES ----------------
idxPan = ejeCond=="PAN" & ~idxCentro;
idxTilt = ejeCond=="TILT" & ~idxCentro;

thetaPan = angCond(idxPan);
errorPan = ex(idxPan);
thetaTilt = angCond(idxTilt);
errorTilt = ey(idxTilt);

validPan = isfinite(thetaPan) & isfinite(errorPan);
validTilt = isfinite(thetaTilt) & isfinite(errorTilt);
thetaPan = thetaPan(validPan);
errorPan = errorPan(validPan);
thetaTilt = thetaTilt(validTilt);
errorTilt = errorTilt(validTilt);

if numel(thetaPan)<3 || numel(thetaTilt)<3
    error('Se requieren al menos tres posiciones angulares validas por eje.');
end

% Agregar el punto central (0,0) como referencia.
thetaPan = [0;thetaPan(:)];
errorPan = [0;errorPan(:)];
thetaTilt = [0;thetaTilt(:)];
errorTilt = [0;errorTilt(:)];

[pPan1,SSEPan1,R2Pan1] = ajustarModelo(thetaPan,errorPan,1);
[pPan2,SSEPan2,R2Pan2] = ajustarModelo(thetaPan,errorPan,2);
[pTilt1,SSETilt1,R2Tilt1] = ajustarModelo(thetaTilt,errorTilt,1);
[pTilt2,SSETilt2,R2Tilt2] = ajustarModelo(thetaTilt,errorTilt,2);

%% ---------------- RESULTADOS EN CONSOLA ----------------
fprintf('\n============================================================\n');
fprintf('             ANALISIS Y CALIBRACION DEL GIRASOL\n');
fprintf('============================================================\n');

fprintf('\n0. REFERENCIAS DE OSCURIDAD Y AMBIENTE\n');
disp(array2table([refOA;SambNeto],'VariableNames',{'S1','S2','S3','S4'}, ...
    'RowNames',{'Oscuridad','Ambiente','Ambiente_neto'}));
fprintf('Muestras utilizadas: oscuridad = %d, ambiente = %d\n',nOA);
disp(array2table(stdOA,'VariableNames',{'S1','S2','S3','S4'}, ...
    'RowNames',{'Std_oscuridad','Std_ambiente'}));
fprintf('\n1. REPETICIONES DEL CENTRO (ADC originales)\n');
fprintf('Iteracion     N       S1          S2          S3          S4\n');
for k=1:numel(idsIteracion)
    fprintf('%9g %5d %10.3f %10.3f %10.3f %10.3f\n', ...
        idsIteracion(k),nCentroRep(k),promCentroRep(k,1), ...
        promCentroRep(k,2),promCentroRep(k,3),promCentroRep(k,4));
end
fprintf('Promedio     -  %10.3f %10.3f %10.3f %10.3f\n',ScentroRepRaw);
fprintf('Centro angular corregido: %10.3f %10.3f %10.3f %10.3f\n',Scentro);
fprintf('Desv. entre iteraciones: %10.3f %10.3f %10.3f %10.3f\n', ...
    std(promCentroRep,0,1));

fprintf('\n2. GANANCIAS DE COMPENSACION\n');
for j=1:4
    fprintf('G%d = %.6f\n',j,ganancias(j));
end

fprintf('\n3. RESULTADOS POR POSICION ANGULAR (ADC corregidos)\n');
fprintf('%-18s %7s %-5s %10s %10s %10s %10s %10s %10s\n', ...
    'Condicion','Angulo','Eje','S1','S2','S3','S4','Error X','Error Y');
for k=1:nCond
    fprintf('%-18s %7.1f %-5s %10.2f %10.2f %10.2f %10.2f %10.5f %10.5f\n', ...
        nombres(k),angCond(k),ejeCond(k),medias(k,1),medias(k,2), ...
        medias(k,3),medias(k,4),ex(k),ey(k));
end

fprintf('\n4. MODELOS ANGULARES\n');
fprintf('Pan lineal:      e_x(theta) = %.8f*theta + %.8f\n',pPan1(1),pPan1(2));
fprintf('Pan cuadratico:  e_x(theta) = %.8f*theta^2 + %.8f*theta + %.8f\n', ...
    pPan2(1),pPan2(2),pPan2(3));
fprintf('Tilt lineal:     e_y(theta) = %.8f*theta + %.8f\n',pTilt1(1),pTilt1(2));
fprintf('Tilt cuadratico: e_y(theta) = %.8f*theta^2 + %.8f*theta + %.8f\n', ...
    pTilt2(1),pTilt2(2),pTilt2(3));

fprintf('\nMetricas de ajuste:\n');
fprintf('%-18s %14s %12s\n','Modelo','SSE','R^2');
fprintf('%-18s %14.6g %12.6f\n','Pan lineal',SSEPan1,R2Pan1);
fprintf('%-18s %14.6g %12.6f\n','Pan cuadratico',SSEPan2,R2Pan2);
fprintf('%-18s %14.6g %12.6f\n','Tilt lineal',SSETilt1,R2Tilt1);
fprintf('%-18s %14.6g %12.6f\n','Tilt cuadratico',SSETilt2,R2Tilt2);

fprintf('\nNota: compare R^2, SSE y la forma de las curvas antes de elegir\n');
fprintf('el modelo. No se recomienda extrapolar fuera de -30 a +30 grados.\n');

%% ---------------- GRAFICAS ----------------
if MOSTRAR_GRAFICAS
fig1=figure('Name','Calibracion angular Pan','Color','w');
scatter(thetaPan,errorPan,65,'filled'); hold on; grid on;
xx=linspace(min(thetaPan),max(thetaPan),200);
plot(xx,polyval(pPan1,xx),'LineWidth',1.6);
plot(xx,polyval(pPan2,xx),'--','LineWidth',1.6);
xlabel('Angulo Pan (grados)'); ylabel('Error horizontal e_x');
title('Calibracion angular del eje Pan');
legend('Mediciones','Ajuste lineal','Ajuste cuadratico','Location','best');

fig2=figure('Name','Calibracion angular Tilt','Color','w');
scatter(thetaTilt,errorTilt,65,'filled'); hold on; grid on;
xx=linspace(min(thetaTilt),max(thetaTilt),200);
plot(xx,polyval(pTilt1,xx),'LineWidth',1.6);
plot(xx,polyval(pTilt2,xx),'--','LineWidth',1.6);
xlabel('Angulo Tilt (grados)'); ylabel('Error vertical e_y');
title('Calibracion angular del eje Tilt');
legend('Mediciones','Ajuste lineal','Ajuste cuadratico','Location','best');

% Promedios del centro y de cada condicion angular.
etiquetas = ["OSCURIDAD"; "AMBIENTE"; nombres(:)];
mediasGraf = [Sosc; Samb; mediasRaw];
fig3=figure('Name','Promedios por condicion','Color','w');
plot(1:numel(etiquetas),mediasGraf,'o-','LineWidth',1.2);
grid on;
xticks(1:numel(etiquetas)); xticklabels(etiquetas); xtickangle(45);
ylabel('Lectura ADC original'); title('Promedio de las muestras finales por condicion');
legend('S1','S2','S3','S4','Location','best');

    figure(fig1); figure(fig2); figure(fig3);
end

%% ---------------- FUNCION LOCAL ----------------
function [p,SSE,R2] = ajustarModelo(x,y,grado)
    p=polyfit(x,y,grado);
    yhat=polyval(p,x);
    SSE=sum((y-yhat).^2);
    SST=sum((y-mean(y)).^2);
    if SST < eps
        R2=NaN;
    else
        R2=1-SSE/SST;
    end
end
