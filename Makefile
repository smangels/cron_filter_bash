
all: test

test: test_cron_script.sh cron_script.sh
	@bash $<

.PHONY: clean
clean:
	rm -f /tmp/cron_script.sh.cron
