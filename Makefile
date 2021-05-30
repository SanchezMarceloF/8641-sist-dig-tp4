#extraído de https://github.com/FedeVerstraeten/sd-2c2019/blob/master/ejemplos/Makefile
#TESTBENCH = sram_tb
# vhdl files
FILES = src/* #acá entiendo que los archivos .vhd están guardos acá
VHDLEX = .vhd #extensión archivos vhdl

# testbench
TESTBENCHPATH = testbench/${TESTBENCH}$(VHDLEX)
#

#GHDL CONFIG
GHDL_CMD = ghdl
GHDL_FLAGS  = --ieee=synopsys --warn-no-vital-generic

SIMDIR = simulation
# Simulation break condition
#GHDL_SIM_OPT = --assert-level=error
GHDL_SIM_OPT = --stop-time=450000ns

WAVEFORM_VIEWER = gtkwave

all: compile run view

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
	#lo cambio por el directorio actual porque no se genera el objeto en binario
	$(GHDL_CMD) -r --workdir=$(SIMDIR) $(TESTBENCH) $(GHDL_SIM_OPT) --vcdgz=$(SIMDIR)/$(TESTBENCH).vcdgz

view:
	gunzip --stdout $(SIMDIR)/$(TESTBENCH).vcdgz | $(WAVEFORM_VIEWER) --vcd

clean :
	$(GHDL_CMD) --clean --workdir=simulation
	rm -f ./*.o $(SIMDIR)/*.o $(SIMDIR)/*.cf $(SIMDIR)/*.vcdgz

