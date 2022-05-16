
# Introduction

This repository is meant to provide a function that could be sourced so that a shell script file executed by a CRON job could check it is allowed to generate an output or not. Thus we could run very frequent tasks in CRON without getting spammed by emails as soon as that task fails.

# State Machine

![Alt text](https://g.gravizo.com/source/custom_filter_cron?https%3A%2F%2Fraw.githubusercontent.com%2Fsmangels%2Fcron_filter_bash%2Fmain%2FREADME.MD)

<details> 
<summary></summary>
custom_filter_cron
@startuml
start
:unknown;
-> function call;
if (result?) is (<color:red>ok) then
:OK;
else 
:FAILED;
endif
end
@enduml
custom_filter_cron
</details>


# Supported features

- filter subsequent FAIL states as long as

# Interface

```sh
prohibit_output <STATE> <TIME_LIMIT_IN_SECONDS>
```

# Integration

```sh
# describe how to source or define a dummy function that always
# return 1
if [ -z MY_ENV_VAR ]; then
  source $FILE_CONTAINING_FUNCTION
else
	function prohibit_output()
	{
		return 1
	}
fi

# call that function
prohibit_output "failed" 120 || echo "this generates email"
```

# Idea Pad

- generate the source code using Ansible and a Jinja2 template
  so that we could dynamically configure the timeout (given in seconds
