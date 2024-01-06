# extraído de https://github.com/FedeVerstraeten/sd-2c2019/blob/master/ejemplos/Makefile

# se puede descomentar la linea de abajo para hacer permanente el archivo del testbench
# sino (si se trabaja con distintos testbenchs) usar 'export TESTBENCH=algun_tb' desde
# bash antes de ejecutar make

ifndef TESTBENCH
  TESTBENCH = tp4_tb
endif  

# vhdl files
FILES = src/*/* # todos los archivos .vhd están guardos acá
VHDLEX = .vhd 	# extensión archivos vhdl

# testbench
TESTBENCHPATH = testbench/${TESTBENCH}$(VHDLEX)

#GHDL CONFIG
GHDL_CMD = ghdl
# GHDL_CMD = /C/Users/MarceloFernando/GHDL/bin/ghdl # por si no funca el Path ( WIN :( )
GHDL_FLAGS  = --ieee=standard --warn-no-vital-generic

SIMDIR = simulation
# Simulation break condition
#GHDL_SIM_OPT = --assert-level=error
GHDL_SIM_OPT = --stop-time=2300000ns
#3451000ns

WAVEFORM_VIEWER = gtkwave
# WAVEFORM_VIEWER = /C/Users/MarceloFernando/GTKWAVE/bin/gtkwave # por si no funca el Path ( WIN :( )

# plot path
PLOT_PATH = octave-src/outploter
# PLOTER = octave-cli --persist
PLOTER = python
PLOT_EXT = py

all: compile run view plot

new:
	@echo "Setting up project ${PROJECT}"
	mkdir src testbench simulation

compile:
ifeq ($(strip $(TESTBENCH)),)
	@echo "TESTBENCH not set. Use TESTBENCH=value to set it."
	@exit 2
endif

	mkdir -p simulation
	$(GHDL_CMD) -i $(GHDL_FLAGS) --workdir=simulation --work=work $(TESTBENCHPATH) $(FILES)
	$(GHDL_CMD) -m  $(GHDL_FLAGS) --workdir=simulation --work=work $(TESTBENCH)
	#@mv $(TESTBENCH) simulation/$(TESTBENCH)

run:
	#$(SIMDIR)/$(TESTBENCH) $(GHDL_SIM_OPT) --vcdgz=$(SIMDIR)/$(TESTBENCH).vcdgz
	# lo cambio por el directorio actual porque no se genera el objeto en binario
	$(GHDL_CMD) -r --workdir=$(SIMDIR) $(TESTBENCH) $(GHDL_SIM_OPT) --vcdgz=$(SIMDIR)/$(TESTBENCH).vcdgz

view:
	# gunzip descomprime el archivo .vcdgz generado por ghdl y lo envia a la salida estandar 'stdout'
	# luego lo toma gktwave y recupera las señales guardadas que se guardaron con "ctrl+s" desde gui
	# fuente: http://billauer.co.il/blog/2017/08/linux-vcd-waveform-viewer/
	gunzip --stdout $(SIMDIR)/$(TESTBENCH).vcdgz | $(WAVEFORM_VIEWER) --vcd $(SIMDIR)/$(TESTBENCH).sav
	
plot:
	# grafico de los puntos del mundito con octave
	$(PLOTER) octave-src/outploter.$(PLOT_EXT)

clean :
	$(GHDL_CMD) --clean --workdir=simulation
	rm -f ./*.o $(SIMDIR)/*.o $(SIMDIR)/*.cf $(SIMDIR)/*.vcdgz

