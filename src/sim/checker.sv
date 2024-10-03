class checker #(parameter WIDTH = 16, parameter DRVS = 8);

    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_drv_received;   // Transacción recibida del driver
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_mnt_received;   // Transacción recibida del monitor
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) auxiliar;                   // Auxiliar para guardar transacciones temporales
    
    mbx_driver_checker  driver_checker_mbx [DRVS - 1 : 0];  // Mailbox del driver al checker
    mbx_monitor_checker mnt_checker_mbx    [DRVS - 1 : 0];  // Mailbox del monitor al checker

    bit [7 : 0]         pkg_id_drv;
    bit [WIDTH - 9 : 0] pkg_payload_drv;
    bit [WIDTH-1:0] campo_drv;
    bit [WIDTH-1:0] campo_mnt;
    bit match_found;
    bit success_get_driver;
    bit success_get_monitor;

    // Método para verificar transacciones
    task run();
        
        // Bucle infinito para reiniciar el proceso de verificación
        forever begin
            // Iterar sobre todas las transacciones de los drivers
            for (int i = 0; i < DRVS; i++) begin
                this.match_found = 0;  // Reiniciar indicador de coincidencia
                this.success_get_driver = driver_checker_mbx[i].try_get(transaccion_drv_received);  // Intentar recibir la transacción del driver
                
                if (this.success_get_driver) begin
                    campo_drv = transaccion_drv_received.campo;  // Obtener campo de interés del driver
                    
                    // Comparar con todas las transacciones de los monitores
                    for (int j = 0; j < DRVS; j++) begin
                        this.success_get_monitor = mnt_checker_mbx[j].try_get(transaccion_mnt_received);  // Intentar recibir la transacción del monitor
                        
                        if (this.success_get_monitor) begin
                            campo_mnt = transaccion_mnt_received.campo;  // Obtener campo de interés del monitor
                            
                            // Verificar si hay coincidencia
                            if (campo_drv == campo_mnt) begin
                                $display("Coincidencia encontrada: Driver[%0d] con Monitor[%0d]: %0h", i, j, campo_drv);
                                match_found = 1;
                                break;  // Salir del loop interno si se encuentra coincidencia
                            end else begin
                                // Si no coincide, volver a colocar la transacción en el mailbox del monitor
                                mnt_checker_mbx[j].put(transaccion_mnt_received);
                            end
                        end
                    end
                    
                    // Si no se encuentra coincidencia con ningún monitor, regresar la transacción del driver al mailbox
                    if (!match_found) begin
                        $display("No se encontró coincidencia para la transacción del Driver[%0d]: %0h. Transacción regresada al mailbox.", i, campo_drv);
                        driver_checker_mbx[i].put(transaccion_drv_received);  // Regresar transacción al mailbox del driver
                    end
                end else begin
                    $display("No hay transacciones disponibles aún para el Driver[%0d]", i);
                end
            end
            
            // Controlar la repetición con un pequeño delay
            #10;  // Ejemplo de delay de 10 unidades de tiempo
        end
    endtask
endclass
