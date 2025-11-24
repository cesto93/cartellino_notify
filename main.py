import asyncio
import os
import sys
from typing import Optional
import typer
from dotenv import load_dotenv

from cartellino import turn_end_time, time_to_turn_end
from notify import send_telegram_notification, get_chat_ids

app = typer.Typer()


@app.command()
def work_end(
    start_time: str = typer.Argument(..., help="Start time in 'HH:MM' format"),
    work_time: str = typer.Option(
        "07:12",
        "--work-time",
        help="Work duration in 'HH:MM' format. Defaults to 07:12",
        metavar="HH:MM",
    ),
    lunch_time: str = typer.Option(
        "0:30",
        "--lunch-time",
        help="Lunch duration in 'HH:MM' format. Defaults to 0:30",
    ),
    leisure_time: Optional[str] = typer.Option(
        None,
        "--leisure-time",
        help="Leisure duration in 'HH:MM' format to be subtracted from work time.",
        metavar="HH:MM",
    ),
):
    """
    A simple tool to calculate remaining time until work turn finishes.
    """
    finish_time = turn_end_time(start_time, work_time, lunch_time, leisure_time)
    print(f"Time remaining until work turn finishes at {finish_time}.")
    remaining_time = time_to_turn_end(start_time, work_time, lunch_time, leisure_time)
    print(f"Remaining time: {remaining_time}")


@app.command()
def notify(
    message: str = typer.Argument("Work time is over!", help="Message to send."),
):
    """
    Sends a notification via Telegram bot.
    """
    bot_token = os.environ.get("TELEGRAM_BOT_TOKEN")
    if not bot_token:
        print("Error: TELEGRAM_BOT_TOKEN environment variable not set.")
        sys.exit(1)

    chat_id = os.environ.get("TELEGRAM_CHAT_ID")
    if not chat_id:
        print("Error: TELEGRAM_CHAT_ID environment variable not set.")
        sys.exit(1)

    asyncio.run(send_telegram_notification(bot_token, chat_id, message))


@app.command()
def chat_ids():
    """
    Gets chat IDs from recent bot interactions.
    """
    bot_token = os.environ.get("TELEGRAM_BOT_TOKEN")
    if not bot_token:
        print("Error: TELEGRAM_BOT_TOKEN environment variable not set.")
        sys.exit(1)

    print("Getting chat IDs...")
    asyncio.run(get_chat_ids(bot_token))


if __name__ == "__main__":
    load_dotenv()
    app()
