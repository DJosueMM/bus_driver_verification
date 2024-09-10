# bus_driver_verification
Proyecto 1 del curso Verificación Funcional de Circuitos Integrados


# Test Plan para el Bus Driver

## 1. Descripción-Estudio del DUT

El dispositivo está compuesto por un bus de datos que conecta múltiples dispositivos FIFO, cada FIFO interactúa con el bus para enviar y recibir datos.

### Módulos Principales
1. **Bus de datos**: Maneja la comunicación entre los FIFOs.
2. **Controlador de FIFOs**: Regula el acceso de los FIFOs al bus.
3. **Dispositivos FIFO**: Estos almacenan datos temporalmente, en este caso el dispositivo principal es capaz de trabajar con algún número de dispositivos, es decir con distintos números de FIFO.

### Funciones

Pndng: Si la fifo está vacía la señal de pndng es 0.

Push: Señal de salida que indica que se debe realizar una operación de push (es decir, enviar datos). La señal probablemente se activa cuando hay datos listos para ser enviados desde un driver.

Pop: Señal de salida que indica que se debe realizar una operación de pop (es decir, recibir datos). La señal se activa cuando hay datos disponibles para ser leídos o recibidos por un driver.

Broadcast: Representa una señal con un valor por defecto de 8 bits (todo 1s: 11111111). Esto significa que el módulo tiene una funcionalidad de transmisión de mensajes a múltiples destinatarios simultáneamente (broadcast).

## 2. Plan de pruebas
### 2.1 Casos generales
Como casos generales o de uso común se tienen las pruebas con cada transacción:

- **Lectura**: Se harán lecturas aleatorizadas para las FIFO con retardos distintos.

- **Escritura**: Se harán escrituras aleatorizadas para las FIFO con retardos distintos.

- **Reset**: Se harán resets aleatorizados.

- **Combinaciones de Acceso**:
    - Una FIFO leyendo mientras otra escribe.
    - Todos los FIFOs accediendo al bus simultáneamente.

Además de esto, como parte de las pruebas, se aleatorizarán distintas variables del test:

- **Número de transacciones**: Se pobrarán cantidades distintas de transacciones.

- **Largo de paquetes**: Se aleatorizará el largo de los paquetes entre 16, 32 y 64 bits.

- **Tiempo de espera entre eventos**: Para las distintas transacciones se aleatorizarán los tiempos de retardo.


### 2.2 Casos de esquina

- **Combinaciones de Acceso**:
    - Un FIFO leyendo mientras otro escribe.
    - Todos los FIFOs accediendo al bus simultáneamente.
- **Overflow**: Consiste en un caso donde una FIFO se le hará push, pero ya está llena.

- **Underflow**: Consiste en un caso donde una FIFO está vacía y se quiere hacer una lectura.

- **Escritura/Lectura**: Esta prueba consiste en escribir y leer algún dato en un mismo ciclo de reloj.

- **Reset con datos aleatorios**:
    • Cuándo la fifo está llena.
    • Cuando está vacía.
    • Cuando está por la mitad.

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

Relacionado al diagrama anterior, los paquetes de transacción son los siguientes:

**pck1**:

**pck2**:

**pck3**:

**pck4**:

**pck5**:
