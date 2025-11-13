#!/bin/bash
echo "=== Namespace and Cgroup Demo ==="
echo
# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi
echo "1. Creating a new PID namespace with unshare..."
echo "   This process will have its own view of process IDs"
echo
# Create a cgroup for memory limiting
CGROUP_NAME="demo_cgroup"
CGROUP_PATH="/sys/fs/cgroup/$CGROUP_NAME"
echo "2. Creating a cgroup to limit memory..."
mkdir -p "$CGROUP_PATH"
# Set memory limit to 50MB
echo "50M" > "$CGROUP_PATH/memory.max"
echo "   Memory limit set to 50MB"
echo
echo "3. Running a shell in new namespace with cgroup limits..."
echo "   Inside this shell, try: ps aux (you'll see only processes in this namespace)"
echo "   Type 'exit' to return"
echo
# Run shell in new PID and mount namespace, within the cgroup
unshare --pid --fork --mount-proc bash -c "
    echo \$\$ > $CGROUP_PATH/cgroup.procs
    echo 'You are now in a new namespace with cgroup limits!'
    echo 'Current PID: \$\$ (appears as PID 1 in this namespace)'
    echo
    echo '--- Process List ---'
    ps aux
    echo
    echo '--- Memory Usage ---'
    echo \"Memory Limit: \$(($(cat $CGROUP_PATH/memory.max) / 1024 / 1024))MB\"
    echo \"Current Usage: \$(($(cat $CGROUP_PATH/memory.current) / 1024 / 1024))MB\"
    echo \"Used: \$(($(cat $CGROUP_PATH/memory.current) / 1024 / 1024))MB / Limit: \$(($(cat $CGROUP_PATH/memory.max) / 1024 / 1024))MB\"
    echo
    echo '--- Try These Commands ---'
    echo '# Check memory anytime:'
    echo 'echo \"\$(($(cat $CGROUP_PATH/memory.current) / 1024 / 1024))MB used\"'
    echo
    echo
    bash
"
# Cleanup
echo
echo "4. Cleaning up cgroup..."
rmdir "$CGROUP_PATH" 2>/dev/null
echo "Demo complete!"