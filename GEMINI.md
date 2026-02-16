# Cartellino Notify

**Cartellino Notify** is a productivity tool designed to help users track their work hours, calculate when their work shift will end, and receive timely notifications. The name "Cartellino" refers to the Italian term for a work time card or clock-in card.

## 🚀 Project Overview

The project provides two main interfaces:
1.  **CLI Tool**: A command-line interface for manual checks and configuration.
2.  **Telegram Bot**: An interactive bot that allows users to log their start time and receive notifications when their shift ends or when they reach the "liquidated overtime" threshold.

## 🛠️ Core Functionality

-   **Work End Calculation**: Calculates the exact time a shift ends based on:
    -   Start Time (HH:MM)
    -   Work Duration (Default: 07:12)
    -   Lunch Break (Default: 00:30)
    -   Leisure Time (Optional HH:MM to subtract from work time)
-   **Automated Notifications**:
    -   **Shift End**: Notifies the user via Telegram when the work duration is reached.
    -   **Liquidated Overtime**: Notifies when the user has exceeded the shift end by 30 minutes (the threshold for liquidatable overtime).
-   **Persistent Storage**: Uses a local SQLite database to store user settings, chat IDs, and daily start times.

## 📁 Project Structure

-   `main.py`: Entry point for the CLI tool (built with `typer`).
-   `bot.py`: Implementation of the Telegram bot (built with `python-telegram-bot`).
-   `cartellino.py`: Core logic for time calculations and shift management.
-   `database.py`: Database interaction layer using SQLite.
-   `actions.py`: Shared business logic actions used by both CLI and Bot.
-   `Dockerfile` & `docker-compose.yml`: Configuration for containerized deployment.
-   `cartellino.db`: SQLite database file.

## 📊 Database Schema

The system uses three main tables:
-   `settings`: Global configurations (e.g., default `work_time`, `lunch_time`).
-   `chats`: Registry of authorized Telegram chat IDs.
-   `user_settings`: Store daily specific values like `start_time` and `leisure_time` (keyed by `chat_id` and `date`).

## ⚙️ Setup and Usage

### Prerequisites
-   Python 3.10+
-   A Telegram Bot Token (set as `TELEGRAM_BOT_TOKEN` in `.env`)

### Running the CLI
```bash
# Set today's start time
python main.py start 09:00

# Check remaining time
python main.py work-end

# Show current config
python main.py config
```

### Running the Telegram Bot
```bash
python main.py job
# OR
python bot.py
```

### Docker Deployment
```bash
docker compose up -d
```

### Deployment & Automation (Makefile)
Common tasks are automated via the `Makefile`:
- `make run`: Starts the Telegram bot using `uv`.
- `make docker-build`: Builds the Docker image.
- `make start` / `make stop`: Manage the containerized application.
- `make format`: Formats code using `ruff`.
- `make railway-start`: Deploys the application to [Railway](https://railway.app/).

## 🧰 Tech Stack

-   **Language**: Python
-   **CLI Framework**: [Typer](https://typer.tiangolo.com/)
-   **Bot Library**: [python-telegram-bot](https://python-telegram-bot.org/)
-   **Database**: SQLite
-   **Containerization**: Docker & Docker Compose
-   **Package Manager**: `uv` or `pip`
