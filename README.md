# bus_driver_verification
Proyecto 1 del curso Verificación Funcional de Circuitos Integrados


# Test Plan para el Bus Driver

## 1. Descripción-Estudio del DUT

El dispositivo está compuesto por un bus de datos que conecta múltiples dispositivos FIFO, cada FIFO interactúa con el bus para enviar y recibir datos.

### Módulos Principales
1. **Bus de datos**: Maneja la comunicación entre los FIFOs.
2. **Controlador de FIFOs**: Regula el acceso de los FIFOs al bus.
3. **Dispositivos FIFO**: Almacenan datos temporalmente.

## 2. Plan de pruebas
### 2.1 Casos generales

### 2.2 Casos de esquina

- **Combinaciones de Acceso**:
    - Un FIFO leyendo mientras otro escribe.
    - Todos los FIFOs accediendo al bus simultáneamente.
- **Errores de Transmisión**: Simular fallos en la comunicación (paquetes corruptos, ACK/NACK incorrectos).
- **Casos de Sobrecarga**: Comportamiento del sistema bajo alta demanda de datos en todos los FIFOs.


## 3. Diseño del ambiente
El ambiente consiste de distintos transactores, en este caso se conforma de un generador Test, un agente, un driver/monitor, un checker y un scoreboard. Además de esto el driver va a tener una interfaz para comunicarse con el DUT.
### Generador de Test
El generador es el bloque que crea los estímulos o entradas que se enviarán al DUT. Los estímulos pueden ser aleatorios o predefinidos, dependiendo del tipo de test. Este componente genera transacciones, que son estructuras de datos que representan las entradas para el DUT.

### Agente
El agente es un conjunto de componentes de verificación que encapsula el driver, el monitor y otros elementos como el *séquencer*, que genera secuencias de estímulos.

### Driver
El driver convierte las transacciones generadas por el generador de test en señales específicas que el DUT puede entender. Estas señales son enviadas al DUT a través de una interfaz, interactuándo directamente con la lógica de entrada del DUT.
A su vez, el monitor observa las señales provenientes del DUT, sin modificarlas. Su función es recopilar datos para su análisis posterior. Los datos recogidos pueden ser usados para verificar el correcto funcionamiento del DUT.

### Checker
El checker compara las salidas del DUT con los valores esperados, para verificar que el DUT se comporta de acuerdo con las especificaciones. 

### Scoreboard
El scoreboard es un componente de verificación que compara las transacciones esperadas (entradas del generador) con las reales (salidas del DUT). Su función es llevar un registro de los errores y fallos en las salidas del DUT.

### Interfaz del Driver con el DUT
La interfaz es el medio a través del cual el driver interactúa con el DUT. Mediante esta interfaz, el driver envía los estímulos convertidos al DUT, y el DUT devuelve las respuestas correspondientes. La interfaz maneja las señales de bajo nivel necesarias para la comunicación adecuada entre ambos.

![Mapa conceptual](https://github.com/user-attachments/assets/41a0b979-11af-45a9-bed0-037a9f917845)


## 4. Implementación del ambiente

