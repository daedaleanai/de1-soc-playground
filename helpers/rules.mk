.RECIPEPREFIX = >
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.PHONY: all clean check-quartus check-qsys project system synthesis fitting assembly payload spl
all: payload spl

check-quartus:
> @which quartus_sh >/dev/null || echo "quartus_sh tools not found in your path" || exit 1

check-qsys:
> @which qsys-generate >/dev/null || echo "qsys-generate not found in your path" || exit 1

check-bsp:
> @which bsp-create-settings >/dev/null || echo "bsp-create-settings not found in your path" || exit 1

project: check-quartus
> quartus_sh -t ../../helpers/new-project.tcl $(NAME)

system: check-qsys
> qsys-generate --synthesis=VERILOG system.qsys

synthesis: project system
> quartus_map --read_settings_files=on --write_settings_files=off $(NAME) -c $(NAME)
> quartus_sh -t ../../helpers/assign-hps-sdram-pins.tcl $(NAME)

fitting: synthesis
> quartus_fit --read_settings_files=on --write_settings_files=off $(NAME) -c $(NAME)

assembly: fitting
> quartus_asm --read_settings_files=on --write_settings_files=off $(NAME) -c $(NAME)

payload: assembly
> quartus_cpf -c output_files/$(NAME).sof fpga-payload.rbf

spl: check-bsp assembly
> bsp-create-settings --type spl --bsp-dir spl              \
    --preloader-settings-dir "hps_isw_handoff/system_hps_0" \
    --settings spl/settings.bsp

clean:
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
