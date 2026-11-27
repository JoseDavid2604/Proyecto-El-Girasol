%% Girasol: diseno preliminar de control integral incremental
% Requiere Control System Toolbox. Angulos internos en radianes.
clear; clc; close all;
Tm=0.02; TsMax=2; MpMax=10; A=deg2rad(5); Ai=deg2rad(1);
N=1500; t=(0:0.005:8)'; td=(0:Tm:8)';
s=tf('s'); z=tf('z',Tm);
G={632.5/(s^2+25.33*s+641.1),627.3/(s^2+25.1*s+633.8)};
H=[-0.06485802,-0.01687204];
J=[H(1),-0.0223;-0.0627,H(2)]; % terminos cruzados redondeados
ab=[25.33 641.1;25.1 633.8]; num=[632.5 627.3];
nombres={'Pan','Tilt'}; KI=nan(1,2); Kp=KI; Td=cell(1,2);
for i=1:2
    c=-num(i)*H(i); limite=prod(ab(i,:))/c;
    fprintf('\n=== %s ===\nRouth: 0 < KI < %.8f\n',nombres{i},limite);
    L0=-H(i)*G{i}/s; Gd=c2d(G{i},Tm,'zoh');
    % Barrido logaritmico: incluye ganancias bajas y altas.
    ks=logspace(log10(limite*1e-5),log10(limite*.999),N);
    met=nan(N,4); viable=false(N,1);
    for j=1:N
        k=ks(j); T=feedback(k*L0,1);
        D=feedback((-k*Tm/(z-1))*Gd*H(i),1);
        if ~isstable(T)||~isstable(D), continue; end
        mc=stepinfo(T,'SettlingTimeThreshold',.02);
        md=stepinfo(D,'SettlingTimeThreshold',.02);
        met(j,:)=[mc.SettlingTime mc.Overshoot md.SettlingTime md.Overshoot];
        viable(j)=all(isfinite(met(j,:))) && max(met(j,[1 3]))<=TsMax && max(met(j,[2 4]))<=MpMax;
    end
    ids=find(viable);
    if isempty(ids)
        warning('No se encontro ganancia que cumpla todas las especificaciones para %s.',nombres{i});
        continue;
    end
    % Menor peor tiempo de asentamiento continuo/discreto; desempate: menor KI.
    [~,q]=min(max(met(ids,[1 3]),[],2)); j=ids(q);
    KI(i)=ks(j); Kp(i)=KI(i)*Tm;
    T=feedback(KI(i)*L0,1); Td{i}=feedback((-Kp(i)/(z-1))*Gd*H(i),1);
    fprintf('KI = %.8f rad/(error*s)\nKp = %.8f rad/error\n',KI(i),Kp(i));
    fprintf('Kp en grados/error = %.8f\n',rad2deg(Kp(i)));
    fprintf('Ts continuo = %.5f s, Mp = %.4f %%\n',met(j,1:2));
    fprintf('Ts discreto = %.5f s, Mp = %.4f %%\n',met(j,3:4));
    fprintf('Polos continuos:\n'); disp(pole(T));
    fprintf('Polos discretos:\n'); disp(pole(Td{i}));
    fprintf('Error estacionario ideal ante 5 grados: %.8g grados\n',5*(1-dcgain(Td{i})));
    %% Lugar geometrico de las raices

figure('Name',['Lugar de raices - ' nombres{i}]);

rlocus(L0);
hold on;

% Polos del sistema en lazo cerrado.
p = pole(T);

hPolos = plot(real(p),imag(p),'ro', ...
    'MarkerSize',9,'LineWidth',2);

grid on;
title(['Lugar de raices - ' nombres{i}]);

% Referencias para la leyenda sin modificar la grafica.
hRaices = plot(NaN,NaN,'b-','LineWidth',1.5);
hIniciales = plot(NaN,NaN,'bx','MarkerSize',8);

% Leyenda de los elementos de la grafica.
lg = legend([hRaices,hIniciales,hPolos], ...
    'Lugar de las raices', ...
    'Polos de lazo abierto', ...
    'Polos de lazo cerrado', ...
    'Location','best');

% Formato de la leyenda.
set(lg, ...
    'Color','k', ...
    'TextColor','w', ...
    'EdgeColor',[0.65 0.65 0.65]);

hold off;
    figure('Name',['Escalon - ' nombres{i}]);
    yc=step(A*T,t); yd=step(A*Td{i},td);
    plot(t,rad2deg(yc),'LineWidth',1.5); hold on; stairs(td,rad2deg(yd));
    yline(rad2deg(A),'--'); yline(rad2deg(A)*1.02,':'); yline(rad2deg(A)*.98,':');
    grid on; xlabel('Tiempo (s)'); ylabel('Angulo (grados)'); legend('Continuo','Discreto','Referencia','Location','best');
    title(['Respuesta al escalon - ' nombres{i}]);
    figure('Name',['Impulso - ' nombres{i}]);
    plot(t,rad2deg(impulse(Ai*T,t)),'LineWidth',1.5); grid on;
    xlabel('Tiempo (s)'); ylabel('Angulo (grados)'); title(['Impulso continuo de referencia - ' nombres{i}]);
end
if any(~isfinite(KI)), error('Diseno individual incompleto; revise especificaciones.'); end
fprintf('\n=== Resumen de ganancias individuales ===\n');
disp(table(nombres',KI',Kp',rad2deg(Kp'),'VariableNames',{'Eje','KI','Kp_rad','Kp_deg'}));
%% Modelo acoplado: estados [estados de plantas; referencias de motores]
% No se usa minreal: interesa estabilidad interna, incluso modos ocultos.
P=ss(blkdiag(G{1},G{2})); [Ap,Bp,Cp,Dp]=ssdata(P);
assert(norm(Dp)==0,'Se supone planta estrictamente propia.');
n=size(Ap,1); Q=diag(KI); R=diag(Kp);
% u_dot = -Q*J*(r-y); y=Cp*x
Ac=[Ap Bp; Q*J*Cp zeros(2)]; Bc=[zeros(n,2);-Q*J]; Cc=[Cp zeros(2)];
Pc=c2d(P,Tm,'zoh'); [Ad,Bd,Cd,Dd]=ssdata(Pc);
% u[k+1]=u[k]-R*J*(r[k]-y[k]); planta usa u[k].
Acld=[Ad Bd; R*J*Cd eye(2)]; Bcld=[zeros(n,2);-R*J]; Ccld=[Cd zeros(2)];
M=ss(Ac,Bc,Cc,zeros(2)); Md=ss(Acld,Bcld,Ccld,zeros(2),Tm);
fprintf('\n=== Evaluacion acoplada ===\n');
fprintf('det(J) = %.9g; cond2(J) = %.5f\n',det(J),cond(J));
fprintf('Polos internos continuos:\n'); disp(eig(Ac));
fprintf('Polos internos discretos:\n'); disp(eig(Acld));
fprintf('Max Re(p) = %.8g; max |z| = %.8g\n',max(real(eig(Ac))),max(abs(eig(Acld))));
if all(real(eig(Ac))<0)&&all(abs(eig(Acld))<1)
    fprintf('Modelo acoplado estable para las ganancias seleccionadas.\n');
else
    warning('Modelo acoplado INESTABLE. No implementar estas ganancias como solucion final.');
end
% Excitar un eje a la vez. Horizonte corto para visualizar divergencia.
tm=(0:Tm:2)'; figure('Name','Respuesta acoplada discreta');
for i=1:2
    r=zeros(numel(tm),2); r(:,i)=A; y=lsim(Md,r,tm);
    subplot(2,1,i); plot(tm,rad2deg(y),'LineWidth',1.4); hold on;
    yline(10,':'); yline(-10,':'); grid on; ylabel('Angulo (grados)'); xlabel('Tiempo (s)');
    title(['Escalon de referencia en ' nombres{i}]); legend('Pan','Tilt','Location','best');
end
fprintf('Las respuestas fuera de la zona local son solo predicciones del modelo lineal.\n');


%% Lugar geometrico de las raices del sistema acoplado

% Factor comun de las ganancias integrales.
alpha = linspace(0,5,5001);

% Almacenamiento de los polos del sistema.
numPolos = size(Ac,1);
polosAcoplados = zeros(numPolos,length(alpha));

% Calculo de los polos para cada factor de ganancia.
for j = 1:length(alpha)

    Acl = [Ap, Bp;
           alpha(j)*Q*J*Cp, zeros(2)];

    polosAcoplados(:,j) = eig(Acl);

end

% Polos iniciales: alpha = 0.
polosIniciales = polosAcoplados(:,1);

% Polos correspondientes a las ganancias seleccionadas: alpha = 1.
polosDiseno = eig(Ac);

% Identificacion de los polos inestables.
polosInestables = polosDiseno(real(polosDiseno)>0);

%% Grafica del lugar de las raices acoplado

figAcoplado = figure( ...
    'Name','Lugar de raices - Sistema acoplado', ...
    'Color','k');

ax = axes('Parent',figAcoplado);
hold on;
grid on;
box on;

% Lugar geometrico de las raices.
h1 = plot(real(polosAcoplados(:)), ...
          imag(polosAcoplados(:)), ...
          '.', ...
          'Color',[0.20 0.65 1.00], ...
          'MarkerSize',4);

% Polos iniciales.
h2 = plot(real(polosIniciales), ...
          imag(polosIniciales), ...
          'wx', ...
          'MarkerSize',10, ...
          'LineWidth',2);

% Polos correspondientes al diseno original.
h3 = plot(real(polosDiseno), ...
          imag(polosDiseno), ...
          'o', ...
          'Color',[0.20 1.00 0.40], ...
          'MarkerSize',9, ...
          'LineWidth',2);

% Polos inestables del diseno original.
h4 = plot(real(polosInestables), ...
          imag(polosInestables), ...
          'ro', ...
          'MarkerSize',12, ...
          'LineWidth',2.5);

% Frontera de estabilidad.
h5 = xline(0,'--w','LineWidth',1.5);

% Etiquetas de los polos inestables.
for j = 1:length(polosInestables)

    text(real(polosInestables(j))+0.5, ...
         imag(polosInestables(j))+1, ...
         sprintf('s = %.4f %+.4fj', ...
         real(polosInestables(j)), ...
         imag(polosInestables(j))), ...
         'Color','r', ...
         'FontSize',11, ...
         'FontWeight','bold');

end

xlabel('Parte real');
ylabel('Parte imaginaria');

title('Lugar geometrico de las raices del sistema acoplado');

lg = legend([h1 h2 h3 h4 h5], ...
    'Lugar de las raices', ...
    'Polos iniciales', ...
    'Polos del diseno (\alpha = 1)', ...
    'Polos inestables del diseno', ...
    'Frontera de estabilidad', ...
    'Location','best');

% Configuracion visual.
set(figAcoplado, ...
    'Color','k', ...
    'InvertHardcopy','off');

set(ax, ...
    'Color','k', ...
    'XColor','w', ...
    'YColor','w', ...
    'GridColor',[0.65 0.65 0.65], ...
    'GridAlpha',0.25, ...
    'FontSize',11);

set([ax.Title ax.XLabel ax.YLabel],'Color','w');

set(lg, ...
    'Color','k', ...
    'TextColor','w', ...
    'EdgeColor',[0.65 0.65 0.65]);

hold off;

%% Resultados adicionales de estabilidad

fprintf('\n=== Lugar de raices del sistema acoplado ===\n');

fprintf('Polos iniciales (alpha = 0):\n');
disp(polosIniciales);

fprintf('Polos del diseno (alpha = 1):\n');
disp(polosDiseno);

fprintf('Polos inestables del diseno:\n');
disp(polosInestables);

% Evaluacion de estabilidad durante el barrido.
maxParteReal = max(real(polosAcoplados),[],1);

estable = maxParteReal < 0;

if any(estable)

    fprintf('Se encontraron factores de ganancia estables.\n');

else

    fprintf(['No se encontraron factores de ganancia ', ...
             'estables en el intervalo evaluado.\n']);

end

