import os
import sys
import argparse

from dotenv import load_dotenv

import telegram
import asyncio


async def send_telegram_notification(
    bot_token: str, chat_id: str, message: str
) -> None:
    """
    Sends a notification via Telegram bot.

    Args:
        bot_token: The Telegram bot token.
        chat_id: The chat ID to send the message to.
        message: The message to send.
    """
    bot = telegram.Bot(token=bot_token)

    async with bot:
        await bot.send_message(chat_id=chat_id, text=message)
        print("Notification sent successfully!")


async def get_chat_ids(bot_token: str) -> None:
    """
    Gets chat IDs from recent bot interactions.

    Args:
        bot_token: The Telegram bot token.
    """
    bot = telegram.Bot(token=bot_token)
    async with bot:
        updates = await bot.get_updates()
        if not updates:
            print("No new messages found.")
            return

        chat_ids = {
            update.message.chat.id
            for update in updates
            if update.message and update.message.chat
        }

        if chat_ids:
            print("Found chat IDs:")
            for chat_id in chat_ids:
                print(chat_id)
        else:
            print("No chat IDs found in recent messages.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Telegram notifier.")
    parser.add_argument(
        "--get-chat-ids",
        action="store_true",
        help="Get chat IDs from recent bot interactions.",
    )
    args = parser.parse_args()

    load_dotenv()

    bot_token = os.environ.get("TELEGRAM_BOT_TOKEN")
    if not bot_token:
        print("Error: TELEGRAM_BOT_TOKEN environment variable not set.")
        sys.exit(1)

    if args.get_chat_ids:
        asyncio.run(get_chat_ids(bot_token))
    else:
        chat_id = os.environ.get("TELEGRAM_CHAT_ID")
        message = "Work time is over!"
        asyncio.run(send_telegram_notification(bot_token, chat_id, message))
