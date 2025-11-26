import asyncio
import os
import sys
from typing import Optional
import typer

from cartellino import time_to_turn_end, turn_end_time
from database import (
    get_all_settings,
    get_setting,
    get_start_time,
    init_db,
    get_daily_setting,
    store_setting,
    store_start_time,
    store_daily_setting,
)
from bot import send_telegram_notification, get_chat_ids, start_bot

app = typer.Typer(
    no_args_is_help=True,
    help="Cartellino Notify CLI Tool",
    context_settings={"help_option_names": ["-h", "--help"]},
)


@app.command()
def work_end(
    start_time: Optional[str] = typer.Argument(
        None, help="Start time in 'HH:MM' format. Defaults to value stored for today."
    ),
    work_time: Optional[str] = typer.Option(
        None,
        "--work-time",
        help="Work duration in 'HH:MM' format. Defaults to value in db or '07:12'",
        metavar="HH:MM",
    ),
    lunch_time: Optional[str] = typer.Option(
        None,
        "--lunch-time",
        help="Lunch duration in 'HH:MM' format. Defaults to value in db or '00:30'",
    ),
    leisure_time: Optional[str] = typer.Option(
        None,
        "--leisure-time",
        help="Leisure duration in 'HH:MM' format to be subtracted from work time. Defaults to value in db.",
        metavar="HH:MM",
    ),
):
    """
    A simple tool to calculate remaining time until work turn finishes.
    """
    # Using a default chat_id for CLI usage
    st = start_time or get_start_time(0)
    if not st:
        print(
            "Error: Start time not provided and no start time stored for today.\n"
            "Use 'start' command to store it or provide it as an argument."
        )
        raise typer.Exit(code=1)

    wt = work_time or get_setting("work_time") or "07:12"
    lt = lunch_time or get_setting("lunch_time") or "00:30"
    lrt = leisure_time or get_daily_setting(0, "leisure_time")

    finish_time = turn_end_time(st, wt, lt, lrt)
    print(f"Time remaining until work turn finishes at {finish_time}.")
    remaining_time = time_to_turn_end(st, wt, lt, lrt)
    print(f"Remaining time: {remaining_time}")


@app.command()
def start(start_time: str = typer.Argument(..., help="Start time in 'HH:MM' format")):
    """
    Stores the start time for the current day.
    """
    # Using a default chat_id for CLI usage
    store_start_time(0, start_time)
    print(f"Stored start time for today: {start_time}")


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
def job():
    """
    Waits until work end and sends a notification.
    """

    start_bot()


@app.command()
def chat_ids():
    """
    Gets and stores chat IDs from recent bot interactions.
    """
    bot_token = os.environ.get("TELEGRAM_BOT_TOKEN")
    if not bot_token:
        print("Error: TELEGRAM_BOT_TOKEN environment variable not set.")
        sys.exit(1)

    print("Getting chat IDs...")
    asyncio.run(get_chat_ids(bot_token))


@app.command(name="set")
def set_config(
    work_time: Optional[str] = typer.Option(
        None, "--work-time", help="Work duration in 'HH:MM' format."
    ),
    lunch_time: Optional[str] = typer.Option(
        None, "--lunch-time", help="Lunch duration in 'HH:MM' format."
    ),
    leisure_time: Optional[str] = typer.Option(
        None, "--leisure-time", help="Leisure duration in 'HH:MM' format."
    ),
):
    """
    Stores configuration values in the database.
    """
    if work_time:
        store_setting("work_time", work_time)
        print(f"Stored work_time: {work_time}")
    if lunch_time:
        store_setting("lunch_time", lunch_time)
        print(f"Stored lunch_time: {lunch_time}")
    if leisure_time:
        # Using a default chat_id for CLI usage
        store_daily_setting(0, "leisure_time", leisure_time)
        print(f"Stored leisure_time: {leisure_time}")


@app.command(name="config")
def show_config():
    """Shows all stored configurations."""
    print(get_all_settings())


@app.command(name="help")
def help_command(ctx: typer.Context):
    """
    Shows the main help message.
    """
    if ctx.parent is not None:
        typer.echo(ctx.parent.get_help())


if __name__ == "__main__":
    init_db()
    app()
