-- ==========================================================
-- Registro Genérico de N bits con carga paralela
-- Estilo: Behavioral (secuencial — usa PROCESS)
-- Clear: reset asíncrono activo en alto
-- Load:  habilitación de carga síncrona
-- Instancias en EC-2:
--   U0: IR  (size=8)  — Registro de Instrucción
--   U2: PC  (size=5)  — Contador de Programa
--   U7: A   (size=8)  — Acumulador
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY reg IS
  GENERIC(size : INTEGER := 8);    -- Tamaño por defecto: 8 bits
  PORT(
    Clock : IN  STD_LOGIC;       -- Reloj del sistema
    Clear : IN  STD_LOGIC;       -- Reset asíncrono (activo alto)
    Load  : IN  STD_LOGIC;       -- Habilitación de carga
    D     : IN  STD_LOGIC_VECTOR(size-1 DOWNTO 0);  -- Entrada de datos
    Q     : OUT STD_LOGIC_VECTOR(size-1 DOWNTO 0)   -- Salida de datos
  );
END reg;

ARCHITECTURE Behavioral OF reg IS
BEGIN
  -- Proceso secuencial: sensible al reloj y al clear
  PROCESS(Clock, Clear)
  BEGIN
    IF Clear = '1' THEN
      -- Reset asíncrono: pone todas las salidas a '0'
      Q <= (OTHERS => '0');
    ELSIF Clock'EVENT AND Clock = '1' THEN
      -- Flanco ascendente: carga D solo si Load='1'
      IF Load = '1' THEN
        Q <= D;
      END IF;
      -- Si Load='0', Q mantiene su valor anterior (implícito)
    END IF;
  END PROCESS;
END Behavioral;