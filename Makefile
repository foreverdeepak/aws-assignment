build:
	docker build -t amazon/terraform .

run:
	docker run --privileged -it -v ${PWD}:/root/terraform -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) amazon/terraform  /bin/bash
