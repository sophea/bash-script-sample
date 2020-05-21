# bash-script-sample
bash-script sample

# special variables
````

$0 - The filename of the current script.|
$n - The Nth argument passed to script was invoked or function was called.|
$# - The number of argument passed to script or function.|
$@ - All arguments passed to script or function.|
$* - All arguments passed to script or function.|
$? - The exit status of the last command executed.|
$$ - The process ID of the current shell. For shell scripts, this is the process ID under which they are executing.|
$! - The process number of the last background command.|
````
# Test it is root user or not
````
test $(id -u) -eq 0  && echo "Root user can run this script." || echo "Use sudo or su to become a root user."
````
