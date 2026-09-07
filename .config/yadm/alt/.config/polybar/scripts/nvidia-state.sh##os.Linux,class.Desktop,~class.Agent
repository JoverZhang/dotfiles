if ! command -v nvidia-smi &>/dev/null; then
	echo "No Nvidia GPU"
	exit 0
fi

usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
temperature=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
used_mem=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)

echo "$usage"% "$temperature"°C "$used_mem"MB
