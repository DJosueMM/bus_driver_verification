class monitor #(parameter WIDTH = 16, parameter DRVS = 8);  // Definición de la clase monitor con parámetros WIDTH y DRVS

    // Mailbox para enviar las transacciones reconstruidas del monitor al checker
    mbx_monitor_checker mnt_checker_mbx;

    // Definición de la interfaz virtual que conecta el monitor con el DUT
    virtual dut_compl_if # (.width(WIDTH), .drvs(DRVS), .bits(1)) vif_monitor_fifo_dut;

    // Variable para almacenar la transacción que recibe el monitor
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaction_receive;

    // Identificador único para cada monitor
    int mnt_id;

    // Variable auxiliar para reconstrucción de la transacción
    logic [WIDTH - 1 : 0] aux_reconstr;

    // Constructor que inicializa el identificador del monitor
    function new(int monitor_id = 0);
        this.mnt_id = monitor_id;  // Asigna el monitor_id pasado como argumento
    endfunction

    // Método principal que ejecuta la lógica del monitor
    task run();
        
        // Imprime un mensaje al inicio de la ejecución indicando el ID del monitor
        $display("[%g] El monitor [%g] fue inicializado", $time, mnt_id);
        
        // Espera el flanco positivo del reloj en la interfaz virtual
        @(posedge vif_monitor_fifo_dut.clk);

        // Bucle infinito para que el monitor esté continuamente atento a las transacciones
        forever begin

            // Inicializar los flags de la interfaz del DUT para este monitor
            vif_monitor_fifo_dut.push   [0][mnt_id] = '0;
            vif_monitor_fifo_dut.D_push [0][mnt_id] = '0;
            
            $display("[%g] El Monitor [%g] espera por una transacción", $time, mnt_id);  // Mensaje indicando que está esperando

            // Esperar el siguiente flanco positivo del reloj
            @ (posedge vif_monitor_fifo_dut.clk);
            
            // Bucle para esperar hasta que el DUT active el flag de 'push' en el monitor actual
            while (vif_monitor_fifo_dut.push[0][mnt_id] == 0) begin
                @(posedge vif_monitor_fifo_dut.clk);  // Espera en cada ciclo de reloj
            end
            
            // Cuando el DUT activa 'push', procesar la transacción
            if (vif_monitor_fifo_dut.push[0][mnt_id] == 1) begin
                                        
                $display("[%g] El Monitor [%g] obtuvo un dato del DUT", $time, mnt_id);  // Indicar que se ha recibido una transacción
                
                transaction_receive = new();  // Crear una nueva instancia de la transacción recibida
                
                // Reconstruir la transacción desde la interfaz del DUT
                transaction_receive.pkg_id           = vif_monitor_fifo_dut.D_push[0][mnt_id][WIDTH - 1 : WIDTH - 8];  // Extraer el ID del paquete
                transaction_receive.pkg_payload      = vif_monitor_fifo_dut.D_push[0][mnt_id][WIDTH - 9 : 0];  // Extraer el payload del paquete
                transaction_receive.receive_time     = $time;  // Registrar el tiempo de recepción
                transaction_receive.receiver_monitor = mnt_id;  // Guardar el ID del monitor que recibe la transacción

                // Determinar si la transacción es un broadcast o un envío normal basado en el pkg_id
                if (transaction_receive.pkg_id == 8'b11111111) begin
                    transaction_receive.tipo_transaccion = broadcast;  // Si el ID es 0xFF, es un broadcast
                end
                else begin
                    transaction_receive.tipo_transaccion = send;  // De lo contrario, es un envío normal
                end
                
                // Inicializar los campos de delay en la transacción
                transaction_receive.delay = 0;
                transaction_receive.max_delay = 0;

                // Imprimir los detalles de la transacción reconstruida
                transaction_receive.print("///////////////////Monitor: Transacción reconstruida en el monitor");

                // Enviar la transacción reconstruida al Checker a través del mailbox
                mnt_checker_mbx.put(transaction_receive);

                // Imprimir detalles adicionales indicando que se ha enviado la transacción al Checker
                transaction_receive.print("Monitor: Transacción enviada al Checker");
                $display("[%g] El Monitor [%g] envió la transacción al Checker", $time, mnt_id);
            end
        end
    endtask
endclass
