# IPAL Transcriber Tutorial

If this is the first time working with IPAL, we recommend skimming the `Introduction to IPAL.pdf` document to understand the idea and main concepts of IPAL before continuing with the tutorial.

Reminder: The provided docker files facilitate an easy installation of the IPAL software bundle.

Note: If you are using Docker, the tutorial files can be found at `tutorial_files`.

## Transcribing network packets

1. Open and familiarize yourself with the pcap from `utils/ModbusTCP.pcap`, e.g., in Wireshark.
2. Study the capabilities of `ipal-transcriber -h`
3. Use the `ipal-transcriber` to convert the pcap into IPAL messages with `ipal-transcriber --pcap utils/ModbusTCP.pcap --ipal.out ModbusTCP.ipal`
4. Inspect the output with, e.g., `cat ModbusTCP.ipal | jq .` and compare it to the Wireshark pcap.

## Enrich the output via rule files

1. Inspect the output once again. Which IP addresses might correspond to which device types (PLC or HMI)?
2. We now want to give these devices more expressive names during the IPAL transcription. Use `utils/rules-template1.py` and add a renaming rule. You can use Python's regular expressions if needed.
3. Transcribe the pcap again with the rule file `ipal-transcriber --pcap utils/ModbusTCP.pcap --rules rules.py --ipal.out ModbusTCP.ipal`
4. Next, we want to convert the values to a human-readable format. Use `utils/rules-template2.py` and add a float conversion based on the values `holding.register.3006` and `holding.register.3007`. The new value should be named `pressure`.
5. Also remove the remaining variables contained in that message (`"holding.register.2999", "holding.register.3000", "holding.register.3001", "holding.register.3002", "holding.register.3003", "holding.register.3004", "holding.register.3005")`.
6. Transcribe and inspect the pcap again and save the IPAL file to `ModbusTCP.ipal.gz`. Note: If a file of any IPAL tools ends with `.gz`, the output will automatically be compressed.

## Introduction to the state extractor

Imagine you operate a process-based IIDS, which operates on the `pressure` value. Thus, you want to extract only the `pressure` value at regular intervals, e.g., every 1 second, from the network traffic.

1. Study the capabilities of `ipal-state-extractor -h`
2. Extract the state on a per-packet basis `ipal-state-extractor --ipal.input ModbusTCP.ipal.gz --state.output - default | jq .` Note: If a file of any IPAL tools is indicated as `-`, the input or output is read or written from stdin or stdout.
3. Extract the state in one-second intervals
	1. `ipal-state-extractor timeslice -h`
	2. `ipal-state-extractor --ipal.input ModbusTCP.ipal.gz --state.output - timeslice --timeslice.interval 1000`
3. Filter for the `pressure` only `ipal-state-extractor --ipal.input ModbusTCP.ipal.gz --state.output - --filter "PLC:pressure" timeslice --timeslice.interval 1000`
4. Create a dump of the state in a single command `ipal-transcriber --pcap utils/ModbusTCP.pcap --rules rules.py --filter "PLC:pressure" --state.out ModbusTCP.state.gz timeslice --timeslice.interval 1000`

## Visualize the process state
1. Use the tool in `utils/plot.py` to visualize the pressure's process behavior. If you are using Docker, the image is saved under `./PLC-Pressure.pdf`.

# IIDS Framework Demo

## Train an IIDS model

As the next task, you want to train the network-based Inter Arrival Time (IaT) IIDS on the set of recorded training data from task 1 (`ModbusTCP.ipal.gz`).

1. Familiarize yourself with the IPAL IIDS Framework `ipal-iids -h`
2. Each IIDS requires a configuration file. Generate a default config file for the IAT IIDS `ipal-iids --default.config inter-arrival-mean > mean.config`
3. Inspect the settings. Each IIDS has a lot of settings that are entirely dependent on the individual detection approach. More information about each approach can be found in the repository's README file.
4. Now train the IIDS with the previously generated IPAL file with `ipal-iids --config mean.config --train.ipal ModbusTCP.ipal.gz`
5. The training phase creates a `model` based on the training data. The trained model can be inspected with `ipal-visualize-model mean.config` (Note 1: you have to provide the config file, not the model! Also, not every IDS implements the capability to visualize the IDS's model.) (Note 2: If you are using IPAL in Docker and want to safe the image instead, add the ``--output [path].pdf` option to `ipal-visualize-model`.)

## Perform Intrusion Detection
After training, you plan to use the trained IIDS to detect some anomalies.

1. Find anomalies in the `utils/Anomalous.ipal.gz` file with `ipal-iids --config mean.config --live.ipal utils/Anomalous.ipal.gz --output Mean-IDS.ipal.gz`
2. Inspect the alerts of the IDS manually, e.g., with `gunzip -c Mean-IDS.ipal.gz | jq .`
3. Use the tool `ipal-plot-alerts` to visualize the alerts `ipal-plot-alerts --attacks utils/attacks.json Mean-IDS.ipal.gz`. The IDS detects the first and last attack, but the second attack is missed. Look at the `./utils/attacks.json` file to learn more about each attack. (Note: If you are using IPAL in Docker and want to safe the image instead, add the ``--output [path].pdf` option to `ipal-plot-alerts`.)
4. Copy the `mean.config` file to `range.config` and change the IDS type in the config file to `inter-arrival-range`. Retrain the model with the `--retrain` parameter. If `--retrain` is not used, `ipal-iids` simply loads the previously trained model and omits the training step. This can be helpful if the training phase takes some time to finish.
5. Save the output of the second IDS as `Range-IDS.ipal.gz` and take a look at the detected attacks with `ipal-plot-alerts`. The second IDS should exhibit more false positives than the first IDS. Note: `ipal-plot-alerts` can be provided with multiple files to compare different IDSs side-by-side.

# IPAL Evaluate

In the final step, we aim to measure the performance of both approaches (Mean and Range).

1. Therefore, the network data within the output files (Mean-IDS.ipal.gz and Range-IDS.ipal.gz) is not required anymore and can be removed to save disc space, especially for large datasets. Apply `ipal-minimize --all` to the generated IPAL files and observe the difference.
2. Then, for each IDS, analyze its performance with `ipal-evaluate --attacks ./utils/attacks.json {file}.ipal.gz`.
3. Save the output of `ipal-evaluate` for the Mean and Range model to individual files. Afterward, visualize their performance with `ipal-plot-metrics`. According to the F1-score, the Mean IDS is slightly better in this scenario, as we already suggested in the visual comparison. (Note: If you are using IPAL in Docker and want to safe the image instead, add the ``--output [path].pdf` option to `ipal-plot-metrics`.)


## Further comments

- If you want to retrain the IDS, e.g., with different parameters, use the `--retrain` option! Otherwise, the previously trained model is loaded from disk, and nothing is re-trained.
- For state-based IIDSs, you need to provide the state file with `--train.state` and `--live.state`!
- Extensive logging can be enabled for all tools with the `--log info` argument.
