
%% Diseno del controlador integral multivariable - El Girasol

clear;
clc;
close all;

%% 1. Parametros generales

Tm = 0.02;
TsMax = 2;
MpMax = 10;

Amplitud = deg2rad(5);
CruceMax = deg2rad(0.5);

t = (0:Tm:8)';

s = tf('s');

%% 2. Modelos de los motores

Gpan = 632.5/(s^2 + 25.33*s + 641.1);
Gtilt = 627.3/(s^2 + 25.1*s + 633.8);

P = ss(blkdiag(Gpan,Gtilt));

[Ap,Bp,Cp,Dp] = ssdata(P);

Pd = c2d(P,Tm,'zoh');

[Ad,Bd,Cd,Dd] = ssdata(Pd);

n = size(Ap,1);

%% 3. Modelo de pequena senal de los sensores

J = [-0.06485802, -0.0223;
     -0.0627,     -0.01687204];

fprintf('\n=== Modelo de los sensores ===\n');

disp(J);

fprintf('Determinante = %.10f\n',det(J));
fprintf('Numero de condicion = %.6f\n',cond(J));

fprintf('Valores singulares:\n');
disp(svd(J));

%% 4. Ganancias del controlador inicial

KIpan = 97.74253844;
KItilt = 373.99448914;

KI = diag([KIpan KItilt]);

Ka = diag([KIpan*abs(J(1,1)), ...
           KItilt*abs(J(2,2))]);

fprintf('\n=== Ganancias integrales angulares ===\n');
disp(Ka);

%% 5. Controladores inicial y multivariable directo

% Controlador integral independiente.
Kind = -KI;

% Controlador multivariable con inversion directa.
Ddirecta = J\eye(2);

Kdirecta = Ka*Ddirecta;

fprintf('\n=== Matriz del controlador independiente ===\n');
disp(Kind);

fprintf('\n=== Matriz del controlador multivariable directo ===\n');
disp(Kdirecta);

fprintf('Compensacion nominal directa:\n');
disp(Ddirecta*J);

%% 6. Evaluacion de los controladores de referencia

Rind = evaluarControlador( ...
    Kind,J,Ap,Bp,Cp,Ad,Bd,Cd,Tm,t,Amplitud);

Rdir = evaluarControlador( ...
    Kdirecta,J,Ap,Bp,Cp,Ad,Bd,Cd,Tm,t,Amplitud);

mostrarResultados('Integral independiente',Rind);
mostrarResultados('Multivariable directo',Rdir);

%% 7. Busqueda del parametro de regularizacion

lambda = logspace(-6,-1,150);

N = length(lambda);

Ts = nan(N,2);
Mp = nan(N,2);
Cruce = nan(N,2);

Ruido = nan(N,1);
Esfuerzo = nan(N,1);
RadioEspectral = nan(N,1);

Estable = false(N,1);
Factible = false(N,1);

Kreg = cell(N,1);
Resultados = cell(N,1);

fprintf('\n=== Busqueda de regularizacion ===\n');

for k = 1:N

    l = lambda(k);

    % Inversa regularizada de Tikhonov.
    D = (J'*J + l^2*eye(2))\J';

    % Matriz del controlador integral.
    K = Ka*D;

    Kreg{k} = K;

    R = evaluarControlador( ...
        K,J,Ap,Bp,Cp,Ad,Bd,Cd,Tm,t,Amplitud);

    Resultados{k} = R;

    Ruido(k) = norm(D,2);
    RadioEspectral(k) = max(abs(R.polosD));

    Estable(k) = R.estableC && R.estableD;

    if ~Estable(k)
        continue;
    end

    Ts(k,:) = R.Ts;
    Mp(k,:) = R.Mp;
    Cruce(k,:) = R.cruce;
    Esfuerzo(k) = max(R.esfuerzo);

    Factible(k) = ...
        all(isfinite(R.Ts)) && ...
        all(R.Ts <= TsMax) && ...
        all(R.Mp <= MpMax) && ...
        all(R.cruce <= CruceMax) && ...
        all(R.errorFinal <= deg2rad(0.01));

end

fprintf('Valores de lambda evaluados: %d\n',N);
fprintf('Controladores estables: %d\n',sum(Estable));
fprintf('Controladores factibles: %d\n',sum(Factible));

%% 8. Evaluacion de robustez

% Incertidumbres relativas hipoteticas en los coeficientes de J.
niveles = [0.01 0.05 0.10];

Npruebas = 100;

rng(1);

% Las mismas perturbaciones se aplican a todos los controladores.
perturbaciones = 2*rand(2,2,Npruebas)-1;

RobInd = evaluarRobustez( ...
    Kind,J,Ap,Bp,Cp,Ad,Bd,Cd,Tm, ...
    niveles,perturbaciones);

RobDir = evaluarRobustez( ...
    Kdirecta,J,Ap,Bp,Cp,Ad,Bd,Cd,Tm, ...
    niveles,perturbaciones);

RobReg = nan(N,length(niveles));

indices = find(Factible);

for k = indices'

    RobReg(k,:) = evaluarRobustez( ...
        Kreg{k},J,Ap,Bp,Cp,Ad,Bd,Cd,Tm, ...
        niveles,perturbaciones);

end

%% 9. Seleccion del controlador regularizado

hayRegularizado = ~isempty(indices);

if hayRegularizado

    % Priorizar robustez y luego menor amplificacion de ruido.
    criterios = [-RobReg(indices,3), ...
                 -RobReg(indices,2), ...
                 -RobReg(indices,1), ...
                  Ruido(indices)];

    [~,orden] = sortrows(criterios);

    mejor = indices(orden(1));

    lambdaOpt = lambda(mejor);

    Kopt = Kreg{mejor};

    Ropt = Resultados{mejor};

    RobOpt = RobReg(mejor,:);

    Dopt = (J'*J + lambdaOpt^2*eye(2))\J';

    fprintf('\n=== Controlador regularizado seleccionado ===\n');

    fprintf('Lambda = %.10f\n',lambdaOpt);

    fprintf('Matriz de compensacion:\n');
    disp(Dopt);

    fprintf('Matriz del controlador integral:\n');
    disp(Kopt);

    mostrarResultados('Multivariable regularizado',Ropt);

else

    fprintf('\nNo se encontro un controlador regularizado ');
    fprintf('que cumpla todas las especificaciones.\n');

end

%% 10. Comparacion de amplificacion de ruido

fprintf('\n=== Sensibilidad al ruido ===\n');

fprintf('Norma de la inversa directa = %.6f\n', ...
    norm(Ddirecta,2));

fprintf('Norma del controlador independiente = %.6f\n', ...
    norm(Kind,2));

fprintf('Norma del controlador directo = %.6f\n', ...
    norm(Kdirecta,2));

if hayRegularizado

    fprintf('Norma de la inversa regularizada = %.6f\n', ...
        norm(Dopt,2));

    fprintf('Norma del controlador regularizado = %.6f\n', ...
        norm(Kopt,2));

    reduccion = 100*(1-norm(Dopt,2)/norm(Ddirecta,2));

    fprintf('Reduccion de amplificacion = %.4f %%\n', ...
        reduccion);

end

%% 11. Tabla de comparacion

nombres = ["Independiente"; "Directo"];

listaR = {Rind; Rdir};

robustez = [RobInd; RobDir];

listaK = {Kind; Kdirecta};

if hayRegularizado

    nombres(end+1) = "Regularizado";

    listaR{end+1} = Ropt;

    listaK{end+1} = Kopt;

    robustez(end+1,:) = RobOpt;

end

M = length(nombres);

tabla = nan(M,9);

estableC = false(M,1);
estableD = false(M,1);

for k = 1:M

    R = listaR{k};

    estableC(k) = R.estableC;
    estableD(k) = R.estableD;

    tabla(k,:) = [ ...
        R.Ts, ...
        R.Mp, ...
        rad2deg(R.cruce), ...
        max(real(R.polosC)), ...
        max(abs(R.polosD)), ...
        norm(listaK{k},2)];

end

Comparacion = table( ...
    nombres,estableC,estableD, ...
    tabla(:,1),tabla(:,2), ...
    tabla(:,3),tabla(:,4), ...
    tabla(:,5),tabla(:,6), ...
    tabla(:,7),tabla(:,8),tabla(:,9), ...
    'VariableNames',{ ...
    'Controlador','EstableC','EstableD', ...
    'TsPan','TsTilt','MpPan','MpTilt', ...
    'CrucePan_deg','CruceTilt_deg', ...
    'MaxRealPolo','MaxModuloPolo','NormaK'});

fprintf('\n=== Comparacion general ===\n');

disp(Comparacion);

TablaRobustez = table( ...
    nombres, ...
    robustez(:,1), ...
    robustez(:,2), ...
    robustez(:,3), ...
    'VariableNames',{ ...
    'Controlador','Estables_1pct', ...
    'Estables_5pct','Estables_10pct'});

fprintf('\n=== Robustez ante incertidumbres ===\n');

disp(TablaRobustez);

%% 12. Respuestas al escalon

colores = [0.95 0.25 0.25;
           0.20 0.65 1.00;
           0.20 0.90 0.40];

fig1 = figure('Name','Respuestas al escalon');

tiledlayout(2,2);

% Seleccionar solamente los controladores multivariables.
indicesEscalon = find(nombres ~= "Independiente");

ejes = {'Pan','Tilt'};

for entrada = 1:2

    for salida = 1:2

        nexttile;

        hold on;
        grid on;

        % Graficar solamente los controladores multivariables.
        for k = indicesEscalon(:)'

            R = listaR{k};

            plot(t, ...
                rad2deg(R.y(:,salida,entrada)), ...
                'Color',colores(k,:), ...
                'LineWidth',1.6, ...
                'DisplayName',char(nombres(k)));

        end

        if entrada == salida

            yline(rad2deg(Amplitud),'--w', ...
                'HandleVisibility','off');

            yline(rad2deg(Amplitud)*1.02,':w', ...
                'HandleVisibility','off');

            yline(rad2deg(Amplitud)*0.98,':w', ...
                'HandleVisibility','off');

        else

            yline(rad2deg(CruceMax),':w', ...
                'HandleVisibility','off');

            yline(-rad2deg(CruceMax),':w', ...
                'HandleVisibility','off');

        end

        xlabel('Tiempo (s)');
        ylabel('Angulo (grados)');

        title([ejes{entrada},' \rightarrow ', ...
               ejes{salida}]);

        legend('show','Location','best');

        % Ajustar el rango angular segun el tipo de respuesta.
        if entrada == salida
        
            % Respuesta directa de cada eje.
            ylim([-0.25 5.5]);
            yticks(0:0.5:5.5);
        
        else
        
            % Respuesta de acoplamiento cruzado.
            ylim([-0.6 0.6]);
            yticks(-0.6:0.1:0.6);
        
        end

        xlim([0 2]);
        xticks(0:0.25:2);

        hold off;

    end

end

formatoOscuro(fig1);

%% 13. Comparacion de los polos continuos

fig2 = figure('Name','Polos continuos');

hold on;
grid on;

for k = 1:M

    p = listaR{k}.polosC;

    plot(real(p),imag(p),'o', ...
        'Color',colores(k,:), ...
        'MarkerSize',9, ...
        'LineWidth',2);

end

xline(0,'--w','LineWidth',1.2);

xlabel('Parte real');
ylabel('Parte imaginaria');

title('Polos del sistema acoplado continuo');

legend([nombres; "Frontera de estabilidad"], ...
    'Location','best');

formatoOscuro(fig2);

%% 14. Comparacion de los polos discretos

fig3 = figure('Name','Polos discretos');

hold on;
grid on;

for k = 1:M

    p = listaR{k}.polosD;

    plot(real(p),imag(p),'o', ...
        'Color',colores(k,:), ...
        'MarkerSize',9, ...
        'LineWidth',2);

end

ang = linspace(0,2*pi,500);

plot(cos(ang),sin(ang),'--w','LineWidth',1.2);

axis equal;

xlabel('Parte real');
ylabel('Parte imaginaria');

title('Polos del sistema acoplado discreto');

legend([nombres; "Circulo unitario"], ...
    'Location','best');

formatoOscuro(fig3);

%% 15. Efecto del parametro de regularizacion

fig4 = figure('Name','Evaluacion de regularizacion');

tiledlayout(2,2);

nexttile;

semilogx(lambda,Ts,'LineWidth',1.5);

hold on;
grid on;

yline(TsMax,'--w','Limite');

xlabel('\lambda');
ylabel('Tiempo de asentamiento (s)');

title('Tiempo de asentamiento');

legend('Pan','Tilt','Location','best');

nexttile;

semilogx(lambda,Mp,'LineWidth',1.5);

hold on;
grid on;

yline(MpMax,'--w','Limite');

xlabel('\lambda');
ylabel('Sobreimpulso (%)');

title('Sobreimpulso');

legend('Pan','Tilt','Location','best');

nexttile;

semilogx(lambda,rad2deg(Cruce),'LineWidth',1.5);

hold on;
grid on;

yline(rad2deg(CruceMax),'--w','Limite');

xlabel('\lambda');
ylabel('Desviacion angular (grados)');

title('Acoplamiento entre los ejes');

legend('Pan a Tilt','Tilt a Pan','Location','best');

nexttile;

loglog(lambda,Ruido,'LineWidth',1.5);

hold on;
grid on;

yline(norm(Ddirecta,2),'--w','Inversion directa');

xlabel('\lambda');
ylabel('Norma de la inversa');

title('Amplificacion del ruido');

if hayRegularizado

    axs = findall(fig4,'Type','axes');

    for ax = axs(:)'

        xline(ax,lambdaOpt,'--g', ...
            'HandleVisibility','off');

    end

end

formatoOscuro(fig4);

%% 16. Esfuerzo de control

fig5 = figure('Name','Esfuerzo de control');

tiledlayout(2,2);

for entrada = 1:2

    for salida = 1:2

        nexttile;

        hold on;
        grid on;

        for k = 1:M

            R = listaR{k};

            if R.estableD

                plot(t, ...
                    rad2deg(R.u(:,salida,entrada)), ...
                    'Color',colores(k,:), ...
                    'LineWidth',1.5, ...
                    'DisplayName',char(nombres(k)));

            end

        end

        xlabel('Tiempo (s)');
        ylabel('Posicion objetivo (grados)');

        title([ejes{entrada},' \rightarrow ', ...
               'Control ',ejes{salida}]);

        legend('show','Location','best');

    end

end

formatoOscuro(fig5);

%% 17. Respuesta ante un pulso de referencia

fig6 = figure('Name','Respuesta ante pulso');

tiledlayout(2,2);

for entrada = 1:2

    referencia = zeros(length(t),2);

    % Pulso angular de una muestra.
    referencia(1,entrada) = deg2rad(1);

    for salida = 1:2

        nexttile;

        hold on;
        grid on;

        for k = 1:M

            R = listaR{k};

            yPulso = lsim(R.Md,referencia,t);

            plot(t,rad2deg(yPulso(:,salida)), ...
                'Color',colores(k,:), ...
                'LineWidth',1.5);

        end

        xlabel('Tiempo (s)');
        ylabel('Angulo (grados)');

        title(['Pulso ',ejes{entrada}, ...
            ' \rightarrow ',ejes{salida}]);

        legend(nombres,'Location','best');

        ylim([-10 10]);

    end

end

formatoOscuro(fig6);

%% 18. Matrices para implementacion discreta

fprintf('\n=== Implementacion discreta ===\n');

fprintf('Matriz incremental directa (rad/error):\n');

disp(Tm*Kdirecta);

fprintf('Matriz incremental directa (grados/error):\n');

disp(rad2deg(Tm*Kdirecta));

if hayRegularizado

    fprintf('Matriz incremental regularizada (rad/error):\n');

    disp(Tm*Kopt);

    fprintf('Matriz incremental regularizada (grados/error):\n');

    disp(rad2deg(Tm*Kopt));

end

fprintf('\nDiseno y evaluacion finalizados.\n');

%% Funciones auxiliares

function R = evaluarControlador( ...
    K,J,Ap,Bp,Cp,Ad,Bd,Cd,Tm,t,A)

    n = size(Ap,1);

    % Modelo continuo del sistema acoplado.
    Ac = [Ap, Bp;
         -K*J*Cp, zeros(2)];

    Bc = [zeros(n,2);
          K*J];

    Cc = [Cp, zeros(2)];

    Mc = ss(Ac,Bc,Cc,zeros(2));

    % Modelo discreto del sistema acoplado.
    Acld = [Ad, Bd;
           -Tm*K*J*Cd, eye(2)];

    Bcld = [zeros(n,2);
            Tm*K*J];

    Ccld = [Cd, zeros(2)];

    Md = ss(Acld,Bcld,Ccld,zeros(2),Tm);

    % Salidas correspondientes a las posiciones objetivo.
    Cu = [zeros(2,n),eye(2)];

    Mu = ss(Acld,Bcld,Cu,zeros(2),Tm);

    R.Mc = Mc;
    R.Md = Md;

    R.polosC = eig(Ac);
    R.polosD = eig(Acld);

    R.estableC = all(real(R.polosC)<0);
    R.estableD = all(abs(R.polosD)<1);

    R.Ts = nan(1,2);
    R.Mp = nan(1,2);
    R.cruce = nan(1,2);
    R.esfuerzo = nan(1,2);
    R.errorFinal = nan(1,2);

    R.y = zeros(length(t),2,2);
    R.u = zeros(length(t),2,2);

    for i = 1:2

        referencia = zeros(length(t),2);

        referencia(:,i) = A;

        y = lsim(Md,referencia,t);

        u = lsim(Mu,referencia,t);

        R.y(:,:,i) = y;
        R.u(:,:,i) = u;

        if ~R.estableC || ~R.estableD
            continue;
        end

        % Respuesta correspondiente al eje excitado.
        yd = y(:,i);

        % Verificar asentamiento dentro del horizonte simulado.
        fuera = find(abs(yd-A)>0.02*abs(A),1,'last');

        if isempty(fuera)

            R.Ts(i) = 0;

        elseif fuera < length(t)

            R.Ts(i) = t(fuera+1);

        else

            R.Ts(i) = Inf;

        end

        % Sobreimpulso.
        R.Mp(i) = max(0,100*(max(yd)-A)/A);

        % Desviacion maxima del eje no excitado.
        otro = 3-i;

        R.cruce(i) = max(abs(y(:,otro)));

        % Maximo esfuerzo angular de control.
        R.esfuerzo(i) = max(abs(u(:)));

        % Error al final del horizonte de simulacion.
        R.errorFinal(i) = abs(A-yd(end));

    end

end

function mostrarResultados(nombre,R)

    fprintf('\n=== %s ===\n',nombre);

    fprintf('Estabilidad continua: %d\n',R.estableC);
    fprintf('Estabilidad discreta: %d\n',R.estableD);

    fprintf('Polos continuos:\n');
    disp(R.polosC);

    fprintf('Polos discretos:\n');
    disp(R.polosD);

    fprintf('Maxima parte real = %.8f\n', ...
        max(real(R.polosC)));

    fprintf('Maximo modulo discreto = %.8f\n', ...
        max(abs(R.polosD)));

    if R.estableC && R.estableD

        fprintf('Ts Pan = %.4f s\n',R.Ts(1));
        fprintf('Ts Tilt = %.4f s\n',R.Ts(2));

        fprintf('Mp Pan = %.4f %%\n',R.Mp(1));
        fprintf('Mp Tilt = %.4f %%\n',R.Mp(2));

        fprintf('Cruce Pan a Tilt = %.6f grados\n', ...
            rad2deg(R.cruce(1)));

        fprintf('Cruce Tilt a Pan = %.6f grados\n', ...
            rad2deg(R.cruce(2)));

        fprintf('Error final Pan = %.8f grados\n', ...
            rad2deg(R.errorFinal(1)));

        fprintf('Error final Tilt = %.8f grados\n', ...
            rad2deg(R.errorFinal(2)));

    else

        fprintf('Sistema inestable.\n');

    end

end

function porcentajes = evaluarRobustez( ...
    K,J,Ap,Bp,Cp,Ad,Bd,Cd,Tm, ...
    niveles,perturbaciones)

    N = size(perturbaciones,3);

    porcentajes = zeros(1,length(niveles));

    for k = 1:length(niveles)

        estables = 0;

        for j = 1:N

            % Perturbacion del modelo real de los sensores.
            Jp = J.*(1+niveles(k)*perturbaciones(:,:,j));

            % El controlador permanece fijo.
            Ac = [Ap, Bp;
                 -K*Jp*Cp, zeros(2)];

            Acld = [Ad, Bd;
                   -Tm*K*Jp*Cd, eye(2)];

            estableC = all(real(eig(Ac))<0);

            estableD = all(abs(eig(Acld))<1);

            if estableC && estableD

                estables = estables+1;

            end

        end

        porcentajes(k) = 100*estables/N;

    end

end

function formatoOscuro(fig)

    set(fig,'Color','k','InvertHardcopy','off');

    axs = findall(fig,'Type','axes');

    for ax = axs(:)'

        set(ax, ...
            'Color','k', ...
            'XColor','w', ...
            'YColor','w', ...
            'ZColor','w', ...
            'GridColor',[0.65 0.65 0.65], ...
            'GridAlpha',0.25);

        set([ax.Title,ax.XLabel,ax.YLabel,ax.ZLabel], ...
            'Color','w');

    end

    lg = findall(fig,'Type','legend');

    for l = lg(:)'

        set(l, ...
            'Color','k', ...
            'TextColor','w', ...
            'EdgeColor',[0.65 0.65 0.65]);

    end

end
