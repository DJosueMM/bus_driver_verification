# Test Plan para la verificación del Bus Driver


## 1. Descripción del DUT

Para el diseño del ambiente de verificación, se toma en cuenta el funcionamiento del dispositivo, que en este caso es un manejador de bus de datos que permite la transmisión de información entre diferentes periféricos. Estos periféricos serán emulados mediante FIFOs, y el objetivo específico es verificar el correcto funcionamiento del bus. Las FIFOs serán descritas a nivel de software y los datos transmitidos serán definidos como específicos o aleatorios, dependiendo del tipo de prueba que se ejecute.

### Módulos Principales
1. **Bus driver**: DUT, se encarga de administrar el acceso de distintos periféricos al bus de datos.
2. **Dispositivos FIFO**: estos almacenan datos temporalmente, en este caso es la interfaz de conexión entre el DUT y el ambiente de verificación.

### Señales 

- pndng: si la fifo está vacía la señal de pndng es 0.
- push: señal de control que indica que se debe realizar una operación de push (es decir, ingresar datos a la FIFO). 
- pop: señal de control que indica que se debe realizar una operación de pop (es decir, sacar datos de la FIFO). 

    ![alt text](doc/img/data_protocol.png)
- Dpush: datos a ser almacenados en la FIFO.
- Dpop: datos a ser extraídos de la FIFO. 
- broadcast: Representa una señal con un valor por defecto de 8 bits (todo 1s: 11111111). Esto significa que el módulo tiene una funcionalidad de transmisión de mensajes a múltiples destinatarios simultáneamente (broadcast).

## 2. Escenarios
### 2.1 Casos generales

Como casos generales o de uso común se tienen las pruebas con cada transacción:

- **Enviar datos**: cada periférico debe poder enviar un paquete a otro periférico a través del bus de datos.

- **Recepción de datos enviados**: si se envía un paquete a cierto periférico, este debe recibirlo dado su ID, el payload debe coincidir con el enviado.

- **Funcionamiento del reset**: ....

- **Broadcast**: si un periférico realiza broadcast con el identificador 8´d1, todos los periféricos deben recibir el payload enviado.


### 2.2 Casos de esquina

- **Overflow**: Consiste en un caso donde una FIFO se le hará push, pero ya está llena.

- **Underflow**: Consiste en un caso donde una FIFO está vacía y se quiere hacer una lectura.

- **Varios envían a la vez**: Este caso probará el comportamiento del bus al enviar datos por varios periférico a la vez
- **Todos envían a la vez**: Este caso probará el comportamiento del bus al enviar datos por cada periférico a la vez
- **Se envía un paquete con un id ilegal**: Con determinado número de periféricos, se utilizará un número o ID que no existe.
- **Todos hacen broadcast simultaneamente**: Similar al caso de enviar todos a la vez, solo que con broadcast.
- **Varios hacen broadcast**: Busca probar mportamiento del bus al recibir varios broadcast 
- **Se envía a sí mismo**: Este caso consiste en sacar un dato de un periférico para volver a enviarlo al mismo.
- **Uno solo envía una ráfaga de paquetes**: Busca probar el comportamiento del dispositivo al enviar datos de forms exhaustiva.
- **Todos le envían al mismo simultaneamente**: Medirá la capacidad de los periféricos al recibir datos exhaustivamente.
- **Reset cuando no se ha terminado una transacción**: El comportamiento esperado es que vacíe el dispositivo, dejándolo sin datos. Por lo que anularía las transacciones hasta dicho momento.

## 3. Aleatorización

Además de esto, como parte de las pruebas, se aleatorizarán distintas variables del test:

- **Número de transacciones**: se pobrarán cantidades distintas de transacciones.

- **Largo de paquetes**: se aleatorizará el largo de los paquetes entre 16, 32 y 64 bits.

- **Tiempo de espera entre eventos**: Para las distintas transacciones se aleatorizarán los tiempos de retardo.

- **Cantidad de periféricos**: El dispositivo al ser capaz de tener diferente cantidad de periféricos, podría tener comportamientos distintos.
- **Dimensión de profundidad en la FIFO**: Los periféricos pueden tener tamaños distintos, lo ideal sería un comportamiento sin cambios.
- **Tipos de transacciones**: Las transacciones pueden ir en distinto órden y cantidad, cada una realiza distintas acciones.
- **Payload**: Los datos oara periféricos serán aleatorizables.
- **Identificadores válidos**: Cada periférico posee un ID, estos estan asociados al numero de periféricos.
- **Identificadores no válidos**: Como prueba se tendrán identificadores para periféricos que no existen.

## 4. Diseño del ambiente
El ambiente consiste de distintos transactores, en este caso se conforma de un generador Test, un agente, un driver/monitor, un checker y un scoreboard. Además de esto el driver va a tener una interfaz para comunicarse con el DUT.

<a name="Ambiente_Bloques"></a>
![Ambiente_Bloques](doc/img/ambiente_bloques.png)


### Generador de Tests
El generador es el bloque que crea los estímulos o entradas que se enviarán al DUT. Los estímulos pueden ser aleatorios o predefinidos, dependiendo del tipo de test. Este componente genera transacciones, que son estructuras de datos que representan las entradas para el DUT.

### Agente
El agente es un transactor que recibe las instrucciones de alto nivel del test y las traduce a un nivel de abstracción menor para enviarlas a los drivers.

### Driver-Monitor
=======
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

