
# Introduction

This repository is meant to provide a function that could be sourced so that a shell script file executed by a CRON job could check it is allowed to generate an output or not. Thus we could run very frequent tasks in CRON without getting spammed by emails as soon as that task fails.

# State Machine

![Alt text](https://g.gravizo.com/source/svg/custom_mark11?https%3A%2F%2Fraw.githubusercontent.com%2Fsmangels%2Fcron_filter_bash%2Fmain%2FREADME.md)
<details> 
<summary>This is a summary</summary>
custom_mark11
	digraph G {
		size = "8,8"
		main [shape=box]
		UNKNOWN -> OK [label="cmd:OK"]
		UNKNOWN -> FAILED [label="cmd:FAILED"]
		OK -> OK [label="cmd:OK"]
		OK -> FAILED [label="cmd:FAILED"]
		FAILED -> FAILED [label="cmd:FAILED"]
		FAILED -> OK [label="cmd:OK"]
		{rank = same; OK; FAILED;}
	}
custom_mark11
</details>


# Supported features

- filter subsequent FAIL states as long as not more than
  X number of seconds have elapsed after last call
- do not prohibit logging when the following transitions are performed
	- UNKNOWN => FAILED
	- UNKNOWN => OK
	- FAILED => OK
	- OK => FAILED
- in case of invalid command [^ok|failed], logging shall not be
  prohibited

# Interface

```sh
prohibit_output <STATE> <TIME_LIMIT_IN_SECONDS>
```


# Architecture

The solution is build around writing and reading a temporary file who's name is derived from the name of the script including

# Integration

```sh
# describe how to source or define a dummy function that always
# return 1
CRON_ENABLE_FILTERING=1

if [ $CRON_ENABLE_FILTERING -gt 0 ]; then
   source ./cron_script.sh
else
   function prohibit_output()
   {
      echo "=> dummy is called"
      return 1
   }
fi
# call that function
prohibit_output "failed" 120 || echo "this generates email"
```

# Idea Pad

- generate the source code using Ansible and a Jinja2 template
  so that we could dynamically configure the timeout (given in seconds
