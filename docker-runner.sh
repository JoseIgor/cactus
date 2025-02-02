#!/bin/sh

set -eu

PROJECT_NAME="cactus"
BUILD_IMAGE_NAME=${BUILD_IMAGE_NAME:-$PROJECT_NAME}
BUILD_CONTAINER_NAME=${BUILD_CONTAINER_NAME:-$PROJECT_NAME"-builder-container"}

DEBUGGER_IMAGE_NAME=${DEBUGGER_IMAGE_NAME:-$PROJECT_NAME"-debugger"}
DEBUGGER_CONTAINER_NAME=${DEBUGGER_CONTAINER_NAME:-$PROJECT_NAME"-debugger-container"}

LINT_IMAGE_NAME=${LIST_IMAGE_NAME:-$PROJECT_NAME"-lint"}
LINT_CONTAINER_NAME=${LINT_CONTAINER_NAME:-$PROJECT_NAME"-lint-container"}



usage()
{
	echo "Usage: ${0} [OPTIONS]"
	echo "Build docker images and creates docker conainters."
	echo "Available options:"
	echo "    -b   Build docker image and container for BUILD purpouse."
	echo "    -d   Build docker image and container for DEBUG purpouse."
	echo "    -l   Build docker image and container for LINT purpouse."
	echo "    -e   Run build container."
	echo "    -f   Run debugger container."
	echo "    -g   Run lint container."
	echo "    -r   Remove all images and containers."
}

cleanup() {
	trap EXIT
}

create_builder_container() {

	echo "info" "Will create builder container and run in detached mode."

	docker build -t "${BUILD_IMAGE_NAME}" .

	if [ "$(docker ps -a -q -f name="${BUILD_CONTAINER_NAME}")" ]; then
		docker rm -f "${BUILD_CONTAINER_NAME}" > /dev/null
	fi

	docker \
		run \
		-it \
		-v $(pwd):/${PROJECT_NAME} \
		--name "${BUILD_CONTAINER_NAME}" \
		-d "${BUILD_IMAGE_NAME}"

	echo "info" "Builder container running in detached mode"

}

run_builder_container() {

	echo "info" "Will run builder docker container."

	# checks if container exists
	if [ ! "$(docker ps -a -q -f name="${BUILD_CONTAINER_NAME}")" ]; then
		create_builder_container
	fi

	# checks if container is running
	if [ ! "$(docker ps -q -f status=running -f name="${BUILD_CONTAINER_NAME}")" ]; then
		docker start "${BUILD_CONTAINER_NAME}" > /dev/null
	fi

	docker exec -it "${BUILD_CONTAINER_NAME}" /bin/sh

	echo "info" "Exited from builder docker container."

}

create_debugger_container() {

	echo "info" "Will create debugger container and run in detached mode."

	docker build -t "${BUILD_IMAGE_NAME}" .

	docker build -t "${DEBUGGER_IMAGE_NAME}" -f Dockerfile.debug .

	if [ "$(docker ps -q -f name="${DEBUGGER_CONTAINER_NAME}")" ]; then
		docker rm -f "${DEBUGGER_CONTAINER_NAME}" > /dev/null
	fi

	docker \
		run \
		-it \
		--privileged \
		-v $(pwd):/${PROJECT_NAME} \
		--name "${DEBUGGER_CONTAINER_NAME}" \
		-d "${DEBUGGER_IMAGE_NAME}"

	echo "info" "Debugger container running in detached mode."
}

run_debugger_container() {

	echo "info" "Will run debugger docker container."

	# checks if container exists
	if [ ! "$(docker ps -a -q -f name="${DEBUGGER_CONTAINER_NAME}")" ]; then
		create_debugger_container
	fi

	# checks if container is running
	if [ ! "$(docker ps -q -f status=running -f name="${DEBUGGER_CONTAINER_NAME}")" ]; then
		docker start "${DEBUGGER_CONTAINER_NAME}" > /dev/null
	fi

	docker exec -it "${DEBUGGER_CONTAINER_NAME}" /bin/sh

	echo "info" "Exited from debugger docker container."
}

create_lint_container() {

	echo "info" "Will create lint container and run in detached mode."

	docker build -t "${LINT_IMAGE_NAME}" -f Dockerfile.lint .

	if [ "$(docker ps -q -f name="${LINT_CONTAINER_NAME}")" ]; then
		docker rm -f "${LINT_CONTAINER_NAME}" > /dev/null
	fi

	docker \
		run \
		--network
		-it \
		-v $(pwd):/${PROJECT_NAME} \
		-u "$(id -u):$(id -g)" \
		--name "${LINT_CONTAINER_NAME}" \
		-d "${LINT_IMAGE_NAME}"

	echo "info" "Lint container running in detached mode."
}

run_lint_container() {

	echo "info" "Will run lint docker container."

	# checks if container exists
	if [ ! "$(docker ps -a -q -f name="${LINT_CONTAINER_NAME}")" ]; then
		create_lint_container
	fi

	# checks if container is running
	if [ ! "$(docker ps -q -f status=running -f name="${LINT_CONTAINER_NAME}")" ]; then
		docker start "${LINT_CONTAINER_NAME}" > /dev/null
	fi

	docker exec -it "${LINT_CONTAINER_NAME}" /bin/bash

	echo "info" "Exited from lint docker container."
}

docker_clean_all() {

	echo "info" "Will remove all docker containers and images."

	# remove builder,debugger and lint containers
	if [ "$(docker ps -q -f status=running -f name="${BUILD_CONTAINER_NAME}")" ]; then
		echo "Stoping container "${BUILD_CONTAINER_NAME}"."
		docker stop "${BUILD_CONTAINER_NAME}" > /dev/null
		echo "Container ${BUILD_CONTAINER_NAME} stoped."
	fi

	if [ "$(docker ps -a -q -f name="${BUILD_CONTAINER_NAME}")" ]; then
		echo "Removing container "${BUILD_CONTAINER_NAME}"."
		docker rm "${BUILD_CONTAINER_NAME}" > /dev/null
		echo "Container "${BUILD_CONTAINER_NAME}" removed."
	fi

	if [ "$(docker ps -q -f status=running -f name="${DEBUGGER_CONTAINER_NAME}")" ]; then
		echo "Stoping container "${DEBUGGER_CONTAINER_NAME}"."
		docker stop "${DEBUGGER_CONTAINER_NAME}" > /dev/null
		echo "Container ${DEBUGGER_CONTAINER_NAME} stoped."
	fi

	if [ "$(docker ps -a -q -f name="${DEBUGGER_CONTAINER_NAME}")" ]; then
		echo "Removing container "${DEBUGGER_CONTAINER_NAME}"."
		docker rm "${DEBUGGER_CONTAINER_NAME}" > /dev/null
		echo "Container "${DEBUGGER_CONTAINER_NAME}" removed."
	fi

	if [ "$(docker ps -q -f status=running -f name="${LINT_CONTAINER_NAME}")" ]; then
		echo "Stoping container "${LINT_CONTAINER_NAME}"."
		docker stop "${LINT_CONTAINER_NAME}" > /dev/null
		echo "Container ${LINT_CONTAINER_NAME} stoped."
	fi

	if [ "$(docker ps -a -q -f name="${LINT_CONTAINER_NAME}")" ]; then
		echo "Removing container "${LINT_CONTAINER_NAME}"."
		docker rm "${LINT_CONTAINER_NAME}" > /dev/null
		echo "Container "${LINT_CONTAINER_NAME}" removed."
	fi

	# remove builder and debugger images
	# Order is important as debugger image depends on builder image. First remove debugger image
	if [ "$(docker images -q "${DEBUGGER_IMAGE_NAME}")" ]; then
		echo "Removing image "${DEBUGGER_IMAGE_NAME}"."
		docker rmi "${DEBUGGER_IMAGE_NAME}" > /dev/null
		echo "Image ${DEBUGGER_IMAGE_NAME} removed."
	fi

	if [ "$(docker images -q "${BUILD_IMAGE_NAME}")" ]; then
		echo "Removing image "${BUILD_IMAGE_NAME}"."
		docker rmi "${BUILD_IMAGE_NAME}" > /dev/null
		echo "Image ${BUILD_IMAGE_NAME} removed."
	fi

	# remove lint image
	if [ "$(docker images -q "${LINT_IMAGE_NAME}")" ]; then
		echo "Removing image "${LINT_IMAGE_NAME}"."
		docker rmi "${LINT_IMAGE_NAME}" > /dev/null
		echo "Image ${LINT_IMAGE_NAME} removed."
	fi

	echo "info" "All  docker containers and images removed."
}

main()
{
	while getopts ":hbdlefgr" _options; do
		case "${_options}" in
		h)
			usage
			exit 0
			;;
		b)
			create_builder_container
			;;

		d)
			create_debugger_container
			;;

		l)
			create_lint_container
			;;

		e)
			run_builder_container
			;;

		f)
			run_debugger_container
			;;

		g)
			run_lint_container
			;;

		r)
			docker_clean_all
			;;

		:)
			echo "Option -${OPTARG} requires an argument."
			exit 1
			;;
		?)
			echo "Invalid option: -${OPTARG}"
			exit 1
			;;
		esac
	done

	cleanup
}

main "${@}"

exit 0

