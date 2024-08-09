# Define variables
VENV_DIR := .venv
PYTHON_VERSION := 3.11

# Target to initialize submodules and create a Python virtual environment
setup:
	git submodule update --init --recursive
	uv venv $(VENV_DIR) -p $(PYTHON_VERSION)

# Target to install Python packages and Node packages
install:
	. $(VENV_DIR)/bin/activate
	uv pip install -e ".[dev, plugins]" -c requirements.txt -p $(VENV_DIR)/bin/python

# Target to update submodules and sync Python and Node packages
sync:
	git submodule update --init --recursive
	uv pip install -e ".[dev, plugins]" -c requirements.txt -p $(VENV_DIR)/bin/python

# Lock python dependencies
lock:
	uv pip compile -p $(PYTHON_VERSION) --python-platform linux --annotation-style=line \
    --extra=plugins \
    --output-file=requirements.txt \
    pyproject.toml


# Update dependencies and submodules
update:
	git submodule update --remote --merge
	uv pip compile -U -p $(PYTHON_VERSION) --python-platform linux --annotation-style=line \
    --extra=plugins \
    --output-file=requirements.txt \
    pyproject.toml

# Start appworker
appworker:
	$(VENV_DIR)/bin/python -m nomad.cli admin run appworker
 
# Target to start infrastructure using docker-compose for infra
infra:
	docker compose -f docker-compose.infra.yml up -d

# Target to start development environment using docker-compose with rebuild
dev_docker:
	docker compose -f docker-compose.yml up --build


.PHONY: setup install sync infra dev_docker
