# IPAL Transcriber Tutorial

## Transcribing network packets

1. Open and familarize yourself with the pcap from `utils/ModbusTCP.pcap`, e.g., in Wireshark
2. Study the capabilities of `ipal-transcriber -h`
3. Use the `ipal-transcriber` to convert the pcap into IPAL messages with `ipal-transcriber --pcap utils/ModbusTCP.pcap --ipal.out ModbusTCP.ipal`
4. Inspect the output with, e.g., `cat ModbusTCP.ipal | jq .` and compare it to the Wireshark pcap

## Enrich the output via rule files

1. Inspect the output once again. Which IP addresses might correspond to which device types (PLC or HMI)?
2. Use `utils/rules-template1.py` and add a renaming rule. You can use Python's regular expressions if needed.
3. Transcribe the pcap again with the rule file `ipal-transcriber --pcap utils/ModbusTCP.pcap --rules rules.py --ipal.out ModbusTCP.ipal`
4. Use `utils/rules-template2.py` and add a float conversion based on the values `holding.register.3006` and `holding.register.3007`. The new value should be named `pressure`.
5. Also remove the remaining variables contained in that message (`"holding.register.2999", "holding.register.3000", "holding.register.3001", "holding.register.3002", "holding.register.3003", "holding.register.3004", "holding.register.3005")`.
6. Transcribe and inspect the pcap again.
7. Safe the ipal file to `ModbusTCP.ipal.gz`


## Introduction to the state extractor
Assume you want to extract only the `pressure` value in regular intervals, e.g., every second.

1. Study the capabilities of `ipal-state-extractor -h`
2. Extract the state on a per-packet basis `ipal-state-extractor --ipal.input ModbusTCP.ipal.gz --state.output - default | jq .`
3. Extract the state in one second intervals
	1. `ipal-state-extractor timeslice -h`
	2. `ipal-state-extractor --ipal.input ModbusTCP.ipal.gz --state.output - timeslice --timeslice.interval 1000`
3. Filter for the `pressure` only `ipal-state-extractor --ipal.input ModbusTCP.ipal.gz --state.output - --filter "PLC:pressure" timeslice --timeslice.interval 1000`
4. Create a dump of the state in a single command `ipal-transcriber --pcap utils/ModbusTCP.pcap --rules rules.py --filter "PLC:pressure" --state.out ModbusTCP.state.gz timeslice --timeslice.interval 1000`

## Visualize the process state
1. Use the tool in `utils/plot.py` to visualize the pressure's process behavior.

# IIDS Framework Demo

## Train an IIDS model
As next task, you want to train the Inter Arrival Time (IAT) IDS on the training data.

1. Familarize yourself with `ipal-iids -h`
2. Generate a default config file for the IAT IIDS `ipal-iids --default.config inter-arrival-mean > iids.config`
3. Inspect the settings. Each IIDS has a lot of settings which are entirely dependent on the individual detection approach. More information about each approach can be found in the README file of the repository.
3. Now train the IIDS on the previously generated IPAL file with `ipal-iids --config iids.config --train.ipal ModbusTCP.ipal.gz`
4. This command creates a `model` based on the training data. The trained model can be inspected with `ipal-visualize-model iids.config` (NOTE: you have to provide the config file, not the model!)

## Perform Intrusion Detection
After training, you plan to use the trained IIDS to detect some anomalies.

1. Find anomalies in the `utils/Anomalous.ipal.gz` file with `ipal-iids --config iids.config --live.ipal utils/Anomalous.ipal.gz --output IDS.ipal.gz`
2. Inspect the alerts of the IDS manually, e.g., with `gzcat IDS.ipal.gz | jq .`
3. Use the tool `./utils/ipal-plot-alerts` to visualize the alerts `./utils/ipal-plot-alerts --attacks utils/attacks.json IDS.ipal.gz`
4. Now change the IDS type in the config file to `inter-arrival-range`, retrain the model with the `--retrain` parameter and observe the trained model and the output of that IDS again.

## Further comments

- If you want to retrain the IDS (with different parameters) use the `--retrain` option! Otherwise the previously trained model is loaded from disk and nothing is re-trained.
- For state-based IIDSs, you need to provide the state file with `--train.state` and `--live.state`!

# IPAL Evaluate

TODO