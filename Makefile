.PHONY: test

test: elm.mk dummy
	cp elm.mk dummy/elm.mk
	cd dummy && $(MAKE) -f elm.mk install && $(MAKE) && $(MAKE) prod
	./tests.sh
	rm -r dummy

dummy:
	mkdir -p $@

elm.mk: templates/* targets.mk
	touch $@
	rm $@
	cat targets.mk > $@
	cat templates/* >> $@
