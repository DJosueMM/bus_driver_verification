# bus_driver_verification
Proyecto 1 del curso de Verificación Funcional de Circuitos Integrados


# Test Plan para el Bus Driver

## 1. Descripción del Diseño
### 1.1 Descripción del Sistema
El dispositivo está compuesto por un bus de datos que conecta múltiples dispositivos FIFO, cada FIFO interactúa con el bus para enviar y recibir datos.

### 1.2 Módulos Principales
1. **Bus de datos**: Maneja la comunicación entre los FIFOs.
2. **Controlador de FIFOs**: Regula el acceso de los FIFOs al bus.
3. **Dispositivos FIFO**: Almacenan datos temporalmente.

## 2. Niveles de Verificación
Se utilizará un enfoque jerárquico para la verificación:

- **Nivel de Componente**: Verificación de cada módulo (bus de datos, FIFOs, controlador).
- **Nivel de Subsistema**: Verificación de la interacción entre módulos (FIFO con el bus).
- **Nivel de Sistema**: Verificación completa del sistema con todos los módulos interconectados.

## 3. Funciones a Verificar
### 3.1 Funcionalidad del Bus de Datos
- Verificar el ancho de banda, latencia y tiempos de acceso.
- Asegurarse de que el bus maneje correctamente las señales de control (lectura/escritura, selección de FIFO).

### 3.2 Comportamiento de los FIFOs
- Verificar la capacidad de cada FIFO.
- Asegurar el correcto manejo de datos en condiciones de llenado/vacío.

### 3.3 Protocolo de Comunicación
- Verificar los formatos de los paquetes de datos.
- Validar la corrección de las señales de control (ACK/NACK).

## 4. Pruebas Específicas y Métodos
- **Simulaciones**: Uso de simuladores para modelar la interacción de los FIFOs y el bus.
- **Pruebas de Integración**: Pruebas de comunicación entre módulos (FIFO, controlador, bus).
- **Pruebas Funcionales**: Verificación del flujo de datos en condiciones normales y extremas (sobrecarga, fallo en los FIFOs).

## 5. Requisitos de Cobertura
- **Cobertura Completa** de los caminos lógicos de los módulos (FIFO, bus).
- **Cobertura de casos de esquina del Diseño**: Validar el comportamiento en condiciones límite (FIFO lleno/vacío).
- **Pruebas de Integridad de Datos**: Asegurarse de que no haya pérdida de datos o corrupción durante la transmisión.

## 6. Escenarios de Prueba (Matriz)
- **Combinaciones de Acceso**:
    - Un FIFO leyendo mientras otro escribe.
    - Todos los FIFOs accediendo al bus simultáneamente.
- **Errores de Transmisión**: Simular fallos en la comunicación (paquetes corruptos, ACK/NACK incorrectos).
- **Casos de Sobrecarga**: Comportamiento del sistema bajo alta demanda de datos en todos los FIFOs.

## 7. Herramientas Requeridas
- **Simuladores**: Para modelar el comportamiento de los módulos y el bus, en este caso se utilizará VCS.

## 8. Criterios de Finalización
- **Cobertura Completa** de todos los escenarios de prueba.
- **Cumplimiento de los Requisitos de Funcionalidad** definidos para cada módulo.
- **Verificación Exitosa** de la comunicación y manejo de datos en el bus y los FIFOs.

