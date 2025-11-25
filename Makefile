coverage:
	uv run pytest --cov=src --cov-report=html tests/
docker-build:
	docker build -t cartellino_notify .
start:
	docker compose up
stop:
	docker compose down
venv:
	uv venv
format:
	ruff format
