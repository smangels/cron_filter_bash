
SIGNAL_FILE="signal_file.txt"

function test_1()
{
	echo "test_1"
}

function tear_down()
{
	rm -f "${SIGNAL_FILE}"
}


test_1


# final
tear_down
