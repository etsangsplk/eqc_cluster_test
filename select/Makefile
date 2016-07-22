.PHONY: all

all: cluster_eqc.beam orgs_eqc.beam users_eqc.beam projects_eqc.beam

%.beam: %.erl
	erlc $<
