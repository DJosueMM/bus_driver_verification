# Test Plan para la verificación del Bus Driver


## Descripción del DUT

Para el diseño del ambiente de verificación, se toma en cuenta el funcionamiento del dispositivo, que en este caso es un manejador de bus de datos que permite la transmisión de información entre diferentes periféricos. Estos periféricos serán emulados mediante FIFOs, y el objetivo específico es verificar el correcto funcionamiento del bus. Las FIFOs serán descritas a nivel de software y los datos transmitidos serán definidos como específicos o aleatorios, dependiendo del tipo de prueba que se ejecute.

![ambiente_bloques](https://github.com/user-attachments/assets/0c49660b-e6cf-4130-af64-8dc9298e3a19)

![interfaz_fifo_dut](https://github.com/user-attachments/assets/2e3744aa-0cae-4d08-90a9-85386c5e7aac)
