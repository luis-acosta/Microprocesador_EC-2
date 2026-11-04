-- ==========================================================
-- Sumador/Restador Genérico de N bits
-- Estilo: Dataflow (combinatorio — asignaciones concurrentes)
-- S='0' → F = A + B  (suma)
-- S='1' → F = A - B  (resta)
-- Instancia en EC-2:
--   U8: addsub (n=8) — opera A ± RAM[dir]
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY addsub IS
  GENERIC(n : INTEGER := 8);        -- Tamaño por defecto: 8 bits
  PORT(
    S               : IN  STD_LOGIC;                         -- 0=Suma, 1=Resta
    A, B           : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);   -- Operandos
    F               : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);   -- Resultado
    unsigned_overflow : OUT STD_LOGIC;                       -- Desbordamiento sin signo (carry out)
    signed_overflow   : OUT STD_LOGIC                        -- Desbordamiento con signo
  );
END addsub;

ARCHITECTURE Dataflow OF addsub IS
  -- Señales internas extendidas a n+1 bits para detectar carry
  SIGNAL A_ext, B_ext, result_ext : UNSIGNED(n DOWNTO 0);
  SIGNAL result                   : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
BEGIN
  -- Extender operandos a n+1 bits (bit extra para carry)
  A_ext <= '0' & unsigned(A);
  B_ext <= '0' & unsigned(B);

  -- Operación: suma o resta según S
  result_ext <= (A_ext - B_ext) WHEN S = '1' ELSE
                 (A_ext + B_ext);

  -- Resultado: los n bits inferiores
  result <= std_logic_vector(result_ext(n-1 DOWNTO 0));
  F <= result;

  -- Desbordamiento sin signo: carry del bit n
  -- En suma: carry=1 indica resultado > 2^n-1
  -- En resta: borrow (carry=1 si A < B en unsigned)
  unsigned_overflow <= result_ext(n);

  -- Desbordamiento con signo (complemento a 2):
  -- Ocurre cuando los signos de los operandos son iguales
  -- pero el signo del resultado difiere.
  -- Suma: overflow si A(msb)=B(msb) ≠ F(msb)
  -- Resta: overflow si A(msb)≠B(msb) y A(msb)≠F(msb)
  signed_overflow <=
    (NOT A(n-1) AND NOT B(n-1) AND result(n-1)) OR        -- +A + +B = -F
    (A(n-1) AND B(n-1) AND NOT result(n-1)) WHEN S = '0'  -- -A + -B = +F
    ELSE
    (NOT A(n-1) AND B(n-1) AND result(n-1)) OR        -- +A - -B = -F
    (A(n-1) AND NOT B(n-1) AND NOT result(n-1));       -- -A - +B = +F
END Dataflow;