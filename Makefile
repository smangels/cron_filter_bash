
all: test

test: testme.sh cron_script.sh
	bash $<