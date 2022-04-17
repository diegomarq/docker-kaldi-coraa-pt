default: build

build:
	docker build --network=host --rm -t kalditr/kaldi-coraa-train-${USER} .	

run:
	docker run --name kalditr-kaldi-coraa-train-${USER} \
		-it \
		-v ${HOME}/docker-kaldi-coraa-pt/models/:/models \
		-v ${HOME}/docker-kaldi-coraa-pt/data/:/data \
		-v ${HOME}/docker-kaldi-coraa-pt/scripts/:/root/scripts \
		kalditr/kaldi-coraa-train-${USER} \
		bash

stop:
	-docker stop kalditr-kaldi-coraa-train-${USER}
	-docker rm kalditr-kaldi-coraa-train-${USER}

clean:
	-docker rmi -f kalditr/kaldi-coraa-train-${USER}
