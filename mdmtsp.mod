
# ---------- SETS ----------
set NODES;                      # Todos los nodos (depósitos + clientes)
set DEPOTS within NODES;        # Subconjunto de depósitos
set CLIENTS within NODES;       # Subconjunto de clientes
set VEHICLES;                   # Vehículos disponibles

# ---------- PARAMETERS ----------
param coord_x{NODES};           # Coordenada X del nodo
param coord_y{NODES};           # Coordenada Y del nodo

# Distancia euclidiana entre nodos
param c{i in NODES, j in NODES} :=
    sqrt((coord_x[i] - coord_x[j])^2 + (coord_y[i] - coord_y[j])^2);

param demand{CLIENTS} >= 0;     # Demanda de cada cliente
param Q_CAPACITY > 0;           # Capacidad máxima por vehículo

# ---------- VARIABLES ----------
var x{i in NODES, j in NODES, k in VEHICLES} binary;  # 1 si el vehículo k va de i a j
var u{i in CLIENTS, k in VEHICLES} >= 0;              # carga acumulada del vehículo k al salir de i

# ---------- OBJECTIVE ----------
minimize TotalCost:
    sum{i in NODES, j in NODES, k in VEHICLES} c[i,j] * x[i,j,k];

# ---------- CONSTRAINTS ----------

# Flujo de entrada = salida para clientes
subject to FlowBalance{i in CLIENTS, k in VEHICLES}:
    sum{j in NODES} x[j,i,k] = sum{j in NODES} x[i,j,k];

# Cada vehículo puede salir de un solo depósito
subject to StartFromDepot{d in DEPOTS, k in VEHICLES}:
    sum{j in CLIENTS} x[d,j,k] <= 1;

# Cada vehículo puede regresar a un solo depósito
subject to ReturnToDepot{d in DEPOTS, k in VEHICLES}:
    sum{i in CLIENTS} x[i,d,k] <= 1;

# Cada cliente es visitado exactamente una vez
subject to UniqueVisit{j in CLIENTS}:
    sum{i in NODES, k in VEHICLES} x[i,j,k] = 1;

# Eliminación de subciclos (MTZ)
subject to SubtourElimination{i in CLIENTS, j in CLIENTS, k in VEHICLES: i != j}:
    u[i,k] - u[j,k] + demand[j] * x[i,j,k] <= Q_CAPACITY - demand[j];

# Límite inferior de carga: debe ser al menos la demanda si el nodo fue visitado
subject to LoadLowerBound{i in CLIENTS, k in VEHICLES}:
    u[i,k] >= demand[i] * sum{j in NODES} x[j,i,k];

# Límite superior: no superar capacidad
subject to LoadUpperBound{i in CLIENTS, k in VEHICLES}:
    u[i,k] <= Q_CAPACITY;

# No loops: el modelo no permite viajes de un nodo a sí mismo
subject to NoSelfLoops{i in NODES, k in VEHICLES}:
    x[i,i,k] = 0;

# Cada vehículo arranca desde algún depósito
subject to OneStartPerVehicle{k in VEHICLES}:
    sum{d in DEPOTS, j in CLIENTS} x[d,j,k] <= 1;

# Cada vehículo debe terminar en algún depósito
subject to OneEndPerVehicle{k in VEHICLES}:
    sum{i in CLIENTS, d in DEPOTS} x[i,d,k] <= 1;
