default: build

build:
	docker build --network=host --rm -t kaldi-coraa-train-${USER} .	

run:
	docker run --name kaldi-coraa-train-${USER} \
		-it \
		-v /home/asr/docker-kaldi-coraa-pt/models/:/models \
		-v /home/asr/docker-kaldi-coraa-pt/data/:/data \
		-v /home/asr/docker-kaldi-coraa-pt/scripts/:/root/scripts \
		kaldi-coraa-train-${USER} \
		bash

stop:
	-docker stop kaldi-coraa-train-${USER}
	-docker rm kaldi-coraa-train-${USER}

clean:
	-docker rmi -f kaldi-coraa-train-${USER}
