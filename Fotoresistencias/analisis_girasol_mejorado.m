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

RANGO_LOCAL = 10;         % Grados alrededor del centro
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
numC = double(getCol(TC,varsC,'N'));
numA = double(getCol(TA,varsA,'N'));
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
validC = isfinite(numC) & isfinite(iteraciones) & all(isfinite(Xcentro),2);
numC = numC(validC);
iteraciones = iteraciones(validC);
Xcentro = Xcentro(validC,:);

validA = isfinite(numA) & isfinite(angulos) & all(isfinite(Xangulos),2) & ...
         strlength(condiciones)>0 & strlength(ejes)>0;
numA = numA(validA);
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
    idx = find(iteraciones==idsIteracion(k));
    [~,ord] = sort(numC(idx));
    Xi = Xcentro(idx(ord),:);
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
    ii = find(idx);
    [~,ord] = sort(numA(ii));
    Xi = Xangulos(ii(ord),:);
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
idxCentro = nombres=="CENTRO_0" & angCond==0 & ejeCond=="CENTRO";
if nnz(idxCentro) ~= 1
    error('Incluya CENTRO_0,0,CENTRO en angulos.csv (misma sesion angular).');
end
mediasRaw = medias;
ScentroRaw = mediasRaw(idxCentro,:);
medias = mediasRaw-Sosc;
Scentro = medias(idxCentro,:);
if any(medias(:)<0)
    warning('Hay lecturas negativas tras restar oscuridad; revise la referencia.');
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

% Caracterizacion ambiental independiente; no se resta del modelo angular.
Uamb = SambNeto .* ganancias;
[eAmbX,eAmbY] = diferencial(Uamb,EPSILON);
eAmbX = eAmbX-Dx0; eAmbY = eAmbY-Dy0;

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
localP = abs(thetaPan)<=RANGO_LOCAL;
localT = abs(thetaTilt)<=RANGO_LOCAL;
[pPanLocal,SSEPanLocal,R2PanLocal] = ajustarModelo(thetaPan(localP),errorPan(localP),1);
[pTiltLocal,SSETiltLocal,R2TiltLocal] = ajustarModelo(thetaTilt(localT),errorTilt(localT),1);
% Jacobiano local: filas = errores X,Y; columnas = angulos Pan,Tilt.
ip = idxPan & abs(angCond)<=RANGO_LOCAL & isfinite(ey) & isfinite(ex);
it = idxTilt & abs(angCond)<=RANGO_LOCAL & isfinite(ex) & isfinite(ey);
pCrossP = ajustarModelo([0;angCond(ip)],[0;ey(ip)],1);
pCrossT = ajustarModelo([0;angCond(it)],[0;ex(it)],1);
J_deg = [pPanLocal(1),pCrossT(1);pCrossP(1),pTiltLocal(1)];
J_rad = J_deg*180/pi;
K_Pan = J_rad(1,1); K_Tilt = J_rad(2,2);

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

fprintf('\n3. RESULTADOS POR POSICION ANGULAR (ADC corregidos por oscuridad)\n');
fprintf('%-18s %7s %-5s %10s %10s %10s %10s %10s %10s\n', ...
    'Condicion','Angulo','Eje','S1','S2','S3','S4','Error X','Error Y');
for k=1:nCond
    fprintf('%-18s %7.1f %-5s %10.2f %10.2f %10.2f %10.2f %10.5f %10.5f\n', ...
        nombres(k),angCond(k),ejeCond(k),medias(k,1),medias(k,2), ...
        medias(k,3),medias(k,4),ex(k),ey(k));
end

fprintf('\n4. MODELOS ANGULARES\n');
fprintf('Pan lineal:      e_x(theta) = %.8f*theta\n',pPan1(1));
fprintf('Pan cuadratico:  e_x(theta) = %.8f*theta^2 %+.8f*theta\n',pPan2(1),pPan2(2));
fprintf('Tilt lineal:     e_y(theta) = %.8f*theta\n',pTilt1(1));
fprintf('Tilt cuadratico: e_y(theta) = %.8f*theta^2 %+.8f*theta\n',pTilt2(1),pTilt2(2));
fprintf('Pan local:       e_x(theta) = %.8f*theta\n',pPanLocal(1));
fprintf('Tilt local:      e_y(theta) = %.8f*theta\n',pTiltLocal(1));
modelos = ["Pan lineal";"Pan cuadratico";"Tilt lineal";"Tilt cuadratico";"Pan local";"Tilt local"];
SSE = [SSEPan1;SSEPan2;SSETilt1;SSETilt2;SSEPanLocal;SSETiltLocal];
R2 = [R2Pan1;R2Pan2;R2Tilt1;R2Tilt2;R2PanLocal;R2TiltLocal];
N = [numel(thetaPan);numel(thetaPan);numel(thetaTilt);numel(thetaTilt);nnz(localP);nnz(localT)];
RMSE = sqrt(SSE./N);
disp(table(modelos,N,SSE,RMSE,R2));
fprintf('Posiciones validas: Pan %d/%d; Tilt %d/%d (sin centro).\n',numel(thetaPan)-1,nnz(idxPan),numel(thetaTilt)-1,nnz(idxTilt));
fprintf('\n5. CARACTERIZACION AMBIENTAL\n');
fprintf('Error sin fuente: ex = %.6f, ey = %.6f\n',eAmbX,eAmbY);
fprintf('Total compensado ambiente = %.3f; centro = %.3f\n',sum(Uamb),totalCentro);
fprintf('Incremento ADC centro respecto a ambiente (solo diagnostico):\n');
disp(ScentroRaw-Samb);
fprintf('\n6. GANANCIAS LOCALES Y ACOPLAMIENTO\n');
fprintf('Jacobiano por grado (filas X,Y; columnas Pan,Tilt):\n'); disp(J_deg);
fprintf('Jacobiano por radian:\n'); disp(J_rad);
fprintf('K_Pan = %.8f; K_Tilt = %.8f (error/rad)\n',K_Pan,K_Tilt);
fprintf('Acoplamiento Pan->Y / Pan->X = %.3f %%\n',100*abs(J_deg(2,1))/abs(J_deg(1,1)));
fprintf('Acoplamiento Tilt->X / Tilt->Y = %.3f %%\n',100*abs(J_deg(1,2))/abs(J_deg(2,2)));
fprintf('No asumir desacoplamiento sin evaluar estas relaciones.\n');
fprintf('El ajuste local usa solo tres posiciones si se mide a -10,0,+10 grados.\n');
fprintf('La correccion de oscuridad es empirica; no separa intensidades opticas.\n');
fprintf('No extrapolar fuera del rango medido.\n');

%% ---------------- GRAFICAS ----------------
if MOSTRAR_GRAFICAS
fig1=figure('Name','Calibracion angular Pan','Color','w');
scatter(thetaPan,errorPan,65,'filled'); hold on; grid on;
xx=linspace(min(thetaPan),max(thetaPan),200);
plot(xx,polyval(pPan1,xx),'LineWidth',1.6);
plot(xx,polyval(pPan2,xx),'--','LineWidth',1.6);
xl = linspace(-RANGO_LOCAL,RANGO_LOCAL,100);
plot(xl,polyval(pPanLocal,xl),':','LineWidth',2);
xlabel('Angulo Pan (grados)'); ylabel('Error horizontal e_x');
title('Calibracion angular del eje Pan');
legend('Mediciones','Ajuste lineal','Ajuste cuadratico','Lineal local','Location','best');

fig2=figure('Name','Calibracion angular Tilt','Color','w');
scatter(thetaTilt,errorTilt,65,'filled'); hold on; grid on;
xx=linspace(min(thetaTilt),max(thetaTilt),200);
plot(xx,polyval(pTilt1,xx),'LineWidth',1.6);
plot(xx,polyval(pTilt2,xx),'--','LineWidth',1.6);
xl = linspace(-RANGO_LOCAL,RANGO_LOCAL,100);
plot(xl,polyval(pTiltLocal,xl),':','LineWidth',2);
xlabel('Angulo Tilt (grados)'); ylabel('Error vertical e_y');
title('Calibracion angular del eje Tilt');
legend('Mediciones','Ajuste lineal','Ajuste cuadratico','Lineal local','Location','best');

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
    x=x(:); y=y(:);
    if ~any(x<0) || ~any(x>0)
        warning('Ajuste sin datos validos a ambos lados del centro.');
    end
    A = x.^(grado:-1:1);
    if rank(A)<grado
        error('Datos insuficientes para ajustar el modelo restringido.');
    end
    p = [(A\y).' 0];
    yhat=polyval(p,x);
    SSE=sum((y-yhat).^2);
    SST=sum((y-mean(y)).^2);
    if SST < eps
        R2=NaN;
    else
        R2=1-SSE/SST;
    end
end

function [dx,dy] = diferencial(u,tol)
    dx=NaN; dy=NaN;
    if all(u>=0) && sum(u)>tol
        dx=(u(1)+u(3)-u(2)-u(4))/sum(u);
        dy=(u(1)+u(2)-u(3)-u(4))/sum(u);
    end
end
