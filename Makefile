coverage:
	uv run pytest --cov=src --cov-report=html tests/
docker-build:
	docker build -t cartellino_notify .
start:
	docker compose up -d
stop:
	docker compose down
restart:
	docker compose down
	docker compose up -d
venv:
	uv venv
format:
	ruff format
requirements:
	uv pip compile pyproject.toml -o requirements.txt
run:
	uv run main.py job

