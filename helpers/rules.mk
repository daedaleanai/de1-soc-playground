.RECIPEPREFIX = >
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.PHONY: all clean project system synthesis fitting assembly payload spl
all: payload spl

.sentinel.project:
> quartus_sh -t ../../helpers/new-project.tcl $(NAME)
> touch $@

.sentinel.system:
> qsys-generate --synthesis=VERILOG system.qsys
> touch $@

.sentinel.synthesis: .sentinel.project .sentinel.system
> quartus_map --read_settings_files=on --write_settings_files=off $(NAME) -c $(NAME)
> quartus_sh -t ../../helpers/assign-hps-sdram-pins.tcl $(NAME)
> touch $@

.sentinel.fitting: .sentinel.synthesis
> quartus_fit --read_settings_files=on --write_settings_files=off $(NAME) -c $(NAME)
> touch $@

.sentinel.assembly: .sentinel.fitting
> quartus_asm --read_settings_files=on --write_settings_files=off $(NAME) -c $(NAME)
> touch $@

fpga-payload.rbf: .sentinel.assembly
> quartus_cpf -c output_files/$(NAME).sof fpga-payload.rbf

.sentinel.spl: .sentinel.assembly
> bsp-create-settings --type spl --bsp-dir spl              \
    --preloader-settings-dir "hps_isw_handoff/system_hps_0" \
    --settings spl/settings.bsp
> touch $@

project: .sentinel.project
system: .sentinel.system
synthesis: .sentinel.synthesis
fitting: .sentinel.fitting
assembly: .sentinel.assembly
payload: fpga-payload.rbf
spl: .sentinel.spl

clean:
> rm -rf .sentinel.*
> rm -rf $(NAME).qpf $(NAME).qsf $(NAME).qws
> rm -rf incremental_db
> rm -rf output_files
> rm -rf hps_sdram_p0_all_pins.txt
> rm -rf db
> rm -rf system
> rm -rf system.sopcinfo
> rm -rf c5_pin_model_dump.txt
> rm -rf hps_isw_handoff
> rm -rf spl
> rm -rf fpga-payload.rbf
> rm -rf .qsys_edit
