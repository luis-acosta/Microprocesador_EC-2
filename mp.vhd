LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY mp IS PORT(
  clock, reset, enter : IN  STD_LOGIC;
  input                : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
  output               : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
END mp;

ARCHITECTURE Structural OF mp IS
  -- Declaración de componentes
  COMPONENT cu PORT(
    clock, reset, enter   : IN  STD_LOGIC;
    IR                      : IN  STD_LOGIC_VECTOR(7 DOWNTO 5);
    Aeq0, Apos              : IN  STD_LOGIC;
    IRload, JMPmux, PCload : OUT STD_LOGIC;
    Meminst, MemWr         : OUT STD_LOGIC;
    Asel                    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    Aload, Sub              : OUT STD_LOGIC;
    Halt                    : OUT STD_LOGIC
  );
  END COMPONENT;

  COMPONENT dp PORT(
    clock, reset          : IN  STD_LOGIC;
    input                 : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    IRload, JMPmux, PCload: IN  STD_LOGIC;
    Meminst, MemWr        : IN  STD_LOGIC;
    Asel                   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    Aload, Sub             : IN  STD_LOGIC;
    IR                     : OUT STD_LOGIC_VECTOR(7 DOWNTO 5);
    Aeq0, Apos             : OUT STD_LOGIC;
    output                 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
  END COMPONENT;

  -- Señales internas de interconexión (bus de control + bus de estado)
  -- Estas señales conectan las salidas de un componente con las entradas del otro
  SIGNAL IRsig    : STD_LOGIC_VECTOR(7 DOWNTO 5);
  SIGNAL Aeq0sig, Apos_sig        : STD_LOGIC;
  SIGNAL IRload_s, JMPmux_s, PCload_s : STD_LOGIC;
  SIGNAL Meminst_s, MemWr_s       : STD_LOGIC;
  SIGNAL Asel_s   : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL Aload_s, Sub_s, Halt_s   : STD_LOGIC;
BEGIN
  -- Instancia de la Unidad de Control (CU)
  -- Recibe: reloj, reset, enter, opcode (IRsig), banderas (Aeq0, Apos)
  -- Genera: 8 señales de control para gobernar el datapath
  U1: cu PORT MAP(
    clock, reset, enter,
    IRsig, Aeq0sig, Apos_sig,
    IRload_s, JMPmux_s, PCload_s,
    Meminst_s, MemWr_s,
    Asel_s, Aload_s, Sub_s, Halt_s
  );

  -- Instancia de la Ruta de Datos (Datapath)
  -- Recibe: reloj, reset, entrada de datos, 8 señales de control
  -- Genera: opcode (IRsig), banderas (Aeq0, Apos), salida de datos
  U2: dp PORT MAP(
    clock, reset, input,
    IRload_s, JMPmux_s, PCload_s,
    Meminst_s, MemWr_s,
    Asel_s, Aload_s, Sub_s,
    IRsig, Aeq0sig, Apos_sig,
    output
  );
END Structural;