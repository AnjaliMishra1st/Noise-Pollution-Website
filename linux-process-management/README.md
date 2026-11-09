# Linux process management with Bash

`process_management.sh` demonstrates how a parent shell starts and monitors
three background child processes:

- **PID**: the process ID of a process (`$$` in the script).
- **PPID**: the parent process ID (`$PPID` in the script).
- **`pgrep -P PID`**: lists processes whose parent is the supplied PID.
- **`ps`**: displays the PID, PPID, state, and command.
- **`wait PID`**: makes the parent wait for a child to finish.

Each child calculates one result:

1. Fibonacci number
2. Factorial
3. Armstrong-number check

## Run it

```bash
cd linux-process-management
chmod +x process_management.sh
./process_management.sh 10
```

The argument must be a non-negative integer. For example, `10` produces
Fibonacci(10) = 55 and Factorial(10) = 3628800. An Armstrong check is also
performed for the same input.

## Run one worker directly

```bash
./process_management.sh worker fibonacci 10
./process_management.sh worker factorial 5
./process_management.sh worker armstrong 153
```

The direct worker mode prints its own PID and PPID, which makes the
parent-child relationship easy to inspect with `ps` or `pgrep`.
